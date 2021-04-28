#!/bin/bash

git clone https://github.com/vilvamani/quickstart-eks-boomi-molecule.git boomi_quickstart
pip install -t . -r ./boomi_quickstart/functions/source/BoomiLicenseValidation/requirements.txt

wget https://raw.githubusercontent.com/vilvamani/spring-boot-swagger2/master/test.py

az extension add --name aks-preview

if [ $BOOMIAUTHENTICATIONTYPE == "token" ]
then
    result=`python test.py "$MOLECULEACCOUNTID" "BOOMI_TOKEN.$MOLECULEUSERNAME" "$BOOMIMFAAPITOKEN" MOLECULE 60`
else
    result=`python test.py "$MOLECULEACCOUNTID" "$MOLECULEUSERNAME" "$MOLECULEPASSWORD" MOLECULE 60`
fi

echo \{\"result\":\"$result\"\} > $AZ_SCRIPTS_OUTPUT_PATH
