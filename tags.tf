module "mandatory_tags" {
  source               = "cps-terraform.anthem.com/CORP/terraform-aws-mandatory-tags-v2/aws"
  tags                 = {}
  apm-id               = var.apm-id
  application-name     = var.application-name
  app-support-dl       = var.app-support-dl
  app-servicenow-group = var.app-servicenow-group
  business-division    = var.business-division
  compliance           = var.compliance
  company              = var.company
  costcenter           = var.costcenter
  environment          = var.environment
  PatchGroup           = var.PatchGroup
  PatchWindow          = var.PatchWindow
  workspace            = var.ATLAS_WORKSPACE_NAME
}

module "mandatory_data_tags" {
  source                    = "cps-terraform.anthem.com/CORP/terraform-aws-mandatory-data-tags-v2/aws"
  tags                      = {}
  financial-internal-data   = var.financial-internal-data
  financial-regulatory-data = var.financial-regulatory-data
  legal-data                = var.legal-data
  privacy-data              = var.privacy-data
}

/***** Workspace variables ****/
variable "app-servicenow-group" {}
variable "company" {}
variable "compliance" {}
variable "costcenter" {}
variable "environment" {}
variable "apm-id" {}
variable "application-name" {}
variable "app-support-dl" {}
variable "business-division" {}
variable "PatchGroup" {}
variable "PatchWindow" {}
variable "ATLAS_WORKSPACE_NAME" {}
variable "financial-internal-data" {
    default = "n"
}
variable "financial-regulatory-data" {
      default = "n"
}
variable "legal-data" {
      default = "n"
}
variable "privacy-data" {
      default = "n"
}