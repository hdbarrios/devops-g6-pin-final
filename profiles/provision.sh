#!/bin/bash

# ===========================================================================================================================
# Local Time:
sudo rm -fv /etc/localtime
sudo ln -s /usr/share/zoneinfo/America/Argentina/Buenos_Aires /etc/localtime

# Node exporter: recopila metricas
sudo useradd -s /bin/false node_exporter
sudo wget https://devops-tools-public.s3.amazonaws.com/node_exporter-1.0.1/node_exporter -O /usr/local/bin/node_exporter
sudo chmod 755 /usr/local/bin/node_exporter
sudo chown node_exporter.node_exporter /usr/local/bin/node_exporter
sudo wget https://devops-tools-public.s3.amazonaws.com/node_exporter-1.0.1/node_exporter.service -O /etc/systemd/system/node_exporter.service
sudo chmod 644 /etc/systemd/system/node_exporter.service
sudo chown root.root /etc/systemd/system/node_exporter.service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# ===========================================================================================================================
if ! command -v aws &> /dev/null; then
    echo "Instalando AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
fi

mkdir -p ~/.aws
cat <<EOF > ~/.aws/credentials
[default]
aws_access_key_id = ${ACCESS_KEY}
aws_secret_access_key = ${SECRET_KEY}
region = us-east-1
EOF

echo "Configuración de AWS CLI completada."
aws configure list
# ===========================================================================================================================
sudo apt-get update -y
sudo apt-get install -y docker.io apt-transport-https ca-certificates curl

# instalar kubectl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# instalar helm
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install -y apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm

# Permisos para usar docker: en caso de querer crear/compilar imagen
sudo usermod -aG docker $USER

sudo systemctl start docker
sudo systemctl enable docker

# ===========================================================================================================================
#

#VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=terraform-vpc" --query "Vpcs[0].VpcId" --output text)
#SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text | tr '\n' ',' | sed 's/,$//')

# Crear el cluster EKS
echo "Creando el cluster EKS..."
eksctl create cluster \
  --name eks-mundos-e \
  --version 1.30 \
  --region us-east-1 \
  --node-type t3.small \
  --nodes 3 \
  --with-oidc \
  --ssh-access \
  --ssh-public-key pin \
  --managed \
  --full-ecr-access \
  --zones us-east-1a,us-east-1b,us-east-1c \
  --nodegroup-name ng-mundos-e \
  --node-iam-policies "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicy" \
  --node-iam-policies "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
#  --vpc-public-subnets $SUBNET_IDS \
#  --vpc-id $VPC_ID

# Verificar la creación del cluster
#
echo "Verificando el cluster EKS..."
kubectl get nodes -o wide

# Instalar driver EBS
# la recomendacion de la consigna es esta, sin embargo se prueba con helm para contrl de versiones 
#kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csidriver/deploy/kubernetes/overlays/stable/?ref=release-1.20"

# habilitar/instalar CSI Driver EBS para asegurar que se pueda gestionar volumenes EBS en k8s
#
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
  --namespace kube-system \
  --set controller.serviceAccount.create=true \
  --set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::${AWS_ACCOUNT}:role/AmazonEKS_EBS_CSI_DriverRole

# habilitar OIDC
eksctl utils associate-iam-oidc-provider --cluster eks-mundos-e --approve

# Obtener el ID del proveedor OIDC
var_oidc=$(aws eks describe-cluster --name eks-mundos-e --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
echo $var_oidc

# crear Rol para el EBS CSI Driver
aws iam create-role \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --assume-role-policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Effect\": \"Allow\",
        \"Principal\": {
          \"Federated\": \"arn:aws:iam::536697232168:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/$var_oidc\"
        },
        \"Action\": \"sts:AssumeRoleWithWebIdentity\",
        \"Condition\": {
          \"StringEquals\": {
            \"oidc.eks.us-east-1.amazonaws.com/id/$var_oidc:sub\": \"system:serviceaccount:kube-system:aws-ebs-csi-driver\"
          }
        }
      }
    ]
  }"

# Adjuntar la política AmazonEBSCSIDriverPolicy al rol
aws iam attach-role-policy \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicy

# Obtener el ARN del rol
aws iam get-role --role-name AmazonEKS_EBS_CSI_DriverRole --query "Role.Arn" --output text

# ========================================================================================================
# crear pod nginx
#
echo -e '<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lista de Integrantes</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            margin: 20px;
        }
        table {
            width: 50%;
            margin: 0 auto;
            border-collapse: collapse;
            text-align: left;
        }
        th, td {
            border: 1px solid #000;
            padding: 10px;
        }
        th {
            background-color: #f2f2f2;
        }
        img {
            margin-top: 20px;
            max-width: 300px;
            height: auto;
        }
    </style>
</head>
<body>
    <h1>edu.mundose.com - Proyecto Integracion Final</h1>
    <table>
        <tr>
            <th>Integrantes</th>
            <th>Email</th>
        </tr>
        <tr>
            <td>Juan Pablo Heyda</td>
            <td>juanpabloh.123@gmail.com</td>
        </tr>
        <tr>
            <td>Renzo Emiliano Carletti</td>
            <td>renzocarletti@hotmail.com / pipito1498@gmail.com</td>
        </tr>
        <tr>
            <td>Johanna Dominguez</td>
            <td>johisd9@hotmail.com</td>
        </tr>
        <tr>
            <td>Lucas Bufano</td>
            <td>lucas.bufano2@gmail.com</td>
        </tr>
        <tr>
            <td>Hector Barrios</td>
            <td>hdbarrios@gmail.com</td>
        </tr>
    </table>
    <img src="https://tf-bucket-imgs.s3.us-east-1.amazonaws.com/img/grupo6.png" alt="Grupo6">
</body>
</html>' > /home/ubuntu/index.html

cat <<EOF > /home/ubuntu/nginx-values.yaml
service:
  type: LoadBalancer
  port: 80
replicaCount: 2
EOF

kubectl create namespace mundose
kubectl create configmap nginx-index-html --namespace mundose --from-file=/home/ubuntu/index.html

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm install nginx bitnami/nginx \
  --namespace mundose \
  --create-namespace \
  --set service.type=LoadBalancer \
  --set service.port=80 \
  --set volumeMounts[0].name=nginx-index \
  --set volumeMounts[0].mountPath=/usr/share/nginx/html \
  --set volumes[0].name=nginx-index \
  --set volumes[0].configMap.name=nginx-index-html \
  --set volumes[0].configMap.items[0].key=index.html \
  --set volumes[0].configMap.items[0].path=index.html

kubectl -n mundose get pods
kubectl -n mundose get svc

# Instalando prometheus y grafana
#

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update


# Crear archivo prometheus.yml en /home/ubuntu (directorio por defecto)
cat <<EOF > /home/ubuntu/values-prometheus.yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx_exporter:80']

alertmanager:
  enabled: false        # Deshabilitar Alertmanager si no lo necesitas

pushgateway:
  enabled: false        # Deshabilitar Pushgateway si no lo necesitas

server:
  persistentVolume:
    enabled: false      # Deshabilitar almacenamiento persistente si no lo necesitas
  service:
    type: LoadBalancer  # Exponer Prometheus públicamente
    port: 80

EOF

helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --create-namespace \
  --values values-prometheus.yaml

cat <<EOF > /home/ubuntu/values-grafana.yml
# values-grafana.yaml
service:
  type: LoadBalancer  # Exponer Grafana públicamente
  port: 80

persistence:
  enabled: true       # Deshabilitar almacenamiento persistente si no lo necesitas

adminUser: admin      # Usuario administrador
adminPassword: admin  # Contraseña administrador (cámbiala en producción)
EOF

helm install grafana grafana/grafana \
  --namespace monitoring \
  --create-namespace \
  --values values-grafana.yaml

kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get svc -n mundose

