
locals {
    # declare lambda zip location variable to make it more maintainabble
    lambda_zip_location="C:\\Program Files (x86)\\Temp\\get_time.zip"
}

# I am using a data block to generate an archive from my lambda function
data "archive_file" "get_time" {
  type        = "zip"
  source_file = "get_time.py"
  output_path = local.lambda_zip_location
}

resource "aws_lambda_function" "test_lambda" {
  # filename should be same as output_path on data block
  filename      = local.lambda_zip_location
  function_name = "get_time"
  role          = aws_iam_role.lambda_role.arn
  handler       = "get_time.get_time"

  source_code_hash = "filebase64sha256(local.lambda_zip_location)"

  runtime = "python3.8"

}

