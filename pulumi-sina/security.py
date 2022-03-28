import pulumi_aws as aws

from networking.vpc import vpc

allow_http_sg = aws.ec2.SecurityGroup('sina-sg',
    description='Allow http and https traffic from the instance',
    vpc_id=vpc.id,
    ingress=[
        aws.ec2.SecurityGroupIngressArgs(
            description='HTTP from VPC',
            from_port=80,
            to_port=80,
            protocol='tcp',
            cidr_blocks=['0.0.0.0/0'],
            ipv6_cidr_blocks=['::/0'],
        ),
        aws.ec2.SecurityGroupIngressArgs(
            description='HTTPS from VPC',
            from_port=443,
            to_port=443,
            protocol='tcp',
            cidr_blocks=['0.0.0.0/0'],
            ipv6_cidr_blocks=['::/0'],
        ),
    ],
    egress=[
        aws.ec2.SecurityGroupEgressArgs(
            description='Anything to VPC',
            from_port=0,
            to_port=0,
            protocol='-1',
            cidr_blocks=['0.0.0.0/0'],
            ipv6_cidr_blocks=['::/0'],
        ),
    ],
    tags={
        'Name': 'Allow HTTP and HTTPS'
    },
)
