data "aws_region" "current" {}

/*
===================================================================================================================================================================
===================================================================================================================================================================
      The following execution role will be used by ECS service to set up the task:
        -pull Docker images from ECR
        -Creates CoudWatch log groups and streams
        -Sets up networking and task infrastructure
      It will be used before container starts (during task setup)
      Not available to our application code
      ECS Service → Uses Execution Role → Pulls image → Creates container
===================================================================================================================================================================
===================================================================================================================================================================
*/

# IAM role for ECS execution
resource "aws_iam_role" "ecs_execution_role" {  
    name = "kinesis-producer-execution-role"
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
        }
      ]
    })
    tags = { Name = "kinesis-producer-execution-role" }
}

# AWS managed policy for basic ECS execution
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
    role = aws_iam_role.ecs_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


/*
===================================================================================================================================================================
===================================================================================================================================================================
      * ECS Task Role for producer application runtime access to AWS services.
      * It will be used after container starts (during application runtime)
      * Available inside the container
      * Producer App → Uses Task Role → Access Kinesis data stream
===================================================================================================================================================================
===================================================================================================================================================================
*/

# IAM role for ECS tasks to access Kinesis data stream. The application will use this
resource "aws_iam_role" "ecs_task_role" {
    name = "kinesis-producer-task-role"
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
        }
      ]
    })
    tags = { Name = "kinesis-producer-task-role" }
} 

# The Customer Managed Policy for access Kinesis
resource "aws_iam_policy" "ecs_task_role_policy" {
  name = "kinesis-producer-task-role-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",         # Send single record to Kinesis stream
          "kinesis:PutRecords",        # Send multiple records in batch (more efficient)
          "kinesis:DescribeStream"     # Get stream information (shard count, status)
        ]
        Resource = var.kinesis_stream_arn
      },

    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_runtime_policy" {
    role = aws_iam_role.ecs_task_role.name
    policy_arn = aws_iam_policy.ecs_task_role_policy.arn
}


/*
===================================================================================================================================================================
===================================================================================================================================================================
                                                            ECS 
===================================================================================================================================================================
===================================================================================================================================================================
*/
# ECS Cluster
resource "aws_ecs_cluster" "kinesis_producers" {
    name = var.ecs_cluster_name
    setting {                               # Enhanced monitoring and observability for ECS cluster
        name = "containerInsights"
        value = "enabled"
    }
    tags = { Name = var.ecs_cluster_name }
}

# CloudWatch Log Group for ECS tasks
resource "aws_cloudwatch_log_group" "producer_logs" {
    name = "/ecs/kinesis-producer"
    retention_in_days = 7
    tags = { Name = "kinesis-producer-logs" }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "producer_task_definition" {
    family = "kinesis-producer"
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = 256
    memory = 512
    
    execution_role_arn = aws_iam_role.ecs_execution_role.arn
    task_role_arn = aws_iam_role.ecs_task_role.arn
    
    container_definitions = jsonencode([{
        name  = "kinesis-producer"
        image = var.ecr_image_uri
        
        environment = [
            {
                name = "KINESIS_STREAM_NAME"
                value = var.kinesis_stream_name
            },
            {
                name = "AWS_REGION"
                value = data.aws_region.current.name
            },
            {
                name = "SEND_INTERVAL"
                value = "10"
            }
        ]
        
        logConfiguration = {
            logDriver = "awslogs"
            options = {
                "awslogs-group" = aws_cloudwatch_log_group.producer_logs.name
                "awslogs-region" = data.aws_region.current.name
                "awslogs-stream-prefix" = "ecs"
            }
        }
        
        essential = true                    # Main app (task fails if this fails)
    }])
    
    tags = { Name = var.ecs_task_definition_name }
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_task_sg" {
    vpc_id = var.vpc_id
    
    # Outbound traffic for Docker image pulls and AWS services via VPC endpoints
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [var.vpc_endpoint_sg_id]
    }
    
    tags = { Name = var.ecs_security_group_name }
}

# ECS Service
/*
resource "aws_ecs_service" "producer_service" {
  for_each = var.ecs_service
    name = each.key 
    cluster = aws_ecs_cluster.kinesis_producers.id
    task_definition = aws_ecs_task_definition.producer_task_definition.arn
    desired_count = each.value.desired_count                       
    launch_type = each.value.launch_type
    
    network_configuration {
        subnets = var.ecs_subnets_ids
        security_groups = [aws_security_group.ecs_task_sg.id]
    }
    
    tags = { Name = each.key }
}
*/

resource "aws_ecs_service" "producer_service" {
  name = var.ecs_service.name
  cluster = aws_ecs_cluster.kinesis_producers.id
  task_definition = aws_ecs_task_definition.producer_task_definition.arn
  desired_count = var.ecs_service.desired_count                      
  launch_type = var.ecs_service.launch_type
  
  network_configuration {
      subnets = var.ecs_subnets_ids
      security_groups = [aws_security_group.ecs_task_sg.id]
  }
  
  tags = { Name = var.ecs_service.name }
}

