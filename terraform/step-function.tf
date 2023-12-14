resource "aws_sfn_state_machine" "sf-process-movies" {
  name     = "process-movies"
  role_arn = aws_iam_role.sfn_role.arn

  definition = jsonencode(
    {
      "Comment": "Process and transcribe uploaded files",
      "StartAt": "StartTranscriptionJob",
      "States": {
        "StartTranscriptionJob": {
          "Type": "Task",
          "Resource": "arn:aws:states:::aws-sdk:transcribe:startTranscriptionJob"
          "Parameters": {
            "TranscriptionJobName.$": "States.Format('TranscriptionJob-{}', States.UUID())",
            "LanguageCode": "en-US",
            "Media": {
              "MediaFileUri.$": "States.Format('s3://{}/{}', $.bucket, $.key)"
            },
            "OutputBucketName": aws_s3_bucket.movie-summary-transcription-bucket.bucket
          },
          "Next": "WaitForTranscription",
          "ResultPath": "$.transcriptionJob"
        },
        "WaitForTranscription": {
          "Type": "Wait",
          "Seconds": 60,
          "Next": "CheckTranscriptionJobStatus"
        },
        "CheckTranscriptionJobStatus": {
          "Type": "Task",
          "Resource": "arn:aws:states:::aws-sdk:transcribe:getTranscriptionJob",
          "Parameters": {
            "TranscriptionJobName.$": "$.transcriptionJob.TranscriptionJob.TranscriptionJobName"
          },
          "ResultPath": "$.transcriptionResult"
          "Next": "IsTranscriptionComplete"
        },
        "IsTranscriptionComplete": {
          "Type": "Choice",
          "Choices": [
            {
              "Variable": "$.transcriptionResult.TranscriptionJob.TranscriptionJobStatus",
              "StringEquals": "COMPLETED",
              "Next": "WriteToDynamoDB"
            },
            {
              "Variable": "$.transcriptionResult.TranscriptionJob.TranscriptionJobStatus",
              "StringEquals": "IN_PROGRESS",
              "Next": "WaitForTranscription"
            }
          ],
          "Default": "WaitForTranscription"
        },
        "WriteToDynamoDB": {
          "Type": "Task",
          "Resource": "arn:aws:states:::dynamodb:putItem",
          "Parameters": {
            "TableName": aws_dynamodb_table.Video_transcription_DB.name,
            "Item": {
              "JobName": {
                "S.$": "States.UUID()"
              },
              "VideoName": {
                "S.$": "$.key"
              },
              "Transcription": {
                "S.$": "$.transcriptionResult.TranscriptionJob.Transcript.TranscriptFileUri"
              }
            }
          },
          "End": true
        }
      }
    }
  )
}
