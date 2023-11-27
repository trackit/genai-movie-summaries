resource "aws_cloudwatch_event_rule" "s3_event_rule" {
  name        = "s3-upload-event-rule"
  description = " "

  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail" : {
      "eventSource" : ["s3.amazonaws.com"],
      "eventName" : ["PutObject", "CompleteMultipartUpload"],
      "requestParameters" : {
        "bucketName" : [aws_s3_bucket.movie-bucket.bucket]
        "key": [{
          "suffix": ".mp4"
        }, {
          "suffix": ".mov"
        }, {
          "suffix": ".avi"
        }]
      }
    }
  })
}

resource "aws_iam_role" "event_bridge_role" {
  name = "eventbridge_execution_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "event-bridge_sfn_policy" {
  name        = "EventBridgeSFNPolicy"
  description = "Policy for EventBridge to start Step Function"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = "states:StartExecution",
        Resource = aws_sfn_state_machine.sf-process-movies.arn,
        Effect   = "Allow",
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_sfn_attach" {
  role       = aws_iam_role.event_bridge_role.name
  policy_arn = aws_iam_policy.event-bridge_sfn_policy.arn
}
