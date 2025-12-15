output "vpc_id" {
    value = aws_vpc.vpc.id 
}

output "ecs_subnets_ids" {
    value = [aws_subnet.main["Prv-Sub-1A"].id, aws_subnet.main["Prv-Sub-1B"].id]
}

output "vpc_endpoint_sg_id" {
    value = aws_security_group.endpoints_sg.id
}
