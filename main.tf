########################
# Logging Remote State #
########################

# Connect to the core-logging account to get S3 buckets
data "terraform_remote_state" "logging" {
  backend = "remote"

  config {
    organization = "${var.tfe_org_name}"
    hostname     = "${var.tfe_host_name}"

    workspaces {
      name = "${var.tfe_core_logging_workspace_name}"
    }
  }
}

####################
# Account Baseline #
####################

# Connect to the core-logging account to get VPC FlowLog destinations
# Account baseline
module "account-baseline" {
  source                 = "tfe.tlzdemo.net/TLZ-Demo/baseline-common/aws"
  version                = "~> 0.1.0"
  account_name           = "${var.name}"
  account_type           = "${var.account_type}"
  account_id             = "${var.account_id}"
  okta_provider_domain   = "${var.okta_provider_domain}"
  okta_app_id            = "${var.okta_app_id}"
  region                 = "${var.region_primary}"
  region_secondary       = "${var.region_secondary}"
  role_name              = "${var.role_name}"
  config_logs_bucket     = "${data.terraform_remote_state.logging.s3_config_logs_bucket_name}"
  tfe_host_name          = "${var.tfe_host_name}"
  tfe_org_name           = "${var.tfe_org_name}"
  tfe_avm_workspace_name = "${var.tfe_avm_workspace_name}"
  okta_environment       = "${substr(var.account_type, 0, 3)}"
}

########################
# Simple Email Service #
########################

module "ses-smtp-relay" {
  source                      = "app.terraform.io/blizzard-cloud/ses-smtp-relay/aws"
  version                     = "~> 0.0.1"
  sender_domain               = "${var.primary_zone_name}"
  region                      = "${var.region_primary}"
  tlz_org_account_access_role = "${var.role_name}"
  terraform_svc_user          = "${var.terraform_svc_user}"
}

#######
# IAM #
#######

module "tlz_it_operations" {
  source            = "tfe.tlzdemo.net/TLZ-Demo/baseline-common/aws//modules/iam-tlz_it_operations"
  version           = "~> 0.1.0"
  okta_provider_arn = "${module.account-baseline.okta_provider_arn}"
  deny_policy_arns  = "${module.account-baseline.deny_policy_arns}"
}

module "tlz_it_operations_okta" {
  source           = "app.terraform.io/blizzard-cloud/tlz_group_membership_manager/okta"
  aws_account_id   = "${var.account_id}"
  okta_hostname    = "${var.okta_provider_domain}"
  tlz_account_type = "${var.account_type}"
  user_emails      = ["${var.users_tlz_it_operations}"]
  api_token        = "${var.okta_token}"
  role_name        = "tlz_it_operations"
}

module "tlz_admin" {
  source            = "tfe.tlzdemo.net/TLZ-Demo/baseline-common/aws//modules/iam-tlz_admin"
  version           = "~> 0.1.0"
  okta_provider_arn = "${module.account-baseline.okta_provider_arn}"
  deny_policy_arns  = "${module.account-baseline.deny_policy_arns}"
}

module "tlz_admin_okta" {
  source           = "app.terraform.io/blizzard-cloud/tlz_group_membership_manager/okta"
  aws_account_id   = "${var.account_id}"
  okta_hostname    = "${var.okta_provider_domain}"
  tlz_account_type = "${var.account_type}"
  user_emails      = ["${var.users_tlz_admin}"]
  api_token        = "${var.okta_token}"
  role_name        = "tlz_admin"
}

#TODO: Cirrus-630 needs to hook in with okta to provide actual access. Both SecOps and IR roles
module "tlz_security_ir" {
  source                  = "tfe.tlzdemo.net/TLZ-Demo/baseline-common/aws//modules/iam-policy-securityir"
  version                 = "~> 0.1.0"
  okta_provider_arn       = "${module.account-baseline.okta_provider_arn}"
}

###################
# Transit Gateway #
###################

#TGW Attachment

resource "aws_ec2_transit_gateway_vpc_attachment" "shared_svcs" {
  subnet_ids         = ["${element(data.aws_subnet_ids.shared_svcs.ids, count.index)}"]
  transit_gateway_id = "${data.terraform_remote_state.core_network.transitgw}"
  vpc_id             = "${var.vpc_id}"
}

# Route Tables

resource "aws_ec2_transit_gateway_route_table_association" "global_reach" {
  provider                       = "aws.core_network"
  transit_gateway_attachment_id  = "${aws_ec2_transit_gateway_vpc_attachment.shared_svcs.id}"
  transit_gateway_route_table_id = "${data.aws_ec2_transit_gateway_route_table.global_reach.id}"
}

# Routes

resource "aws_route" "to_tgw_10" {
  count                  = "${length(data.aws_route_tables.shared_svcs.ids)}"
  route_table_id         = "${data.aws_route_tables.shared_svcs.ids[count.index]}"
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = "${data.terraform_remote_state.core_network.transitgw}"
}

resource "aws_route" "to_tgw_172" {
  count                  = "${length(data.aws_route_tables.shared_svcs.ids)}"
  route_table_id         = "${data.aws_route_tables.shared_svcs.ids[count.index]}"
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = "${data.terraform_remote_state.core_network.transitgw}"
}

resource "aws_route" "to_tgw_192" {
  count                  = "${length(data.aws_route_tables.shared_svcs.ids)}"
  route_table_id         = "${data.aws_route_tables.shared_svcs.ids[count.index]}"
  destination_cidr_block = "192.168.0.0/16"
  transit_gateway_id     = "${data.terraform_remote_state.core_network.transitgw}"
}

###################
# Egress Proxying #
###################

module "squid" {
  source           = "app.terraform.io/blizzard-cloud/squid-proxy/aws"
  version          = "~> 0.1.0"
  whitelisted_urls = "${var.whitelisted_urls}"
}
