variable "vpc_id" {
  type = string
}

variable "alb_subnets" {
  type = list(string)
}

variable "task_role_arn" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "ecs_subnets" {
  type = list(string)
}

variable "image" {
  type = string
}