FROM openjdk:8u181-jdk

EXPOSE 8080
ADD target/spring-boot-swagger*SNAPSHOT.jar spingbootapi.jar

ENTRYPOINT ["java", "-Xmx100m", "-jar", "spingbootapi.jar"]
