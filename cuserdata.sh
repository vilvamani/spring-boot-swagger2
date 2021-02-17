#!/bin/bash

while [[ $# > 0 ]]
do
  key="$1"
  shift
  case "$key" in
    --resource_group|-rg)
      resource_group="$1"
      shift
      ;;
    --aks_name|-an)
      aks_name="$1"
      shift
      ;;
    --molecule_username)
      molecule_username="$1"
      shift
      ;;
    --molecule_password)
      molecule_password="$1"
      shift
      ;;
    --molecule_account)
      molecule_account="$1"
      shift
      ;;
    --fileshare)
      fileshare="$1"
      shift
      ;;
    --netAppIP)
      netAppIP="$1"
      shift
      ;;
    --help|-help|-h)
      print_usage
      exit 13
      ;;
    *)
      echo "ERROR: Unknown argument '$key' to script '$0'" 1>&2
      exit -1
  esac
done

exec &> /var/log/bastion.log
set -x

#cfn signaling functions
yum install git -y || apt-get install -y git || zypper -n install git

#install kubectl
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client

rpm --import https://packages.microsoft.com/keys/microsoft.asc

cat <<EOF > /etc/yum.repos.d/azure-cli.repo
[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

yum install azure-cli -y

yum install -y nfs-utils

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

#Sign in with a managed identity
az login --identity

#Sign in with a service principal
#az login --service-principal --username "$app_id" --password "$app_key" --tenant "$tenant_id"

az aks get-credentials --resource-group "$resource_group" --name "$aks_name"

helm repo add stable https://charts.helm.sh/stable

helm install --generate-name --set nfs.server=$netAppIP --set nfs.path=$fileshare stable/nfs-client-provisioner

cat >/tmp/secrets.yaml <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: boomi-secret
type: Opaque
stringData:
  username: $molecule_username
  password: $molecule_password
  account: $molecule_account
EOF

cat >/tmp/persistentvolume.yaml <<EOF
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: azurefile
spec:
  storageClassName: "nfs-client"
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  mountOptions:
    - vers=3
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: $netAppIP
    path: $fileshare
EOF

whoami

