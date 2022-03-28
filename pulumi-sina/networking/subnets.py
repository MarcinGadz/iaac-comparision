import pulumi_aws as aws

from vpc import ig, vpc


def associate_subnet_with_route_table(subnet: aws.ec2.subnet,
    route_table: aws.ec2.route_table):
    return aws.ec2.RouteTableAssociation(
        f'{subnet._name}-{route_table._name}-association',
        subnet_id=subnet.id,
        route_table_id=route_table.id,
    )

priv_app_sub_1a = aws.ec2.Subnet('sina-private-subnet-1',
    vpc_id=vpc.id,
    cidr_block='10.0.0.0/24',
    availability_zone='eu-central-1a',
)

priv_app_sub_1b = aws.ec2.Subnet('sina-private-subnet-2',
    vpc_id=vpc.id,
    cidr_block='10.0.1.0/24',
    availability_zone='eu-central-1b',
)

pub_lb_sub_1a = aws.ec2.Subnet('sina-public-subnet-1',
    vpc_id=vpc.id,
    cidr_block='10.0.2.0/24',
    availability_zone='eu-central-1a',
)

pub_lb_sub_1b = aws.ec2.Subnet('sina-public-subnet-2',
    vpc_id=vpc.id,
    cidr_block='10.0.3.0/24',
    availability_zone='eu-central-1b',
)

route_table = aws.ec2.RouteTable('sina-route-table',
    vpc_id=vpc.id,
    routes = [
        aws.ec2.RouteTableRouteArgs(
            cidr_block='0.0.0.0/0',
            gateway_id=ig.id,
        )
    ],
)

pub_sub_1a_rt_association = associate_subnet_with_route_table(
    pub_lb_sub_1a, route_table)

pub_sub_1b_rt_association = associate_subnet_with_route_table(
    pub_lb_sub_1b, route_table)

