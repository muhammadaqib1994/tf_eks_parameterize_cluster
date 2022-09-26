variable "CLUSTER_NAME" {
  type        = string
  description = "Name for the eks cluster."
  default     = "test-cluster"
}

variable "CLUSTER_VERSION" {
  default     = "1.20"
  type        = string
  description = "Kubernetes version in EKS."
}

variable "INSTANCE_TYPES" {
  type    = list(string)
  default = ["t2.micro"]
}

variable "VPC_ID" {
  type        = string
  description = "VPC ID of the vpc where the cluster will be."
  default     = "vpc-01d4c978b2a9ae023"
}

variable "API_SUBNET" {
  type        = list(string)
  description = "List of the subnets for the EKS api server."
  default     = ["subnet-06ea7c1b162480758", "subnet-0416519b4bda4578f"]
}

variable "WORKERS_SUBNETS" {
  type        = list(string)
  description = "List of the subnets for the EKS api server."
  default     = ["subnet-073b537ecd7c2efa7", "subnet-0f2143f26f35ea0b6"]
}


variable "API_PRIVATE_ACCESS" {
  type    = bool
  default = false
}


variable "AWS_REGION" {
  type    = string
  default = "us-west-2"
}

