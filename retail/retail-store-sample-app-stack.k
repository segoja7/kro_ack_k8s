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
            template = {
                apiVersion = "ec2.services.k8s.aws/v1alpha1"
                kind = "VPC"
                metadata = {
                    name = "vpc-${schema.spec.name}"
                }
                spec = {
                    cidrBlocks = ["10.0.1.0/20"]  
                    enableDNSHostnames = True
                    enableDNSSupport = True
                    instanceTenancy = "default"
                    tags = [
                        {
                            key = "ManagedBy"
                            value = "ec2-controller"
                        }
                        {
                            key = "Name"
                            value = "vpc-${schema.spec.name}"
                        }
                    ]
                }
            }
        },
    ]
    resources += [
        {
            id = subnet_config.name
            template = {
                apiVersion = "ec2.services.k8s.aws/v1alpha1"
                kind = "Subnet"
                metadata = {
                    name = subnet_config.name
                }
                spec = {
                    availabilityZone = subnet_config.az
                    cidrBlock = subnet_config.cidr
                    vpcID = r"""${vpc.status.vpcID}"""
                    mapPublicIPOnLaunch =  True if subnet_config.type == "public"  else False
                    tags = [
                        {
                            key = "ManagedBy"
                            value = "ec2-controller"
                        }
                    ]
                }
            }
        } for subnet_config in my_config.subnet_configs
    ] 
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
                            value = "ec2-controller"
                        }
                        {
                            key = "Name" 
                            value =  metadata.name

                        }
                    ]
                }
            }
        } 
    ]     
    resources += [
        {
            id = route_config.name
            template = {
                apiVersion = "ec2.services.k8s.aws/v1alpha1"
                kind = "RouteTable"
                metadata = {
                    name = route_config.name
                }
                spec = {
                    vpcID = r"""${vpc.status.vpcID}"""
                    routes = [
                        {
                            destinationCIDRBlock = "0.0.0.0/0"
                            if route_config.subnet_type == "public" : 
                                gatewayID = r"""${internetgateway.status.internetGatewayID}"""
                            else:
                                natGatewayID = r"""${natgateway.status.natGatewayID}"""
                        }
                    ]                    
                    tags = [
                        {
                            key = "ManagedBy"
                            value = "ec2-controller"
                        }
                        {
                            key = "Name" 
                            value =  metadata.name + "-" + my_config.project_name

                        }
                    ]
                }
            }
        } for route_config in my_config.routeTableConfig
    ]
    
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
                    subnetRef = { 
                        from = {
                            name = my_config.subnet_configs[0].name
                        }
                    } 
                    allocationID = r"""${elasticipaddress.status.allocationID}"""                 
                    tags = [
                        {
                            key = "ManagedBy"
                            value = "ec2-controller"
                        }
                        {
                            key = "Name" 
                            value =  metadata.name

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
                            value = "ec2-controller"
                        }
                        {
                            key = "Name" 
                            value =  metadata.name

                        }
                    ]
                }
            }
        } 
    ] 
}
