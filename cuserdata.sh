#!/bin/bash
result=$(az extension add --name aks-preview)

echo $result

status=$(jq --version)

echo \{\"license_validation\":\"$status\"\,\"result\":\"$result\"\} > $AZ_SCRIPTS_OUTPUT_PATH
