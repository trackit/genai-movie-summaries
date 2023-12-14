resource "aws_s3_bucket" "movie-bucket" {
  bucket = "my-movie-summary-bucket"
}

resource "aws_s3_bucket" "movie-summary-transcription-bucket" {
  bucket = "movie-transcription-bucket"
}

resource "aws_cloudwatch_event_rule" "s3_event_rule" {
  name        = "s3-upload-event-rule"
  description = ""

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

resource "aws_cloudwatch_event_target" "s3_event_target" {
  rule      = aws_cloudwatch_event_rule.s3_event_rule.name
  target_id = "sf-target"
  arn       = aws_sfn_state_machine.sf-process-movies.arn
  role_arn  = aws_iam_role.event_bridge_role.arn

  input_transformer {
    input_paths = {
      "bucketName" = "$.detail.requestParameters.bucketName"
      "objectKey"  = "$.detail.requestParameters.key"
    }

    input_template = <<EOF
{"bucket": <bucketName>, "key": <objectKey>}
EOF
  }
}
