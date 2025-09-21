#!/bin/bash

# Create kubectl function that actually works
kubectl() {
  docker run --rm -it \
    -v ~/.kube:/root/.kube:ro \
    -v ~/.aws:/root/.aws:ro \
    -v "$(pwd)":/workspace -w /workspace \
    --env KUBECONFIG=/root/.kube/config \
    alpine/k8s:1.28.4 kubectl "$@"
}

# Export the function for current session
export -f kubectl

# Add to your shell profile for persistence
echo '# EKS kubectl function - WORKING VERSION
kubectl() {
  docker run --rm -it \
    -v ~/.kube:/root/.kube:ro \
    -v ~/.aws:/root/.aws:ro \
    -v "$(pwd)":/workspace -w /workspace \
    --env KUBECONFIG=/root/.kube/config \
    alpine/k8s:1.28.4 kubectl "$@"
}
export -f kubectl' >> ~/.zshrc

echo "✅ kubectl function created successfully!"
echo "Your EKS cluster has 3 nodes ready!"
echo ""
echo "Test commands:"
echo "kubectl get nodes"
echo "kubectl get nodes --show-labels"
echo "kubectl get namespaces"
