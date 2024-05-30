#!/usr/bin/env bash

json_to_yaml() {
  python -c 'import sys, json, yaml; print(yaml.safe_dump(json.load(sys.stdin), default_flow_style=False))'
}

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$0")

# Use the script directory to resolve the paths
JUMPBOX_IP=$(terraform -chdir="${SCRIPT_DIR}/../terraform" output -raw jumpbox_ip)
ANSIBLE_USER=$(terraform -chdir="${SCRIPT_DIR}/../terraform" state pull |
  jq 'first(.resources[] | select(.type=="ansible_host")).instances[0].attributes.variables.ansible_user' -r)

TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

rsync -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -J ${ANSIBLE_USER}@${JUMPBOX_IP}" \
  --rsync-path="sudo rsync" \
  --chown=$(whoami):$(whoami) \
  "${ANSIBLE_USER}@k8s-node-cp-0.internal:/etc/kubernetes/admin.conf" \
  "${TMP_DIR}/admin.conf"

KUBECONFIG="${TMP_DIR}/admin.conf" kubectl config view --raw -o json |
  jq "(.users[] | select(.name == \"kubernetes-admin\").name) = \"cka-admin\" |
    (.clusters[] | select(.name == \"cluster.local\").name) = \"cka-cluster\" |
    (.clusters[] | select(.name == \"cka-cluster\").cluster.server) = \"https://${JUMPBOX_IP}:6443\" |
    (.contexts[] | select(.name == \"kubernetes-admin@cluster.local\").name) = \"cka-admin@cka-cluster\" |
    (.contexts[] | select(.name == \"cka-admin@cka-cluster\").context.cluster) = \"cka-cluster\" |
    (.contexts[] | select(.name == \"cka-admin@cka-cluster\").context.user) = \"cka-admin\"" |
    json_to_yaml > "${TMP_DIR}/new-config"

KUBECONFIG="${TMP_DIR}/new-config:$HOME/.kube/config" kubectl config view --flatten --merge > "${TMP_DIR}/config"
install -m 600 "${TMP_DIR}/config" "$HOME/.kube/config"

kubectl config use-context cka-admin@cka-cluster
