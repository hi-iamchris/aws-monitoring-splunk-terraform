
output "splunk_iam_access_key_id" {
  description = "The access key ID"
  value = element(concat(aws_iam_access_key.splunk.*.id,[""],),0,)
}

output "splunk_iam_access_key_secret" {
  description = "The access key secret"
  value       = element(concat(aws_iam_access_key.splunk.*.secret, [""]), 0)
}