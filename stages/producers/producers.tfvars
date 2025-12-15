ecs_cluster_name = "kinesis-cluster"

ecs_security_group_name = "kinesis-producer-tasks-SG" 

ecs_task_definition_name = "kinesis-producer-task-definition"

/*
ecs_service_config = {
    kinesis-producer-service = {
        desired_count = 1   # Only one producer to not have multiple values for the same stocks at the same time
        launch_type = "FARGATE"
    }
}
*/

ecs_service_config = {
    name = "kinesis-producer-service"
    desired_count = 1       # Only one producer to not have multiple values for the same stocks at the same time
    launch_type = "FARGATE"
}