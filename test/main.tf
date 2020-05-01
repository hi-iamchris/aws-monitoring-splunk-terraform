//AWS Provider - configure credentials using AWS CLI
provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}

module "vpc_flow_logs" {
  source = "../cloudwatch"
  vpcflowlog-name = "VPCFlowLog"
  vpc-id = "vpc-xxxxxx"
}

module "splunk-iam" {
  source = "../helpers/splunk"
  iam_user_name = "splunk"
}

module "config_service" {
  source = "../config"
  config-name = "aws-config-terraform"
  config-snapshot-freq = "Six_Hours"
  s3-bucket-name = "config-service"
  splunk-config-sqs-queue = "splunk-config-sqs-queue"
}

module "cloudtrail" {
  source = "../cloudtrail"
  s3-bucket-name-cloutrail = "cloudtrail-logs"
  s3-bucket-prefix-cloutrail = "ct"
  splunk-cloudtrail-sqs-queue = "splunk-cloudtrail-sqs-queue"
  trail-name = "splunk_trail"
}
