# ---- Build stage ----
FROM eclipse-temurin:21-jdk AS builder
WORKDIR /app

# Leverage Docker layer caching for dependencies
COPY gradlew ./
COPY gradle ./gradle
COPY settings.gradle build.gradle ./
RUN chmod +x ./gradlew
# Warm Gradle caches (ignore failure if no network; build step will retry)
RUN ./gradlew --no-daemon dependencies || true

# Copy sources and build
COPY src ./src
RUN ./gradlew --no-daemon clean bootJar -x test

# ---- Runtime stage ----
FROM eclipse-temurin:21-jre
WORKDIR /app

# Vercel (and many PaaS) set PORT dynamically
ENV PORT=8080
ENV JAVA_OPTS=""

# Copy the fat jar from the builder
COPY --from=builder /app/build/libs/*.jar /app/app.jar

EXPOSE 8080
# Respect injected PORT and allow extra JVM opts
CMD ["sh", "-c", "java $JAVA_OPTS -Dserver.port=${PORT} -jar /app/app.jar"]
