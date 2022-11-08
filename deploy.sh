#!/usr/bin/env bash

set -Eeuo pipefail
# set -x

[[ "${BASH_VERSINFO[0]}" -lt 5 ]] && echo "Why are you not using Bash's latest version?" && exit 1

NAMESPACE="sebacruz-vpn"
TEMPLATE="wireguard-aws.template.yaml"
STACK_BASENAME="WireGuardVPN"
declare -A REGIONS=([LHR]="eu-west-2" [CMH]="us-east-2")

function deploy {
    local stack_name="${STACK_BASENAME}-${2}"
    local region="${3}"
    local command="aws cloudformation deploy \
                    --template-file ${1} \
                    --stack-name ${stack_name} \
                    --region ${region} \
                    --no-execute-changeset \
                    --tags Namespace=${NAMESPACE} auto-start=no auto-stop=no auto-delete=no"
    
    # If 4th argument to this function is not empty, then append new argument for command
    [[ -n "${4:-}" ]] && command="${command} --parameter-overrides ${4}"

    # Deployment "fails" when there's no updates to make. Ignore that so that we can continue with other templates.
    deploy_result=$(eval "${command} 2>&1")
    if [[ "${deploy_result}" == *"No changes to deploy."* ]]; then
        echo "${deploy_result}" | tail -1
    else
        changeset_arn=$(sed -n 's/aws cloudformation describe-change-set --change-set-name //p' <<< "${deploy_result}")

        echo "Describing changes..."
        aws cloudformation describe-change-set \
            --region "${region}" \
            --change-set-name "${changeset_arn}" \
            --query 'Changes[*].ResourceChange.{"Action": Action, "Logical ID":LogicalResourceId, "Resource Type":ResourceType, "Replacement":Replacement}' \
            --output table

        read -r -p "Do you want to apply the changes? [y/N] " apply
        if [[ "$apply" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            echo "Executing changeset..."
            aws cloudformation execute-change-set \
                --region "${region}" \
                --change-set-name "${changeset_arn}"
            echo "Waiting for stack update to complete ..."
            aws cloudformation wait stack-update-complete \
                --region "${region}" \
                --stack-name "${stack_name}"
        else
            read -r -p "Do you want to delete the changeset before exiting? [Y/n] " delete
            if [[ ! "$delete" =~ ^([nN][oO]|[nN])+$ ]]; then
                aws cloudformation delete-change-set \
                    --region "${region}" \
                    --change-set-name "${changeset_arn}"
            fi
        fi
    fi
}

# Iterate over each template
for airport in "${!REGIONS[@]}"
do
    read -r -p "Do you want to process region ${airport}? [y/N] " process
    if [[ "$process" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        if [[ -f "wireguard.params.json" ]]; then
            parameters_file="wireguard.params.json"
            mapfile -t params < <(jq -r '.Parameters[] | [.ParameterKey, .ParameterValue] | "\(.[0]|@sh)=\(.[1]|@sh)"' "${parameters_file}")
            echo "Processing region ${airport} with parameters ${parameters_file}..."
            deploy "${TEMPLATE}" "${airport}" "${REGIONS[$airport]}" "${params[*]}"
        else
            echo "Processing region ${airport} without parameters..."
            deploy "${TEMPLATE}" "${airport}" "${REGIONS[$airport]}"
        fi
    fi
done
