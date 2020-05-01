
############ AWS Config Service ###################

variable "config-name" {
  type = string
  description = "AWS Config Service name"
  default = "aws-config-terraform"
}

variable "config-snapshot-freq" {
  type = string
  description = "How frequently AWS Config should snapshot the AWS Resources config to S3"
  default = "Six_Hours"
}

variable "s3-bucket-name" {
  type = string
  description = "Name of S3 bucket used by AWS Config Service"
  default = "config-service"
}

variable "splunk-config-sqs-queue" {
  description = "SQS Name for Splunk to read from"
  default = "splunk-config-sqs-queue"
}
