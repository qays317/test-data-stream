data "terraform_remote_state" "foundation_state" {
    backend = "s3"
    config = {
      bucket = var.state_bucket_name
      key = "stages/foundation/terraform.tfstate"
      region = var.state_bucket_region
    }      
}

data "terraform_remote_state" "stream_state" {
    backend = "s3"
    config = {
      bucket = var.state_bucket_name
      key = "stages/data-streaming/terraform.tfstate"
      region = var.state_bucket_region
    }      
}

module "producer" {
    source = "../../modules/producers"
    # From foundation stage
    vpc_id = data.terraform_remote_state.foundation_state.outputs.vpc_id
    ecs_subnets_ids = data.terraform_remote_state.foundation_state.outputs.ecs_subnets_ids
    # From data streaming stage
    kinesis_stream_name = data.terraform_remote_state.stream_state.outputs.kinesis_stream_name
    kinesis_stream_arn = data.terraform_remote_state.stream_state.outputs.kinesis_stream_arn
    # ECS configuration
    ecs_cluster_name = var.ecs_cluster_name
    ecs_task_definition_name = var.ecs_task_definition_name
    ecs_security_group_name = var.ecs_security_group_name
    ecs_service = var.ecs_service_config
    ecr_image_uri = var.ecr_image_uri
}