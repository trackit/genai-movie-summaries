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

resource "aws_iam_policy" "transcribe_policy" {
  name = "StepFunctionTranscribePolicy"
  description = "Policy to allow Step Function to access Transcribe services"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "transcribe:StartTranscriptionJob",
          "transcribe:GetTranscriptionJob",
        ],
        Resource = "*",
        Effect   = "Allow"
      },  {
        "Effect": "Allow",
        "Action": "s3:GetObject",
        "Resource": "${aws_s3_bucket.movie-bucket.arn}/*"
      }, {
        "Effect": "Allow",
        "Action": [
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Resource": [
          aws_s3_bucket.movie-summary-transcription-bucket.arn,
          "${aws_s3_bucket.movie-summary-transcription-bucket.arn}/*"
        ]
      }, {
        "Effect": "Allow",
        "Action": [
          "dynamodb:PutItem"
        ],
        "Resource": "arn:aws:dynamodb:*:*:table/${aws_dynamodb_table.Video_transcription_DB.name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "transcribe_attach" {
  role = aws_iam_role.sfn_role.name
  policy_arn = aws_iam_policy.transcribe_policy.arn
}

resource "aws_iam_role" "lambda_role" {
  name = "my_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "s3:GetObject",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "bedrock:InvokeModel"
        ],
        Effect = "Allow",
        Resource = "*",
      },
    ],
  })
}
