#
# conductor:server - Netflix conductor server
#
# ===========================================================================================================
# 0. Builder stage
# ===========================================================================================================

FROM eclipse-temurin:17-jdk AS builder
LABEL maintainer="Ibrahim Awad <ibrahim.a.hamid@gmail.com>"

COPY . /app
WORKDIR /app
RUN ./gradlew clean build -x test && echo "Done building Server"

# ===========================================================================================================
# 1. Runtime stage
# ===========================================================================================================

# Stage 2: Runtime stage with platform-specific adjustments
FROM --platform=$TARGETPLATFORM alpine:3.18 AS runtime
LABEL maintainer="Ibrahim Awad <ibrahim.a.hamid@gmail.com>"

# ARG to detect platform during build
ARG TARGETPLATFORM

# Default environment
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Install OpenJDK for supported platforms
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ] || [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        apk add --no-cache coreutils curl openjdk17-jre-base && \
        mkdir -p /app/config /app/logs /app/libs /app/info; \
    else \
        echo "Unsupported platform for openjdk17 on Alpine"; exit 1; \
    fi

COPY ./docker/config/startup.sh /app/startup.sh
COPY ./docker/config/config.properties /app/config/config.properties

COPY --from=builder /app/server/build/libs/orkes-conductor-server-boot.jar /app/libs/server.jar

HEALTHCHECK --interval=60s --timeout=30s --retries=10 CMD ["curl", "-I", "-XGET", "http://localhost:8080/health"]

EXPOSE 8080

CMD ["/app/startup.sh"]
ENTRYPOINT ["/bin/sh"]
