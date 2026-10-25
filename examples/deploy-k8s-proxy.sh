#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-$HOME/.kube/config}"
NAMESPACE="${NAMESPACE:-zitadel}"

echo "Using kubeconfig $KUBECONFIG_PATH (override with KUBECONFIG_PATH=...)" >&2
echo "Edit the placeholders in examples/k8s/*.yaml first (issuer, upstream, image, hostname, gateway)." >&2

kubecfg() {
  KUBECONFIG="$KUBECONFIG_PATH" kubectl "$@"
}

kubecfg get ns "$NAMESPACE" >/dev/null 2>&1 || kubecfg create ns "$NAMESPACE"
kubecfg apply -f "$ROOT_DIR/examples/k8s/configmap.yaml"
kubecfg apply -f "$ROOT_DIR/examples/k8s/deployment.yaml"
kubecfg apply -f "$ROOT_DIR/examples/k8s/service.yaml"
kubecfg apply -f "$ROOT_DIR/examples/k8s/httproute.yaml"
kubecfg -n "$NAMESPACE" rollout status deploy/zitadel-auth-proxy --timeout=240s

GATEWAY="$(kubecfg -n "$NAMESPACE" get httproute zitadel-auth-proxy \
  -o jsonpath='{.spec.parentRefs[0].name}' 2>/dev/null || true)"

echo "Proxy deployed in namespace $NAMESPACE, reachable through gateway ${GATEWAY:-<see httproute.yaml>}"
