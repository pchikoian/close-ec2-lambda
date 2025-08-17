import boto3
import json
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    AWS Lambda function to stop all running EC2 instances in a specific region
    """
    try:
        # Get region from environment variable
        region = os.environ.get('AWS_REGION', 'us-east-1')
        logger.info(f"Operating in region: {region}")
        
        # Initialize EC2 client for the specific region
        ec2 = boto3.client('ec2', region_name=region)
        
        # Get all running instances in this region
        response = ec2.describe_instances(
            Filters=[
                {
                    'Name': 'instance-state-name',
                    'Values': ['running']
                }
            ]
        )
        
        instance_ids = []
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_ids.append(instance['InstanceId'])
        
        stopped_instances = []
        total_instances = len(instance_ids)
        
        if instance_ids:
            # Stop the instances
            stop_response = ec2.stop_instances(InstanceIds=instance_ids)
            
            for instance in stop_response['StoppingInstances']:
                stopped_instances.append({
                    'InstanceId': instance['InstanceId'],
                    'Region': region,
                    'PreviousState': instance['PreviousState']['Name'],
                    'CurrentState': instance['CurrentState']['Name']
                })
            
            logger.info(f"Stopped {total_instances} instances in region {region}")
        else:
            logger.info(f"No running instances found in region {region}")
        
        # Prepare response
        response = {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully stopped {total_instances} EC2 instances in {region}',
                'stopped_instances': stopped_instances,
                'region': region,
                'total_instances_stopped': total_instances
            })
        }
        
        logger.info(f"Lambda execution completed. Stopped {total_instances} instances in region {region}")
        return response
        
    except Exception as e:
        logger.error(f"Lambda execution failed: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Lambda execution failed',
                'message': str(e)
            })
        }