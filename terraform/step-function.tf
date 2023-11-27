resource "aws_sfn_state_machine" "sf-process-movies" {
  name     = "process-movies"
  role_arn = aws_iam_role.sfn_role.arn

  definition = jsonencode(
  {
    "Comment": "A simple minimal Step Function",
    "StartAt": "PassState",
    "States": {
      "PassState": {
        "Type": "Pass",
        "Result": "This is a test state",
        "End": true
      }
    }
  })
}

resource "aws_iam_role" "sfn_role" {
  name = "sfn_execution_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}