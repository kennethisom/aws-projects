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

resource "aws_cloudwatch_event_rule" "every_day_at_1800" {
  name = "EveryDayAt1800"
  description = "Every day at 18:00 UTC"
  schedule_expression = "cron(0 18 * * ? *)"
}

resource "aws_cloudwatch_event_target" "every_day_at_1800" {
  rule = aws_cloudwatch_event_rule.every_day_at_1800.name
  target_id = "weather_alert_every_day_at_1800_target"
  arn = aws_lambda_function.weather_alert.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_weather_alert_lambda_1800" {
  statement_id = "AllowExecutionFromCloudWatch1800"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.weather_alert.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.every_day_at_1800.arn
}

resource "aws_cloudwatch_event_rule" "every_day_at_2200" {
  name = "EveryDayAt2200"
  description = "Every day at 22:00 UTC"
  schedule_expression = "cron(0 22 * * ? *)"
}

resource "aws_cloudwatch_event_target" "every_day_at_2200" {
  rule = aws_cloudwatch_event_rule.every_day_at_2200.name
  target_id = "weather_alert_every_day_at_2200_target"
  arn = aws_lambda_function.weather_alert.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_weather_alert_lambda_2200" {
  statement_id = "AllowExecutionFromCloudWatch2200"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.weather_alert.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.every_day_at_2200.arn
}

resource "aws_ses_email_identity" "target_email" {
  email = "kennethisom@gmail.com"
}

resource "aws_ses_email_identity" "source_email" {
  email = "dustycursor@gmail.com"
}

resource "aws_lambda_function" "weather_alert" {
  function_name = "weatherAlert"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_weather_alert.key

  runtime = "nodejs20.x"
  handler = "main.handler"

  source_code_hash = data.archive_file.lambda_weather_alert.output_base64sha256

  role = aws_iam_role.weather_alert_execute.arn
}

resource "aws_cloudwatch_log_group" "weather_alert" {
  name = "/aws/lambda/${aws_lambda_function.weather_alert.function_name}"

  retention_in_days = 7
}

resource "aws_iam_role" "weather_alert_execute" {
  name = "weatherAlert-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "weather_alert_policy" {
  role       = aws_iam_role.weather_alert_execute.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}