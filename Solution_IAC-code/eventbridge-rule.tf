# eventbridge rule 

resource "aws_cloudwatch_event_rule" "eventbridge_rule" {
  name        = var.eventbridge_rule_name
  description = "EventBridge rule will trigger Lambda function at 7PM "

  schedule_expression = "cron(0 19 * * ? *)" 
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.eventbridge_rule.name
  arn       = aws_lambda_function.lambda_function.arn
  
}