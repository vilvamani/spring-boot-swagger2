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
    containerTemplate(name: 'maven', image: 'maven:3.8.1-openjdk-8', command: 'cat', ttyEnabled: true, runAsGroup: '1000', runAsUser: '1000'),
    containerTemplate(name: 'maven1', image: 'vilvamani007/k8s-docker-slave:maven1', command: 'cat', ttyEnabled: true, runAsGroup: '1000', runAsUser: '1000'),
    containerTemplate(name: 'node', image: 'vilvamani007/k8s-docker-slave:node', command: 'cat', ttyEnabled: true, runAsGroup: '1000', runAsUser: '1000'),
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
            git_commit = sh label: 'get last commit', returnStdout: true, script: 'git rev-parse --short HEAD~0'
            author_email = sh label: 'get last commit', returnStdout: true, script: 'git log -1 --pretty=format:"%ae"'
          }

          stage("UnitTest") {
            sh 'mvn clean test -U'
          }

          stage("Publish Report"){
            junit(allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml,' + '**/target/failsafe-reports/*.xml')
            jacoco()
          }

          stage("Maven Build") {
            sh "mvn install -DskipTests"
            sh '''
              echo Download newRelicc jar
              curl -O https://download.newrelic.com/newrelic/java-agent/newrelic-agent/current/newrelic-java.zip
              jar -xvf newrelic-java.zip
            '''
          }
        }

        container('sonarqube') {
          stage('SonarQube') {
            withSonarQubeEnv('SonarQube') {
              sh '''
                sonar-scanner -Dsonar.projectBaseDir=${WORKSPACE} -Dsonar.projectKey=springboot-api -Dsonar.login="${SONARQUBE_API_TOKEN}" -Dsonar.java.binaries=target/classes -Dsonar.sources=src/main/java/ -Dsonar.language=java
              '''
            }
          }
        }
        
        stage('Create Docker images') {
          container(name: 'kaniko', shell: '/busybox/sh') {
            withEnv(['PATH+EXTRA=/busybox:/kaniko']) {
            sh '''
              #!/busybox/sh
              cp newrelic/newrelic.jar ./newrelic.jar
              rm -rf newrelic newrelic-java.zip
              /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --destination=vilvamani007/test:${IMAGE_VERSION}
            '''
            }
            
            kubeconfig(caCertificate: 'LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeE1EVXdPVEF6TXpjeE5Gb1hEVE14TURVd056QXpNemN4TkZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTGJkCjc4dEJOTnljMGFCdWxyZkR1b1FpaFI2SnliRGNuL0s0ZHBlUU9ZcUFoQk96bzMrRUY1VmExYlpwb090N3F2ekwKK1NsN2JXcVRBbGtKdERpTnJmb3c5KzgxVTBWZVN1UGtBQlRLUW1GbFZUbnIzcmtjMVVRamhMRDFWUk91UDdVWQpkSWdkQnplYXJLNytyZlBDYTZEWU5rV2piZjg3dkh2Zm5yNWFYTWJqNk9YL3ZVRU96T3B4MEVMbE9mQlA4NENYClJoenp1c1NGVFcyRzBPT25HNklvM2pvYnVGeDNqWGRNNEtHTkJQZWJ5ZE9hTktjWlV0aXNYQTRKaXU2eUVRbjYKSU9scVBXWXN2MHQyWkozV0xUdFRFY0hNd01zUmF3bCtNMVNzNERSR2dHNUxBVjdDak4rRndoYkpVdkZDS3BDZwprWU9yU1pHOUdFK3ROeXBFNnIwQ0F3RUFBYU5DTUVBd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZMd2NFTWl6UFJjU0ZvL0dRbCtVdUpCYTRyQ2dNQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFDSTRBOHJRVGdCTG1pNFRuakJ3MVlCbGJqeGZQUjVKU2NGcm1JMWVLWjRGTmd4b3ZqRwpKc3QzelUzd3EwZ0N4OEFFMkltN1hrSnpLdzNUWTNmSUJNdFBxVTVDOGhIUUFWaVRmOStOZzlaa2RRWWNEREE1CnR2ejNTVEpWSWhmOXcwaGllWkljUG9XTHMwWjE1bi9qVCtXOHBPVnRQck53cnlYTDVIZzE1Zmt5K3c5ck5WbmYKUFFVRVRXN25iM2VDTDQ0eHZuYWdIcUkrdzZmZ1BCdWV5QS8wVnN3dTJoMjlUeUVCSUhFR0M3cTZYMVMxMkNtTwpMYlNzdzRMU1FoV0pPK1k1WndqVEhnRFQ3VGlGYnFmeWIxU3Fka1BFZUFwdndqUmRXdjIvZzRxK003TzNvZm1ICmFhVEMwVXRaWXhuY2VOSW1xM3J0MVM2UFZHQXZnYmw2VzVragotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==', serverUrl: 'https://10.0.101.6:6443') {
    kubectl get pods -A
}
          }
        }
      }
    } 
    catch (FlowInterruptedException interruptEx) {
      echo "Job was cancelled"
      throw interruptEx
    }
    catch (failure) {
      throw failure
    }
  }
}
