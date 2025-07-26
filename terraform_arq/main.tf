provider "aws" {
  region     = var.aws_default_region  # Substitua pela sua região AWS desejada
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_session_token # Descomente e preencha se estiver usando credenciais temporárias
}

# Bloco que define configurações do Terraform, como os provedores necessários.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Bloco de recurso. Define um recurso a ser criado na nuvem.
# Neste caso, um bucket no serviço S3 da AWS.
resource "aws_s3_bucket" "bucket_do_projeto" {
  # O nome do bucket. PRECISA SER GLOBALMENTE ÚNICO!
  # Mude para algo único para você.
  bucket = "big-data-architecture-fiap-fase-002"

  # Tags são etiquetas para organizar seus recursos.
  tags = {
    Name        = "Bucket do projeto FIAP - Fase 2"
    Environment = "Dev"
  }
  
}

resource "aws_s3_bucket_versioning" "versionamento_do_meu_bucket" {
  # Vincula esta configuração ao bucket criado acima, usando o ID do bucket.
  bucket = aws_s3_bucket.bucket_do_projeto.id

  # O bloco de configuração mudou de nome
  versioning_configuration {
    # O status agora é uma string "Enabled" ou "Suspended"
    status = "Enabled"
  }
}

# "Pasta/Objeto" raw para armazena dados brutos do Scrapping
resource "aws_s3_object" "raw" {
  bucket       = aws_s3_bucket.bucket_do_projeto.id
  key          = "raw/"
  content      = ""
  content_type = "application/x-directory"
}

# "Pasta/Objeto" refined armazenara os dados brutos processados via Glue
resource "aws_s3_object" "refined" {
  bucket = aws_s3_bucket.bucket_do_projeto.id
  key = "refined/"
  content = ""
  content_type = "application/x-directory"
}

# Trazendo o IAM LabRole
data "aws_iam_role" "minha_role_existente" {
  name = "LabRole"
}