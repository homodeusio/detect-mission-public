resource "aws_ecr_repository" "application" {
  name = "application-repository"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "application-cluster"
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "application"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 1024
  memory = 2048

  container_definitions = templatefile("${path.module}/api-container-definition.json", {
    NAME      = "api"
    IMAGE     = var.image
  })

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn
}

resource "aws_ecs_service" "application" {
  name            = "api"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets = var.ecs_subnets
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    container_name   = "api"
    container_port   = 80
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "ECS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}