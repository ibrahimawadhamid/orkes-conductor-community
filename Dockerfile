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

FROM alpine:3.18 AS runner
LABEL maintainer="Ibrahim Awad <ibrahim.a.hamid@gmail.com>"

RUN apk add --no-cache coreutils curl openjdk17 && rm -rf /var/cache/apk/* \
	&& mkdir -p /app/config /app/logs /app/libs /app/info

COPY ./docker/config/startup.sh /app/startup.sh
COPY ./docker/config/config.properties /app/config/config.properties

COPY --from=builder /app/server/build/libs/orkes-conductor-server-boot.jar /app/libs/server.jar

HEALTHCHECK --interval=60s --timeout=30s --retries=10 CMD ["curl", "-I", "-XGET", "http://localhost:8080/health"]

EXPOSE 8080

CMD ["/app/startup.sh"]
ENTRYPOINT ["/bin/sh"]
