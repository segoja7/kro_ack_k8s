#!/bin/bash

export KRO_VERSION=$(curl -sL \
    https://api.github.com/repos/kro-run/kro/releases/latest | \
    jq -r '.tag_name | ltrimstr("v")'
  )

helm install kro oci://ghcr.io/kro-run/kro/kro \
  --namespace kro \
  --create-namespace \
  --version=${KRO_VERSION}
  
kubectl create ns ack-system
kubectl create secret generic aws-credentials -n ack-system --from-file=credentials=./profile.txt
aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws


# Define the AWS region
export CONTROLLER_REGION=us-east-1

# Define the services
SERVICES=("iam" "ec2" "eks")

# Iterate through the services
for SERVICE in "${SERVICES[@]}"; do
  # Get the latest release version from GitHub
  RELEASE_VERSION=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/${SERVICE}-controller/releases/latest | jq -r '.tag_name | ltrimstr("v")')

  # Check if the release version was retrieved successfully
  if [[ -z "$RELEASE_VERSION" ]]; then
    echo "Error: Could not retrieve release version for ${SERVICE}."
    continue  # Skip to the next service
  fi

  # Install the Helm chart
  helm install --create-namespace -n ack-system \
    oci://public.ecr.aws/aws-controllers-k8s/${SERVICE}-chart \
    --version="${RELEASE_VERSION}" \
    --generate-name \
    --set aws.region="${CONTROLLER_REGION}" \
    --set aws.credentials.secretName=aws-credentials \
    --set aws.credentials.profile=default

  # Check if the Helm install was successful
  if [[ $? -eq 0 ]]; then
    echo "Successfully installed ${SERVICE} controller."
  else
    echo "Error: Failed to install ${SERVICE} controller."
  fi
done

echo "Installation process complete."

kubectl create ns tekton-tasks

#tekton secret
kubectl get secret aws-credentials -n ack-system -o yaml \
  | sed "s/namespace: ack-system/namespace: tekton-tasks/" \
  | kubectl apply -f -

kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml


