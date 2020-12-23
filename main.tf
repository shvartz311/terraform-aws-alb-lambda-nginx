
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
  # source_code_has allows it so if I make changes to the lambda and re-apply on terraform, it knows that there have been changes and applies them
  source_code_hash = "filebase64sha256(local.lambda_zip_location)"
  runtime = "python3.8"
  memory_size   = "128"
  timeout       = "30"
  publish       = false
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
  priority = 100

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

# insert ubuntu with nginx as container configuerd by ansible here
# generate key pair to access ec2 instance
resource "aws_instance" "ubuntu" {
  ami           = "ami-0987943c813a8426b"
  instance_type = "t2.micro"
  key_name = "ubuntu"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id = aws_subnet.subnet-1.id

  # ansible should delpoy and configure so no docker run apparently
  user_data = <<-EOF
                 #!/bin/bash
                 sudo apt update -y
                 sudo apt install -y jq gzip nano tar git unzip wget docker.io epel-release ansible
                 echo "<h1>Ory</h1>" > /index.html
                 chmod 644 /index.html
                 EOF
  
  provisioner "remote-exec" {
    inline = [
      "ansible-playbook playbook.yaml",
    ]
  }
}
  #sudo docker run --name mynginx1 -p 80:80 -v /index.html:/usr/share/nginx/html/index.html -d nginx

  tags = {
    Name = "ubuntu"
  }
}

resource "aws_eip" "ubuntu" {
  vpc      = true
  instance = aws_instance.ubuntu.id
}


# return base url
output "base_url" {
  value = aws_lb.default.dns_name
}