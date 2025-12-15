variable "vpc_cidr_block_config" {
    type = string
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
    az_map = {
        "A" = data.aws_availability_zones.available.names[0]
        "B" = data.aws_availability_zones.available.names[1]
    }
    subnet_config = {
        Pub-Sub-1 = {
            cidr_block = "192.168.1.0/24"
            availability_zone = local.az_map["A"]
            map_public_ip_on_launch = true
        }
        Pub-Sub-2 = {
            cidr_block = "192.168.2.0/24"
            availability_zone = local.az_map["B"]
            map_public_ip_on_launch = true
        }
        Prv-Sub-1 = {
            cidr_block = "192.168.3.0/24"
            availability_zone = local.az_map["A"]
            map_public_ip_on_launch = false
        }
        Prv-Sub-2 = {
            cidr_block = "192.168.4.0/24"
            availability_zone = local.az_map["B"]
            map_public_ip_on_launch = false
        }
    }
}

variable "subnet_config" {
    type = map(object({
        cidr_block = string
        availability_zone = string
        map_public_ip_on_launch = bool
    }))
}

variable "endpoint_config" {
    type = map(object({
        vpc_endpoint_type = string
    }))
}
