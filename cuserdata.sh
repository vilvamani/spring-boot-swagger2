#!/bin/bash
serviceIp=$(python --version)
# Create output for S3 endpoint IP 
echo \{\"loadBalancerIP\":\"$serviceIp\"\} > $AZ_SCRIPTS_OUTPUT_PATH
