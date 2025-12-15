output "vpc_id" {
    value = module.foundation.vpc_id
}

output "ecs_subnets_ids" {
    value = module.foundation.ecs_subnets_ids
}
  
output "vpc_endpoint_sg_id" {
    value = module.foundation.vpc_endpoint_sg_id
}