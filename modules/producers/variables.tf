variable "vpc_id" {
  type = string
}

variable "kinesis_stream_arn" {
  type = string                             # For producer role policy
}

variable "ecs_cluster_name" {
  type = string
}

variable "kinesis_stream_name" {            # For ECS environment variable
  type = string 
}

variable "ecs_subnets_ids" {            # ECS service network configuration, VPC endpoints 
  type = list(string)
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

variable "ecs_service" {
  type = object({
    name = string
    desired_count = number
    launch_type   = string
  })
}

/*
variable "ecs_service" {
  type = map(object({
    desired_count = number
    launch_type = string
  }))
}
*/

variable "vpc_endpoint_sg_id" {
  type = string
}
