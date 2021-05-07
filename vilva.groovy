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
    containerTemplate(name: 'jnlp', image: '549050352176.dkr.ecr.us-east-1.amazonaws.com/translated-reviews/jenkins-jnlp:4.7-1', args: '${computer.jnlpmac} ${computer.name}'),
    containerTemplate(name: 'awscli', image: 'amazon/aws-cli:2.2.3', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'sonarqube', image: 'sonarsource/sonar-scanner-cli:4.6', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'nodejs', image: 'node:11-alpine', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'kaniko', image: 'gcr.io/kaniko-project/executor:debug', command: '/busybox/cat', ttyEnabled: true),
  ],
  volumes: [
    configMapVolume(configMapName: 'docker-config', mountPath: '/kaniko/.docker/'),
  ],
  envVars: [],
  annotations: [
    podAnnotation(key: "iam.amazonaws.com/role", value: "arn:aws:iam::549050352176:role/translated-reviews-deploy")
  ],
  runAsUser: '1000',
  runAsGroup: '1000'
) {
  timeout(time: 2, unit: 'HOURS') {
    try {
      node(label) {
        properties([
            disableConcurrentBuilds(),
            parameters([booleanParam(defaultValue: false, description: 'Whether or not to wait for canary deployment + check', name: 'skipCanary')])
        ])

        container('nodejs') {
          stage('Install') {
              getGitCredentials()
              IMAGE_VERSION = "${GIT_COMMIT}-${BRANCH_NAME}-${BUILD_NUMBER}"
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
