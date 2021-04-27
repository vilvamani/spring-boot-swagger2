#!/bin/bash
pythonVersion=$(python --version)

git clone https://github.com/vilvamani/quickstart-eks-boomi-molecule.git boomi_quickstart
location=$(ls)
pip install -t . -r ./boomi_quickstart/functions/source/BoomiLicenseValidation/requirements.txt

# Create output for S3 endpoint IP 
echo \{\"pythonVersion\":\"$pythonVersion\"\, \"pwd\":\"$location\"\} > $AZ_SCRIPTS_OUTPUT_PATH
