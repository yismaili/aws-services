#!/bin/bash
set -e

# Create ArgoCD namespace and install
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

kubectl get svc -n argocd

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo


nslookup a0c43decadb3642dea52a9edb4e887f5-1093740350.us-west-2.elb.amazonaws.com


kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.6/deploy/static/provider/cloud/deploy.yaml


# 1.
kubectl apply -f argocd-repo-secret.yaml

# 2. 
kubectl apply -f argocd-nginx-ingress.yaml

# 3.
kubectl get svc -n ingress-nginx
# 4. 
kubectl apply -f argocd-application.yaml




echo "=== Checking for any remaining AWS Load Balancer resources ==="
echo "Load Balancers:" && aws elbv2 describe-load-balancers --query 'length(LoadBalancers)' --output text
echo "Target Groups:" && aws elbv2 describe-target-groups --query 'length(TargetGroups)' --output text
echo "Classic Load Balancers:" && aws elb describe-load-balancers --query 'length(LoadBalancerDescriptions)' --output text