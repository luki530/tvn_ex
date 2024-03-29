variable "app_image" {
  type = string
}

variable "ecr_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}


variable "public_subnets" {
  type = list(string)
}
