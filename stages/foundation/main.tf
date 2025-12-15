module "foundation" {
    source = "../../modules/foundation"
    vpc_cidr_block = var.vpc_cidr_block_config
    subnet = var.subnet_config
    endpoint = var.endpoint_config
}