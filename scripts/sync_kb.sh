#!/bin/bash

# ==============================================================================
# Amazon Bedrock Knowledge Base Sync Script
# 
# Usage: ./sync_kb.sh <KB_ID> <DS_ID>
# ==============================================================================

set -e

KB_ID=$1
DS_ID=$2

if [ -z "$KB_ID" ] || [ -z "$DS_ID" ]; then
    echo "Error: Missing arguments."
    echo "Usage: $0 <KB_ID> <DS_ID>"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed or not in PATH."
    exit 1
fi

echo "----------------------------------------------------------------"
echo "Starting Knowledge Base Ingestion Job..."
echo "Knowledge Base ID: $KB_ID"
echo "Data Source ID:    $DS_ID"
echo "----------------------------------------------------------------"

# Start the ingestion job
JOB_INFO=$(aws bedrock-agent start-ingestion-job \
    --knowledge-base-id "$KB_ID" \
    --data-source-id "$DS_ID")

JOB_ID=$(echo "$JOB_INFO" | grep -o 'ingestionJobId": "[^"]*' | cut -d'"' -f3)

if [ -n "$JOB_ID" ]; then
    echo "Success! Ingestion Job started."
    echo "Job ID: $JOB_ID"
    echo "----------------------------------------------------------------"
    echo "You can monitor the status in the AWS Console under Bedrock > Knowledge Bases."
else
    echo "Error: Failed to start ingestion job."
    echo "$JOB_INFO"
    exit 1
fi
