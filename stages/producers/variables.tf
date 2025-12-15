variable "ecs_cluster_name" {
  type = string
}

variable "ecr_image_uri" {
    type = string
}

variable "ecs_task_definition_name" {
    type = string
}

variable "ecs_security_group_name" {
  type = string
}

/*
variable "ecs_service_config" {
  type = map(object({
    desired_count = number
    launch_type = string
  }))
}
*/

variable "ecs_service_config" {
  type = object({
    name = string
    desired_count = number
    launch_type = string 
  })
}
