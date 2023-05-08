resource "aws_s3_bucket_policy" "bucket_policy" {
  for_each = var.user

  bucket = module.upload_bucket.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowAccesstoS3",
        Action = [
          "s3:ListBucket"
        ],
        Effect = "Allow",
        Resource = [
          "${module.upload_bucket.s3_bucket_arn}",
          "${module.upload_bucket.s3_bucket_arn}/*"
        ],
        Principal = {
          AWS = [
            aws_iam_role.sftp_role[each.key].arn
          ]
        }
      }
    ]
  })
}


module "upload_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.bucket["name"]
  //acl    = var.bucket["acl"]

  versioning = {
    enabled = var.bucket["versioning"]
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.kms_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

}

resource "aws_kms_key" "kms_key" {
  description = "kms encryption for the bucket"
}



