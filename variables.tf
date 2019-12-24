# AWS Provider Vaiables
variable "region_primary" {
  description = "AWS Region to deploy to"
}

variable "role_name" {
  description = "AWS role name to assume"
}

# Account Variables
variable "account_id" {
  description = "The ID of the working account"
}

variable "name" {
  description = "Name of the account"
}

variable "region_secondary" {
  description = "secondary region to to configure vpc-flowlog-buckets"
  default     = "us-east-1"
}

variable "okta_provider_domain" {
  description = "The domain name of the IDP.  This is concatenated with the app name and should be in the format 'site.domain.tld' (no protocol or trailing /)."
}

variable "okta_app_id" {
  description = "The Okta app ID for SSO configuration."
}

variable "account_type" {
  description = "Account template type"
}

variable "tfe_host_name" {
  description = "host_name for ptfe"
}

variable "tfe_org_name" {
  description = "ptfe organization name"
}

variable "tfe_avm_workspace_name" {
  description = "Name of avm workspace"
}

variable "tfe_core_logging_workspace_name" {
  description = "Name of logging workspace"
}

variable "primary_zone_name" {
  type        = "string"
  description = "DNS zone used by AVM resources. Should be just the raw host name, eg: 'example.com'"
}

variable "terraform_svc_user" {
  description = "Name of the user terraform uses to log into AWS"
  type        = "string"
  default     = "terraform_svc"
}

variable "okta_token" {
  type        = "string"
  description = "Okta API token (sensitive)"
}

variable "users_tlz_admin" {
  type        = "list"
  description = "list of user emails to provide access to this role (via okta)"
}

variable "users_tlz_it_operations" {
  type        = "list"
  description = "list of user emails to provide access to this role (via okta)"
}

variable "vpc_id" {
  description = "Name of the vpc to connect to transit gateway"
}

variable "core_network_account" {
  description = "Core Networking Account ID"
}

variable "whitelisted_urls" {
  description = "List of URLs to whitelist in the egress proxy"
  type        = "list"
}
