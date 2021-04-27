#!/bin/bash
pythonVersion=$(python --version)

git clone https://github.com/vilvamani/quickstart-eks-boomi-molecule.git boomi_quickstart
location=$(ls)
pip install -t . -r ./boomi_quickstart/functions/source/BoomiLicenseValidation/requirements.txt

wget https://raw.githubusercontent.com/vilvamani/spring-boot-swagger2/master/test.py

az extension add --name aks-preview

if [ $BOOMIAUTHENTICATIONTYPE == "token" ]
then
    result=`python test.py "$MOLECULEACCOUNTID" "BOOMI_TOKEN.$MOLECULEUSERNAME" "$BOOMIMFAINSTALLTOKEN"`
else
    result=`python test.py "$MOLECULEACCOUNTID" "$MOLECULEUSERNAME" "$MOLECULEPASSWORD"`
fi

echo \{\"pythonVersion\":\"$pythonVersion\"\, \"result\":\"$result\"\} > $AZ_SCRIPTS_OUTPUT_PATH
