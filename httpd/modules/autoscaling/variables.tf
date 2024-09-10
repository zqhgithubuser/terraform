variable "namespace" {
  type = string
}

variable "region" {
  type = string
}

variable "sg" {
  type = any
}

variable "subnet" {
  type = any
}

variable "lb_target_group" {
  type = any
}

variable "efs_id" {
  type = string
}

variable "efs_mount_targetA" {
  type = any
}

variable "efs_mount_targetB" {
  type = any
}
