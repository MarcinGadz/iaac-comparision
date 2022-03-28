"""An AWS Python Pulumi program"""

import pulumi
import pulumi_aws as aws

vpc = aws.ec2.Vpc('sina-vpc',
    cidr_block='10.0.0.0/16')

sg = aws.ec2.SecurityGroup('sina-sg',
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

ig = aws.ec2.InternetGateway('sina-ig',
    vpc_id=vpc.id,
    tags={
        'Name': 'SinaInternetGateway',
    }
)

p_subnet_1 = aws.ec2.Subnet('sina-private-subnet-1',
    vpc_id=vpc.id,
    cidr_block='10.0.0.0/24',
    availability_zone='eu-central-1a',
)

p_subnet_2 = aws.ec2.Subnet('sina-private-subnet-2',
    vpc_id=vpc.id,
    cidr_block='10.0.1.0/24',
    availability_zone='eu-central-1b',
)

subnet_1 = aws.ec2.Subnet('sina-public-subnet-1',
    vpc_id=vpc.id,
    cidr_block='10.0.2.0/24',
    availability_zone='eu-central-1a',
)

rt = aws.ec2.RouteTable('sina-route-table',
    vpc_id=vpc.id,
    routes = [
        aws.ec2.RouteTableRouteArgs(
            cidr_block='0.0.0.0/0',
            gateway_id=ig.id,
        )
    ],
)

rt_association = aws.ec2.RouteTableAssociation('sina-public-subnet-1-route-table-association',
    subnet_id=subnet_1.id,
    route_table_id=rt.id,
)

subnet_2 = aws.ec2.Subnet('sina-public-subnet-2',
    vpc_id=vpc.id,
    cidr_block='10.0.3.0/24',
    availability_zone='eu-central-1b',
)

rt_association = aws.ec2.RouteTableAssociation('sina-public-subnet-2-route-table-association',
    subnet_id=subnet_2.id,
    route_table_id=rt.id,
)

ami = aws.ec2.get_ami(
    most_recent=True,
    filters=[
        aws.ec2.GetAmiFilterArgs(
            name='name',
            values=['sinaami-*']
        ),
    ],
    owners=['self'],
)

template = aws.ec2.LaunchTemplate('sina-template',
    name_prefix='sina-template',
    image_id=ami.id,
    instance_type='t2.micro',
    vpc_security_group_ids=[sg.id],
    tags={
        'Name': 'SinaASGTemplate',
    },
    tag_specifications=[aws.ec2.LaunchTemplateTagSpecificationArgs(
        resource_type='instance',
        tags={
            'Name': 'SinaASGInstance',
        }
    )],
    key_name='sina-key',
)

asg = aws.autoscaling.Group('sina-asg',
    vpc_zone_identifiers=[p_subnet_1.id, subnet_2.id],
    desired_capacity=2,
    max_size=3,
    min_size=2,
    launch_template=aws.autoscaling.GroupLaunchTemplateArgs(
        id=template.id,
        version='$Latest',
    ),
)

lb = aws.lb.LoadBalancer('sina-elb',
    internal=False,
    subnets=[subnet_1.id, subnet_2.id],
    load_balancer_type='application',
    security_groups=[sg.id],
)

tg = aws.lb.TargetGroup('sina-tg',
    vpc_id=vpc.id,
    port=80,
    protocol='HTTP',
)

asg_attach = aws.autoscaling.Attachment('sina-asg-attachment',
    autoscaling_group_name=asg.id,
    alb_target_group_arn=tg.arn,
    opts=pulumi.ResourceOptions(depends_on=[tg, asg]),
)

http_listener = aws.lb.Listener('sina-lb-http-listener',
    load_balancer_arn=lb.arn,
    # availability_zones=['eu-central-1a', 'eu-central-1b'],
    port=80,
    protocol='HTTP',
    default_actions=[aws.lb.ListenerDefaultActionArgs(
        type='forward',
        target_group_arn=tg.arn,
    )],
)
# tg_a = aws.lb.TargetGroupAttachment('sina-tg-a',
#     target_group_arn=tg.arn,
#     target_id=asg.id,
#     opts=pulumi.ResourceOptions(depends_on=[asg]),
# )


# https_listener = aws.lb.Listener('sina-lb-https-listener',
#     load_balancer_arn=lb.arn,
#     port=443,
#     protocol='HTTPS',
#     default_actions=[aws.lb.ListenerDefaultActionArgs(
#         type='forward',
#         target_group_arn=tg.arn,
#     )],
# )

pulumi.export('Application Load Balancer DNS name', lb.dns_name)


# web = aws.ec2.Instance("pulumi-web",
#     ami=ami.id,
#     instance_type='t2.micro',
#     security_groups=['sina-sec-group'],
#     tags={
#         'Name': 'PulumiWeb'
#     },
# )

# pulumi.export('AWS Instance public IP', web.public_ip)
# pulumi.export('AWS Instance public dns', web.public_dns)