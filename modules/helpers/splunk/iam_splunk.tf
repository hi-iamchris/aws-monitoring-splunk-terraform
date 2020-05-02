resource "aws_iam_user" "splunk" {
  name = var.iam_user_name
  force_destroy = true
}

resource "aws_iam_access_key" "splunk" {
  user    = aws_iam_user.splunk.name
}

resource "aws_iam_user_policy" "splunk_add_on_for_aws" {
  name = var.iam_policy_name
  user = aws_iam_user.splunk.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Action": [
            "sqs:GetQueueAttributes",
            "sqs:ListQueues",
            "sqs:ReceiveMessage",
            "sqs:GetQueueUrl",
            "sqs:SendMessage",
            "sqs:DeleteMessage",
            "s3:ListBucket",
            "s3:GetObject",
            "s3:GetBucketLocation",
            "s3:ListAllMyBuckets",
            "s3:GetBucketTagging", 
            "s3:GetAccelerateConfiguration", 
            "s3:GetBucketLogging", 
            "s3:GetLifecycleConfiguration", 
            "s3:GetBucketCORS",
            "config:DeliverConfigSnapshot",
            "config:DescribeConfigRules",
            "config:DescribeConfigRuleEvaluationStatus",
            "config:GetComplianceDetailsByConfigRule",
            "config:GetComplianceSummaryByConfigRule",
            "iam:GetUser",
            "iam:ListUsers",
            "iam:GetAccountPasswordPolicy",
            "iam:ListAccessKeys",
            "iam:GetAccessKeyLastUsed", 
            "autoscaling:Describe*",
            "cloudwatch:Describe*",
            "cloudwatch:Get*",
            "cloudwatch:List*",
            "sns:Get*",
            "sns:List*",
            "sns:Publish",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:GetLogEvents",
            "ec2:DescribeInstances",
            "ec2:DescribeReservedInstances",
            "ec2:DescribeSnapshots",
            "ec2:DescribeRegions",
            "ec2:DescribeKeyPairs",
            "ec2:DescribeNetworkAcls",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeVolumes",
            "ec2:DescribeVpcs",
            "ec2:DescribeImages",
            "ec2:DescribeAddresses",
            "lambda:ListFunctions",
            "rds:DescribeDBInstances",
            "cloudfront:ListDistributions",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeInstanceHealth",
            "elasticloadbalancing:DescribeTags",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:DescribeListeners",
            "inspector:Describe*",
            "inspector:List*",
            "kinesis:Get*",
            "kinesis:DescribeStream",
            "kinesis:ListStreams",
            "kms:Decrypt",
            "sts:AssumeRole"
        ],
        "Resource": [
            "*"
        ]
        }
    ]
}
    EOF
}