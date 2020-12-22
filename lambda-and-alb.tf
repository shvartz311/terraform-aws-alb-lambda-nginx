
locals {
    # declare vars to make code more maintainabble, like lambda zip location variable
    lambda_zip_location="C:\\Program Files (x86)\\Temp\\get_time.zip"
    lb_name = "test-elb"
    env      = "dev"
}

# I am using a data block to generate an archive from my lambda function
data "archive_file" "get_time" {
  type        = "zip"
  source_file = "get_time.py"
  output_path = local.lambda_zip_location
}

resource "aws_lambda_function" "get_time" {
  # filename should be same as output_path on data block
  filename      = local.lambda_zip_location
  function_name = "get_time"
  role          = aws_iam_role.lambda_role.arn
  handler       = "get_time.get_time"
  # this allows it so if I make changes to the lambda and re-apply on terraform, it knows that there have been changes and applies them
  source_code_hash = "filebase64sha256(local.lambda_zip_location)"
  runtime = "python3.8"
  # Network config for the lambda
  vpc_config {
    subnet_ids         = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
    security_group_ids = [aws_security_group.allow_web.id]
  }

}

# Create our application load balancer
resource "aws_lb" "default" {
  name               = local.lb_name
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
  security_groups    = [aws_security_group.allow_web.id]
  enable_deletion_protection = true
}

# Our load balancer has listeners, which have rules that decide where to direct traffic (target group), as I've defined:
resource "aws_lb_target_group" "lambdaTG" {
  name        = "lambda-TG"
  target_type = "lambda"
}

resource "aws_lb_listener" "lambdalsnr" {
  load_balancer_arn = aws_lb.default.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambdaTG.arn
  }
}

resource "aws_lb_listener_rule" "lambdalsnrrule" {
  listener_arn = aws_lb_listener.lambdalsnr.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambdaTG.arn
  }

  condition {
    path_pattern {
      values = ["/lambda/*"]
    }
  }
}

# Give permission so that accessing the LB can trigger the lambda function
resource "aws_lambda_permission" "with_lb" {
  statement_id  = "AllowExecutionFromLB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_time.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambdaTG.arn
}

resource "aws_lb_target_group_attachment" "default" {
  target_group_arn = aws_lb_target_group.lambdaTG.arn
  target_id        = aws_lambda_function.get_time.arn
}

# return base url
output "base_url" {
  value = aws_lb.default.dns_name
}