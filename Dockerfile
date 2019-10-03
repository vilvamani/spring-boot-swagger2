FROM openjdk:8u181-jdk

ARG app_version=not_set
ARG git_commit_id=not_set

RUN echo "app_version: $app_version" > /version.yml
RUN echo "git_commit_id: $git_commit_id" >> /version.yml

EXPOSE 8080
ADD target/spring-boot-swagger*SNAPSHOT.jar spingbootapi.jar

ENTRYPOINT ["java", "-Xmx100m", "-jar", "spingbootapi.jar"]
