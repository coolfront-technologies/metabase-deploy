# Multi-stage build for Metabase
# Using official Eclipse Temurin JRE - widely compatible
FROM eclipse-temurin:11-jre

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the start script (using existing bin/start)
COPY bin/start ./bin/start
RUN chmod +x ./bin/start

# Copy pre-built Metabase JAR
# Note: You need to build the JAR separately or download it
# For production, replace with your actual JAR or build it in a previous stage
COPY target/uberjar/metabase.jar ./target/uberjar/metabase.jar

# Set environment variables for Metabase
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV MB_JETTY_HOST=0.0.0.0

# Expose port (Azure App Service uses PORT env var, default to 3000)
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT:-3000}/api/health || exit 1

# Run the application
CMD ["./bin/start"]
