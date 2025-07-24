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
  description = "Região padrão da AWS para criar os recursos."
  type        = string
}