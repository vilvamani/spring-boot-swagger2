#!/usr/bin/env groovy
import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException

def label = "slave-${UUID.randomUUID().toString()}"
def IMAGE_VERSION = ''

def getGitCredentials() {
  checkout scm
  print("============1================")
  sh "ls -l"
  IMAGE_VERSION = sh(label: 'get last commit', returnStdout: true, script: 'git rev-parse --short HEAD~0')
}


def slackNotifier(String buildResult) {
	
  currentBuild.displayName = "#" + (currentBuild.number + ' - ' + buildResult)
	
  if ( buildResult == "SUCCESS" ) {
    slackSend color: "good", message: "Deployment of ${env.JOB_NAME} with buildnumber ${env.BUILD_NUMBER} : <${BUILD_URL}|Successfull>"
  }
  else if( buildResult == "FAILURE" ) { 
    slackSend color: "danger", message: "Deployment of ${env.JOB_NAME} with buildnumber ${env.BUILD_NUMBER} : <${BUILD_URL}|Failed>"
  }
  else if( buildResult == "UNSTABLE" ) { 
    slackSend color: "warning", message: "Deployment of ${env.JOB_NAME} with buildnumber ${env.BUILD_NUMBER} : <${BUILD_URL}|Unstable"
  }
  else {
    slackSend color: "danger", message: "Deployment of ${env.JOB_NAME} with buildnumber ${env.BUILD_NUMBER} : <${BUILD_URL}|Unclear"	
  }
}


podTemplate(label: label, containers: [
    containerTemplate(name: 'jnlp', image: 'jenkins/jnlp-slave:4.7-1-alpine', args: '${computer.jnlpmac} ${computer.name}', runAsGroup: '1000', runAsUser: '1000'),
    containerTemplate(name: 'maven', image: 'algoshack/k8s-docker-slave:maven', command: 'cat', ttyEnabled: true, runAsGroup: '1000', runAsUser: '1000'),
    containerTemplate(name: 'rubyimage', image: 'vilvamani007/ruby:10', command: 'cat', ttyEnabled: true)
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
        ])
        container('maven') {
          stage('Git Checkout') {
            cleanWs()  
            sh "ls -l"
            getGitCredentials()
            print("============2================")
            
            sh "git config user.name 'vilvamani'"

            withCredentials([usernamePassword(credentialsId: 'github-token', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                creds = "${GIT_USERNAME}"
                sh """
                set +x
                echo ${creds}
                """
            }

            sh """
            git config user.email translated-reviews@bazaarvoice.com
            git config user.name 'git'
            git tag -a test -m test

            """
            withCredentials([usernamePassword(credentialsId: 'github-token', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                print(creds)
                
                sh """
                git config --list
                git push --tags
                """
            }
            
          }

        }

        currentBuild.result = 'SUCCESS'
      }
    } 
    catch (FlowInterruptedException interruptEx) {
      echo "Job was cancelled"
      currentBuild.result = 'FAILURE'
      throw interruptEx
    }
    catch (Exception err) {
        print(err)
      currentBuild.result = 'FAILURE'
    }
    finally{
	  /* Use slackNotifier.groovy from shared library and provide current build result as parameter */
      slackNotifier(currentBuild.result)
    }
  }
}
