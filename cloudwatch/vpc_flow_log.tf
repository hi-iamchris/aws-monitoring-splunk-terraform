####################################################################
#####-------------   VPC Flow Log monitoring --------###############
####################################################################


resource "aws_flow_log" "account_vpc_logs" {
  iam_role_arn    = aws_iam_role.vpc_flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = var.vpc-id
}
//---- Create a new CloudWatch Log group
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name = var.vpcflowlog-name
}

//---- CloudWatch VPC Flow Log privileges
resource "aws_iam_role" "vpc_flow_log" {
  name = "vpc_flow_log_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

//---- IAM Roles to able to publish logs to CloudWatch 
resource "aws_iam_role_policy" "vpc_flow_log" {
  name = "vpc_flow_log_policy"
  role = aws_iam_role.vpc_flow_log.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
######### ------ End of VPC Flow log monitoring ------###########