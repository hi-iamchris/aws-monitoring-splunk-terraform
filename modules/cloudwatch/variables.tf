########## AWS VPC Flow Log ########################

variable "vpc-id" {
  type = string
  description = "VPC for which VPC Flow log will be enabled"
}

variable "vpcflowlog-name" {
  type = string
  description = "Name for the VPC FlowLog"
  default = "VPCFlowLog"
}

