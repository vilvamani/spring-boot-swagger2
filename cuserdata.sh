#!/bin/bash
pythonVersion=$(python --version)

git clone https://github.com/vilvamani/quickstart-eks-boomi-molecule.git boomi_quickstart
location=$(ls -a)
#pip install -t . -r ./boomi_quickstart/functions/source/BoomiLicenseValidation/requirements.txt

# Create output for S3 endpoint IP 
echo \{\"pythonVersion\":\"$pythonVersion\"\, \"BOOMIAUTHENTICATIONTYPE\":\"$BOOMIAUTHENTICATIONTYPE\"\} > $AZ_SCRIPTS_OUTPUT_PATH
