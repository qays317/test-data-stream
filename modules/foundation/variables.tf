variable "vpc_cidr_block" {
    type = string
}

variable "subnet" {
    type = map(object({
        cidr_block = string
        availability_zone = string
        map_public_ip_on_launch = bool
    }))
}

variable "endpoint" {
    type = map(object({
        vpc_endpoint_type = string
    }))
}
