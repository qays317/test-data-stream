vpc_cidr_block_config = "192.168.0.0/16"

endpoint_config = {
  logs = {
    vpc_endpoint_type = "Interface"
  }
  kinesis-streams = {
    vpc_endpoint_type = "Interface"
  }
  s3 = {
    vpc_endpoint_type = "Gateway"
  }
  ecr_api = {
    vpc_endpoint_type = "Interface"
  }
  ecr_dkr = {
    vpc_endpoint_type = "Interface"
  }
}
