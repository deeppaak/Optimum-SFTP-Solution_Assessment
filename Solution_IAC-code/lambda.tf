resource "aws_lambda_function" "lambda_function" {
  filename      = data.archive_file.lambda_code.output_path
  function_name = var.lambda_fn_name
  
  role          = aws_iam_role.lambda_role.arn
  handler       = "${var.lambda_fn_name}.lambda_handler"
  runtime       = "python3.9"
  environment {
    variables = {
      SES_FROM = var.ses_from
      SES_TO = var.support_email
      
     # ses_arn = aws_ses_email_identity.ses.arn
      Landing_Bucket_Name = module.upload_bucket.s3_bucket_id
      Server_Id           = aws_transfer_server.sftp.id
    }
  }
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.eventbridge_rule.arn
}

# lambda IAM Role

resource "aws_iam_role" "lambda_role" {
  name = "sftp-lambda-alert-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "sftp_lambda_function_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = aws_cloudwatch_log_group.transfer_logs.arn
      }
    ]
    
  })
}

resource "aws_iam_role_policy_attachment" "lambda_function" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}

data "aws_iam_policy_document" "lambda_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${module.upload_bucket.s3_bucket_arn}",
      "${module.upload_bucket.s3_bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ses:SendEmail"
      
    ]
    resources = [
      "${aws_ses_email_identity.ses.arn}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "transfer:ListServers",
      "transfer:ListUsers"
    ]
    resources = [
      "${aws_transfer_server.sftp.arn}",
      "*"
    ]
  }
  # statement {
  #   effect = "Allow"
  #   actions = [
  #     "sns:Publish"
  #   ]
  #   resources = [
  #     "${aws_sns_topic.topic.arn}"
  #   ]
  # }
}

resource "aws_iam_policy" "lambda_sftp_policy" {
  name   = "lambda_policy"
  policy = data.aws_iam_policy_document.lambda_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_sftp_policy.arn
  role       = aws_iam_role.lambda_role.name
}