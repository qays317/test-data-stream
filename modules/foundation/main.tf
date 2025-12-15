data "aws_region" "current" {}


//==================================================================================================================================================
//                                                                       VPC, Subnets, NAt
//==================================================================================================================================================

resource "aws_vpc" "vpc" {
    cidr_block = var.vpc_cidr_block
    # enable DNS for endpoints
    enable_dns_hostnames = true  
    enable_dns_support   = true 
    tags = {
        Name = "Kinesis-VPC"
    }
}

resource "aws_subnet" "main" {
    for_each = var.subnet       
        vpc_id = aws_vpc.vpc.id
        cidr_block = each.value.cidr_block
        availability_zone = each.value.availability_zone
        map_public_ip_on_launch = each.value.map_public_ip_on_launch
        tags = {
            Name = "${each.key}"
        }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    tags = { Name = "Kinesis-IGW" }
}


//==================================================================================================================================================
//                                                                       Route Tables
//==================================================================================================================================================

locals {
  route_tables = {
    private = {}
    public = {
      gateway_id = aws_internet_gateway.igw.id
    }
  }
}

resource "aws_route_table" "main" {
  for_each = local.route_tables
    vpc_id = aws_vpc.vpc.id
    
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = lookup(each.value, "gateway_id", null)
    }
    
    tags = { Name = "${each.key}-route-table" }
}

resource "aws_route_table_association" "private_route_table_associations" {
    for_each = {
      for k, v in aws_subnet.main : k => v
    }
      subnet_id = each.value.id
      route_table_id = each.value.map_public_ip_on_launch == true ? aws_route_table.main["private"].id : aws_route_table.main["private"].id
}


//==================================================================================================================================================
//                                                                     Endpoints
//==================================================================================================================================================

resource "aws_security_group" "endpoints_sg" {
    vpc_id = aws_vpc.vpc.id
    ingress {
        from_port = 443
        to_port = 443
        protocol = "TCP"
        cidr_blocks = [aws_vpc.vpc.cidr_block]
    }
    tags = { Name = "endpoints-sg" }
}

resource "aws_vpc_endpoint" "main" {
    for_each = var.endpoint
        vpc_id = aws_vpc.vpc.id
        service_name = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
        vpc_endpoint_type = each.value.vpc_endpoint_type
        # Interface endpoints use subnets and security groups
        subnet_ids = each.value.vpc_endpoint_type == "Interface" ? [aws_subnet.main["Prv-Sub-1A"].id, aws_subnet.main["Prv-Sub-1B"].id] : null
        security_group_ids = each.value.vpc_endpoint_type == "Interface" ? [aws_security_group.endpoints_sg.id] : null
        private_dns_enabled = each.value.vpc_endpoint_type == "Interface" ? true : null
        # Gateway endpoints use route tables
        route_table_ids = each.value.vpc_endpoint_type == "Gateway" ? [aws_route_table.main["private"].id] : null
        # Policy for VPC endpoints
        policy = null                       # For simplicity - we already have IAM roles on ECS tasks, SGs, private subnets
        tags = { Name = "${each.key}-endpoint" }
}


