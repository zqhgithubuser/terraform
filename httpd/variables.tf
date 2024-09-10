variable "namespace" {
  description = "The project namespace to use for unique resource naming"
  type        = string
}

variable "region" {
  description = "The AWS region"
  default     = "ap-southeast-1"
  type        = string
}
