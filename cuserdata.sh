#!/bin/bash
pythonVersion=$(python --version)
location=$(pwd)

git clone https://github.com/vilvamani/quickstart-eks-boomi-molecule.git boomi_quickstart && cd boomi_quickstart/functions/source/BoomiLicenseValidation

pip install -t . -r ./requirements.txt

# Create output for S3 endpoint IP 
echo \{\"pythonVersion\":\"$pythonVersion\"\, \"pwd\":\"$location\"\} > $AZ_SCRIPTS_OUTPUT_PATH
