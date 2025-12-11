variable "region" {
  description = "Región de OCI donde se desplegarán los recursos"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID del compartment donde desplegar los recursos"
  type        = string
}

variable "vcn_cidr_block" {
  description = "CIDR block para el VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block para la subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block para la subnet privada"
  type        = string
  default     = "10.0.2.0/24"
}

variable "mysql_admin_username" {
  description = "Usuario administrador de MySQL"
  type        = string
  default     = "admin"
}

variable "mysql_admin_password" {
  description = "Contraseña del administrador de MySQL"
  type        = string
  sensitive   = true
}

variable "mysql_db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "nl2sql_db"
}

variable "compute_shape" {
  description = "Shape de la instancia de compute"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "compute_ocpus" {
  description = "Número de OCPUs para la instancia"
  type        = number
  default     = 2
}

variable "compute_memory_in_gbs" {
  description = "Memoria en GB para la instancia"
  type        = number
  default     = 16
}

variable "heatwave_model_id" {
  description = "Model ID para HeatWave GenAI"
  type        = string
  default     = "mistral-7b-instruct-v1"
}