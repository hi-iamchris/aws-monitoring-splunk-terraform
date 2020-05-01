####################################################################
#####-------------   AWS Config Service      --------###############
####################################################################

##-- If you have previously configured the service via UI, clear the config via CMD:
##--  aws configservice delete-configuration-recorder --configuration-recorder-name default
##--  aws configservice delete-delivery-channel --delivery-channel-name default


# Get the access to the effective Account ID in which Terraform is working.
data "aws_caller_identity" "current" {
}
# Data source to lookup information about the current AWS partition in which Terraform is working.
data "aws_partition" "current" {
}

# Local variables
locals {
  //Appends AWS instance ID to name of S3 buket
  s3-bucket-name-for-config = format("%s-%s",var.s3-bucket-name,data.aws_caller_identity.current.account_id)
}

// Create an S3 Bucket for AWS Cofig Service to store the data in
resource "aws_s3_bucket" "aws_s3_bucket_for_config" {
  bucket = local.s3-bucket-name-for-config
  acl="private"
  force_destroy = true
}
//Block S3 public access
resource "aws_s3_bucket_public_access_block" "s3_public_restriction" {
  bucket = aws_s3_bucket.aws_s3_bucket_for_config.id
  block_public_acls   = true
  block_public_policy = true
}
################
/// Create an SNS topic that for AWS Config to push 
resource "aws_sns_topic" "splunk_updates_config" {
  name = "splunk-config-updates"
}

/// Configure SNS Topic policy -> Allow Config Role to access SNS
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.splunk_updates_config.arn
  policy = <<POLICY
     {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "AWSNSPolicy20200403",
          "Effect": "Allow",
          "Principal": {
            "AWS": "*"
          },
          "Action": [
            "sns:GetTopicAttributes",
            "sns:SetTopicAttributes",
            "sns:AddPermission",
            "sns:RemovePermission",
            "sns:DeleteTopic",
            "sns:Subscribe",
            "sns:ListSubscriptionsByTopic",
            "sns:Publish"
          ],
          "Resource": "${aws_sns_topic.splunk_updates_config.arn}",
          "Condition": {
            "StringEquals": {
              "AWS:SourceOwner": "${data.aws_caller_identity.current.account_id}"
            }
          }
        },
        {
          "Sid": "AWSConfigSNSPolicy20200404",
          "Effect": "Allow",
          "Principal": {
            "AWS": "${aws_iam_role.aws-config-terraform.arn}"
          },
          "Action": "sns:Publish",
          "Resource": "${aws_sns_topic.splunk_updates_config.arn}"
    }
  ]
}
POLICY
}

/// Create an SQS queue for queueing notification from AWS config via SNS

resource "aws_sqs_queue" "splunk_config_sqs_queue" {
  name                      = var.splunk-config-sqs-queue
  message_retention_seconds = 345600 //4 days
  visibility_timeout_seconds = 360 // visibility timeout set to 6 minutes
  //Configure DeadQueue for undelivered messages in the queue
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.splunk_queue_deadletter.arn
    maxReceiveCount     = 4
  })

  tags = {
    Environment = "Test"
  }
  depends_on = [aws_sqs_queue.splunk_queue_deadletter]
}

// Allow SNS to push the notifications to SQS queue
resource "aws_sqs_queue_policy" "splunk_cloudtrail_sqs_queue_policy" {
  queue_url = aws_sqs_queue.splunk_config_sqs_queue.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy202004222",
  "Statement": [
    {
      "Sid": "AWSCloudTrailSQSPolicyAllowSNS20204222",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.splunk_config_sqs_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.splunk_updates_config.arn}"
        }
      }
    }
  ]
}
POLICY
}

// SNS Dead Queue 
resource "aws_sqs_queue" "splunk_queue_deadletter" {
  name                      = "splunk-config-sns-dead-queue"
}
// Create SNS subscription to push notification to SQS queue
resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.splunk_updates_config.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.splunk_config_sqs_queue.arn
 
  depends_on = [aws_sqs_queue.splunk_config_sqs_queue, aws_sns_topic.splunk_updates_config]
}

//Enable AWS Config Service Recorder
resource "aws_config_configuration_recorder_status" "main" {
  name       = var.config-name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.aws_config_s3_sns]
}
//Configure AWS Config Service Delivery Channel to store the data in the creted S3 bucket and push all changes to SNS
resource "aws_config_delivery_channel" "aws_config_s3_sns" {
  name           = var.config-name
  s3_bucket_name = local.s3-bucket-name-for-config
  sns_topic_arn = aws_sns_topic.splunk_updates_config.arn

  snapshot_delivery_properties {
    delivery_frequency = var.config-snapshot-freq
  }

  depends_on = [aws_config_configuration_recorder.main, aws_s3_bucket.aws_s3_bucket_for_config]
}
//Record all AWS resources in All regions + Include Global resources like IAM or S3
resource "aws_config_configuration_recorder" "main" {
  name     = var.config-name
  role_arn = aws_iam_role.aws-config-terraform.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

// --- IAM for AWS Config ------
# Allow the AWS Config role to deliver logs to configured S3 Bucket.
# Derived from IAM Policy document found at https://docs.aws.amazon.com/config/latest/developerguide/s3-bucket-policy.html
data "template_file" "aws_config_policy" {
  template = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "AWSConfigBucketPermissionsCheck",
        "Effect": "Allow",
        "Action": "s3:GetBucketAcl",
        "Resource": "${aws_s3_bucket.aws_s3_bucket_for_config.arn}"
    },
    {
        "Sid": "AWSConfigBucketExistenceCheck",
        "Effect": "Allow",
        "Action": "s3:ListBucket",
        "Resource": "${aws_s3_bucket.aws_s3_bucket_for_config.arn}"
    },
    {
        "Sid": "AWSConfigBucketDelivery",
        "Effect": "Allow",
        "Action": "s3:PutObject",
        "Resource": "$${resource}",
        "Condition": {
          "StringLike": {
            "s3:x-amz-acl": "bucket-owner-full-control"
          }
        }
    }

  ]
}
JSON

  vars = {
    //if you skip creating a new S3 bucket and would like to use existing one 
    //bucket_arn = format("arn:%s:s3:::%s", data.aws_partition.current.partition, var.config_logs_bucket)
    resource = format(
      "arn:%s:s3:::%s/AWSLogs/%s/Config/*",
      data.aws_partition.current.partition,
      local.s3-bucket-name-for-config,
      data.aws_caller_identity.current.account_id,
    )
  }
}

// Allow IAM policy to assume the role for AWS Config service only (not any other policy)
data "aws_iam_policy_document" "aws-config-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "aws-config-terraform" {
  name               = "${var.config-name}-role"
  assume_role_policy = data.aws_iam_policy_document.aws-config-role-policy.json
}

// Attach AWS pre-defined AWSConfigRole role to the policy // This grants AWS Config read access to all AWS Resources
resource "aws_iam_role_policy_attachment" "managed-policy" {
  role       = aws_iam_role.aws-config-terraform.name
  policy_arn = format("arn:%s:iam::aws:policy/service-role/AWSConfigRole", data.aws_partition.current.partition)
}

//  Establish S3 policy defined above
resource "aws_iam_policy" "aws-config-policy" {
  name   = "${var.config-name}-policy"
  policy = data.template_file.aws_config_policy.rendered
}
// Attach S3 generated policy to the created Main Role
resource "aws_iam_role_policy_attachment" "aws-config-policy" {
  role       = aws_iam_role.aws-config-terraform.name
  policy_arn = aws_iam_policy.aws-config-policy.arn
}
