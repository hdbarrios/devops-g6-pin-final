# General:
aws_region                = "us-east-1"
aws_account               = "536697232168"
#aws_profile               = "terraform-admin"
aws_profile               = "pinf"
availability_zones        = ["us-east-1a", "us-east-1b", "us-east-1c"]
tags                      = {
    repositorio = "git@github.com:hdbarrios/devops-g6-pin-final.git"
    proyecto    = "PINF"
    equipo      = "Grupo6"
    environment = "PRD"
}

# VPC:
vpc_cidr                  = "10.11.0.0/16"
private_subnet_cidrs      = ["10.11.10.0/24", "10.11.20.0/24", "10.11.50.0/24"]
public_subnet_cidrs       = ["10.11.1.0/24", "10.11.30.0/24", "10.11.40.0/24"]
ssh_cidr                  = ["0.0.0.0/0", "10.11.1.0/24"]
create_private_subnet     = true
create_public_subnet      = true

# EC2:
ec2_user                  = "ubuntu"
ec2_ami                   = "ami-0e2c8caa4b6378d8c"   # Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
ec2_storage_type          = "gp2"
ec2_storage               = 40                        # Tamaño del volumen en GB
ec2_instance_type         = "t2.micro"
ec2_name                  = "pinf"
key_name                  = "pin"

# IAM 
ec2_admin_role_cicd       = "ec2_admin_role_cicd"
ec2_admin_profile         = "ec2_admin_profile"
programmatic_user         = "ec2_admin_role_cicd"

# EKS
eks_cluster_name    = "mundos-e"
eks_cluster_version = "1.30"
eks_enable_irsa     = true
eks_min_size        = 2
eks_desired_size    = 3
eks_max_size        = 3
eks_capacity_type   = "ON_DEMAND"
eks_instance_types  = "t3.small"
eks_associate_public_ip_address = true
eks_volume_size     = 20
eks_volume_type     = "gp2"
eks_device_name     = "/dev/xvda"


