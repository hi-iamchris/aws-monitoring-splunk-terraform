####################################################################
#####-------  AWS Config Service Managed Rules  -----###############
####################################################################

######---  Root accounts MFA enabled rule
resource "aws_config_config_rule" "root-account-mfa-enabled" {
  //count       = var.check_root_account_mfa_enabled ? 1 : 0
  name        = "root-account-mfa-enabled"
  description = "Ensure root AWS account has MFA enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }
  //maximum_execution_frequency = var.config_max_execution_frequency
  //tags = var.tags
depends_on = [aws_config_configuration_recorder.main]
}

#### TBC ######
