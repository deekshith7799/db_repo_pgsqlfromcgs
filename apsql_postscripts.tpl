#!/bin/bash -xe
##################################################################################################################################################################
# Program       :  apsql_postscripts.tpl
# Programmer    :  Service Catalog DB Team
# Notes         :  As part of post script provisioning the script would
#                  1. Updates the credentials of infrastructure accounts by fetching the credentials from vault
#                  2. Updates the created-by tag in the provisioned database  
#                  3. Updates the antmsysdba master credentials to be managed by vault
# IMPORTANT     : Copyright  (c) 2023 by ElevanceHealth.
#                 All Rights Reserved.
##################################################################################################################################################################
sudo su
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
cd /home/ec2-user
error() {
  echo "Error on line $1: $2" > postscripts_error.log 2>&1
  aws sns publish --topic-arn arn:aws:sns:${aws_region}:${account_id}:antmdbes-database-status-topic --message "Error on line $1: $2" \
    --subject "EH Cloud Database Services Post Script ERROR for ${aws_region}:${account_id}:${identifier}"
  eval $(aws sts assume-role \
 --role-arn arn:aws:iam::868159525660:role/CROSS-ACCOUNT-ROLE-SECRETS-TO-LAMBDA-RDS \
 --role-session-name=test --duration-seconds 900 \
 --query 'join(``, [`export `, `AWS_ACCESS_KEY_ID=`, 
 Credentials.AccessKeyId, ` ; export `, `AWS_SECRET_ACCESS_KEY=`,
 Credentials.SecretAccessKey, `; export `, `AWS_SESSION_TOKEN=`,
 Credentials.SessionToken])' \
 --output text)
  aws s3 cp . s3://eh-dbaservices-log-${region}/apsql/postscript/logs/${cluster_endpoint}/ --exclude "*" --include "postscripts_error.log" --recursive  --region ${aws_region}
  aws s3 cp /home/ec2-user/apsql_scripts/ s3://eh-dbaservices-log-${region}/apsql/postscript/logs/${cluster_endpoint}/ --exclude "*" --include "*.log" --recursive  --region ${aws_region}
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
  exit 1
}
trap 'error $LINENO "$BASH_COMMAND"' ERR
eval $(aws sts assume-role \
 --role-arn arn:aws:iam::868159525660:role/CROSS-ACCOUNT-ROLE-SECRETS-TO-LAMBDA-RDS \
 --role-session-name=test --duration-seconds 900 \
 --query 'join(``, [`export `, `AWS_ACCESS_KEY_ID=`, 
 Credentials.AccessKeyId, ` ; export `, `AWS_SECRET_ACCESS_KEY=`,
 Credentials.SecretAccessKey, `; export `, `AWS_SESSION_TOKEN=`,
 Credentials.SessionToken])' \
 --output text)


aws s3 cp s3://antmdb-dbaservices-${region}/apsql/postscript/scripts apsql_scripts --recursive --region ${aws_region} || error $LINENO "Failed to connect to s3 for importing the postscripts"
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
export ws_name='${TFC_WORKSPACE_NAME}'
export organization='${business-division}'
export tfe_token='${tfe_read_token}'
export environment='${environment}'
export Hostname='${cluster_endpoint}'
export dbinstance='${cluster_endpoint}'
export PGPASSWORD='${result}'
cd apsql_scripts
pip install terrasnek
pip install response
pip install pyhcl
created_by_user=$(python3 get_created_by.py) || error $LINENO "Failed to retrieve Created By Value. TFE returned an Unsuccessful response. \
Did not get HTTP-200 for REST-API call. Refer get-created-by.log for more details"
if [ $? -eq 0 ]; then
  CURRENT_TAG=$(aws rds describe-db-clusters \
  --db-cluster-identifier ${identifier} \
  --query 'DBClusters[].TagList[] | [?Key==`created-by`].Value' --output text)
  if [[ "$CURRENT_TAG" == *"AUTOMATION"* ]]; then
    aws rds add-tags-to-resource --resource-name ${arn} --tags "[{\"Key\": \"created-by\",\"Value\": \"$created_by_user\"}]" &>> get_created_by.log
    %{ for instance in instance_arn }
    aws rds add-tags-to-resource --resource-name ${instance} --tags "[{\"Key\": \"created-by\",\"Value\": \"$created_by_user\"}]" &>> get_created_by.log
    %{ endfor ~} 
  else
    echo "Skipping tag updation - The value of the created-by tag:$CURRENT_TAG" >> get_created_by.log
  fi       
fi

psql --host=${cluster_endpoint} --port=5432 --username=antmsysdba --dbname=postgres < apsql_main.sql > apsql_main.log 2>&1 || error $LINENO "Failed to connect to PgSQL Aurora Cluster for running the postscripts"
chmod 777 apsql-manage-credentials.sh
source apsql-manage-credentials.sh
eval $(aws sts assume-role \
 --role-arn arn:aws:iam::868159525660:role/CROSS-ACCOUNT-ROLE-SECRETS-TO-LAMBDA-RDS \
 --role-session-name=test --duration-seconds 900 \
 --query 'join(``, [`export `, `AWS_ACCESS_KEY_ID=`, 
 Credentials.AccessKeyId, ` ; export `, `AWS_SECRET_ACCESS_KEY=`,
 Credentials.SecretAccessKey, `; export `, `AWS_SESSION_TOKEN=`,
 Credentials.SessionToken])' \
 --output text)
aws s3 cp /home/ec2-user/apsql_scripts/ s3://eh-dbaservices-log-${region}/apsql/postscript/logs/${cluster_endpoint}/ --exclude "*" --include "*.log" --recursive  --region ${aws_region} || error $LINENO "Failed to connect to s3 for exporting the postscripts logs"
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
shutdown -h now