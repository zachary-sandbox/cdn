#!/bin/bash
set -e

echo "===== Step1 Create argocd namespace ====="
kubectl create namespace argocd || echo "namespace argocd already exists, skip"

echo "\n===== Step2 Deploy Argo‑CD stable release ====="
kubectl apply -n argocd --server-side --force-conflicts \
-f https://raw.githubusercontent.com/zachary-sandbox/cdn/stable/argoproj/argo-cd/manifests/install.yaml

echo "\n===== Step3 Wait for secret argocd-initial-admin-secret to be created ====="
# Poll until secret becomes available; secret is generated after installation completes
until kubectl get secret -n argocd argocd-initial-admin-secret >/dev/null 2>&1; do
    echo "Waiting for argocd-initial-admin-secret secret ..."
    sleep 5
done

echo "\n===== Step4 Retrieve initial admin password ====="
ADMIN_PWD=$(kubectl get secret argocd-initial-admin-secret \
-n argocd \
-o jsonpath="{.data.password}" | base64 -d)

# ArgoCD Login Url
ARGOCD_URL=$(cat /etc/killercoda/host | sed 's/PORT/30080/')

# Optional: save password to local file
echo "${ADMIN_PWD}" > ./argocd_admin_password.txt
echo "\nPassword also saved to local file: ./argocd_admin_password.txt"

echo "\n===== Step5 Start background port‑forward for Argo‑CD UI ====="
kubectl port-forward svc/argocd-server -n argocd 30080:80 >/dev/null 2>&1 &
PF_PID=$!

echo "ArgoCD Namespace: argocd"
echo "Argo‑CD Web UI URL: ${ARGOCD_URL}"
echo "Username: admin"
echo "Initial Admin Password: ${ADMIN_PWD}"
echo "Port‑forward background PID: ${PF_PID}"
echo "To stop port‑forward manually, execute: kill ${PF_PID}"

echo "\n===== Step6 (Optional) Try argocd CLI login ====="

export ARGOCD_VERSION=v3.5.3 && \
curl -fsSL --connect-timeout 10 --max-time 30 -o argocd https://github.com/argoproj/argo-cd/releases/download/$ARGOCD_VERSION/argocd-linux-amd64 && \
sudo mv argocd /usr/local/bin && \
sudo chmod +x /usr/local/bin/argocd

echo "argocd login "$ARGOCD_URL" --username admin --password ${ADMIN_PWD} --insecure --grpc-web"
