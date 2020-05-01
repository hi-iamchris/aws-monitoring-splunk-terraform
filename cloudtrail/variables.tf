variable "s3-bucket-name-cloutrail" {
  type = string
  description = "Name of S3 bucket used by AWS CloudTrail"
  default = "cloudtrail-logs"
}

variable "s3-bucket-prefix-cloutrail" {
  type = string
  description = "Prefix for S3 bucket used by AWS CloudTrail"
  default = "ct"
}

variable "splunk-cloudtrail-sqs-queue" {
  description = "SQS Name for Splunk to read from"
  default = "splunk-cloudtrail-sqs-queue"
}

variable "trail-name" {
  description = "Name for the CloudTrail trail"
  default = "splunk_trail"
}
