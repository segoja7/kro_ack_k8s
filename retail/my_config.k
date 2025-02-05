subnet_configs = [
    {"name": "appPrivateSubnetaz1", "cidr": "10.0.0.0/24", "zone": "us-east-1a", "type": "private"},
    {"name": "appPrivateSubnetaz2", "cidr": "10.0.1.0/24", "zone": "us-east-1b", "type": "private"},
    {"name": "publicSubnetaz1", "cidr": "10.0.2.0/24", "zone": "us-east-1a", "type": "public"},
    {"name": "publicSubnetaz2", "cidr": "10.0.3.0/24", "zone": "us-east-1b", "type": "public"}
]

project_name = "retail"