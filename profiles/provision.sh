#!/bin/bash

# ===========================================================================================================================
# Local Time:
echo -e "configurar local time"
sudo rm -fv /etc/localtime
sudo ln -s /usr/share/zoneinfo/America/Argentina/Buenos_Aires /etc/localtime

# ===========================================================================================================================
# Node exporter: recopila metricas
echo -e "configurar node_exporter"
# Crear usuario para node_exporter

sudo useradd -s /bin/false node_exporter

# Descargar node_exporter desde el repositorio oficial de Prometheus
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz
sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/

# Establecer permisos y propiedad del binario
sudo chmod 755 /usr/local/bin/node_exporter
sudo chown node_exporter.node_exporter /usr/local/bin/node_exporter

# Crear archivo de servicio systemd para node_exporter
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Establecer permisos y propiedad del archivo de servicio
sudo chmod 644 /etc/systemd/system/node_exporter.service
sudo chown root:root /etc/systemd/system/node_exporter.service

# Recargar systemd y habilitar/iniciar el servicio
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# ===========================================================================================================================
#
sudo apt-get update -y
sudo apt-get install -y ca-certificates unzip curl

# ===========================================================================================================================
# AWS Cli

echo -e "configurar access key"
mkdir -p /home/${EC2_USER}/.aws
cat <<EOF > /home/${EC2_USER}/.aws/credentials
[default]
aws_access_key_id = ${ACCESS_KEY}
aws_secret_access_key = ${SECRET_KEY}
region = us-east-1
EOF

echo -e "instalar aws cli"
if ! command -v aws &> /dev/null; then
    echo "Instalando AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
fi

chown -R ${EC2_USER}:${EC2_USER} /home/${EC2_USER}/.aws

echo "Configuración de AWS CLI completada."
aws configure list

# ===========================================================================================================================
# Instalar eksctl

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Instalar kubectl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# Instalar helm
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install -y apt-transport-https 
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm

# ===========================================================================================================================
#
#

echo "crear ssh key en instancia ec2 admin"

cat <<EOF > /home/${EC2_USER}/.ssh/pin.pem
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCkf5wBCxIS1Rt1
8hkWUiY8dO79zIfygSj+hizDmWCAq6QZWs3rb8K2MrUCY+S7lIZG/0d3d7oLVxZD
W9jYabpf1S5T3tdB2sGJpkLbM6eVcVdVq6zOvFcV7FUBYhLeTnFgib2Ox8/DJ1rZ
lcZwomGZr8LwG9r3fb89achUhOudy9sWephCo8jRCP/T1LmGWZNP52qCMwR1oVaj
DsGDmP1MRGrtlazo4DQw7GxhP+CSYmSbRoRpGPNJFzB4OHlcZqKZ8wfUxJ515eDT
9xPi9uiVldfofuXxPRuG4rFtOUymO8IFrtvxOTbqwM6kSZimdK/9yp7J8N5N0T+j
QQ1901DFAgMBAAECggEAAtsuswDwHyYWnDloJfBRYXmD9cxW7EcXAQuvhso+DUs4
UJ1i7RcrbxJEfNENtWkVMhyNbzMDvAiBe97CI4h7F94MeCCAJdCoeB1MKgtZ+fkL
aRLPmmZVmm1C+5YU7vRh4754grG69y/oKVYq/s/UTdYUq9Ub+/Hxv7KmFmZEGLZc
i5Wip0RCxCXByZDy9cRFK03Molyu3oR78dfFTQ5t8GneTwM6PNvScJ4CumowbWD1
TS5G50GVPxytuO1zf6YwmCc0T5EYMCT82vlqbHkb3L0OaW1MtagpNWZf0Ps6Gi2r
We+rQPXRua6x0pYa742F0GJuTS2YTkQVd22J/QUoUQKBgQDSzD7lNN1T5aHdr8/r
f4CwdiLhIVcTini4Qhr3UkN4lS1Bl4O1UZ8MktAgqVzoMHrN+8g/2yHANZbpvbNy
LPFPHJUsgb8w0/SME0HNfXm7wfaL+UBqjlnQxHy+ZsQCWr/e6482uwg14+HF+SCD
8FpQqpB/N1l5DjilnTViLSMA0QKBgQDHxcI8WLqoMkhiDc5H0dB7m+0VRmQXWADc
/1wIP8Fkze5V0FWqQYH9/hwkoJoO9UmUYSh/MJ+0DdZdk7ELqYnbOJIAkj21MfEb
Kxi8XQH29hlPdn+srw0qzLDaoSLDQfSKa52H76o0Jsdyt6ml0hCw5gXU5Qxihhf1
dBy2Ab8ttQKBgEiuvfz/9lSIOACdLz7PDstJYItpmIGXXDqEKJIgXj1Ein80Q+iQ
BRwrvvGUFAHHPYCqkQhbgU6p66gajbYPgwC5JUJcVlT6sDZgKW82FXRE08K9pZVY
EeXm6fAotOru6Xtuk0nWwWT7dwxw8uIrTKjFtt72cbZIzgVkqFR6pbgRAoGAeTgn
l2SjxqHUSCNmcy/+WLMR1mIDJCMTSwZsetjs6dUHdOzYvlnHni6ONy94q/Ds9+tI
nn0Luz7WP6v5t0Dl1K7r8QrMBOHMEpdBCDNLmOZWD2CxMkB6NelEuzUhmeewkjmg
ujaUSdbqGVMWzva7iAvbqAZgUHxbl2YgcdR3hC0CgYAChKHASLfz30CZgl4bRfE/
C0myii/OwMgMwc7EMcrZKlriR2Ai3l2egfOfjKREEdgJ/q5ezWGltZD9lQUMYijm
RD8vNrmgg1tN6BOMhiXkWwtM4tW5G1AEqSLVWz1lQsBfzJVDhFlOwR+fni1NANRA
kCffR0L9ievLmM5WO+BQIA==
-----END PRIVATE KEY-----
EOF
chmod 600 /home/${EC2_USER}/.ssh/pin.pem

# ===========================================================================================================================
# files:
#

echo "crear script con comandos para administrar eks"
cat <<EOFILE > /home/${EC2_USER}/script.sh  
#!/bin/bash

echo "Verificando el cluster EKS..."
kubectl get nodes -o wide

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm upgrade --install nginx-webserver oci://registry-1.docker.io/bitnamicharts/nginx --namespace mundose --create-namespace

kubectl -n mundose get pods
kubectl -n mundose get svc


helm install prometheus prometheus-community/prometheus \
  --namespace prometheus \
  --create-namespace \
  --values prometheus-values.yaml

helm install grafana grafana/grafana \
  --namespace grafana \
  --create-namespace \
  --values grafana-values.yaml

kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get svc -n mundose

kubectl get pv

RUNNER_IP=$(curl -s ifconfig.me)
echo "Puedes acceder a Prometheus en: http://$RUNNER_IP:8080"

# Ejecutar el port-forward en segundo plano
kubectl port-forward -n prometheus deploy/prometheus-server 8080:9090 --address 0.0.0.0 &
PORT_FORWARD_PID=$!  # Capturar el PID del proceso en segundo plano

# Esperar 1 minutos (60 segundos)
sleep 60

# Detener el port-forward después de 5 minutos
kill $PORT_FORWARD_PID
echo "Port-forward detenido después de 5 minutos."

EOFILE

chown -R ${EC2_USER}:${EC2_USER} /home/${EC2_USER}/
