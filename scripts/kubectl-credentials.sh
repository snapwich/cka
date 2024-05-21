#!/usr/bin/env bash

SSH_USER=$(cat ./terraform/terraform.tfstate | jq -r \
  '.resources.[] | select(.name=="k8s-jumpbox") | .instances[0].attributes.variables.ansible_user')
SSH_HOST=$(cat ./terraform/terraform.tfstate | jq -r \
  '.resources.[] | select(.name=="k8s-jumpbox") | .instances[0].attributes.variables.ansible_host')

// copy kubernetes credentials to tempdir
scp -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST:/tmp/kubeconfig /tmp/kubeconfig
echo "ssh -J $SSH_USER@$SSH_HOST $SSH_USER@k8s-cp.internal. -o StrictHostKeyChecking=no"