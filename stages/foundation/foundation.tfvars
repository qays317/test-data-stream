vpc_cidr_block_config = "192.168.0.0/16"

subnet_config = {
  Prv-Sub-1 = {
    cidr_block = "192.168.1.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
  }
  Pub-Sub-2 = {
    cidr_block = "192.168.2.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
  }
  Prv-Sub-1A = {
    cidr_block = "192.168.3.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = false
  }
  Prv-Sub-1B = {
    cidr_block = "192.168.4.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = false
  }
}

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
