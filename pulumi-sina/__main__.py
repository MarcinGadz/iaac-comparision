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
    opts=pulumi.ResourceOptions(depends_on=[tg, asg]),
)

pulumi.export('Application Load Balancer DNS name', lb.dns_name)
# pulumi.export('AWS Instance public IP', web.public_ip)
# pulumi.export('AWS Instance public dns', web.public_dns)
