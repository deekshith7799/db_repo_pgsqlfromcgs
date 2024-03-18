# Aurora PgSQL Single-AZ/Multi-AZ

    This template provisions Aurora PgSQL with Enhanced Monitoring, Performance Insights enabled and KMS for database encryption. The aurora-pgsql module handles the provisioning of security group, cluster parameter group and subnet group.

# Release Notes: #
### New Version - 0.1.6 ###
    1. Replaced instance_class and instance_count with instance_provisioner parameter.
    2. Added a parameter use latest restore time to the restore point in time block to facilitate cloning of a exsiting db. 
### Adoption of the New Version - 0.1.6 ###
    1. The instance_class and instance_count parameters have been replaced with the instance_provisioner parameter. This change allows for a more flexible and detailed configuration of instances.


    In the provided code snippet, the instance_provisioner parameter is an array of objects, where each object represents an instance to be provisioned. Each object includes the following properties:

    type: Specifies the role of the instance. It can be either “writer” or “reader”.
    instance_class: Specifies the class of the instance, which determines its computational and memory capacity.
    parameter_group: Specifies the path to the JSON file that contains the configuration parameters for the instance.

      instance_provisioner = [
      {
      type = "writer"
      instance_class = "db.r6g.large"
      parameter_group = "./AuroraPostgreSQL_Writer01_Instance_Parameter_Group.json"
      },
      # {
      # type = "reader"
      # instance_class = "db.r6g.large"
      # parameter_group = "./AuroraPostgreSQL_Reader01_Instance_Parameter_Group.json"
      # }
      ]

    2. To clone the exsiting database uncomment the restore_point_in_time block and use "copy-on-write" as restore-type and pass the Databses Cluster Id for source identifier.
### Old Version - 0.1.5 ###
    1. The postscripts module updated to pull the HA-ID for created-by tag
    2. The postscripts code block of the EC2 instance has been modularized into a separate template file
    3. The postscripts location in the s3 folder changed to /scripts from /sql
    4. SNS module name and the sns_name paramter includes the identifier variable. Example - antmdbes-dataplatform-topic-${var.ATLAS_WORKSPACE_NAME}-${module.pgsql.identifier} 
### Adoption of the Old Version - 0.1.5 ###
    1. Copy the apsql_postscripts.tpl to the working directory which hosts the apsql.tf file
    2. Copy the local.tfe_read_token, local.postscripts, data.vault_generic_secret.tfe_creds and var.TFC_WORKSPACE_NAME to the apsql.tf
    3. Update the user_data argument in the terraform-aws-ec2 module to user_data = local.postscripts
    4. Copy the apsql_postscripts.tpl to the working directory which hosts the apsql.tf file
### Old Version - 0.0.9 ###
    1. Included multiple instance class types for the same cluster.
    2. The first instance class type will be associated to the **Writer instance**, rest will be associated with the **Reader Instance**.
    3. Renamed main.tf to apsql.tf, based on our naming standards **DB-ENGINE-SHORT-NAME**.
    4. Updated standard SNS Topic and Subscription Names to include Workspace variable like  "antmdbes-dataplatform-topic-${var.ATLAS_WORKSPACE_NAME}", "antmdbes-dataplatform-cluster-${var.ATLAS_WORKSPACE_NAME}".
    5. Added CNAME record creation module.
    6. Moved **Workspace-variables** from apsql.tf to tags.tf
### Adoption of the Old Version - 0.0.9 ###
    1. Number of Instance_count must be equal to the instance_class types as shown in the below example.
    Example : If Instance_count = 2, then we must have instance_class = ["db.r6g.2xlarge", "db.r6g.4xlarge"].

    2. Rename the main.tf to apsql.tf and move the **Workspace-variables** section to tags.tf.

    3. KMS service name updated to **var.application-name**-**var.environment** so if you are having multiple environments in single account declare the variable accordingly.

    4. application-name tag value must always be the apm id of the application since it is used in the naming standards.

    5. Update standard SNS Topic and Subscription Names to the format "antmdbes-dataplatform-topic-${var.ATLAS_WORKSPACE_NAME}", "antmdbes-dataplatform-cluster-${var.ATLAS_WORKSPACE_NAME}". 

    6. Add the **cname-record-aurora** module to your existing code and also add the respective data blocks and run terraform init, plan, apply. Naming standard for the records are **ClusterIdentifier.ACCOUNTNUMBER.awsdns.internal.das** for **US-EAST-1** and **ClusterIdentifier.ACCOUNTNUMBER.US-EAST-2.awsdns.internal.das** for **US-EAST-2**.

### Reference Videos
  [Provisioning aws-aurora-pgsql using Terraform - Part 1](https://collaborate.wellpoint.com/\:v\:/r/teams/ServiceCatalog/Shared%20Documents/AWS%20Cloud/Database/AWS-Aurora-Pgsql-DB-SingleAZ-Part-1.mp4?csf=1&web=1&e=q5S7xu)
  [Provisioning aws-aurora-pgsql using Terraform - Part 2](https://collaborate.wellpoint.com/\:v\:/r/teams/ServiceCatalog/Shared%20Documents/AWS%20Cloud/Database/AWS-Aurora-Pgsql-DB-SingleAZ-Part-2.mp4?csf=1&web=1&e=J00qiN)

### Prerequisite
    1. Configure provider.tf file with organization, hostname and workspace name.

      terraform {
        backend "remote" {
          hostname     = "<TFE-URL>"
          organization = "<ORGANIZATION-NAME>"
          workspaces {
            name = "<WORKSPACE-NAME>"
          }
        }
      }

    2. Set organization name in the source of the modules. **ORGANIZATION-NAME**

    source  = "cps-terraform.anthem.com/<ORGANIZATION-NAME>/terraform-aws-kms-service/aws"

    3. To hydrate an instance using existing snapshot, un-comment and update the template variable snapshot_identifier with the snapshot name before apply.

    4. To recover an instance using Point In Time Recovery (PITR), un-comment and update restore_to_point_in_time by passing existing DB Cluster Identifier in source_cluster_identifier and the time it should be recovered to in Restore_to_time. Restore_to_time has to be in UTC Timezone and in RFC3339 format. REF [https://medium.com/easyread/understanding-about-rfc-3339-for-datetime-formatting-in-software-engineering-940aa5d5f68a]
    For Example: If the Restore Time is April 28 2021, 12:55:45PM then restore_Time = "2021-04-28T12:55:45Z"

    5. To Restore_to_time, restore_type must be "full-copy"

    6. Update **Application_tags** as per Application teams requirements with no duplicate values.

    7. Performance Insights and Enhanced monitoring is enabled by default in this template.

  ### Notes
    1. Loading data into an Amazon Aurora PgSQL DB cluster from Amazon S3 bucket is enabled
