#!/bin/bash

# set -x

printf "Searching latest OpenVPN AMI. This may take some time... "

IFS=$'\t' read -r -a IMAGE <<< "$(aws ec2 describe-images --owners 679593333241 --query 'Images[?Name!=`null`]|[?starts_with(Name, `OpenVPN`) == `true`] | reverse(sort_by(@, &CreationDate)) | [:1].[CreationDate,ImageId,Name]' --output text)"

printf "found!\n\n"
printf "%b" "${IMAGE[*]}\n"

printf "\nFinding all current AWS regions. This may take some time... "

IFS=$'\t' read -r -a REGIONS <<< "$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)"

printf "found %d!\n\n" "${#REGIONS[@]}"
printf "%b" "${REGIONS[*]}\n"

printf "This script will find the latest OpenVPN AMI on each region that match this: %s\n" "${IMAGE[2]}"
printf "The output below is valid YAML to integrate into a CloudFormation template mapping.\n"
printf "NOTE: Be patient, this requires going around the world querying APIs.\n"
printf "===========================================================================\n\n"

printf "# Software Version: %s\n" "${IMAGE[2]}"
for r in "${REGIONS[@]}"; do
    ami=$(aws ec2 describe-images --owners 679593333241 --query 'Images[*].[ImageId]' --filters "Name=name,Values=${IMAGE[2]}" --region "${r}" --output text)
    if [[ "${ami}" =~ ^ami-.{17}$ ]]; then
      printf "%s:\n  HVM64: %s\n" "${r}" "${ami}"
    fi
done

exit
