output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.k8s_cluster.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.k8s_cluster.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.k8s_cluster.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = aws_eks_cluster.k8s_cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = aws_iam_role.eks_cluster_role.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.k8s_cluster.certificate_authority[0].data
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = aws_eks_cluster.k8s_cluster.vpc_config[0].cluster_security_group_id
}


output "node_groups" {
  description = "EKS node groups"
  value = {
    frontend = aws_eks_node_group.frontend_nodes.arn
    backend  = aws_eks_node_group.backend_nodes.arn
    database = aws_eks_node_group.database_nodes.arn
  }
}

# EBS CSI Driver outputs
output "ebs_csi_driver_role_arn" {
  description = "ARN of the EBS CSI Driver IAM role"
  value       = aws_iam_role.ebs_csi_role.arn
}

output "ebs_csi_driver_role_name" {
  description = "Name of the EBS CSI Driver IAM role"
  value       = aws_iam_role.ebs_csi_role.name
}

# Storage outputs
output "storage_class_name" {
  description = "Name of the GP3 storage class"
  value       = kubernetes_storage_class_v1.gp3.metadata[0].name
}

# Namespace output
output "pingpong_namespace" {
  description = "Name of the pingpong namespace"
  value       = kubernetes_namespace.pingpong.metadata[0].name
}

# OIDC outputs
output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.k8s_cluster.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enabled"
  value       = aws_iam_openid_connect_provider.eks.arn
}

# Region and VPC outputs
output "region" {
  description = "AWS region"
  value       = var.region
}

output "vpc_id" {
  description = "ID of the VPC where the cluster and workers are deployed"
  value       = data.aws_vpc.default.id
}

# Instructions for connecting to the cluster
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
}