import my_config

apiVersion = "kro.run/v1alpha1"

kind = "ResourceGraphDefinition"

metadata = {
    name = "deploysampleappstack.kro.run"
}

spec = {
    schema = {
        apiVersion = "v1alpha1"
        kind = "DeploySampleAppStack"
        spec = {
            name = "string"
        }
    }
  
    resources = [
        {
            id = "tektontaskauthenticate"
            template = {
                apiVersion = "tekton.dev/v1beta1"
                kind = "Task"
                metadata = {
                    name = "authenticate-eks-" + my_config.project_name
                    namespace = "tekton-pipelines"
                }
                spec = {
                    params = [
                        {
                            name = "cluster-name"
                            $type = "string"
                        }
                        {
                            name = "aws-region"
                            $type = "string"
                        }
                    ]
                    workspaces = [
                        {
                            name = "aws-credentials"
                        }
                    ]
                    steps = [
                        {
                            name = "configure-kubeconfig"
                            image = "amazon/aws-cli:latest"
                            script = r"#!/bin/sh\nexport AWS_SHARED_CREDENTIALS_FILE=$(workspaces.aws-credentials.path)/aws-credentials\naws eks update-kubeconfig --name $(params.cluster-name) --region $(params.aws-region)"
                        }
                    ]
                }
            }
        }
    ]
    
    resources += [
        {
            id = "tektontaskdeployapp"
            template = {
                apiVersion = "tekton.dev/v1beta1"
                kind = "Task"
                metadata = {
                    name = "deploy-app-" + my_config.project_name
                    namespace = "tekton-pipelines"
                }
                spec = {
                    params = [
                        {
                            name = "game-yaml-url"
                            $type = "string"
                        }
                    ]
                    workspaces = [
                        {
                            name = "aws-credentials"
                        }
                    ]
                    steps = [
                        {
                            name = "download-game-yaml"
                            image = "curlimages/curl:latest"
                            script = r"#!/bin/sh\necho \"Downloading game.yaml from $(params.game-yaml-url)...\"\ncurl -o /workspace/game.yaml $(params.game-yaml-url)"
                        }
                        {
                            name = "deploy-game"
                            image = "bitnami/kubectl:latest"
                            script = r"#!/bin/sh\necho \"Deploying game.yaml to Kubernetes...\"\nkubectl apply -f /workspace/game.yaml"
                        }
                    ]
                }
            }
        }
    ]
    resources += [
        {
            id = "tektonpipeline"
            template = {
                apiVersion = "tekton.dev/v1beta1"
                kind = "Pipeline"
                metadata = {
                    name = "pipeline-" + my_config.project_name
                    namespace = "tekton-pipelines"
                }
                spec = {
                    params = [
                        {
                            name = "cluster-name"
                            $type = "string"
                        }
                        {
                            name = "aws-region"
                            $type = "string"
                        }
                        {
                            name = "game-yaml-url"
                            $type = "string"
                        }
                    ]
                    workspaces = [
                        {
                            name = "aws-credentials"
                        }
                    ]
                    tasks = [
                        {
                            name = "authenticate-eks-" + my_config.project_name
                            taskRef = {
                                name = "authenticate-eks-" + my_config.project_name
                            }
                            params = [
                                {
                                    name = "cluster-name"
                                    value = r"$(params.cluster-name)"
                                }
                                {
                                    name = "aws-region"
                                    value = r"$(params.aws-region)"
                                }
                            ]
                            workspaces = [
                                {
                                    name = "aws-credentials"
                                    workspace = "aws-credentials"
                                }
                            ]
                        }
                        {
                            name = "deploy-app-" + my_config.project_name
                            taskRef = {
                                name = "deploy-app-" + my_config.project_name
                            }
                            params = [
                                {
                                    name = "game-yaml-url"
                                    value = r"$(params.game-yaml-url)"
                                }
                            ]
                            workspaces = [
                                {
                                    name = "aws-credentials"
                                    workspace = "aws-credentials"
                                }
                            ]
                        }
                    ]
                }
            }
        }
    ]    
}
