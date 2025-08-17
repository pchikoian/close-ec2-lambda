#!/bin/bash

# Script to zip Lambda function and upload to S3 with git commit ID as filename

# Configuration - Update these variables
S3_BUCKET="your-lambda-deployment-bucket"
AWS_REGION="us-east-1"

# Get git commit ID
COMMIT_ID=$(git rev-parse HEAD)
if [ $? -ne 0 ]; then
    echo "Error: Not a git repository or git not found"
    exit 1
fi

# Create deployment package name
PACKAGE_NAME="close-ec2-lambda-${COMMIT_ID}.zip"

echo "Creating deployment package: ${PACKAGE_NAME}"

# Create a temporary directory for the package
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: ${TEMP_DIR}"

# Copy Lambda function to temp directory
cp lambda_function.py "${TEMP_DIR}/"

# Install dependencies if requirements.txt exists
if [ -f "requirements.txt" ]; then
    echo "Installing dependencies..."
    pip install -r requirements.txt -t "${TEMP_DIR}/" --no-user
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install dependencies"
        rm -rf "${TEMP_DIR}"
        exit 1
    fi
fi

# Create the zip file
echo "Creating zip file..."
cd "${TEMP_DIR}"
zip -r "../${PACKAGE_NAME}" .
cd - > /dev/null

# Move the zip file to current directory
mv "${TEMP_DIR}/../${PACKAGE_NAME}" .

# Clean up temp directory
rm -rf "${TEMP_DIR}"

# Upload to S3
echo "Uploading ${PACKAGE_NAME} to S3 bucket: ${S3_BUCKET}"
aws s3 cp "${PACKAGE_NAME}" "s3://${S3_BUCKET}/${PACKAGE_NAME}" --region "${AWS_REGION}"

if [ $? -eq 0 ]; then
    echo "Successfully uploaded to S3: s3://${S3_BUCKET}/${PACKAGE_NAME}"
    echo "Git commit ID: ${COMMIT_ID}"
    
    # Optional: Remove local zip file
    read -p "Remove local zip file? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "${PACKAGE_NAME}"
        echo "Local zip file removed"
    fi
else
    echo "Error: Failed to upload to S3"
    exit 1
fi