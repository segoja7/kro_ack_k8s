import my_config

apiVersion = "kro.run/v1alpha1"

kind = "ResourceGraphDefinition"

metadata = {
    name = "retailstoresampleappstack.kro.run"
}

spec = {
    schema = {
        apiVersion = "v1alpha1"
        kind = "RetailStoreSampleAppStack"
        spec = {
            name = "string"
        }
        status = {
            networkingInfo = {
                vpcID = r"""${vpc.status.vpcID}"""
            }
        }
    }
    resources = [
        {
            id = "vpc"
            # readyWhen = [
            #     r"""${vpc.status.state == "available"}"""
            # ]
            template = {
                apiVersion = "ec2.services.k8s.aws/v1alpha1"
                kind = "VPC"
                metadata = {
                    name = "vpc" + my_config.project_name
                }
                spec = {
                    cidrBlocks = ["10.0.1.0/20"]
                    enableDNSHostnames = True
                    enableDNSSupport = True
                    instanceTenancy = "default"
                    tags = [
                        {
                            key = "ManagedBy"
                            value = apiVersion
                        }
                        {
                            key = "Name"
                            value = metadata.name
                        }
                    ]
                }
            }
        }
    ]
    resources += [{    
        id = subnet_config.name
        template = {
            apiVersion = "ec2.services.k8s.aws/v1alpha1"
            kind = "Subnet"
            metadata = {
                name = subnet_config.name + my_config.project_name
            }
            spec = {
                availabilityZone = subnet_config.zone
                cidrBlock = subnet_config.cidr
                vpcID = r"""${vpc.status.vpcID}"""
                if subnet_config.type == "public":
                    mapPublicIPOnLaunch = True 
                    routeTables = [
                        r"""${routetablepublic.status.routeTableID}""" 
                    ]
                    tags = [
                        {
                            key = "ManagedBy"
                            value = apiVersion
                        }
                        {
                            key = "Name"
                            value = metadata.name
                        }
                        {
                            key = "kubernetes.io/role/elb" 
                            value = "1"
                        }
                        {
                            key = r"""kubernetes.io/cluster/cluster""" + my_config.project_name + """"""
                            value = "shared"
                        }
                    ]
                else:
                    mapPublicIPOnLaunch = False
                    routeTables = [
                        r"""${routetableprivate.status.routeTableID}"""
                    ]
                    tags = [
                        {
                            key = "ManagedBy"
                            value = apiVersion
                        }
                        {
                            key = "Name"
                            value = metadata.name
                        }
                        {
                            key = "kubernetes.io/role/internal-elb"
                            value = "1"
                        }
                        {
                            key = r"""kubernetes.io/cluster/cluster""" + my_config.project_name + """"""
                            value = "shared"
                        }
                    ]
            }
        }
    } for subnet_config in my_config.subnet_configs]
    resources += [
        {
            id = "internetgateway"
            template = {
                apiVersion = "ec2.services.k8s.aws/v1alpha1"
                kind = "InternetGateway"
                metadata = {
                    name = "internetgateway" + my_config.project_name
                }
                spec = {
                    vpc = r"""${vpc.status.vpcID}"""
                    tags = [
                        {
                            key = "ManagedBy"
                            value = apiVersion
                        }
                        {
                            key = "Name"
                            value = metadata.name
                        }
                    ]
                }
            }
        }
    ]
    resources += [{               
        id = route_config.name
        template = {
            apiVersion = "ec2.services.k8s.aws/v1alpha1"
            kind = "RouteTable"
            metadata = {
                name = route_config.name + my_config.project_name
            }
            spec = {
                vpcID = r"""${vpc.status.vpcID}"""
                routes = [
                    if route_config.subnet_type == "public":
                        {
                            destinationCIDRBlock = "0.0.0.0/0"
                            gatewayID = r"""${internetgateway.status.internetGatewayID}"""
                        }
                    else:
                        {
                           destinationCIDRBlock = "0.0.0.0/0"
                           natGatewayID = r"""${natgateway.status.natGatewayID}"""
                        }
                ]
                tags = [
                    {
                        key = "ManagedBy"
                        value = apiVersion
                    }
                    {
                        key = "Name"
                        value = metadata.name + "-" + my_config.project_name
                    }
                ]
            }
        }
    } for route_config in my_config.routeTableConfig]
    resources += [
        {           
            id = "natgateway"
            template = {
                apiVersion = "ec2.services.k8s.aws/v1alpha1"
                kind = "NATGateway"
                metadata = {
                    name = "natgateway" + my_config.project_name
                }
                spec = {
                    subnetID = r"""${publicsubnetaz1.status.subnetID}"""
                    allocationID = r"""${elasticipaddress.status.allocationID}"""
                    tags = [
                        {
                            key = "ManagedBy"
                            value = apiVersion
                        }
                        {
                            key = "Name"
                            value = metadata.name
                        }
                    ]
                }
            }
        }
    ]
    resources += [
        {
            id = "elasticipaddress"
            template = {
                apiVersion = "ec2.services.k8s.aws/v1alpha1"
                kind = "ElasticIPAddress"
                metadata = {
                    name = "elasticipaddress" + my_config.project_name
                }
                spec = {
                    tags = [
                        {
                            key = "ManagedBy"
                            value = apiVersion
                        }
                        {
                            key = "Name"
                            value = metadata.name
                        }
                    ]
                }
            }
        }
    ]
    resources += [
        {
            id = "clusterrole"
            template = {
                apiVersion = "iam.services.k8s.aws/v1alpha1"
                kind = "Role"
                metadata = {
                    name = "clusterrole" + my_config.project_name
                }
                spec = {
                    name = metadata.name
                    policies = [
                        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
                    ]
                    assumeRolePolicyDocument = r"""{
                        "Version": "2012-10-17",
                        "Statement": [
                          {
                            "Effect": "Allow",
                            "Principal": {
                              "Service": "eks.amazonaws.com"
                            },
                            "Action": "sts:AssumeRole"
                          }
                        ]
                      }"""
                    tags = [
                        {
                            key = "ManagedBy"
                            value = apiVersion
                        }
                        {
                            key = "Name"
                            value = metadata.name
                        }
                    ]
                }
            }
        }
    ]
    resources += [
        {
            id = "clusternoderole"
            template = {
                apiVersion = "iam.services.k8s.aws/v1alpha1"
                kind = "Role"
                metadata = {
                    name = "clusternoderole" + my_config.project_name
                }
                spec = {
                    name = metadata.name
                    policies = [
                        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
                        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
                        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
                    ]
                    assumeRolePolicyDocument = r"""{
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                            "Effect": "Allow",
                            "Principal": {
                                "Service": "ec2.amazonaws.com"
                            },
                            "Action": "sts:AssumeRole"
                            }
                        ]
                        }
                        """
                        tags = [
                            {
                                key = "ManagedBy"
                                value = apiVersion
                            }
                            {
                                key = "Name"
                                value = metadata.name
                            }
                        ]                        
                }
            }
        }
    ]
    resources += [
        {
            id = "clusteradminrole"
            template = {
                apiVersion = "iam.services.k8s.aws/v1alpha1"
                kind = "Role"
                metadata = {
                    name = "clusteradminrole" + my_config.project_name
                }
                spec = {
                    name = metadata.name
                    policies = [
                        "arn:aws:iam::aws:policy/AdministratorAccess"
                    ]
                    assumeRolePolicyDocument = r"""{
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Sid": "AllowEksAuthToAssumeRoleForPodIdentity",
                                "Effect": "Allow",
                                "Principal": {
                                    "Service": "pods.eks.amazonaws.com"
                                },
                                "Action": [
                                    "sts:AssumeRole",
                                    "sts:TagSession"
                                ]
                            }
                        ]
                        }
                        """
                    tags = [
                        {
                            key = "ManagedBy"
                            value = apiVersion
                        }
                        {
                            key = "Name"
                            value = metadata.name
                        }
                    ]       
                }
            }
        }
    ]
    resources += [
        {
            id = "cluster"
            readyWhen = [
                r"""${cluster.status.status == "ACTIVE"}"""
            ]
            template = {
                apiVersion = "eks.services.k8s.aws/v1alpha1"
                kind = "Cluster"
                metadata = {
                    name = "cluster" + my_config.project_name
                }
                spec = {
                    name = metadata.name
                    accessConfig = {
                        authenticationMode = "API_AND_CONFIG_MAP"
                    }
                    roleARN = r"""${clusterrole.status.ackResourceMetadata.arn}"""
                    resourcesVPCConfig = {
                        endpointPrivateAccess = True
                        endpointPublicAccess = True
                        subnetIDs = [
                            r"""${""" + subnet.name + """.status.subnetID}"""
                            for subnet in my_config.subnet_configs if subnet.type == "private"
                        ]
                    }
                    tags = {
                        "ManagedBy" = apiVersion
                        "Name" =  metadata.name
                    }
                    
                }
            }
        }
    ]    
    resources += [
        {
            id = "clusternodegroup"
            template = {
                apiVersion = "eks.services.k8s.aws/v1alpha1"
                kind = "Nodegroup"
                metadata = {
                    name = "clusternodegroup" + my_config.project_name
                }
                spec = {
                    name = metadata.name
                    diskSize = 20
                    instanceTypes = [
                        "t3.small"
                    ]
                    clusterName = r"""${cluster.spec.name}"""
                    subnets = [
                        r"""${""" + subnet.name + """.status.subnetID}"""
                        for subnet in my_config.subnet_configs if subnet.type == "private"
                    ]
                    nodeRole = r"""${clusternoderole.status.ackResourceMetadata.arn}"""
                    updateConfig = {
                        maxUnavailable = 1
                    }
                    scalingConfig = {
                        minSize = 1
                        maxSize = 1
                        desiredSize = 1
                    }
                    tags = {
                        "ManagedBy" = apiVersion
                        "Name" =  metadata.name
                    }
                }
            }
        }
    ]
}

