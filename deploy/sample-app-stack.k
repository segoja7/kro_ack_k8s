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
            id = "authenticateanddeploy"
            template = {
                apiVersion = "tekton.dev/v1beta1"
                kind = "Task"
                metadata = {
                    name = "authenticate-and-deploy" + my_config.project_name
                    namespace = "tekton-tasks"
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
                                                           
                    steps = [
                        {
                            name = "configure-kubeconfig"
                            image = "amazon/aws-cli:latest"
                            script = r"""#!/bin/sh
                            set -e

                            # Instalar kubectl
                            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                            chmod +x kubectl
                            mv kubectl /usr/local/bin/

                            #AWS credentials
                            export AWS_SHARED_CREDENTIALS_FILE=$(workspaces.aws-credentials.path)/credentials
                            aws eks update-kubeconfig --name $(params.cluster-name) --region $(params.aws-region)
                            
                            #verify cluster connectivity
                            kubectl get nodes

                            #deploy-game
                            echo "Deploying game.yaml to Kubernetes..."
                            kubectl apply -f $(params.game-yaml-url)

                            #retrieve dns alb
                            kubectl get svc mygame-svc -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
                            """



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
                    namespace = "tekton-tasks"
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
                            name = "authenticate-and-deploy" + my_config.project_name
                            taskRef = {
                                name = "authenticate-and-deploy" + my_config.project_name
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
