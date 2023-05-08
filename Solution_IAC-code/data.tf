data "archive_file" "lambda_code" {
  type        = "zip"
  source_dir  = "./lambda-code/"
  output_path = "./lambda-code/alert-mail-lambda.zip"
}
