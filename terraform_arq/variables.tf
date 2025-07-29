# variables.tf

variable "aws_access_key" {
  description = "Chave de acesso da AWS."
  type        = string
  sensitive   = true # Impede que o Terraform mostre este valor nos logs
}

variable "aws_secret_key" {
  description = "Chave secreta da AWS."
  type        = string
  sensitive   = true # Impede que o Terraform mostre este valor nos logs
}

variable "aws_session_token" {
  description = "Token de sessão da AWS (para credenciais temporárias)."
  type        = string
  default     = null # Torna esta variável opcional
  sensitive   = true # Impede que o Terraform mostre este valor nos logs
}

variable "aws_default_region" {
  description = "Região padrão (us-east-1) da AWS para criar os recursos."
  type        = string
}

variable "bucket_name"{
  description = "Nome único para o bucket."
  type = string
}

variable "glue_name" {
  description = "Nome do glue que irá ser acionado pela lambda."
  type = string
}