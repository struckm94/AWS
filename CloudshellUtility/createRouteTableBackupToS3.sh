#!/bin/bash

# Set Customer ID
custid=""

# Current date in YYYY-MM format
current_date=$(date +%Y-%m)

# Concatenate the AWS_REGION to the bucket name
bucket_name="${custid,,}-matt-route-table-${AWS_REGION,,}"

# Check if the S3 bucket exists and create it if it doesn't
if ! aws s3 ls "s3://${bucket_name}" > /dev/null 2>&1; then
    # The bucket does not exist, so create it
    aws s3 mb "s3://${bucket_name}" --region "${AWS_REGION}"
    echo "Bucket ${bucket_name} created."
    # Enable versioning on the new bucket
    aws s3api put-bucket-versioning --bucket "${bucket_name}" --versioning-configuration Status=Enabled
    echo "Versioning enabled on bucket ${bucket_name}."
fi

# Retrieve route tables
route_tables=$(aws ec2 describe-route-tables --query 'RouteTables[].RouteTableId' --output text)

# Process each route table
for rt_id in ${route_tables}; do
    object_key="${rt_id}/${current_date}/route-table-output.json"
    # Fetch the details of the specific route table
    route_table_details=$(aws ec2 describe-route-tables --route-table-ids "${rt_id}" --output json)
    
    # Temporary file path to store the JSON data
    temp_file="/tmp/${rt_id}.json"

    # Save the JSON details to the temporary file
    echo "${route_table_details}" > "${temp_file}"
    
    # Upload the JSON file to the S3 bucket
    aws s3api put-object --bucket "${bucket_name}" --key "${object_key}" --body "${temp_file}"
    
    # Optionally delete the temp file after upload (uncomment next line if desired)
    # rm "${temp_file}"
    
    echo "Object ${object_key} uploaded to bucket ${bucket_name}."
done