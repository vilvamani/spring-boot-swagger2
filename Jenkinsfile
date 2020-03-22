node('laptop') {

 def mvnHome = tool 'M3'
 env.PATH = "${mvnHome}/bin:${env.PATH}"

 imageName = "vilvamani007/testrepo:${env.BUILD_NUMBER}"

 stage('SCM') {
  git 'https://github.com/vilvamani/spring-boot-swagger2'
 }

 stage('Build') {
  sh 'mvn clean install'
 }

 stage('DockerBuild') {
  // This step should not normally be used in your script. Consult the inline help for details.

  customImage = docker.build(imageName)
 }

 stage('DockerPush') {
  withDockerRegistry(credentialsId: '9e3831ee-d147-48f4-81f8-9eb813bd97cb') {
   customImage.push()
  }
 }

 stage('Anchore') {
  writeFile file: 'anchore_images', text: imageName
  anchore engineRetries: '500', name: 'anchore_images'
 }
}
