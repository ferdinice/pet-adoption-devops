FROM eclipse-temurin:11-jre

WORKDIR /app

COPY target/spring-petclinic-2.4.2.war app.war

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.war", "--server.port=8080"]