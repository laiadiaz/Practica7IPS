# ── Etapa 1: Build ──────────────────────────────────────────────────────────
FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /app

# Copiar descriptor de dependencias primero (aprovecha el cache de Docker)
COPY pom.xml .
RUN mvn dependency:go-offline -q

# Copiar código fuente y compilar (tests se ejecutan en CI, no aquí)
COPY src ./src
RUN mvn package -DskipTests -q

# ── Etapa 2: Runtime ─────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Metadatos de la imagen
LABEL maintainer="laiadiaz"
LABEL org.opencontainers.image.description="Springuma - Hospital management with mammography AI analysis"
LABEL org.opencontainers.image.source="https://github.com/laiadiaz/Practica7IPS"

# Crear usuario no-root por seguridad
RUN addgroup -S spring && adduser -S spring -G spring
USER spring

# Copiar el JAR generado en la etapa de build
COPY --from=builder /app/target/Practica6-0.0.1-SNAPSHOT.jar app.jar

# Puerto en el que escucha Spring Boot
EXPOSE 8080

# Health check para que Docker/K8s sepan si el contenedor está sano
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
