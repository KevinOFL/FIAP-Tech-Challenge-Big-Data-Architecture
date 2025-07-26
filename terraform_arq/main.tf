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

# Zipando o código fonte da função lambda
data "archive_file" "lambda_zip" {
  type = "zip"
  source_file = "${path.module}/src/trigger_glue.py"
  output_path = "${path.module}/dist/trigger_glue.zip"
}

# Criação da função lambda para fazer a ponte do arquivo para o Glue
resource "aws_lambda_function" "scrapping_b3_lambda" {
  # Nome da função
  function_name = "GlueTriggerlambda"
  role = data.aws_iam_role.minha_role_existente.arn # Role para poder ter o poder de acessar o S3

  filename = data.archive_file.lambda_zip.output_path # Local onde se encontra o zip do código
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Configurações de uso do código
  handler = "trigger_glue.lambda_handler"
  runtime = "python3.11"
  timeout = 30

  # Criação da variavel de ambiente no lambda
  environment {
    variables = {
      GLUE_JOB_NAME = "ETL_glue_pregao_B3"
    }
  }
  tags = {
   ManageBy = "Terraform"
  }
}

# Criando a permissão para o S3 poder invocar a função lambda
resource "aws_lambda_permission" "allow_s3_to_invoke" {
  statement_id = "AllowS3ToInvokeLambda" # Nome da regra de politica
  action = "lambda:InvokeFunction" # Especificando qual a ação será acionada
  function_name = aws_lambda_function.scrapping_b3_lambda.function_name # Função que será acionada
  principal = "s3.amazonaws.com" # Serviço que pode realizar a invocação
  source_arn = aws_s3_bucket.bucket_do_projeto.arn # Especificando qual S3 pode exclusivamente acionar
}

# Criando o gatilho de invocação da lambda
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket_do_projeto.id # Bucket que acionara

  lambda_function {
    lambda_function_arn = aws_lambda_function.scrapping_b3_lambda.arn # Função lambda
    events = ["s3:ObjectCreated:Put", "s3:ObjectCreated:CompleteMultipartUpload"] # Qual o tipo de evento gatilho. No caso o de criação de um novo arquivo
    filter_prefix = "raw/" # Gatilho só para a pasta raw/
  }

  depends_on = [ aws_lambda_permission.allow_s3_to_invoke ] # Dependencia da permissão acima
}