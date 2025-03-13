# Grupo 6

## Despliegue de Infraestructura en AWS con Terraform y EKS

Este proyecto demuestra cómo desplegar una infraestructura en AWS utilizando Terraform y Amazon EKS (Elastic Kubernetes Service). Incluye la creación de una instancia EC2, un clúster EKS con 3 nodos, y el despliegue de aplicaciones como Nginx, Prometheus y Grafana utilizando GitHub Actions para la automatización.

---

## **Arquitectura de la Infraestructura**

A continuación se muestra un diagrama de la infraestructura desplegada:

![Diagrama de Infraestructura](infra-diagram.png)

### **Componentes Principales**
1. **VPC y Subredes**:
   - Una VPC con subredes públicas y privadas.
   - Subredes públicas accesibles a través de un Internet Gateway.
   - Subredes privadas conectadas a Internet mediante NAT Gateways.

2. **Instancia EC2**:
   - Servidor administrador con herramientas como `kubectl`, `eksctl`, y `helm`.
   - Configurado con un rol IAM para gestionar recursos en AWS.

3. **Clúster EKS**:
   - Clúster de Kubernetes con 3 nodos gestionados.
   - Roles IAM asignados al clúster y a los nodos para interactuar con servicios de AWS.

4. **Aplicaciones Desplegadas**:
   - **Nginx**: Servidor web desplegado en el clúster EKS.
   - **Prometheus**: Sistema de monitoreo y alertas.
   - **Grafana**: Plataforma de visualización de métricas.

---

## **Cómo Usar Este Repositorio**

### **Requisitos Previos**
- Cuenta de AWS con permisos suficientes.
- Terraform instalado en tu máquina local.
- GitHub Actions configurado en el repositorio.

### **Pasos para Desplegar la Infraestructura**

1. **Clonar el Repositorio**:
   ```bash
   git clone https://github.com/tu-usuario/tu-repositorio.git
   cd tu-repositorio
   ```

2. **Configurar AWS CLI:**
Asegúrate de tener configuradas tus credenciales de AWS:

```bash
aws configure
```

3. **Inicializar Terraform:**

```bash
terraform init
```

4. **Revisar el Plan de Terraform:**

```bash
terraform plan
```

5. **Aplicar los Cambios:**

```bash
terraform apply
```

6. **Desplegar Aplicaciones con GitHub Actions:**

- Los workflows de GitHub Actions se ejecutarán automáticamente al hacer push a la rama master o al mergear un pull request.

- Revisa la sección de "Actions" en GitHub para ver el progreso.

7. **Destruir la Infraestructura:**
Para eliminar todos los recursos creados:

```bash
terraform destroy
```

**Estructura del Repositorio**
```bash
.
├── main.tf                  # Configuración principal de Terraform
├── variables.tf             # Variables de Terraform
├── outputs.tf               # Outputs de Terraform
├── backend.tf               # Configuración del backend de Terraform (S3)
├── provision.sh             # Script de provisionamiento para la instancia EC2
├── create_backend.sh        # Script para crear el backend de Terraform en S3
├── .github/workflows/       # Workflows de GitHub Actions
│   ├── apply.yml            # Workflow para desplegar la infraestructura
│   └── destroy.yml          # Workflow para destruir la infraestructura
└── README.md                # Este archivo
```
