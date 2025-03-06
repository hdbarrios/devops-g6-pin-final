terraform {
  backend "s3" {
    bucket         = "tf-state-pinf-bucket"         # Nombre del bucket
    key            = "pinf-ec2/terraform.tfstate"   # Ruta del archivo state
    region         = "us-east-1"                      # Región del bucket
    dynamodb_table = "tf-pinf-locks"                # Nombre de la tabla DynamoDB (para lock)
    encrypt        = false
  }
}
