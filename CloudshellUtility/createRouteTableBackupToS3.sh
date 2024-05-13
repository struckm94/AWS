#!/bin/bash

# Set Customer ID
custid=""

# Check if custid is empty
if [ -z "$custid" ]; then
    echo "Error: Customer ID is not set. Please provide a valid Customer ID."
    exit 1
fi

# Get Region
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Current date in YYYY-MM format
current_date=$(date +%Y-%m)

# Function to backup to an S3 bucket
BackupToS3() {
    # Concatenate the AWS_REGION to the bucket name
    bucket_name="${custid,,}-route-table-${AWS_REGION,,}"

    # Check if the S3 bucket exists and create it if it doesn't
    if ! aws s3 ls "s3://${bucket_name}" > /dev/null 2>&1; then
        aws s3 mb "s3://${bucket_name}" --region "${AWS_REGION}"
        echo "Bucket ${bucket_name} created."
        aws s3api put-bucket-versioning --bucket "${bucket_name}" --versioning-configuration Status=Enabled  
        echo "Versioning enabled on bucket ${bucket_name}."
    fi

    # Retrieve and process route tables
    route_tables=$(aws ec2 describe-route-tables --query 'RouteTables[].RouteTableId' --output text)
    for rt_id in ${route_tables}; do
        object_key="${rt_id}/${current_date}/route-table-output.json"
        route_table_details=$(aws ec2 describe-route-tables --route-table-ids "${rt_id}" --output json)      
        temp_file="/tmp/${rt_id}.json"
        echo "${route_table_details}" > "${temp_file}"
        aws s3api put-object --bucket "${bucket_name}" --key "${object_key}" --body "${temp_file}"
        # rm "${temp_file}" # Uncomment to delete temp file after upload
        echo "Object ${object_key} uploaded to bucket ${bucket_name}."
    done
}

BackupToLocal() {
    # Define the base backup directory including the customer ID and AWS region
    backup_dir="/tmp/${custid,,}-route-table-${AWS_REGION,,}"

    # Retrieve and process route tables
    route_tables=$(aws ec2 describe-route-tables --query 'RouteTables[].RouteTableId' --output text)
    for rt_id in ${route_tables}; do
        # Ensure the directory for the route table ID exists
        rt_dir="${backup_dir}/${rt_id}"
        mkdir -p "${rt_dir}"

        # Define the filename including the date
        file_name="${current_date}_route-table-output.json"
        file_path="${rt_dir}/${file_name}"

        # Fetch route table details and write them to the file
        route_table_details=$(aws ec2 describe-route-tables --route-table-ids "${rt_id}" --output json)      
        echo "${route_table_details}" > "${file_path}"

        echo "Backup of ${rt_id} saved to ${file_path}."
    done
}

# Call functions to execute
# BackupToS3
BackupToLocal
