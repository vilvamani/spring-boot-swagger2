#!/bin/bash
result=$(az feature show --name AKS-IngressApplicationGatewayAddon --namespace Microsoft.ContainerService)


status=`echo $result | jq .properties.state`

echo \{\"license_validation\":\"$status\"\} > $AZ_SCRIPTS_OUTPUT_PATH
