import pulumi
import pulumi_aws as aws

vpc = aws.ec2.Vpc('sina-vpc',
    cidr_block='10.0.0.0/16')


ig = aws.ec2.InternetGateway('sina-ig',
    vpc_id=vpc.id,
    tags={
        'Name': 'SinaInternetGateway',
    }
)
