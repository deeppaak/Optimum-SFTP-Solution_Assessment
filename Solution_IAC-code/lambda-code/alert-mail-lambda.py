import os
import boto3
from datetime import datetime
from botocore.exceptions import ClientError

# Create AWS clients
transfer = boto3.client('transfer')
s3 = boto3.resource('s3')
ses = boto3.client('ses')

# SES email parameters
ses_from = os.environ['SES_FROM']
ses_to = os.environ['SES_TO']

def send_email(subject, body, attachment_path=None):
    """
    Send an email with the specified subject and body, and an optional attachment.
    """
    message = {
        'Subject': {'Data': subject},
        'Body': {'Text': {'Data': body}}
    }

    if attachment_path is not None:
        with open(attachment_path, 'rb') as attachment:
            message['Attachments'] = [{
                'Filename': os.path.basename(attachment_path),
                'Content': attachment.read(),
                'ContentType': 'application/octet-stream'
            }]

    try:
        response = ses.send_email(
            Source=ses_from,
            Destination={'ToAddresses': [ses_to]},
            Message=message
        )
    except ClientError as e:
        print(f"Error sending email: {e.response['Error']['Message']}")
    else:
        print(f"Email sent: Message ID: {response['MessageId']}")

def check_subfolder_for_files(bucket_name, subfolder):
    """
    Check the specified subfolder in the specified S3 bucket for files.
    """
    bucket = s3.Bucket(bucket_name)
    if not bucket.objects.filter(Prefix=subfolder).all():
        print(f"Subfolder '{subfolder}' does not exist")
    else:
        objs = list(bucket.objects.filter(Prefix=subfolder))
        if len(objs) == 0:
            print(f"No objects found in subfolder '{subfolder}'")
            send_email(
                subject='Not uploaded any files',
                body=f'Client not uploaded any files to {subfolder}'
            )
        else:
            print(f"Objects found in subfolder '{subfolder}':")
            objects_uploaded_today = False
            for obj in objs:
                if obj.last_modified.date() == datetime.utcnow().date():
                    objects_uploaded_today = True
                    print(f" - {obj.key} (uploaded today)")
            if not objects_uploaded_today:
                print(f"No files uploaded to subfolder '{subfolder}' today")
                send_email(
                    subject='No new files uploaded today',
                    body=f'No new files were uploaded to {subfolder} on {datetime.utcnow().strftime("%Y-%m-%d")}'
                )

def lambda_handler(event, context):
    bucket_name = os.environ['Landing_Bucket_Name']
    aws_trasfer_server_id = os.environ['Server_Id']

    response = transfer.list_users(
        ServerId=aws_trasfer_server_id
    )

    for user in response['Users']:
        home_directory = user['HomeDirectory']
        username = user['UserName']
        splitfolder = home_directory.split('/')[2]
        check_subfolder_for_files(bucket_name, splitfolder)
