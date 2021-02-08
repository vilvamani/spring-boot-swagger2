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
    --storage_acc_name|-san)
      storage_acc_name="$1"
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

#Sign in with a managed identity
az login --identity

#Sign in with a service principal
#az login --service-principal --username "$app_id" --password "$app_key" --tenant "$tenant_id"

az aks get-credentials --resource-group "$resource_group" --name "$aks_name"

# Get storage account key
storage_acc_key=$(az storage account keys list --resource-group "$resource_group" --account-name "$storage_acc_name" --query "[0].value" -o tsv)

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

cat >/tmp/service.yaml <<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: molecule-service
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-resource-group: $resource_group
  labels:
    app: molecule
spec:
  selector:
    app: molecule
  ports:
  - protocol: TCP
    port: 80
    targetPort: 9090
EOF

cat >/tmp/persistentvolume.yaml <<EOF
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: azurefile
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteMany
  storageClassName: "azurefile"
  azureFile:
    secretName: azure-secret
    shareName: $fileshare
    readOnly: false
  mountOptions:
  - dir_mode=0777
  - file_mode=0777
  - uid=1000
  - gid=1000
  - mfsymlinks
  - nobrl
EOF

whoami

kubectl get nodes --kubeconfig=/root/.kube/config

kubectl create secret generic azure-secret --from-literal=azurestorageaccountname="$storage_acc_name" --from-literal=azurestorageaccountkey="$storage_acc_key"  --kubeconfig=/root/.kube/config

#kubectl apply -f https://raw.githubusercontent.com/vilvamani/boomi-aks/main/kubernetes/persistent_volume.yaml --kubeconfig=/root/.kube/config

kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/v1.6.0/deploy/infra/deployment-rbac.yaml --kubeconfig=/root/.kube/config

kubectl apply -f /tmp/persistentvolume.yaml --kubeconfig=/root/.kube/config

kubectl apply -f https://raw.githubusercontent.com/vilvamani/boomi-aks/main/kubernetes/persistent_volume_claim.yaml --kubeconfig=/root/.kube/config

kubectl apply -f /tmp/secrets.yaml --kubeconfig=/root/.kube/config

kubectl apply -f https://raw.githubusercontent.com/vilvamani/boomi-aks/main/kubernetes/statefulset.yaml --kubeconfig=/root/.kube/config

kubectl apply -f /tmp/service.yaml --kubeconfig=/root/.kube/config

kubectl apply -f https://raw.githubusercontent.com/vilvamani/boomi-aks/main/kubernetes/hpa.yaml --kubeconfig=/root/.kube/config

#kubectl apply -f https://raw.githubusercontent.com/vilvamani/boomi-aks/main/kubernetes/ingress.yaml --kubeconfig=/root/.kube/config

rm /tmp/secrets.yaml
rm /tmp/service.yaml
rm /tmp/persistentvolume.yaml
