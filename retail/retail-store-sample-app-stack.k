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
            id = my_config.project_name + subnet_config.name
            template = {
                apiVersion = "ec2.services.k8s.aws/v1alpha1"
                kind = "Subnet"
                metadata = {
                    name = subnet_config.name
                }
                spec = {
                    availabilityZone = subnet_config.az
                    cidrBlock = subnet_config.cidr
                    vpcRef = {
                        from = {
                            name = "vpc-${schema.spec.name}"
                        }
                    }
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
}
