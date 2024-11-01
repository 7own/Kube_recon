#!/bin/bash
# Simple script to enumerate exposed services
# on a Kubernetes cluster
#############

TOOL="kubectl"

$TOOL get namespace -o custom-columns='NAME:.metadata.name' | grep -v NAME | while IFS='' read -r ns; do
    echo "Namespace: $ns"
    kubectl get service -n "$ns"
    kubectl get ingress -n "$ns"
    echo "=============================================="
    echo ""
    echo ""
done | grep -v "ClusterIP"

# Remove the last '| grep -v "ClusterIP"' to see also type ClusterIP
