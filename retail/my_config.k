subnet_configs = [
    {"name": "appprivatesubnetaz1", "cidr": "10.0.0.0/24", "zone": "us-east-1a", "type": "private"},
    {"name": "appprivatesubnetaz2", "cidr": "10.0.1.0/24", "zone": "us-east-1b", "type": "private"},
    {"name": "publicsubnetaz1", "cidr": "10.0.2.0/24", "zone": "us-east-1a", "type": "public"},
    {"name": "publicsubnetaz2", "cidr": "10.0.3.0/24", "zone": "us-east-1b", "type": "public"}
]

project_name = "retail"

routeTableConfig = [
    {"name": "routetablepublic", "subnet_type": "public"},
    {"name": "routetableprivate", "subnet_type": "private"}
]


