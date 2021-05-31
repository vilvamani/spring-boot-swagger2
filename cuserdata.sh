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
    --boomi_auth)
      boomi_auth="$1"
      shift
      ;;
    --boomi_token)
      boomi_token="$1"
      shift
      ;;
    --boomi_username)
      boomi_username="$1"
      shift
      ;;
    --boomi_password)
      boomi_password="$1"
      shift
      ;;
    --boomi_account)
      boomi_account="$1"
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

MoleculeSharedDir="/mnt/molecule"
MoleculeClusterName="molecule1"
MoleculeLocalPath="/opt/molecule/local/"
MoleculeLocalTemp="/mnt/tmp"


mkdir -p ${MoleculeLocalPath}
mkdir -p ${MoleculeSharedDir}
mkdir -p ${MoleculeLocalTemp}
mkdir -p ${MoleculeSharedDir}/Molecule_${MoleculeClusterName}

chown centos:centos ${MoleculeLocalPath} ${MoleculeLocalTemp}
chown centos:centos ${MoleculeSharedDir}/Molecule_${MoleculeClusterName}


cat >/tmp/molecule_set_cluster_properties.sh <<EOF
#!/bin/bash
LOCAL_IVP4=$(curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2019-06-01&format=text")
echo com.boomi.container.cloudlet.initialHosts=[7800] >> ${MoleculeSharedDir}/Molecule_${MoleculeClusterName}/conf/container.properties
echo com.boomi.container.cloudlet.clusterConfig=UNICAST >> ${MoleculeSharedDir}/Molecule_${MoleculeClusterName}/conf/container.properties
echo com.boomi.deployment.quickstart=True >> ${MoleculeSharedDir}/Molecule_${MoleculeClusterName}/conf/container.properties
EOF

cat >/tmp/molecule.service <<EOF
[Unit]
Description=Dell Boomi Molecule Cluster
After=network.target
RequiresMountsFor=/opt/boomi/Molecule_${MoleculeClusterName}
[Service]
Type=forking
User=root
Restart=always
ExecStart=/opt/boomi/Molecule_${MoleculeClusterName}/bin/atom start
ExecStop=/opt/boomi/Molecule_${MoleculeClusterName}/bin/atom stop
ExecReload=/opt/boomi/Molecule_${MoleculeClusterName}/bin/atom restart
[Install]
WantedBy=multi-user.target
EOF

yum install java-1.8.0-openjdk -y

#cfn signaling functions
yum install git wget -y || apt-get install -y git || zypper -n install git

yum install -y nfs-utils

mkdir -p ~/$fileshare

mount -t nfs -o rw,hard,rsize=1048576,wsize=1048576,vers=4.1,tcp $netAppIP:/$fileshare ~/$MoleculeSharedDir -o dir_mode=0755,file_mode=0664

chmod -R 777 /tmp/molecule_set_cluster_properties.sh
/tmp/molecule_set_cluster_properties.sh

wget https://platform.boomi.com/atom/molecule_install64.sh
chmod -R 777 ./molecule_install64.sh

if [ $boomi_auth == "token" ]
then
  echo "************token**************"
 ls -l
 ./molecule_install64.sh -q -console -Vusername=$boomi_username -VinstallToken=$boomi_token  -VatomName=$MoleculeClusterName -VaccountId=$oomi_account -VlocalPath=$MoleculeLocalPath -VlocalTempPath=$MoleculeLocalTemp -dir $MoleculeSharedDir
 else
 echo "************password**************"
 ls -l
 ./molecule_install64.sh -q -console -Vusername=$boomi_username -Vpassword=$boomi_password  -VatomName=$MoleculeClusterName -VaccountId=$boomi_account -VlocalPath=$MoleculeLocalPath -VlocalTempPath=$MoleculeLocalTemp -dir $MoleculeSharedDir
 fi
 
 mv /tmp/molecule.service /lib/systemd/system/molecule.service
 systemctl enable molecule
