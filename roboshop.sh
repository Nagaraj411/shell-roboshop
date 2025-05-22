#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f" # replace with your AMI ID
SG_ID="sg-009d0f9988cd2de9b" # replace with your Security groups ID
INSTANCES=("mongodb" "redis" "frontend" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch")
ZONE_ID="Z05005862BAG0R5BQ5WUP" # replace with your ZONE ID
DOMAIN_NAME="devops84.shop" # replace with your domain

for instance in ${INSTANCES[@]}
#for instance in $@

do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-009d0f9988cd2de9b --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)
    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
        RECORD_NAME="$DOMAIN_NAME"  # adding this line to set the domain name for frontend IP Address instance
    fi
    echo "$instance IP address: $IP"

    # UPSERT Create or update the Route 53 record set using UPSERT
    
    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Creating or Updating a record set for cognito endpoint"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }'
done