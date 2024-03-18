#!/bin/bash -xe
##################################################################################################################################################################
# Program       :  apsql_vault_cleanup_script.tpl
# Programmer    :  Service Catalog DB Team
# Notes         :  This script will remove the vault configurations created for the database. 
# IMPORTANT     :  Copyright  (c) 2023 by ElevanceHealth.
#                  All Rights Reserved.
##################################################################################################################################################################
exec > >(tee -a /var/log/vault_cleanup_script.log) 2>&1
echo "Starting cleanup_script"
sudo su
export dbinstance='${dbinstance}'
AWS_ACC_NUM=$(aws sts get-caller-identity --output text | awk '{ print $1 }'| sed 's/\s/?/g')
export VAULT_ADDR=https://vault.acr.awsdns.internal.das
vault login -no-print -method=aws role=elvdb-$AWS_ACC_NUM

if [ ${environment} != "production" ]; then
    echo -e "Deleting vault configs for ${dbinstance}"
    vault delete corp-antmdb/aws/apsql/nonprod/config/${dbinstance}
    vault delete corp-antmdb/aws/apsql/nonprod/static-roles/${dbinstance}-master
    if [ $? -eq 0 ]; then
        echo -e "Deletion of vault configs successful for ${dbinstance}!!"
    else
        echo -e "Error - Deleting vault configs of ${dbinstance}"
    fi
else
    echo -e "Deleting vault configs for ${dbinstance}"
    vault delete corp-antmdb/aws/apsql/prod/config/${dbinstance}
    vault delete corp-antmdb/aws/apsql/prod/static-roles/${dbinstance}-master
    if [ $? -eq 0 ]; then
        echo -e "Deletion of vault configs successful for ${dbinstance}!!"
    else
        echo -e "Error - Deleting vault configs of ${dbinstance}"
    fi
fi
eval $(aws sts assume-role \
 --role-arn arn:aws:iam::868159525660:role/CROSS-ACCOUNT-ROLE-SECRETS-TO-LAMBDA-RDS \
 --role-session-name=test --duration-seconds 900 \
 --query 'join(``, [`export `, `AWS_ACCESS_KEY_ID=`, 
 Credentials.AccessKeyId, ` ; export `, `AWS_SECRET_ACCESS_KEY=`,
 Credentials.SecretAccessKey, `; export `, `AWS_SESSION_TOKEN=`,
 Credentials.SessionToken])' \
 --output text)

aws s3 cp /var/log s3://eh-dbaservices-log-${region}/apsql/postscript/logs/${dbinstance}/ --exclude "*" --include "vault_cleanup_script.log" --recursive  --region ${aws_region}
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
shutdown -h now