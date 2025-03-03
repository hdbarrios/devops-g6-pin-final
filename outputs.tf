output "instance_ip" {
  description = "IP pública de la instancia EC2"
  value       = aws_instance.admin_server.public_ip
}

output "instance_private_ip" {
  description = "IP privada de la instancia EC2"
  value       = aws_instance.admin_server.private_ip
}

output "instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.admin_server.id
}

output "instance_type" {
  description = "Tipo de instancia EC2"
  value       = aws_instance.admin_server.instance_type
}

output "instance_state" {
  description = "Estado de la instancia EC2"
  value       = aws_instance.admin_server.instance_state
}

output "instance_public_dns" {
  description = "DNS público de la instancia EC2"
  value       = aws_instance.admin_server.public_dns
}

output "instance_private_dns" {
  description = "DNS privado de la instancia EC2"
  value       = aws_instance.admin_server.private_dns
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.vpc.id
}

# Cambiado para usar las subredes públicas creadas
output "subnet_id" {
  description = "ID de la subred pública"
  value       = aws_subnet.public_subnets[0].id
}

output "security_group_id" {
  description = "ID del grupo de seguridad"
  value       = aws_security_group.sg.id
}

# Cambiado para usar la tabla de rutas pública creada
output "route_table_id" {
  description = "ID de la tabla de rutas"
  value       = aws_route_table.public_route_table.id
}

output "internet_gateway_id" {
  description = "ID del internet gateway"
  value       = aws_internet_gateway.igw.id
}

output "instance_key_name" {
  description = "Nombre de la clave SSH de la instancia"
  value       = aws_instance.admin_server.key_name
}

output "account_id" {
  description = "ID de la cuenta de AWS"
  value       = var.aws_account
}

output "programmatic_user_name" {
  description = "Nombre del usuario programático"
  value       = aws_iam_user.programmatic_user.name
}

output "programmatic_user_access_key" {
  description = "Access key del usuario programático"
  value       = aws_iam_access_key.programmatic_user_key.id
  sensitive   = true
}

output "eks_cluster_name" {
  description = "Nombre del cluster EKS"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint del cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Datos del certificado de autoridad del cluster EKS"
  value       = module.eks.cluster_certificate_authority_data
}

# Este output ya no está disponible en la versión 20 del módulo
# Reemplazado por la siguiente información sobre acceso
#output "aws_auth_configmap_yaml" {
#  description = "Información de acceso al cluster"
#  value       = "El ConfigMap yaml ya no está disponible en la versión 20 del módulo EKS. Se usa access_entries en su lugar."
#}

# Añadimos información sobre los accesos configurados
output "eks_access_entries" {
  description = "Entradas de acceso configuradas para el cluster EKS"
  value       = module.eks.access_entries
}
