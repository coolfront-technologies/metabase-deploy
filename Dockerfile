# Multi-stage build for Metabase - Production Ready for Azure
# Stage 1: Download and prepare Metabase JAR
FROM eclipse-temurin:11-jdk as downloader

WORKDIR /download

# Install wget
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

# Download Metabase JAR from official releases
# Using v0.49.3 (latest stable available)
# Check available versions at: https://github.com/metabase/metabase/releases
RUN mkdir -p /metabase/target/uberjar && \
    wget https://downloads.metabase.com/v0.49.3/metabase.jar -O /metabase/target/uberjar/metabase.jar && \
    echo "JAR downloaded successfully: $(ls -lh /metabase/target/uberjar/metabase.jar)"

# Stage 2: Runtime stage
FROM eclipse-temurin:11-jre

# Install curl for health checks and other utilities
RUN apt-get update && \
    apt-get install -y curl bash && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the start script from repository
COPY bin/start ./bin/start
RUN chmod +x ./bin/start

# Copy pre-built Metabase JAR from downloader stage
COPY --from=downloader /metabase/target/uberjar/metabase.jar ./target/uberjar/metabase.jar

# Verify JAR exists
RUN ls -lh ./target/uberjar/metabase.jar || (echo "JAR not found!" && exit 1)

# ============================================
# Set environment variables for Metabase
# ============================================
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Jetty configuration
ENV MB_JETTY_HOST=0.0.0.0

# Java options for containerized environment
ENV JAVA_OPTS="-server -Djava.awt.headless=true -Dfile.encoding=UTF-8"

# ============================================
# Azure-specific configurations
# ============================================
# For Azure App Service, PORT env var is set by platform
# The bin/start script will use it automatically
# Database configuration examples (set via Azure environment):
# MB_DB_TYPE=postgres
# MB_DB_HOST=your-db.postgres.database.azure.com
# MB_DB_PORT=5432
# MB_DB_DBNAME=metabase
# MB_DB_USER=postgres@your-server
# MB_DB_PASS=your-password
# ============================================

# Expose port
EXPOSE 3000

# Health check for Azure monitoring
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT:-3000}/api/health || exit 1

# Run the application using the start script
CMD ["./bin/start"]
