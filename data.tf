locals {
  core_network_baseline_workspace_name = "res-core_network-baseline"
}

###################
# Transit Gateway #
###################

data "terraform_remote_state" "core_network" {
  backend = "remote"

  config {
    organization = "${var.tfe_org_name}"
    hostname     = "${var.tfe_host_name}"

    workspaces {
      name = "${local.core_network_baseline_workspace_name}"
    }
  }
}

data "aws_subnet_ids" "shared_svcs" {
  vpc_id = "${var.vpc_id}"

  filter {
    name   = "tag:Network"
    values = ["Private"]
  }
}

data "aws_ec2_transit_gateway" "core_network"{
  provider = "aws.core_network"
  id       = "${data.terraform_remote_state.core_network.transitgw}"
}

data "aws_ec2_transit_gateway_route_table" "global_reach" {
  provider = "aws.core_network"
  id       = "${data.aws_ec2_transit_gateway.core_network.propagation_default_route_table_id}"
}

data "aws_route_tables" "shared_svcs" {
  vpc_id = "${var.vpc_id}"
}
