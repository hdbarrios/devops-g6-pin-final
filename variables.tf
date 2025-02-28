variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS Profile"
  default     = "terraform-admin"
}

variable "profile_path" {
  default = "./profiles"
}

variable "ec2_ami" {
  description = "ID de la AMI para la EC2"
  type        = string
}

variable "ec2_instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
}

variable "ec2_storage_type" {
  description = "Tipo de almacenamiento EBS"
  type        = string
}

variable "ec2_storage" {
  description = "Tamaño del volumen EBS en GB"
  type        = number
}

variable "ec2_name" {
  description = "Nombre de la instancia EC2"
  type        = string
}

variable "tags" {
  description = "Etiquetas comunes para recursos"
  type        = map(string)
}

variable "vpc_cidr" {
  description = "CIDR del VPC"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDRs de las subredes privadas"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDRs de las subredes públicas"
  type        = list(string)
}

variable "ssh_cidr" {
  description = "Rango de IPs permitidas para SSH"
  type        = list(string)
}

# Nuevas variables para la configuración de la VPC y EC2

variable "availability_zones" {
  description = "Zonas de disponibilidad para la VPC"
  type        = list(string)
}

variable "key_name" {
  description = "Nombre de la clave SSH para la EC2"
  type        = string
}

variable "create_private_subnet" {
  description = "Indica si se debe crear una subred privada"
  type        = bool
  default     = true
}

variable "create_public_subnet" {
  description = "Indica si se debe crear una subred pública"
  type        = bool
  default     = true
}

variable "ec2_admin_role_cicd" {
  description = "Nombre del role" 
  type        = string
  default     = "ec2_admin_role_cicd"
}

variable "ec2_admin_profile" {
  description = "Nombre del profile"
  type        = string
  default     = "ec2_admin_profile"
}

variable "programmatic_user" {
  description = "Nombre del usuario programatico"
  type        = string
  default     = "ec2_admin_role_cicd"
}

variable "aws_account" {
  description = "Cuenta de AWS"
  type        = string
  default     = 536697232168
}
