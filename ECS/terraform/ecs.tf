resource "aws_ecs_cluster" "main" { # Creates an ECS cluster
  name = "${var.project_name}-${var.environment}-cluster"
  
  setting {
    name  = "containerInsights" # allows CloudWatch to collect metrics/logs.
    value = "enabled"
  }
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-cluster"
    Environment = var.environment
  }
}

# ECS Task Definition blueprint for container
resource "aws_ecs_task_definition" "app" { 
  family                   = "${var.project_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"] # It will run on Fargate.
  cpu                      = var.task_cpu # Needs X CPU & Y memory.
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn # Uses the execution role (to pull images, send logs).
  task_role_arn            = aws_iam_role.ecs_task.arn # Uses the task role (for app permissions like S3, DynamoDB).
  
  container_definitions = jsonencode([ 
    {
      name  = "${var.project_name}-${var.environment}" # Container name
      image = "${aws_ecr_repository.app.repository_url}:latest" # Image: pulled from ECR repo
      
      portMappings = [ # Opens the app’s port
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      
      environment = [ # Environment variables inside the container
        {
          name  = "PORT"
          value = tostring(var.container_port)
        },
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]
      
      logConfiguration = { # Sends container logs to CloudWatch Logs
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      essential = true
    }
  ])
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-task"
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "app" { # Deploys the task definition into the cluster
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  
  network_configuration { # Runs tasks inside private subnets.
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }
  
  load_balancer { # Connects the service to an Application Load Balancer
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.project_name}-${var.environment}"
    container_port   = var.container_port
  }
  
  depends_on = [ # Waits until the ALB listener and IAM role are ready before deploying
    aws_lb_listener.app,
    aws_iam_role_policy_attachment.ecs_task_execution
  ]
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-service"
    Environment = var.environment
  }
}