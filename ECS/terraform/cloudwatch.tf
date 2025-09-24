resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 7
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-logs"
    Environment = var.environment
  }
}

# CloudWatch Log Stream
resource "aws_cloudwatch_log_stream" "ecs" {
  name           = "${var.project_name}-${var.environment}-stream"
  log_group_name = aws_cloudwatch_log_group.ecs.name
}