resource "aws_dynamodb_table" "Video_transcription_DB" {
  name           = "VideoTranscriptionDB"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "JobName"

  attribute {
    name = "JobName"
    type = "S"
  }
}

output "DYNAMODB_TABLE_NAME" {
  value = aws_dynamodb_table.Video_transcription_DB.name
}

