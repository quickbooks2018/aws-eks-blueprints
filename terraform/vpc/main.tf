locals {
  cluster_name = "cloudgeeks-eks-dev"
}

#########
# Eks Vpc
#########
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "registry.terraform.io/terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = local.cluster_name

  cidr             = "10.60.0.0/16"
  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets  = ["10.60.0.0/23", "10.60.2.0/23", "10.60.4.0/23"]
  public_subnets   = ["10.60.100.0/23", "10.60.102.0/24", "10.60.104.0/24"]
  database_subnets = ["10.60.11.0/24", "10.60.12.0/24", "10.60.13.0/24"]


  map_public_ip_on_launch = true
  enable_nat_gateway      = true
  single_nat_gateway      = true
  one_nat_gateway_per_az  = false

  create_database_subnet_group           = true
  database_subnet_group_name             = "cloudgeeks-eks-dev"
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = false
  create_database_nat_gateway_route      = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  # https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}"  = "owned"
    "karpenter.sh/discovery/${local.cluster_name}" = local.cluster_name
    "kubernetes.io/role/internal-elb"              = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

}


