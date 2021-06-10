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

mkdir -p ${MoleculeSharedDir}
chown -R boomi:boomi ${MoleculeSharedDir}
chmod -R 777 ${MoleculeSharedDir}

yum update -y --disablerepo='*' --enablerepo='*microsoft*'
yum install nfs-utils git wget -y
yum install java-11-openjdk-devel -y

echo "$netAppIP:/$fileshare $MoleculeSharedDir nfs bg,rw,hard,noatime,nolock,rsize=65536,wsize=65536,vers=4.1,tcp,_netdev 0 0" >> /etc/fstab
mount -a

mkdir -p ${MoleculeLocalPath}
mkdir -p ${MoleculeLocalPath}/data
mkdir -p ${MoleculeLocalPath}/tmpdata
mkdir -p ${MoleculeLocalTemp}
mkdir -p ${MoleculeSharedDir}/Molecule_${MoleculeClusterName}

chown -R boomi:boomi ${MoleculeLocalPath} ${MoleculeLocalTemp}
chown -R boomi:boomi ${MoleculeLocalPath}/data
chown -R boomi:boomi ${MoleculeLocalPath}/tmpdata
chown -R boomi:boomi ${MoleculeSharedDir}/Molecule_${MoleculeClusterName}

chmod -R 777 ${MoleculeLocalPath}/


cat >/tmp/molecule_set_cluster_properties.sh <<EOF
#!/bin/bash
LOCAL_IVP4=$(curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2019-06-01&format=text")
echo com.boomi.container.cloudlet.initialHosts=${!LOCAL_IVP4}[7800] >> ${MoleculeSharedDir}/Molecule_${MoleculeClusterName}/conf/container.properties
echo com.boomi.container.cloudlet.clusterConfig=UNICAST >> ${MoleculeSharedDir}/Molecule_${MoleculeClusterName}/conf/container.properties
echo com.boomi.deployment.quickstart=True >> ${MoleculeSharedDir}/Molecule_${MoleculeClusterName}/conf/container.properties
EOF

chmod -R 777 /tmp/molecule_set_cluster_properties.sh

cat >/tmp/molecule.service <<EOF
[Unit]
Description=Dell Boomi Molecule Cluster
After=network.target
RequiresMountsFor=${MoleculeSharedDir}/Molecule_${MoleculeClusterName}
[Service]
Type=forking
User=root
Restart=always
ExecStart=${MoleculeSharedDir}/Molecule_${MoleculeClusterName}/bin/atom start
ExecStop=${MoleculeSharedDir}/Molecule_${MoleculeClusterName}/bin/atom stop
ExecReload=${MoleculeSharedDir}/Molecule_${MoleculeClusterName}/bin/atom restart
[Install]
WantedBy=multi-user.target
EOF

chmod -R 777 /tmp/molecule.service

wget https://platform.boomi.com/atom/molecule_install64.sh -P /tmp
chmod -R 777 /tmp/molecule_install64.sh


local_ip=$(ip addr show dev eth0 | egrep -oi 'inet.*brd' | cut -d '/' -f 1 | awk '{print $2}')
ip_hostname=$(hostname -s)
echo "${local_ip} ${ip_hostname}" >> /etc/hosts

if [ $boomi_auth == "token" ]
then
  echo "************token**************"
 ls -l
 sh /tmp/molecule_install64.sh -q -console -Vusername=$boomi_username -VinstallToken=$boomi_token  -VatomName=$MoleculeClusterName -VaccountId=$oomi_account -VlocalPath=$MoleculeLocalPath -VlocalTempPath=$MoleculeLocalTemp -dir $MoleculeSharedDir
else
 echo "************password**************"
 ls -l
 sh /tmp/molecule_install64.sh -q -console -Vusername=$boomi_username -Vpassword=$boomi_password  -VatomName=$MoleculeClusterName -VaccountId=$boomi_account -VlocalPath=$MoleculeLocalPath -VlocalTempPath=$MoleculeLocalTemp -dir $MoleculeSharedDir
fi
 
chown -R boomi:boomi ${MoleculeSharedDir}/Molecule_${MoleculeClusterName}
#sh /tmp/molecule_set_cluster_properties.sh

mv /tmp/molecule.service /lib/systemd/system/molecule.service
systemctl enable molecule

${MoleculeSharedDir}/Molecule_${MoleculeClusterName}/bin/atom stop
sudo -u boomi bash -c "$MoleculeSharedDir/Molecule_$MoleculeClusterName/bin/atom start"


