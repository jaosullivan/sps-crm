module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  fargate_profiles = {
    apps = {
      name = "apps"
      selectors = [
        { namespace = "sps-crm" },
        { namespace = "kube-system", labels = { "app.kubernetes.io/name" = "aws-load-balancer-controller" } },
      ]
    }
  }

  # No managed node groups — Fargate-first for cost.
  eks_managed_node_groups = {}
}
