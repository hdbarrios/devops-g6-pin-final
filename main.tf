provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Datos de las zonas de disponibilidad
data "aws_availability_zones" "azs" {
  state = "available"
}

###################
# Recursos de red #
###################

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = merge(
    var.tags,
    {
      Name = "terraform-vpc"
    }
  )
}

# Subredes públicas
resource "aws_subnet" "public_subnets" {
  count                   = 3
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(data.aws_availability_zones.azs.names, count.index)
  map_public_ip_on_launch = true
  
  tags = merge(
    var.tags,
    {
      Name                     = "public-subnet-${count.index + 1}"
      "kubernetes.io/role/elb" = 1
    }
  )
}

# Subredes privadas
resource "aws_subnet" "private_subnets" {
  count                   = 3
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = element(data.aws_availability_zones.azs.names, count.index)
  map_public_ip_on_launch = false
  
  tags = merge(
    var.tags,
    {
      Name                              = "private-subnet-${count.index + 1}"
      "kubernetes.io/role/internal-elb" = 1
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  
  tags = merge(
    var.tags,
    {
      Name = "main-igw"
    }
  )
}

# NAT Gateway para cada zona de disponibilidad
resource "aws_eip" "nat" {
  count  = 3
  domain = "vpc"
  
  tags = merge(
    var.tags,
    {
      Name = "nat-eip-${count.index + 1}"
    }
  )
}

resource "aws_nat_gateway" "nat_gw" {
  count         = 3
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id
  
  tags = merge(
    var.tags,
    {
      Name = "nat-gw-${count.index + 1}"
    }
  )
  
  depends_on = [aws_internet_gateway.igw]
}

# Tabla de rutas pública
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "public-route-table"
    }
  )
}

# Asociación de tabla de rutas pública
resource "aws_route_table_association" "public_rta" {
  count          = 3
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Tablas de rutas privadas
resource "aws_route_table" "private_route_table" {
  count  = 3
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "private-route-table-${count.index + 1}"
    }
  )
}

# Asociación de tablas de rutas privadas
resource "aws_route_table_association" "private_rta" {
  count          = 3
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

# Grupo de seguridad para EC2 y EKS
resource "aws_security_group" "sg" {
  name        = "eks-ec2-security-group" # Cambiado para no empezar con sg-
  description = "Security group for EC2 admin and EKS nodes"
  vpc_id      = aws_vpc.vpc.id

  # El resto permanece igual
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Grafana
  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Prometheus
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # cAdvisor
  ingress {
    description = "cAdvisor"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # NGINX Exporter
  ingress {
    description = "NGINX Exporter"
    from_port   = 9091
    to_port     = 9091
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir comunicación interna entre las instancias en la VPC
  ingress {
    description = "All internal traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # Permitir todo el tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    var.tags,
    {
      Name = "eks-ec2-security-group"
    }
  )
}
###################
# Par de claves SSH #
###################

resource "aws_key_pair" "ssh_key" {
  #key_name   = "eks-ssh-key"
  key_name   = var.key_name
  public_key = file("${var.profile_path}/pin.pub")
  
  tags = merge(
    var.tags,
    {
      Name = "eks-ssh-key"
    }
  )
}

###################
# IAM Recursos #
###################

# Rol para EC2 admin
resource "aws_iam_role" "ec2_admin_role" {
  name = var.ec2_admin_role_cicd
  
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
  
  tags = merge(
    var.tags,
    {
      Name = var.ec2_admin_role_cicd
    }
  )
}

resource "aws_iam_role_policy_attachment" "ec2_admin_policy_attachment" {
  role       = aws_iam_role.ec2_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Perfil de instancia para EC2
resource "aws_iam_instance_profile" "ec2_admin_profile" {
  name = var.ec2_admin_profile
  role = aws_iam_role.ec2_admin_role.name
  
  # Evitar conflictos en caso de que el perfil ya exista
  lifecycle {
    create_before_destroy = true
  }
  
  tags = merge(
    var.tags,
    {
      Name = var.ec2_admin_profile
    }
  )
}

# Usuario programático con acceso administrativo
resource "aws_iam_user" "programmatic_user" {
  name = var.programmatic_user
  
  tags = merge(
    var.tags,
    {
      Name = var.programmatic_user
    }
  )
}

resource "aws_iam_user_policy_attachment" "programmatic_user_admin_policy" {
  user       = aws_iam_user.programmatic_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_access_key" "programmatic_user_key" {
  user = aws_iam_user.programmatic_user.name
}

# Política para administrar EBS
resource "aws_iam_policy" "ebs_management_policy" {
  name        = "ebs-management-policy"
  description = "Policy for EBS volume management"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumeAttribute",
          "ec2:ModifyVolume",
          "ec2:DescribeSnapshots",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = merge(
    var.tags,
    {
      Name = "ebs-management-policy"
    }
  )
}

###################
# Instancia EC2 Admin #
###################

resource "aws_instance" "admin_server" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_instance_type
  key_name               = aws_key_pair.ssh_key.key_name
  subnet_id              = aws_subnet.public_subnets[0].id
  vpc_security_group_ids = [aws_security_group.sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_admin_profile.name
  
  root_block_device {
    volume_type = var.ec2_storage_type
    volume_size = var.ec2_storage
    encrypted   = false
  }
  
  user_data = templatefile("${var.profile_path}/provision.sh", {
    ami_user    = "ubuntu"
    ACCESS_KEY  = aws_iam_access_key.programmatic_user_key.id
    SECRET_KEY  = aws_iam_access_key.programmatic_user_key.secret
    AWS_ACCOUNT = var.aws_account
    EC2_USER    = var.ec2_user
  })
  
  tags = merge(
    var.tags,
    {
      Name = var.ec2_name
    }
  )
  
  depends_on = [
    aws_internet_gateway.igw,
    aws_route_table_association.public_rta
  ]
}

###################
# Cluster EKS #
###################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version
  
  # Configuración de red
  vpc_id                   = aws_vpc.vpc.id
  subnet_ids               = aws_subnet.private_subnets[*].id
  control_plane_subnet_ids = aws_subnet.private_subnets[*].id
  
  # Habilitar OIDC para Roles de IAM para cuentas de servicio
  enable_irsa = var.eks_enable_irsa
  
  # Grupo de nodos gestionados por EKS
  eks_managed_node_groups = {
    main_node_group = {
      name         = "ng-${var.eks_cluster_name}"
      min_size     = var.eks_min_size
      max_size     = var.eks_max_size
      desired_size = var.eks_desired_size
      
      instance_types = [var.eks_instance_types]
      capacity_type  = var.eks_capacity_type
      ami_type       = "AL2_x86_64"
      
      # Configuraciones que anteriormente estaban en la plantilla de lanzamiento
      key_name      = aws_key_pair.ssh_key.key_name
      disk_size     = var.eks_volume_size
      
      subnet_ids = aws_subnet.private_subnets[*].id
      
      # Asignar la política de EBS
      iam_role_additional_policies = {
        ebs_management = aws_iam_policy.ebs_management_policy.arn
      }
      
      tags = merge(
        var.tags,
        {
          Name = "ng-${var.eks_cluster_name}"
        }
      )
    }
  }
  
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Allow nodes to communicate with each other"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    
    ingress_ssh_all = {
      description = "SSH access from private subnets"
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      type        = "ingress"
      cidr_blocks = [var.vpc_cidr]
    }
  }
  
  # Usar el nuevo método para la autenticación en lugar de los argumentos obsoletos
  authentication_mode = "API_AND_CONFIG_MAP"
  
  access_entries = {
    # Agregar usuario programático como administrador del cluster
    programmatic_user = {
      #kubernetes_groups = ["system:masters"]
      principal_arn     = "arn:aws:iam::${var.aws_account}:user/${var.programmatic_user}"
      type              = "STANDARD"
    }
    
    # Agregar rol de EC2 admin como administrador del cluster
    admin_role = {
      #kubernetes_groups = ["system:masters"]
      principal_arn     = aws_iam_role.ec2_admin_role.arn
      type              = "STANDARD"
    }
  }
  
  tags = merge(
    var.tags,
    {
      Name = var.eks_cluster_name
    }
  )
}
