#####################################################################################################################################
##			                                          Local Variable Definitions                                                       
#####################################################################################################################################
locals {
   REGION         = data.aws_region.current.name == "us-east-1" ? "awsdns.internal.das" : "us-east-2.awsdns.internal.das"
   region         = data.aws_region.current.name == "us-east-1" ? "primary-us-east-1-plat" : "secondary-us-east-2-plat"
   endpoint       = data.aws_region.current.name == "us-east-1" ? "https://bucket.vpce-0c65760352332dd5a-qahda5nv.s3.us-east-1.vpce.amazonaws.com" : "https://bucket.vpce-0157fc5f0d4d2b003-zy0yy31z.s3.us-east-2.vpce.amazonaws.com"
   aws_region     = data.aws_region.current.name
   tfe_read_token = data.vault_generic_secret.tfe_creds.data.token
 }
 locals {
   postscripts = templatefile("apsql_postscripts.tpl", {
      region             = local.region
      tfe_read_token     = local.tfe_read_token
      aws_region         = local.aws_region
      TFC_WORKSPACE_NAME = var.TFC_WORKSPACE_NAME
      business-division  = var.business-division
      environment        = var.environment
      Hostname           = module.aurora-pgsql.cluster_endpoint
      identifier         = module.aurora-pgsql.identifier
      arn                = module.aurora-pgsql.arn
      cluster_endpoint   = module.aurora-pgsql.cluster_endpoint
      result             = module.aurora-pgsql.result
      instance_arn       = module.aurora-pgsql.instance_arn
      account_id         = data.aws_caller_identity.current.account_id
  })
 }
 locals {
  vault_cleanup_script = templatefile("apsql_vault_cleanup_script.tpl", {
    dbinstance         = module.aurora-pgsql.cluster_endpoint
    environment        = var.environment
    region             = local.region
    aws_region         = local.aws_region
  })
}

#####################################################################################################################################
##			                                          Variable Definitions                                                       
#####################################################################################################################################
variable "TFC_WORKSPACE_NAME" {
  type = string
}
variable "vpc_id" {
  type        = string
  default     = null
}
variable "create_s3_bucket" {
  default = true
}

#####################################################################################################################################
##			                                          Data Sources                                                                     
#####################################################################################################################################
data "aws_region" "current" {}
data "aws_ami" "antm-golden-dbclients" {
  most_recent = true
  owners      = ["300499308742"]
  filter {
    name      = "name"
    values    = ["antm-golden-dbclients-*"]
  }
}
data "aws_security_group" "db_security_group" {
  name = "default"
}
data "aws_vpc" "vpc" {
  id       = var.vpc_id
  filter {
    name   = "tag:Name"
    values = ["aws-landing-zone-VPC", "lz-additional-vpc-VPC"]
  }
}
data "aws_subnets" "private" {
  filter {
    name    = "vpc-id"
    values  = [var.vpc_id == null ? "${data.aws_vpc.vpc.id}" : var.vpc_id]
  }
  tags      = {
    Network = "Private"
  }
}
data "aws_route53_zone" "selected" {
  name         = "${data.aws_caller_identity.current.account_id}.${local.REGION}"
  private_zone = true
}
data "aws_caller_identity" "current" {}
data "vault_generic_secret" "tfe_creds" {
  path = "corp-dlvrsermgt/secret/tfe/prod/${lower(var.business-division)}"
}

#####################################################################################################################################
##			                                          Aurora PGSQL Cluster Provisioner                                                         
#####################################################################################################################################
module "aurora-pgsql" {
  /******** Local source location of the module **************/
 source  = "cps-terraform.anthem.com/<ORGANIZATION-NAME>/terraform-aws-aurora-postgresql/aws"
 version = "0.1.6"
  /* Data Platform Technical Tags */
  application-name     = var.application-name
  bcp-tier             = "Tier-84"
  database-platform    = "A-PgSql"
  database-state       = "Active"
  db-patch-schedule    = "M09W4"
  db-patch-time-window = "Sunday 0100"
  environment          = var.environment
  prepatch-snapshot-flag = "N"
  /* Application Specific Tags */ 
  application_tag1 = "NULL"
  application_tag2 = "NULL" 
  application_tag3 = "NULL" 
  application_tag4 = "NULL"
  application_tag5 = "NULL"
  /***** Parameters Required for Aurora PgSql Resource Creation *****/
  apply_immediately                   = false
  aurorapostgresql_parameters         = "./AuroraPostgreSQL_PARAMETERS.json"
  aws_rds_cluster_role_association    = true
  ca_cert_identifier                  = "rds-ca-rsa2048-g1"
  enabled_cloudwatch_logs_exports     = ["postgresql"]
  engine                              = "aurora-postgresql"
  engine_version                      = "14.5"
  final_snapshot_identifier           = null
  family                              = "aurora-postgresql14"
  feature_name                        = "s3Import"
  iam_database_authentication_enabled = false
  identifier                          = "00"
  ingress_rules = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["30.0.0.0/8"]
      description = "ElevanceHealth OnPrem"
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["33.0.0.0/8"]
      description = "Carelon OnPrem"
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["10.152.0.0/15"]
      description = "ElevanceHealth Governance Team Application Servers in IBM Private Hosting Ashburn"
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["10.45.0.0/16"]
      description = "ElevanceHealth vDaaS"
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["10.112.248.0/22"]
      description = "ElevanceHealth Hashi Vault Infrastructure"
    },
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = "${data.aws_security_group.db_security_group.id}"
      description              = "ElevanceHealth PostScripts Automation"
    },
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = "<SECURITY GROUP ID>"
      description              = "Application Tier Security Group ID"
    }
  ]
  instance_provisioner = [
  {
  type = "writer"
  instance_class = "db.r6g.large"
  parameter_group = "./AuroraPostgreSQL_Writer_Instance_Parameter_Group.json"
  }#,
  # {
  # type = "reader"
  # instance_class = "db.r6g.large"
  # parameter_group = "./AuroraPostgreSQL_Reader01_Instance_Parameter_Group.json"
  # }
  ]
  kms_key_id                                    = lookup(module.kms_service_aurora.kms_arn, "aurora")
  kms_key_id_log_group                          = lookup(module.kms_service_aurora.kms_arn, "logs")
  monitoring_interval                           = "5"
  monitoring_role_arn                           = module.iam-enhanced-monitoring-role.iamrole_arn
  performance_insights_enabled                  = true 
  performance_insights_kms_key_id               = lookup(module.kms_service_aurora.kms_arn, "aurora")
  performance_insights_retention_period         = "7"
  preferred_backup_window_cluster               = "22:00-00:00"
  preferred_maintenance_window_cluster          = "Mon:00:00-Mon:03:00"
  preferred_maintenance_window_cluster_instance = "sun:22:10-sun:22:40"
  port                                          = "5432"
  retention_in_days_aurora_postgresql           = 7
  # restore_to_point_in_time = [{
  #   use_latest_restorable_time                = true  
  #   restore_to_time                           = ""
  #   source_cluster_identifier                 = ""
  #   restore_type                              = "copy-on-write"
  # }]
  role_arn                                      = module.iam-enhanced-monitoring-role.iamrole_arn
  serial_number                                 = "01"
 # snapshot_identifier                           = ""
  tags                                          = module.mandatory_tags.tags
  vpc_id                                        = data.aws_vpc.vpc.id
}

#####################################################################################################################################
##			                                          S3 Bucket Provisioner                                                               
#####################################################################################################################################
module "s3-bucket-aurora" {
  source     = "cps-terraform.anthem.com/<ORGANIZATION-NAME>/terraform-aws-s3/aws"
  version    = "<Provide The Latest Version>"
  depends_on = [
    module.aurora-pgsql
  ]
  /***** Parameters Required for S3 Creation *****/
  aws_kms_key_arn                       = var.create_s3_bucket == false ? "" : module.kms_service_aurora.kms_arn["s3"]
  bucket                                = lower("${module.aurora-pgsql.id}-s3")
  create_aws_s3_lifecycle_configuration = true
  create_s3_bucket                      = var.create_s3_bucket
  force_destroy                         = false
  role                                  = module.iam-enhanced-monitoring-role.iamrole_arn
  tags                                  = merge(module.mandatory_tags.tags, module.mandatory_data_tags.tags)
}

#####################################################################################################################################
##			                                          Event Subscription Provisioner                                                               
#####################################################################################################################################
module "dataplatform_event_subscription_cluster" {
  /******** Local source location of the module **************/
  source  = "cps-terraform.anthem.com/<ORGANIZATION-NAME>/terraform-aws-db-event-subscription/aws"
  version = "<Provide The Latest Version>"
  /******** Parameter required for resource creation ****/
  enabled          = true
  event_categories = ["deletion", "failure", "failover", "notification", "low storage"]
  name             = "antmdbes-dataplatform-cluster-${var.ATLAS_WORKSPACE_NAME}-${module.aurora-pgsql.identifier}"
  source_ids       = ["${module.aurora-pgsql.id}"]
  source_type      = "db-cluster"
  tags             = module.mandatory_tags.tags
/******** Parameter required for SNS resource creation ****/
  delivery_policy            = "./delivery_policy.json"
  sns_name                   = "antmdbes-dataplatform-topic-${var.ATLAS_WORKSPACE_NAME}-${module.aurora-pgsql.identifier}"
  sns_topic_policy_json      = file("sns_rds_topic_policy.json")
  subscribers                = {
    DD-DL-1                  = {
      protocol               = "email"
      endpoint               = "event-juhmlmkj@dtdg.co"
      endpoint_auto_confirms = true
    },
    DD-DL-2                  = {
      protocol               = "email"
      endpoint               = "event-zbtwuuzw@dtdg.co"
      endpoint_auto_confirms = true
    },
 }
}

#####################################################################################################################################
##			                                          KMS Provisioner                                                               
#####################################################################################################################################
module "kms_service_aurora" {
  source         = "cps-terraform.anthem.com/<ORGANIZATION-NAME>/terraform-aws-kms-service/aws"
 version         = "<Provide The Latest Version>"
  description    = "KMS for Aurora PgSQL"
  kms_alias_name = "${var.application-name}-${var.environment}"
  service_name   = ["aurora", "logs", "s3"]
  tags           = module.mandatory_tags.tags
}

#####################################################################################################################################
##			                                          IAM Role Provisioner                                                               
#####################################################################################################################################
module "iam-enhanced-monitoring-role" {
  /***** Source location of the module *****/
  source  = "cps-terraform.anthem.com/<ORGANIZATION-NAME>/terraform-aws-iam-role/aws"
  version = "<Provide The Latest Version>"
  /***** Parameters Required for aurora-pgsql Enhanced monitoring IAM role *****/
  assume_role_service_names = ["monitoring.rds.amazonaws.com", "s3.amazonaws.com", "rds.amazonaws.com"]
  force_detach_policies     = true
  iam_role_name             = module.aurora-pgsql.iam_role_name
  managed_policy_arns       = ["arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"]
  inline_policy             = [{
     name                   = "policy-s3-replication"
     policy                 = file("./aurora-s3-integration-policy.json")
  }]
  role_description          = "Allow aurora_pgsql to send enhanced monitoring metrics to CloudWatch Logs"
  tags                      = module.mandatory_tags.tags
}

#####################################################################################################################################
##			                                          CNAME Record Provisioner                                                               
#####################################################################################################################################
module "cname-record-aurora" {
   source  = "cps-terraform.anthem.com/<ORGANIZATION-NAME>/terraform-aws-route53-routing-record/aws"
   version = "<Provide The Latest Version>"
   hosted_zone_id                    = "${data.aws_route53_zone.selected.zone_id}"
   record_name                       = "${module.aurora-pgsql.id}"
   set_identifier                    = "CNAME Record FOR ${module.aurora-pgsql.id} Cluster"
   records                           = ["${module.aurora-pgsql.cluster_endpoint}"]
   record_type                       = "CNAME"
}

#####################################################################################################################################
##			                                          AutoScaler Provisioner                                                               
#####################################################################################################################################
# module "iam-appautoscaling-role" {
#   /***** Source location of the module *****/
#   source  = "cps-terraform.anthem.com/<ORGANIZATION-NAME>/terraform-aws-iam-role/aws"
#   version = "<Provide The Latest Version>"
#   /***** Parameters Required for APP autoscaling Enhanced monitoring IAM role *****/
#   assume_role_service_names = ["ec2.application-autoscaling.amazonaws.com"]
#   force_detach_policies     = true
#   iam_role_name             = "iam-appautoscaling-aurora-test"
#    inline_policy            = [{
#      name                   = "policy-appautoscaling"
#      policy                 = file("./iam-policy.json")
#    }]
#   role_description          = "Allow APPautoscaling policy for aurora pgsql"
#   tags                      = module.mandatory_tags.tags
# }
# module "auto_scaling_aurora_pgsql_target_primary_cpu" {
#   source  = "cps-terraform.anthem.com/<ORGANIZATION-NAME>/terraform-aws-appautoscaling-target/aws"
#   version = "<Provide The Latest Version>"
#   /***** Parameters Required for App Autoscaling Target Creation *****/
#   max_capacity       = 10
#   min_capacity       = 1
#   resource_id        = "cluster:${module.aurora-pgsql.id}"
#   role_arn           = module.iam-appautoscaling-role.iamrole_arn
#   scalable_dimension = "rds:cluster:ReadReplicaCount"
#   service_namespace  = "rds"
# }
# module "auto_scaling_aurora_pgsql_policy_primary_cpu" {
#   source  = "cps-terraform.anthem.com/<ORGANIZATION-NAME>/terraform-aws-appautoscaling-policy/aws"
#   version = "<Provide The Latest Version>"
#   /***** Parameters Required for App Autoscaling Polcy Creation *****/
#   name                   = "cpu-auto-scaling:${module.auto_scaling_aurora_pgsql_target_primary_cpu.resource_id}"
#   policy_type            = "TargetTrackingScaling"
#   predefined_metric_type = "RDSReaderAverageCPUUtilization"
#   resource_id            = "${module.auto_scaling_aurora_pgsql_target_primary_cpu.resource_id}"
#   scalable_dimension     = "${module.auto_scaling_aurora_pgsql_target_primary_cpu.scalable_dimension}"
#   service_namespace      = "${module.auto_scaling_aurora_pgsql_target_primary_cpu.service_namespace}"
#   scale_in_cooldown      = 300
#   scale_out_cooldown     = 300
#   target_value           = 75
# }
#module "auto_scaling_aurora_pgsql_target_primary_connections" {
#
#  source = "cps-terraform.anthem.com/<ORGANIZATION-NAME>/terraform-aws-appautoscaling-target/aws"
#  version = "<Provide The Latest Version>"
#
#  /***** Parameters Required for App Autoscaling Target Creation *****/
#
#  max_capacity = 10
#  min_capacity = 1
#  resource_id  = "cluster:${module.aurora-pgsql.id}"
#  role_arn     = module.iam-appautoscaling-role.iamrole_arn
#  scalable_dimension = "rds:cluster:ReadReplicaCount"
#  service_namespace  = "rds"
#}
#
#module "auto_scaling_aurora_pgsql_policy_primary_connections" {
#
# source = "cps-terraform.anthem.com/<ORGANIZATION-NAME>/terraform-aws-appautoscaling-policy/aws"
# version = "<Provide The Latest Version>"
#
#  /***** Parameters Required for App Autoscaling Polcy Creation *****/
#
#  name               = "cpu-auto-scaling:${module.auto_scaling_aurora_pgsql_target_primary_connections.resource_id}"
#  policy_type        = "TargetTrackingScaling"
#  predefined_metric_type = "RDSReaderAverageDatabaseConnections"
#  resource_id        = "${module.auto_scaling_aurora_pgsql_target_primary_connections.resource_id}"
#  scalable_dimension = "${module.auto_scaling_aurora_pgsql_target_primary_connections.scalable_dimension}"
#  service_namespace  = "${module.auto_scaling_aurora_pgsql_target_primary_connections.service_namespace}"
#  scale_in_cooldown  = 300
#  scale_out_cooldown = 300
#  target_value       = 75
#}

#####################################################################################################################################
##			                                          Post Scripts Provisioner                                                               
#####################################################################################################################################
module "terraform-aws-ec2" {
  depends_on = [ module.aurora-pgsql]
  source     = "cps-terraform.anthem.com/<ORGANIZATION-NAME>/terraform-aws-ec2/aws"
  version    = "<Provide The Latest Version>"
/******** Parameter required for EC2 resource creation ****/
  vpc_security_group_ids               = [data.aws_security_group.db_security_group.id]
  kms_key_id                           = module.kms_service_ec2.kms_arn["ec2"]
  instance_ami                         = data.aws_ami.antm-golden-dbclients.id
  instance_name                        = "${module.mandatory_tags.tags["application-name"]}-${module.mandatory_tags.tags["environment"]}-${module.mandatory_tags.tags["business-division"]}"
  delete_on_termination                = true
  disable_api_termination              = false
  number_of_instances                  = 1
  subnet_ids                           = data.aws_subnets.private.ids
  instance_initiated_shutdown_behavior = "terminate"
  iam_instance_profile                 = "CMDBLambdaRole"
  root_volume_size                     = "120"
  tags                                 = module.mandatory_tags.tags
  user_data                            = local.postscripts
}
module "kms_service_ec2" {
  source           = "cps-terraform.anthem.com/<ORGANIZATION-NAME>/terraform-aws-kms-service/aws"
  version          = "<Provide The Latest Version>" 
  description      = "KMS for EC2"
  kms_alias_name   = "${var.application-name}-${var.environment}"
  service_name     = ["ec2"]
  tags             = module.mandatory_tags.tags
}

#####################################################################################################################################
##			                                          Vault Cleanup Provisioner                                                               
#####################################################################################################################################
#module "terraform-aws-ec2-vault-cleaner" {
#  source = "cps-terraform.anthem.com/CORP/terraform-aws-ec2/aws"
#  tags = module.mandatory_tags.tags
#  /***** Parameters Required for EC2 *****/
#  delete_on_termination                = true
#  disable_api_termination              = false
#  iam_instance_profile                 = "CMDBLambdaRole"
#  instance_ami                         = data.aws_ami.antm-golden-dbclients.id
#  instance_name                        = "${module.mandatory_tags.tags["application-name"]}-${module.mandatory_tags.tags["environment"]}-${module.mandatory_tags.tags["business-division"]}-cleaner"
#  instance_initiated_shutdown_behavior = "terminate"
#  kms_key_id                           = module.kms_service_ec2.kms_arn["ec2"]
#  number_of_instances                  = 1
#  root_volume_size                     = "120"
#  subnet_ids                           = data.aws_subnets.private.ids
#  vpc_security_group_ids               = [data.aws_security_group.db_security_group.id]
#  user_data                            = local.vault_cleanup_script
#}
