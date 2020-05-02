data "aws_caller_identity" "current" {}


resource "aws_sns_topic" "splunk_updates_cloudtrail" {
  name = "splunk-cloudtrail-updates"
}

# Local variables
locals {
  //Appends AWS instance ID to name of S3 buket
  s3-bucket-name-for-cloudtrail = format("%s-%s",var.s3-bucket-name-cloutrail,data.aws_caller_identity.current.account_id)
}

resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.splunk_updates_cloudtrail.arn
  //policy = data.aws_iam_policy_document.sns_topic_policy.json - When used with the JSON policy
  //AWSNSPolicy2020408 - default SNS topic policy
  //AWSCloudTrailSNSPolicy2020408 - allow CloudTrail to Publish to SNS
  
  policy = <<POLICY
    {
  "Version": "2008-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "AWSNSPolicy2020408",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "SNS:GetTopicAttributes",
        "SNS:SetTopicAttributes",
        "SNS:AddPermission",
        "SNS:RemovePermission",
        "SNS:DeleteTopic",
        "SNS:Subscribe",
        "SNS:ListSubscriptionsByTopic",
        "SNS:Publish",
        "SNS:Receive"
      ],
      "Resource": "${aws_sns_topic.splunk_updates_cloudtrail.arn}",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "${data.aws_caller_identity.current.account_id}"
        }
      }
    },
    {
      "Sid": "AWSCloudTrailSNSPolicy2020408",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "SNS:Publish",
      "Resource": "${aws_sns_topic.splunk_updates_cloudtrail.arn}"
    }
  ]
}
  POLICY
}
//JSON-based policy
/*data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"
  version = "2008-10-17"
  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
        // values = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        values = ["${data.aws_caller_identity.current.account_id}"]
    }
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      //"${aws_sns_topic.splunk_updates_cloudtrail.arn}",
      "${data.aws_caller_identity.current.account_id}:splunk-cloudtrail-updates"
    ]
    sid = "__default_statement_ID"
  }
}*/

/// Create an SQS queue for queueing notification from AWS config via SNS

resource "aws_sqs_queue" "splunk_cloudtrail_sqs_queue" {
  name                      = var.splunk-cloudtrail-sqs-queue
  message_retention_seconds = 345600 //4 days
  visibility_timeout_seconds = 360 // visibility timeout set to 6 minutes
  //Configure DeadQueue for undelivered messages in the queue
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.splunk_queue_deadletter.arn
    maxReceiveCount     = 4
  })

  tags = {
    Environment = "Test",
    System = "Splunk"
  }
  depends_on = [aws_sqs_queue.splunk_queue_deadletter]
}
// Allow SNS to push the notifications to SQS queue
resource "aws_sqs_queue_policy" "splunk_cloudtrail_sqs_queue_policy" {
  queue_url = aws_sqs_queue.splunk_cloudtrail_sqs_queue.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy20200422",
  "Statement": [
    {
      "Sid": "AWSCloudTrailSQSPolicyAllowSNS2020422",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.splunk_cloudtrail_sqs_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.splunk_updates_cloudtrail.arn}"
        }
      }
    }
  ]
}
POLICY
}

// SNS Dead Queue 
resource "aws_sqs_queue" "splunk_queue_deadletter" {
  name                      = "splunk-cloudtrail-sns-dead-queue"
}
// Create SNS subscription to push notification to SQS queue
resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.splunk_updates_cloudtrail.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.splunk_cloudtrail_sqs_queue.arn
 
  depends_on = [aws_sqs_queue.splunk_cloudtrail_sqs_queue, aws_sns_topic.splunk_updates_cloudtrail]
}

//Create CloudTrail Topic
resource "aws_cloudtrail" "cloudtrail_s3_sns" {
  name                          = var.trail-name
  s3_bucket_name                = aws_s3_bucket.bucket_ct.id
  s3_key_prefix                 = var.s3-bucket-prefix-cloutrail
  include_global_service_events = true     // do not long from global services like IAM or S3
  is_multi_region_trail = false             //only for local region
  sns_topic_name = aws_sns_topic.splunk_updates_cloudtrail.name

  depends_on = [aws_s3_bucket.bucket_ct]
}

resource "aws_s3_bucket" "bucket_ct" {
  bucket        = local.s3-bucket-name-for-cloudtrail
  acl="private"
  force_destroy = true

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${local.s3-bucket-name-for-cloudtrail}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${local.s3-bucket-name-for-cloudtrail}/${var.s3-bucket-prefix-cloutrail}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

//Block S3 public access
resource "aws_s3_bucket_public_access_block" "s3_public_restriction" {
  bucket = aws_s3_bucket.bucket_ct.id
  block_public_acls   = true
  block_public_policy = true
}