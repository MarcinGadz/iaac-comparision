import json
import pulumi
import pulumi_aws as aws

import networking.subnets as subnets
from autoscaling import asg
from networking.vpc import vpc
from security import allow_http_sg

lb = aws.lb.LoadBalancer('sina-elb',
    internal=False,
    subnets=[subnets.pub_lb_sub_1a, subnets.pub_lb_sub_1b],
    load_balancer_type='application',
    security_groups=[allow_http_sg.id],
)

tg = aws.lb.TargetGroup('sina-tg',
    vpc_id=vpc.id,
    port=80,
    protocol='HTTP',
)

http_listener = aws.lb.Listener('sina-lb-http-listener',
    load_balancer_arn=lb.arn,
    port=80,
    protocol='HTTP',
    default_actions=[aws.lb.ListenerDefaultActionArgs(
        type='forward',
        target_group_arn=tg.arn,
    )],
)

asg_attach = aws.autoscaling.Attachment('sina-asg-attachment',
    autoscaling_group_name=asg.id,
    alb_target_group_arn=tg.arn,
)

bucket = aws.s3.Bucket('sina-bucket',
    bucket='pl-sina-bucket',
    tags={
        'Name': 'Sina Bucket',
    })

def public_read_policy_for_bucket(arn):
    return json.dumps({
        'Version': '2012-10-17',
        'Statement': [
            {
                'Sid': 'PublicReadPolicy',
                'Effect': 'Allow',
                'Principal': '*',
                'Action': [
                    's3:GetObject',
                ],
                'Resource': f'{arn}/*',
            }
        ],
    })

bucket_policy = aws.s3.BucketPolicy('sina-public-read-bucket-policy',
    bucket=bucket.id,
    policy=bucket.arn.apply(public_read_policy_for_bucket),
)

pulumi.export('Application Load Balancer DNS name', lb.dns_name)
pulumi.export('S3 Bucket URL', bucket.bucket_domain_name)
