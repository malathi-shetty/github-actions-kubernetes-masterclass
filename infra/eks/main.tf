provider "aws" {
  region = "us-west-2"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "skillpulse-cluster"
  cluster_version = "1.29"

  vpc_id     = "vpc-05ca9cbf89bb468e0"

  subnet_ids = [
    "subnet-02a82aee776e54c08",
    "subnet-0fb798ad0f9973196",
    "subnet-0a49a5c0f0b09a901",
    "subnet-0a467b52ac953ee48"
  ]

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["t3.xlarge"]
    }
  }

resource "aws_eks_node_group" "skillpulse" {
  cluster_name    = aws_eks_cluster.skillpulse.name
  node_group_name = "skillpulse-ng"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.subnet_ids

  instance_types = ["t3.xlarge"]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }
}
}
