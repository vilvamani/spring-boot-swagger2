#!/bin/bash
pythonVersion=$(python --version)

git clone https://github.com/vilvamani/quickstart-eks-boomi-molecule.git boomi_quickstart
location=$(ls)
#pip install -t . -r ./boomi_quickstart/functions/source/BoomiLicenseValidation/requirements.txt

wget https://raw.githubusercontent.com/vilvamani/spring-boot-swagger2/master/test.py
result=`python test.py "$BOOMIAUTHENTICATIONTYPE" "$MOLECULEACCOUNTID" "$MOLECULEUSERNAME" "$MOLECULEPASSWORD" "$BOOMIMFAINSTALLTOKEN"`

echo \{\"pythonVersion\":\"$pythonVersion\"\, \"result\":\"$result\"\} > $AZ_SCRIPTS_OUTPUT_PATH
