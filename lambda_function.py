import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    AWS Lambda function to stop all running EC2 instances across all regions
    """
    try:
        # Initialize EC2 client
        ec2 = boto3.client('ec2')
        
        # Get all regions
        regions_response = ec2.describe_regions()
        regions = [region['RegionName'] for region in regions_response['Regions']]
        
        stopped_instances = []
        total_instances = 0
        
        # Iterate through all regions
        for region in regions:
            try:
                regional_ec2 = boto3.client('ec2', region_name=region)
                
                # Get all running instances in this region
                response = regional_ec2.describe_instances(
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
                
                if instance_ids:
                    # Stop the instances
                    stop_response = regional_ec2.stop_instances(InstanceIds=instance_ids)
                    
                    for instance in stop_response['StoppingInstances']:
                        stopped_instances.append({
                            'InstanceId': instance['InstanceId'],
                            'Region': region,
                            'PreviousState': instance['PreviousState']['Name'],
                            'CurrentState': instance['CurrentState']['Name']
                        })
                    
                    total_instances += len(instance_ids)
                    logger.info(f"Stopped {len(instance_ids)} instances in region {region}")
                else:
                    logger.info(f"No running instances found in region {region}")
                    
            except Exception as e:
                logger.error(f"Error processing region {region}: {str(e)}")
                continue
        
        # Prepare response
        response = {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully stopped {total_instances} EC2 instances',
                'stopped_instances': stopped_instances,
                'total_regions_processed': len(regions)
            })
        }
        
        logger.info(f"Lambda execution completed. Stopped {total_instances} instances across {len(regions)} regions")
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