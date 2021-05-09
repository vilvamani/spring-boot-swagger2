#!/usr/bin/env groovy
import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException

def label = "slave-${UUID.randomUUID().toString()}"
def IMAGE_VERSION


def getGitCredentials() {
  def co = checkout(scm)
  sh 'git config --local credential.helper "!p() { echo username=\\$GIT_USERNAME; echo password=\\$GIT_PASSWORD; }; p"'
  GIT_COMMIT = co.GIT_COMMIT
}


podTemplate(label: label, containers: [
    containerTemplate(name: 'jnlp', image: 'jenkins/jnlp-slave:4.7-1-alpine', args: '${computer.jnlpmac} ${computer.name}', runAsGroup: '1000', runAsUser: '1000'),
    containerTemplate(name: 'awscli', image: 'amazon/aws-cli:2.2.3', command: 'cat', ttyEnabled: true, runAsGroup: '1000', runAsUser: '1000'),
    containerTemplate(name: 'sonarqube', image: 'sonarsource/sonar-scanner-cli:4.6', command: 'cat', ttyEnabled: true, runAsGroup: '1000', runAsUser: '1000'),
    containerTemplate(name: 'maven', image: 'vilvamani007/k8s-docker-slave:maven', command: 'cat', ttyEnabled: true, runAsGroup: '1000', runAsUser: '1000'),
    containerTemplate(name: 'kaniko', image: 'gcr.io/kaniko-project/executor:debug', command: '/busybox/cat', ttyEnabled: true, privileged: true, runAsGroup: '0', runAsUser: '0'),
  ],
  volumes: [
    configMapVolume(configMapName: 'docker-config', mountPath: '/kaniko/.docker/'),
  ],
  envVars: [],
  annotations: []/*,
  runAsUser: '1000',
  runAsGroup: '1000'*/
) {
  timeout(time: 30, unit: 'MINUTES') {
    try {
      node(label) {
        properties([
            disableConcurrentBuilds(),
            parameters([booleanParam(defaultValue: false, description: 'Whether or not to wait for canary deployment + check', name: 'skipCanary')])
        ])

        container('maven') {
          stage('Git Checkout') {
              getGitCredentials()
              IMAGE_VERSION = "${GIT_COMMIT}-${BRANCH_NAME}-${BUILD_NUMBER}"
          }

          stage("Read Author") {
              git_commit = sh label: 'get last commit',
                  returnStdout: true,
                  script: 'git rev-parse --short HEAD~0'
              author_email = sh label: 'get last commit',
                  returnStdout: true,
                  script: 'git log -1 --pretty=format:"%ae"'
          }

          stage("UnitTest") {
              sh 'mvn clean test -U'
          }

          stage("Publish Report"){
              junit(
                  allowEmptyResults: true,
                  testResults: '**/target/surefire-reports/*.xml,' +
                          '**/target/failsafe-reports/*.xml'
              )
              jacoco()
          }

          stage("Maven Build") {
              sh "mvn install -DskipTests"
          }
        }

        stage('SonarQube') {
          container('sonarqube') {
            withSonarQubeEnv('SonarQube') {
              sh '''
              sonar-scanner -Dsonar.projectBaseDir=${WORKSPACE} -Dsonar.projectKey=${env.JOB_NAME} -Dsonar.login="${SONARQUBE_API_TOKEN}"
            '''
            }
          }
        }
        
          stage('Create Docker images') {
            container(name: 'kaniko', shell: '/busybox/sh') {
              withEnv(['PATH+EXTRA=/busybox:/kaniko']) {
                sh """#!/busybox/sh
                ls -l
                /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --destination=vilvamani007/test:${IMAGE_VERSION}
                """
              }
            }
          }
      }

    } catch (FlowInterruptedException interruptEx) {
      echo "Job was cancelled"
      throw interruptEx
    } catch (failure) {
      throw failure
    }
  }
}
