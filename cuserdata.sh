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

yum -y update

yum install java-1.8.0-openjdk -y

#cfn signaling functions
yum install git wget -y || apt-get install -y git || zypper -n install git

yum install -y nfs-utils

mkdir -p ~/$fileshare

mount -t nfs -o rw,hard,rsize=1048576,wsize=1048576,vers=4.1,tcp $netAppIP:/$fileshare ~/$fileshare -o dir_mode=0755,file_mode=0664

wget https://platform.boomi.com/atom/molecule_install64.sh
chmod -R 777 ./molecule_install64.sh

if [ $boomi_auth == "token" ]
then
  echo "************token**************"
 ls -l
 ./molecule_install64.sh -q -console -Vusername=$boomi_username -VinstallToken=$boomi_token  -VatomName=azureMolecule -VaccountId=$oomi_account -VlocalPath=/tmp/local -VlocalTempPath=/home/centos/temp -dir ~/$fileshare
 else
 echo "************password**************"
 ls -l
 ./molecule_install64.sh -q -console -Vusername=$boomi_username -Vpassword=$boomi_password  -VatomName=azureMolecule -VaccountId=$boomi_account -VlocalPath=/tmp/local -VlocalTempPath=/home/centos/temp -dir ~/$fileshare
 fi
