data "archive_file" "lambda_weather_alert" {
  type = "zip"

  source_dir  = "${path.module}/../dist/bundle"
  output_path = "${path.module}/../dist/artifact/weather-alert.zip"
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "terraform-lambda-deploys"
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket]

  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

resource "aws_s3_object" "lambda_weather_alert" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "weather-alert.zip"
  source = data.archive_file.lambda_weather_alert.output_path

  etag = filemd5(data.archive_file.lambda_weather_alert.output_path)
}

resource "aws_lambda_function" "weather_alert" {
  function_name = "weatherAlert2"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_weather_alert.key

  runtime = "nodejs20.x"
  handler = "main.handler"

  source_code_hash = data.archive_file.lambda_weather_alert.output_base64sha256

  role = "arn:aws:iam::648899017763:role/service-role/weatherAlert-role-ai4pddjv"
  # role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "weather_alert" {
  name = "/aws/lambda/${aws_lambda_function.weather_alert.function_name}"

  retention_in_days = 7
}

# resource "aws_iam_role" "lambda_exec" {
#   name = "weatherAlert-role-ai4pddjv"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Sid    = ""
#       Principal = {
#         Service = "lambda.amazonaws.com"
#       }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda_policy" {
#   role       = aws_iam_role.lambda_exec.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }