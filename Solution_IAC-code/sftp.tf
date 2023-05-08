data "aws_caller_identity" "current" {}

resource "aws_transfer_server" "sftp" {
  endpoint_type          = "PUBLIC"
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = aws_iam_role.cloudwatch_role.arn
  tags = {
    Name = "transfer-server-dump-s3"
  }
}

resource "aws_transfer_user" "users" {
  for_each = var.user

  server_id      = aws_transfer_server.sftp.id
  user_name      = each.key
  home_directory = "/${module.upload_bucket.s3_bucket_id}/${each.value}"
  role           = aws_iam_role.sftp_role[each.key].arn
   # "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${each.key}-sftprole"
      
}

//IAM Roles and Policies for AWS Transfer Family


resource "aws_iam_role" "sftp_role" {
  for_each    = var.user
  name        = "${each.key}-sftprole"
 

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })

}

resource "aws_iam_policy" "sftp_policy" {
  for_each = var.user
  name     = "sftppolicy-${each.key}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket"
           

        ]
        Effect = "Allow"
        Resource = [
          "${module.upload_bucket.s3_bucket_arn}",
          "${module.upload_bucket.s3_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "s3:*"

        ]
        Effect = "Deny"
        Resource = [
          "${module.upload_bucket.s3_bucket_arn}/*}"
        ]
      },
      {
        Action = [
          "s3:GetObject"
        ],
        Effect = "Allow",
        Resource = [
          "${module.upload_bucket.s3_bucket_arn}/${each.value}/*"
        ]
      },

      {
        Effect = "Allow",
        Action = "s3:PutObject",
        Resource = [
          "${module.upload_bucket.s3_bucket_arn}/${each.value}/*"
          
        ]
      }

    ]
  })
}

resource "aws_iam_role_policy_attachment" "sftp_attachment" {
  for_each   = var.user
  role       = aws_iam_role.sftp_role[each.key].name
  policy_arn = aws_iam_policy.sftp_policy[each.key].arn
}

resource "aws_iam_policy" "kms_policy" {
  name_prefix = "kms-policy-"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Stmt1544140969635",
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ],
        Resource = aws_kms_key.kms_key.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kms_policy_attachment" {
  for_each   = var.user
  policy_arn = aws_iam_policy.kms_policy.arn
  role       = aws_iam_role.sftp_role[each.key].name
}

resource "aws_iam_role" "cloudwatch_role" {
  name = "sftp-server-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cloudwatch_policy" {
  name_prefix = "cloudwatch-policy-transfer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_cloudwatch_log_group.transfer_logs.arn}",
          "${aws_cloudwatch_log_group.transfer_logs.arn}:*"
        ]
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
  role       = aws_iam_role.cloudwatch_role.name
}





