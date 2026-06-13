# Build stage
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn package -DskipTests

# Run stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copy the built jar
COPY --from=build /app/target/cricmanager-backend-0.0.1-SNAPSHOT.jar app.jar

# Bundle the required CSV data files
RUN mkdir -p /app/Output
COPY Output/player_season_values.csv /app/Output/player_season_values.csv
COPY Output/historical_squad_values.csv /app/Output/historical_squad_values.csv

# HuggingFace Spaces requires port 7860
EXPOSE 7860

# Server port env var — Spring will read SERVER_PORT
ENV SERVER_PORT=7860

ENTRYPOINT ["java", "-jar", "app.jar"]
