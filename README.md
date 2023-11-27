# Movie Summarization Pipeline

This repository contains code for deploying a movie summarization pipeline using AWS services and Python-based Lambda functions. The pipeline utilizes Large Language Models for generating summaries of movies uploaded to an AWS S3 bucket.

## Overview

The pipeline is designed to process video files uploaded to S3, using AWS services for event handling, task orchestration, and data storage. It offers both a full and a simplified version for different use cases.

## Features

- **AWS S3 Integration**: Upload and store movie files.
- **Event-Driven Architecture**: Trigger processes with AWS EventBridge and Step Functions.
- **Video Processing**: (Full version) Use AWS Elemental MediaConvert and Amazon Rekognition.
- **Data Storage**: Store and retrieve data with Amazon DynamoDB.
- **API Access**: Interact with the pipeline through AWS API Gateway and Lambda functions.
- **LLM Summarization**: Leverage Bedrock and Anthropic's Claude Instant for generating summaries.

## Getting Started

### Prerequisites

- AWS account and CLI configured.
- Terraform installed for infrastructure deployment.
- Python 3.8 for Lambda functions.

### Deployment

1. **Initialize Terraform**
   ```
   terraform init
   ```
2. **Apply Terraform Configuration**
   ```
   terraform apply
   ```

### Usage

- Upload a video file to the designated S3 bucket.
- The pipeline will trigger and process the file.
- Access the summaries through the provided API endpoints.

## API Reference

- **List Movies Endpoint**: `GET /list`
- **Summarize Movie Endpoint**: `GET /summarize/:id`

## Acknowledgments

- Anthropic for the Claude Instant model.
- AWS services used in this project.
