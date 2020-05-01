variable "iam_user_name" {
  type        = string
  default     = "splunk"
  description = "Name for the user that will get created. Needs to be configured in Splunk."
}

variable "iam_policy_name" {
  type        = string
  default     = "splunk_add_on_for_aws"
  description = "Name for the user policy that will get created"
}