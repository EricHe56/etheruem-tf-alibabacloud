
variable "profile" {
  type = string
  default = "default"
}

variable "region" {
  default = "eu-west-1"
}

variable "ram_role_name" {
  description = "Role name by default for ECS instance access kms"
  type = string
  default = "ecs-kms-ram-role"
}

variable "ram_role_description" {
  description = "Description of the RAM role."
  type        = string
  default     = "ecs access kms with ecs-kms-ram-role role"
}

variable "instance_type" {
  description = "ECS Instance type."
  type        = string
  default     = "ecs.c5.xlarge "
}

variable "ecs_instance_name" {
  description = "ECS Instance name."
  type        = string
  default = "eth-node"
}

variable "secret_name" {
  description = "The ethereum private key secret name in KMS."
  type        = string
  default     = "ethereum_private_key"
}

variable "secret_data" {
  description = "The secret data which is ethereum private key."
  type        = string
  default     = ""
  sensitive = true
}

variable "file_system_protocol_type" {
  default = "NFS"
}

//file_system_type: standard(General-purpose),extreme
variable "file_system_type" {
  default = "standard"
}

//when FileSystemType=standard, the value options is Performance or Capacity
//when FileSystemType=extreme, the value options is standard or advance
variable "file_system_storage_type" {
  default = "Performance"
}

variable "file_system_source_cidr_ip" {
  default = "0.0.0.0/0"
}

variable "file_system_description" {
  default = "ethdata"
}
