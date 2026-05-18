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

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["t3.xlarge"]
      ami_type = "AL2_x86_64"
    }
  }
}
