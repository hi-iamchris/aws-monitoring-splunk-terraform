# aws-monitoring-splunk-terraform

Terraform module to implement best-practise monitoring for AWS instances using following AWS Services:
- AWS CloudWatch Basic Monitoring 
- VPC Flow Logs via AWS CloudWatch
- AWS CloudTrail
- AWS Config 
- AWS Config Rules (in progress) 

AWS monitoring services pushe notifications to SNS service and then to SQS queues, where those could be fetched by third party monitoring system, like Splunk.  

## Pre-requisites
- Terraform v0.12
- Splunk Enteprise/Cloud environment with installed Splunk App for AWS and Splunk Add-on for Amazon Web Services / or different monitoring solution
- AWS instance with API credentials 

## Input variables
See `main.tf` to set input variables for every module. Optionally, have a look at `variables.tf` of every module for details and customisations.
  

## Example of use
See test directory for test examples or use the snipet below

`main.tf`

```
provider "aws" {
	profile = "default"
	region = "eu-west-2"
}

module "vpc_flow_logs" {
	source = "../cloudwatch"
	vpcflowlog-name = "VPCFlowLog"
	vpc-id = "vpc-xxxxx"
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
```

## Run
```
terraform init
terraform plan
terraform apply
```

## Outputs
AWS credentials (key_id and key_secret) to be configured within Splunk Add-on for AWS:
- module.splunk_iam.splunk_iam_access_key_id
- value = module.splunk_iam.splunk_iam_access_key_secret

## Splunk configuration
- In Splunk Add-on for AWS, on the Configration tab, add AWS account with Key ID and Key secret returned by the aws-monitoring-splunk-terraform script
- In Splunk Add-on for AWS, on the Inputs tab, configure Inputs:
	- AWS CloudWatch 
	- AWS Config (Data type: Config)
	- AWS CloudTrail (Data type: CloudTrail)
	- AWS Desription
