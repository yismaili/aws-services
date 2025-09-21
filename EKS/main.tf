terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "default" { 
  default = true
}

data "aws_subnets" "default" { 
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Data source to get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# EKS cluster IAM Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS node group IAM role
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# EKS cluster
resource "aws_eks_cluster" "k8s_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}

# OIDC provider for EKS 
data "tls_certificate" "eks" {
  url = aws_eks_cluster.k8s_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.k8s_cluster.identity[0].oidc[0].issuer

  tags = {
    Name = "${var.cluster_name}-eks-irsa"
  }
}

# EBS CSI Driver IAM role
data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.k8s_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "ebs_csi_role" {
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json
  name               = "${var.cluster_name}-ebs-csi-driver-role"
}

# Use AWS managed policy instead of custom policy
resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_role.name
}

# Frontend node group
resource "aws_eks_node_group" "frontend_nodes" {
  cluster_name    = aws_eks_cluster.k8s_cluster.name
  node_group_name = "frontend-pool"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.default.ids
  instance_types  = [var.frontend_node_size]

  scaling_config {
    desired_size = var.frontend_node_count
    max_size     = var.frontend_node_count + 1
    min_size     = 1
  }

  labels = {
    role = "frontend"
  }

  tags = {
    Name = "frontend-pool"
    Role = "frontend"
    Application = "pingpong"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]
}

# Backend node group
resource "aws_eks_node_group" "backend_nodes" {
  cluster_name    = aws_eks_cluster.k8s_cluster.name
  node_group_name = "backend-pool"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.default.ids
  instance_types  = [var.backend_node_size]

  scaling_config {
    desired_size = var.backend_node_count
    max_size     = var.backend_node_count + 1
    min_size     = 1
  }

  labels = {
    role = "backend"
  }

  tags = {
    Name = "backend-pool"
    Role = "backend"
    Application = "pingpong"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]
}

# Database node group
resource "aws_eks_node_group" "database_nodes" {
  cluster_name    = aws_eks_cluster.k8s_cluster.name
  node_group_name = "database-pool"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.default.ids
  instance_types  = [var.database_node_size]

  scaling_config {
    desired_size = var.database_node_count
    max_size     = var.database_node_count + 1
    min_size     = 1
  }

  labels = {
    role = "database"
  }

  tags = {
    Name = "database-pool"
    Role = "database"
    Application = "pingpong"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]
}

# EBS CSI Driver add-on
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.k8s_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.48.0-eksbuild.2"
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn
  
  depends_on = [
    aws_eks_node_group.database_nodes,
    aws_iam_role_policy_attachment.ebs_csi_policy
  ]
}

# Get EKS cluster auth data
data "aws_eks_cluster_auth" "cluster_auth" {
  name = aws_eks_cluster.k8s_cluster.name
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = aws_eks_cluster.k8s_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.k8s_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}

# Create namespace for the application
resource "kubernetes_namespace" "pingpong" {
  metadata {
    name = "pingpong"
    labels = {
      app = "pingpong"
    }
  }
  depends_on = [aws_eks_cluster.k8s_cluster]
}

# GP3 Storage Class for dynamic provisioning
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
  }
  
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  
  parameters = {
    type       = var.postgres_volume_type
    encrypted  = "true"
    iops       = var.postgres_volume_type == "gp3" ? tostring(var.postgres_volume_iops) : null
    throughput = var.postgres_volume_type == "gp3" ? tostring(var.postgres_volume_throughput) : null
  }

  depends_on = [aws_eks_addon.ebs_csi]
}
