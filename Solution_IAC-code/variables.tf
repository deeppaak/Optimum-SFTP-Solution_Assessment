variable "region" {
  type        = string
  description = "Resources will be created in this region"
  default = "eu-west-1"
}

variable "bucket" {
  type = map(string)
  default = {
    name = "sftp-main-filetransfer-bucket"
    acl        = "private"
    versioning = true
  }
}

variable "user" {
type = map(string)
description = "Username and folder name "

  default = {
    "user1" = "user1"
    "user2" = "user2"
    "user3" = "user3"
  }
}

variable "lambda_fn_name" {
  type = string
  default = "alert-mail-lambda"
}

variable "eventbridge_rule_name" {
  description = "EventBridge rule will be created"
  default     = "lambda-scheduled-trigger"
}

variable "lambda_role" {
  description = "IAM role Name for Lambda Execution"
  default     = "lambda_execution_role"
}

variable "support_email" {
 default = "deepakaspirenxt@gmail.com"

}

variable "ses_from" {
    
    default = "deepakaspirenxt@gmail.com"
    
}