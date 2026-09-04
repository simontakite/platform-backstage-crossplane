#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# LOCAL RANCHER + K3D + FLUX LAB
#
# Architecture:
#
# MacBook
#   |
# Rancher Desktop (dockerd/Moby)
#   |
# k3d cluster
#   |
# ├── server-0 (2 CPU / 4 GB RAM)
# ├── agent-0  (2 CPU / 4 GB RAM)
# ├── agent-1  (2 CPU / 4 GB RAM)
# └── agent-2  (2 CPU / 4 GB RAM)
#
# Then installs:
# - cert-manager
# - Rancher Manager
# - FluxCD
#
###############################################################################

CLUSTER_NAME="rancher-lab"

echo "================================================"
echo " Local Rancher + k3d + Flux Lab Setup"
echo "================================================"

###############################################################################
# 1. CHECK PREREQUISITES
###############################################################################

echo
echo "[1/8] Checking prerequisites..."

if ! command -v brew >/dev/null 2>&1; then
  echo "ERROR: Homebrew is not installed."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker CLI is not available."
  echo "Make sure Rancher Desktop is running with dockerd (Moby)."
  exit 1
fi

echo "Checking Docker connection..."

docker info >/dev/null

echo "Docker is available."

###############################################################################
# 2. INSTALL REQUIRED CLI TOOLS
###############################################################################

echo
echo "[2/8] Installing required CLI tools..."

if ! command -v k3d >/dev/null 2>&1; then
  brew install k3d
fi

if ! command -v kubectl >/dev/null 2>&1; then
  brew install kubectl
fi

if ! command -v helm >/dev/null 2>&1; then
  brew install helm
fi

if ! command -v flux >/dev/null 2>&1; then
  brew install fluxcd/tap/flux
fi

echo "Tools installed."

echo
echo "Versions:"
k3d version
kubectl version --client
helm version
flux --version

###############################################################################
# 3. DELETE OLD CLUSTER IF IT EXISTS
###############################################################################

echo
echo "[3/8] Checking for existing cluster..."

if k3d cluster list | grep -q "${CLUSTER_NAME}"; then
  echo "Existing cluster found."
  echo "Deleting existing cluster..."

  k3d cluster delete "${CLUSTER_NAME}"
fi

###############################################################################
# 4. CREATE MULTI-NODE K3D CLUSTER
###############################################################################

echo
echo "[4/8] Creating multi-node Kubernetes cluster..."

k3d cluster create "${CLUSTER_NAME}" \
  --servers 1 \
  --agents 3 \
  --servers-memory 4g \
  --agents-memory 4g \
  --api-port 6550 \
  --wait

echo
echo "Cluster created."

kubectl config use-context "k3d-${CLUSTER_NAME}"

echo
echo "Waiting for nodes..."

kubectl wait \
  --for=condition=Ready \
  nodes \
  --all \
  --timeout=300s

echo
echo "Cluster nodes:"

kubectl get nodes -o wide

###############################################################################
# 5. APPLY CPU LIMITS TO NODE CONTAINERS
###############################################################################

echo
echo "[5/8] Applying CPU limits to k3d nodes..."

# Each Kubernetes node is a Docker container.
# Limit each node container to 2 CPUs.

for NODE in $(docker ps \
  --format '{{.Names}}' \
  | grep "k3d-${CLUSTER_NAME}"); do

  echo "Limiting ${NODE} to 2 CPUs..."

  docker update \
    --cpus="2" \
    "${NODE}"

done

echo
echo "Node resource limits:"

docker stats \
  --no-stream \
  $(docker ps \
    --format '{{.Names}}' \
    | grep "k3d-${CLUSTER_NAME}")

###############################################################################
# 6. INSTALL CERT-MANAGER
###############################################################################

echo
echo "[6/8] Installing cert-manager..."

helm upgrade \
  --install cert-manager \
  oci://quay.io/jetstack/charts/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --wait \
  --timeout 10m

echo
echo "cert-manager status:"

kubectl get pods \
  --namespace cert-manager

###############################################################################
# 7. INSTALL RANCHER
###############################################################################

echo
echo "[7/8] Installing Rancher..."

helm repo add rancher-stable \
  https://releases.rancher.com/server-charts/stable \
  --force-update

helm repo update

kubectl create namespace cattle-system \
  --dry-run=client \
  -o yaml \
  | kubectl apply -f -

helm upgrade \
  --install rancher \
  rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.localhost \
  --set replicas=1 \
  --set bootstrapPassword=admin \
  --wait \
  --timeout 15m

echo
echo "Rancher status:"

kubectl get pods \
  --namespace cattle-system

###############################################################################
# 8. INSTALL FLUX
###############################################################################

echo
echo "[8/8] Installing FluxCD..."

flux check --pre

flux install

flux check

echo
echo "================================================"
echo " INSTALLATION COMPLETE"
echo "================================================"

echo
echo "Kubernetes Nodes:"
kubectl get nodes

echo
echo "Rancher Pods:"
kubectl get pods -n cattle-system

echo
echo "Flux Pods:"
kubectl get pods -n flux-system

echo
echo "================================================"
echo " ACCESS RANCHER"
echo "================================================"

echo
echo "Run this command in a separate terminal:"
echo
echo "kubectl -n cattle-system port-forward svc/rancher 8443:443"
echo
echo "Then open:"
echo
echo "https://localhost:8443"
echo
echo "Username: admin"
echo "Password: admin"
echo
echo "================================================"
echo " USEFUL COMMANDS"
echo "================================================"

echo
echo "kubectl get nodes"
echo "kubectl get pods -A"
echo "flux get all"
echo "k3d cluster list"

echo
echo "================================================"