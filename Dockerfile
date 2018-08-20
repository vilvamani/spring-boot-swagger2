FROM openjdk:8u181-jdk

EXPOSE 8080
ADD target/spring-boot-swagger2-0.0.1-SNAPSHOT.jar spingbootapi.jar

ENTRYPOINT ["java", "-Xmx100m", "-jar", "spingbootapi.jar"]
