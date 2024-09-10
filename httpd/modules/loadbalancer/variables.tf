variable "namespace" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet" {
  type = any
}

variable "sg" {
  type = any
}
