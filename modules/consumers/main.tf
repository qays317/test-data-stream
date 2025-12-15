//======================================================================================================================================
//                                                        DynamoDB
//======================================================================================================================================

# DynamoDB table for storing active trading positions 
resource "aws_dynamodb_table" "dynamodb_table" {
    name = var.dynamodb_table_name
    billing_mode = "PAY_PER_REQUEST"        # No need to provision capacity
    hash_key = "symbol"
    range_key = "position_id"

    attribute {
      name = "symbol"                       # Stock symbol
      type = "S"
    }

    attribute {
      name = "position_id"                  # Sort key
      type = "S"
    }

    tags = { Name = var.dynamodb_table_name }
}


//======================================================================================================================================
//                                                          Lambda
//======================================================================================================================================

# Lambda IAM role 
resource "aws_iam_role" "lambda_execution_role" {
    name = "kinesis-consumer-lambda-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })  
    tags = { Name = "kinesis-consumer-lambda-role" }
}

# Custom policies
resource "aws_iam_policy" "lambda_policies" {
    for_each = {
        for k, v in var.lambda_policies : k => v
        if !v.is_aws_managed
    }
        name = "kinesis-consumer-${each.key}-policy"
        policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
                {
                    Effect = "Allow"
                    Action = each.value.policy_document.actions
                    Resource = coalesce(
                        each.key == "kinesis-access" ? [var.kinesis_stream_arn] : null,
                        each.key == "dynamodb-access" ? [aws_dynamodb_table.dynamodb_table.arn] : null,
                        each.key == "s3-access" ? ["arn:aws:s3:::${var.s3_bucket_id}/*"] : null,
                        []
                    )
                }
            ]
        })
}

# Attach all policies
resource "aws_iam_role_policy_attachment" "lambda_policy_attachments" {
  for_each = var.lambda_policies  
    role = aws_iam_role.lambda_execution_role.name
    policy_arn = each.value.is_aws_managed ? each.value.aws_policy_arn : aws_iam_policy.lambda_policies[each.key].arn
}

# Lambda function
resource "aws_lambda_function" "kinesis_consumer" {
    function_name = var.lambda_function_name
    role = aws_iam_role.lambda_execution_role.arn
    handler = "consumer_lambda_function.lambda_handler"
    runtime = "python3.9"
    timeout = 300
    
    filename = "consumer_lambda_function.zip"
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    
    environment {
        variables = {
            DYNAMODB_TABLE = aws_dynamodb_table.dynamodb_table.name
            S3_BUCKET = var.s3_bucket_id
        }
    }
    
    tags = { Name = var.lambda_function_name }
}

# Create Lambda deployment package
data "archive_file" "lambda_zip" {
    type = "zip"
    output_path = "consumer_lambda_function.zip"
    source {
        content = file("${path.module}/consumer_lambda_function.py")
        filename = "consumer_lambda_function.py"
    }
}

# Event Source Mapping - Connect Kinesis to Lambda
resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
    event_source_arn = var.kinesis_stream_arn
    function_name = aws_lambda_function.kinesis_consumer.arn
    starting_position = "LATEST"
    batch_size = 10
}
