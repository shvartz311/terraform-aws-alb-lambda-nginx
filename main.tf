
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

/* resource "aws_elb_attachment" "attach_ec2" {
  elb      = aws_lb.default.id
  instance = aws_instance.ubuntu.id
} */

# Our load balancer has listeners, which have rules that decide where to direct traffic (target group), as I've defined:

resource "aws_lb_listener" "lambdalsnr" {
  load_balancer_arn = aws_lb.default.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginxTG.arn
  }
}

# Setting up 1 target group and rule to send requests to lambda, and another to send requests to the nginx
resource "aws_lb_target_group" "lambdaTG" {
  name        = "lambda-TG"
  target_type = "lambda"
  vpc_id = aws_vpc.prod-vpc.id
  lifecycle {
        create_before_destroy = true
        ignore_changes = [name]
    }

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
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

resource "aws_lb_target_group_attachment" "default" {
  target_group_arn = aws_lb_target_group.lambdaTG.arn
  target_id        = aws_lambda_function.get_time.arn
}

resource "aws_lb_target_group" "nginxTG" {
  name = "nginx-TG"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.prod-vpc.id
}

resource "aws_lb_listener_rule" "nginxlsnrrule" {
  listener_arn = aws_lb_listener.lambdalsnr.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginxTG.arn
  }

  condition {
    path_pattern {
      values = ["/web/*"]
    }
  }
}

resource "aws_lb_target_group_attachment" "defaultweb" {
  target_group_arn = aws_lb_target_group.nginxTG.arn
  target_id        = aws_instance.ubuntu.id
}

# Give permission so that accessing the LB can trigger the lambda function
resource "aws_lambda_permission" "with_lb" {
  statement_id  = "AllowExecutionFromLB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_time.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambdaTG.arn
}

# return base url
output "base_url" {
  value = aws_lb.default.dns_name
}


resource "aws_eip" "ubuntu" {
  vpc      = true
  instance = aws_instance.ubuntu.id
}

resource "aws_eip" "lambda" {
  vpc      = true
}

# generate key pair to access ec2 instance
resource "aws_instance" "ubuntu" {
  ami           = "ami-0987943c813a8426b"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id = aws_subnet.subnet-1.id
  key_name = "ubuntu"
  

  # Unable to provision the playbook so thinking about echo
  user_data = <<-EOF
                 #!/bin/bash
                 sudo apt update -y
                 sudo apt install -y jq gzip nano tar git unzip wget docker.io epel-release ansible
                 echo "<h1>Ory</h1>" > /index.html
                 chmod 644 /index.html
                 EOF
  
  tags = {
    Name = "ubuntu"
  }

  # Breaking my head trying to provision the playbook to the instance...
  /* provisioner "file" {
    source      = "playbook.yaml"
    destination = "/playbook.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /playbook.yaml",
      "ansible-playbook /playbook.yaml",
    ]
  }
    connection {
      type     = "ssh"
      host     = aws_instance.ubuntu.id
      user     = "ubuntu"
      #host_key = self.key_name
      #host_key = file("id_rsa.pub")
      private_key = file("ubuntu.pem")
    } */

  
  }

  
  #sudo docker run --name mynginx1 -p 80:80 -v /index.html:/usr/share/nginx/html/index.html -d nginx

