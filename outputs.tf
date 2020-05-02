output "this_iam_access_key_id" {
  description = "The access key ID"
  value       = module.splunk-iam.splunk_iam_access_key_id
}

output "this_iam_access_key_secret" {
  description = "The access key secret"
  value       = module.splunk-iam.splunk_iam_access_key_secret
}