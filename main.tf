provider "aws" {
  region  = var.aws_region                        # Región de AWS
}

# Crear rol IAM con permisos admin
#
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
}

resource "aws_iam_role_policy_attachment" "ec2_admin_policy_attachment" {
  role       = aws_iam_role.ec2_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Crear una instancia de perfil de IAM y asociar el rol
#
resource "aws_iam_instance_profile" "ec2_admin_profile" {
  name = var.ec2_admin_profile
  role = aws_iam_role.ec2_admin_role.name
}

# Crear usuario programatico:
#
resource "aws_iam_user" "programmatic_user" {
  name = var.programmatic_user
}

resource "aws_iam_user_policy_attachment" "programmatic_user_admin_policy" {
  user       = aws_iam_user.programmatic_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_access_key" "programmatic_user_key" {
  user = aws_iam_user.programmatic_user.name
}

# Leer la clave pública desde el archivo .pem
# Generar la clave privada localmente
# openssl genpkey -algorithm RSA -out pin.pem
# openssl rsa -in pin.pem -text -noout

resource "aws_key_pair" "key" {
  key_name   = "pin"      
  public_key = file("${var.profile_path}/pin.pub") # Asegúrate de tener la clave pública generada
}

# Crear la instancia EC2
#
resource "aws_instance" "server" {
  ami             = var.ec2_ami
  instance_type   = var.ec2_instance_type
  key_name        = aws_key_pair.key.key_name

  # Asociar la EC2 con la subred de la VPC
  subnet_id       = aws_subnet.subnet_public.id
  vpc_security_group_ids = [aws_security_group.sg.id]  # Asociar el grupo de seguridad

  root_block_device {
    volume_type = var.ec2_storage_type   # Tipo de volumen EBS (por ejemplo, gp2)
    volume_size = var.ec2_storage        # Tamaño del volumen en GB (40GB en tu caso)
    encrypted  = false                   # Si se debe encriptar el volumen (false en este caso)
  }

  # asociar el perfil de IAM a la instancia EC2
  iam_instance_profile = aws_iam_instance_profile.ec2_admin_profile.name

  tags = merge(
    var.tags,
    {
      Name         = var.ec2_name
      Project = "PINF"
      Group = "Grupo6"
    }
  )
  
  user_data = templatefile("${var.profile_path}/provision.sh", {
    ami_user    = "ubuntu"
    # asociar access key y user a la instancia
    ACCESS_KEY  = aws_iam_access_key.programmatic_user_key.id
    SECRET_KEY  = aws_iam_access_key.programmatic_user_key.secret
    AWS_ACCOUNT = var.aws_account
  })

}


# Crear VPC en us-east-1
#
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr         # Usar la variable CIDR del VPC
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    var.tags,
    {
      Name    = "terraform-vpc"
      Project = "PINF"
      Group   = "Grupo6"
    }
  )
}

# Obtener todas las zonas de disponibilidad para la región
#
data "aws_availability_zones" "azs" {
  state = "available"
}

# Crear Subred Pública #1 en la primera zona de disponibilidad
#
resource "aws_subnet" "subnet_public" {
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_cidrs[0]  # Usar CIDR para la subred pública
  map_public_ip_on_launch = true  # Permitir asignación de IP pública
  tags = {
    Name = "subnet-public-1"
  }
}

# Crear Internet Gateway
#
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

# Crear tabla de rutas
#
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "Route_Table"
  }
}

# Agregar una ruta predeterminada (0.0.0.0/0) a la tabla de rutas
#
resource "aws_route" "route" {
  route_table_id         = aws_route_table.route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Asociar la tabla de rutas con la Subnet Pública
#
resource "aws_route_table_association" "subnet_association_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.route_table.id
}

# Crear Grupo de Seguridad (SG) para permitir TCP/80 y TCP/22
#
resource "aws_security_group" "sg" {
  name        = "sg"
  description = "Allow TCP/80 & TCP/22"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr   # Usar la variable de CIDR permitidas para SSH
  }

  ingress {
    description = "Allow HTTP traffic on TCP/80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow  NGINX Exporter traffic"
    from_port   = 9091
    to_port     = 9091
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow   cadvisor traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow  prometheus traffic"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow  Grafana traffic"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

