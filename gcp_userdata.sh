  #!/bin/bash
  #### Log the execution to a file ####
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3 RETURN
  exec 1>/var/log/configure-bastion.log 2>&1

  set -x
  sudo yum update -y
  sudo yum install -y tinyproxy
  sudo yum install git -y

  curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin/kubectl
  kubectl version --client

  sudo yum -y install nfs-utils
  sudo mkdir -p /mnt/boominfs
