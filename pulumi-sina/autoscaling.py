import security
import networking.subnets as subnets

import pulumi_aws as aws

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
    vpc_security_group_ids=[security.allow_http_sg.id],
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
    vpc_zone_identifiers=[subnets.priv_app_sub_1a.id, subnets.priv_app_sub_1b.id],
    desired_capacity=2,
    max_size=3,
    min_size=2,
    launch_template=aws.autoscaling.GroupLaunchTemplateArgs(
        id=template.id,
        version='$Latest',
    ),
)