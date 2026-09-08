#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: helm nuke <release> <namespace>" >&2
  exit 1
fi

RELEASE="$1"
NAMESPACE="$2"

echo "Uninstalling release '$RELEASE' in namespace '$NAMESPACE'..."
helm uninstall "$RELEASE" --namespace "$NAMESPACE"

echo "Deleting namespace '$NAMESPACE'..."
kubectl delete namespace "$NAMESPACE"

echo "Done."
