module "ecs_alb_us" {
  source = "./ecs_alb"

  vpc_id              = module.vpc_us.vpc_id
  alb_subnets         = module.vpc_us.public_subnets

  task_role_arn = aws_iam_role.task_role.arn
  execution_role_arn = aws_iam_role.execution_role.arn

  ecs_subnets = module.vpc_us.private_subnets

  image = "nginx:latest"

  providers = {
    aws = "aws.us-east-2"
  }
}

module "ecs_alb_eu" {
  source = "./ecs_alb"

  vpc_id              = module.vpc_eu.vpc_id
  alb_subnets         = module.vpc_eu.public_subnets

  task_role_arn = aws_iam_role.task_role.arn
  execution_role_arn = aws_iam_role.execution_role.arn

  ecs_subnets = module.vpc_eu.private_subnets

  image = "nginxdemos/hello:latest"

  providers = {
    aws = "aws.eu-west-2"
  }
}