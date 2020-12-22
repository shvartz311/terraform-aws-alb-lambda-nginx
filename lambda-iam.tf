resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = file("C:\\Users\\Ory\\Documents\\terraform-lambda-alb\\iam\\lambda-policy.json")
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = file("C:\\Users\\Ory\\Documents\\terraform-lambda-alb\\iam\\lambda-assume-policy.json")
}
