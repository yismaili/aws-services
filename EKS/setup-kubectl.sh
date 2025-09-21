#!/bin/bash
set -e

CLUSTER_NAME="pingpong-k8s-cluster"
REGION="us-west-2"

if [ ! -f ~/.aws/credentials ]; then
    echo "❌ AWS credentials not found"
    echo "Please run: aws configure"
    exit 1
fi

if ! docker run --rm -v ~/.aws:/root/.aws:ro amazon/aws-cli sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS access failed"
    exit 1
fi

mkdir -p ~/.kube

if [ -f ~/.kube/config ]; then
    cp ~/.kube/config ~/.kube/config.backup.$(date +%s) 2>/dev/null || true
    rm -f ~/.kube/config
fi

docker run --rm \
    -v ~/.aws:/root/.aws:ro \
    -v ~/.kube:/root/.kube \
    amazon/aws-cli eks update-kubeconfig --region $REGION --name $CLUSTER_NAME > /dev/null 2>&1

if [ ! -f ~/.kube/config ]; then
    echo "❌ Failed to create kubeconfig"
    exit 1
fi

KUBECTL_FUNCTION='kubectl() {
  docker run --rm -it \
    -v ~/.kube:/root/.kube:ro \
    -v ~/.aws:/root/.aws:ro \
    -v "$(pwd)":/workspace -w /workspace \
    --env KUBECONFIG=/root/.kube/config \
    alpine/k8s:1.28.4 kubectl "$@"
}
export -f kubectl'

eval "$KUBECTL_FUNCTION"

if ! kubectl get nodes > /dev/null 2>&1; then
    echo "❌ kubectl function failed"
    exit 1
fi

SHELL_RC=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.profile"
fi

if grep -q "alpine/k8s:1.28.4" "$SHELL_RC" 2>/dev/null; then
    sed -i.bak '/kubectl() {/,/^}/d' "$SHELL_RC" 2>/dev/null || true
    sed -i.bak '/export -f kubectl/d' "$SHELL_RC" 2>/dev/null || true
fi

echo "" >> "$SHELL_RC"
echo "# EKS kubectl function" >> "$SHELL_RC"
echo "$KUBECTL_FUNCTION" >> "$SHELL_RC"

echo "✅ kubectl setup completed!"
echo ""
echo "Test with: kubectl get nodes"

sleep 20

kubectl() {
  docker run --rm -it \
    -v ~/.kube:/root/.kube:ro \
    -v ~/.aws:/root/.aws:ro \
    -v "$(pwd)":/workspace -w /workspace \
    --env KUBECONFIG=/root/.kube/config \
    alpine/k8s:1.28.4 kubectl "$@"
}
export -f kubectl

echo "✅ kubectl function loaded!"
echo "Test with: kubectl get nodes"