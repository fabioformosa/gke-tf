#!/bin/bash

error_exit() {
    echo "$1" 1>&2
    exit 1
}

check_var() {
    local var_name="$1"
    local var_value="$2"
    [ -z "$var_value" ] && error_exit "Error: $var_name is mandatory."
}

# Controlla che siano stati passati tre argomenti
if [ "$#" -ne 3 ]; then
    error_exit "Usage: $0 <PROJECT_ID> <BUCKET_NAME> <REGION>"
fi

PROJECT_ID=$1
BUCKET_NAME=$2
REGION=$3

check_var "PROJECT_ID" "$PROJECT_ID"
check_var "BUCKET_NAME" "$BUCKET_NAME"
check_var "REGION" "$REGION"

if ! gsutil ls -b gs://$BUCKET_NAME; then
  gsutil mb -p $PROJECT_ID -l $REGION gs://$BUCKET_NAME
fi

# Inizializza Terraform
terraform init \
  -backend-config="bucket=$BUCKET_NAME" \
  -backend-config="prefix=terraform/state" || error_exit "Terraform init failed."

# Documentation
cat << EOF
cat << EOF
Usage:
  $0 <PROJECT_ID> <BUCKET_NAME> <REGION>

Description:
  This script initializes a Terraform backend with a Google Cloud Storage bucket. It checks if the bucket exists, and if not, it creates the bucket. Then it initializes Terraform with the specified backend configuration.

Arguments:
  PROJECT_ID    The Google Cloud project ID
  BUCKET_NAME   The name of the GCS bucket to store Terraform state
  REGION        The GCP region for the bucket

EOF
