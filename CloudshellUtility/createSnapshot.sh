#!/bin/bash

# Prompt for Volume ID
read -p "Enter the EBS Volume ID: " volume_id

# Prompt for CustID
read -p "Enter CustID: " cust_id

# Prompt for Reason
read -p "Enter the reason for the snapshot: " reason

# Get the attached instance ID and OS
instance_id=$(aws ec2 describe-volumes --volume-ids $volume_id --query "Volumes[*].Attachments[*].InstanceId" --output text)
instance_name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$instance_id" "Name=key,Values=Name" --query "Tags[*].Value" --output text)
os=$(uname -a)

# Prompt for Name if not available
if [ -z "$instance_name" ]; then
  read -p "Enter the Name tag (Instance Name not found): " instance_name
fi

# Prompt for OS if not available
if [ -z "$os" ]; then
  read -p "Enter the OS tag (OS information not found): " os
fi

# Get CreatedBy and process it
created_by_full=$(aws sts get-caller-identity --query "Arn" --output text)
created_by=${created_by_full##*/}
if [[ $created_by == abc* ]]; then
  created_by=${created_by:3}
fi

# Create the snapshot with tags
aws ec2 create-snapshot --volume-id $volume_id --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value='$instance_name'},{Key=CustID,Value='$cust_id'},{Key=OS,Value='$os'},{Key=Description,Value='Snapshot created via script'},{Key=Reason,Value='$reason'},{Key=CreatedBy,Value='$created_by'}]"

echo "Snapshot creation initiated for volume: $volume_id"
