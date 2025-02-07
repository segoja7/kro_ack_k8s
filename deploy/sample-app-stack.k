project_name = "segoja7"

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
            id = "tektonpipeline"
            template = {
                apiVersion = "tekton.dev/v1beta1"
                kind = "Pipeline"
                metadata = {
                    name = "pipeline" + project_name
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
                            name = "authenticate-eks"
                            taskRef = {
                                name = "authenticate-eks"
                            }
                            params = [
                                {
                                    name = "cluster-name"
                                    value = r"""$(params.cluster-name)"""
                                }
                                {
                                    name = "aws-region"
                                    value = r"""$(params.aws-region)"""
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
                            name = "deploy-game"
                            taskRef = {
                                name = "deploy-game"
                            }
                            params = [
                                {
                                    name = "game-yaml-url"
                                    value = r"""$(params.game-yaml-url)"""
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
    
    resources += [
        {
            id = "tektontaskauthenticate"
            template = {
                apiVersion = "tekton.dev/v1beta1"
                kind = "Task"
                metadata = {
                    name = "authenticate-eks" + project_name
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
                            script = r"""#!/bin/sh
    export AWS_SHARED_CREDENTIALS_FILE=$(workspaces.aws-credentials.path)/aws-credentials
    aws eks update-kubeconfig --name $(params.cluster-name) --region $(params.aws-region)
    """
                        }
                    ]
                }
            }
        }
    ]
    resources += [
        {
            id = "tektontaskdeploy"
            template = {
                apiVersion = "tekton.dev/v1beta1"
                kind = "Task"
                metadata = {
                    name = "deploy-eks" + project_name
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
                            script = r"""#!/bin/sh
            echo "Downloading game.yaml from $(params.game-yaml-url)..."
            curl -o /workspace/game.yaml $(params.game-yaml-url)
            """
                        }
                        {
                            name = "deploy-game"
                            image = "bitnami/kubectl:latest"
                            script = r"""#!/bin/sh
            echo "Deploying game.yaml to Kubernetes..."
            kubectl apply -f /workspace/game.yaml
            """
                        }
                    ]
                }
            }
        }
    ]    
    
    resources += [
        {
            id = "tektontaskdeploygame"
            template = {
                apiVersion = "tekton.dev/v1beta1"
                kind = "Task"
                metadata = {
                    name = "deploy-game-app" + project_name
                    namespace = "tekton-pipelines"
                }
                spec = {
                    workspaces = [
                        {
                            name = "manifest"
                        }
                    ]
                    steps = [
                        {
                            name = "apply-game-manifest"
                            image = "bitnami/kubectl:latest"
                            script = r"""#!/bin/sh
    kubectl apply -f $(workspaces.manifest.path)/game.yaml
    """
                        }
                    ]
                }
            }
        }
    ]
                 
}

