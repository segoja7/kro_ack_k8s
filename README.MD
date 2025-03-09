# Kubernetes Deployments Simplified with Kro, ACK, and KCL

This repository demonstrates how to deploy an application on AWS EKS using Kro, ACK controllers, and KCL. This powerful combination simplifies infrastructure management, reduces code duplication, and streamlines the deployment process.

## Key Technologies

* **Kro:** A cloud-agnostic, Kubernetes-native tool for defining and grouping applications and their dependencies.  Kro simplifies application management by encapsulating components as a single resource.  (Currently experimental and under active development.  See the **Kro Status Update** below.)

* **ACK (AWS Controllers for Kubernetes):**  Manage AWS service resources directly from your Kubernetes cluster.  ACK provides a bridge between your Kubernetes environment and various AWS services.

* **KCL (Kubernetes Configuration Language):**  A modern configuration language that leverages programming language techniques to generate Kubernetes manifests. KCL promotes DRY (Don't Repeat Yourself) principles and reduces the complexity of managing YAML files.

## Kro Status Update

* **Open Source Release (November 2024):** Kro is now open-source!
* **Cross-Cloud Collaboration (January 2025):**  Azure, GCP, and AWS are collaborating on Kro's further development.
* **Production Readiness:** While currently experimental, Kro is actively being prepared for production use.

## Project Overview

This repository provides a practical example of deploying a 2048 game on EKS.  It uses:

* **ACK Controllers:** To provision the necessary AWS infrastructure.
* **Kro:** To package the application and its dependencies.
* **KCL:** To generate the Kubernetes manifests.


## Getting Started

### Prerequisites

* Kubernetes Cluster (Minikube recommended for testing: `minikube start -p kro`)
* AWS Programmatic Access (Configure AWS CLI with credentials)
* Helm (v3.16.2 or later)

### Installation

1. **Install Kro:**
   ```bash
   # Get latest version
   export KRO_VERSION=$(curl -sL https://api.github.com/repos/kro-run/kro/releases/latest | jq -r '.tag_name | ltrimstr("v")')
   # Install with Helm
   helm install kro oci://ghcr.io/kro-run/kro/kro --namespace kro --create-namespace --version=${KRO_VERSION}
   ```

2. **Install ACK Controllers:**
   ```bash
   # Create namespace and AWS secret (replace ./profile.txt with your credentials file)
   kubectl create ns ack-system
   kubectl create secret generic aws-credentials -n ack-system --from-file=credentials=./profile.txt
   # Install controllers (adapt script for desired controllers)
   ./install-ack-controllers.sh # See provided script example in the repository
   ```

3. **Install KCL:** Follow the instructions on the official KCL website: [https://www.kcl-lang.io/docs/user_docs/getting-started/install](https://www.kcl-lang.io/docs/user_docs/getting-started/install)

4. **Install Tekton Pipelines:**
   ```bash
   kubectl create ns tekton-tasks
   kubectl get secret aws-credentials -n ack-system -o yaml | sed "s/namespace: ack-system/namespace: tekton-tasks/" | kubectl apply -f -
   kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
   ```



**Summary of Steps:**

1. **Infrastructure Provisioning:** Use Kro and KCL to define and create the necessary AWS resources (e.g., VPC, subnets, etc.).
2. **Application Deployment:** Use Kro and KCL to define and deploy the 2048 game application.  This includes setting up a Tekton pipeline for the deployment process.
3. **Trigger Pipeline:**  Initiate the Tekton pipeline to deploy the application to your EKS cluster.

## Code Organization

* `./infra`: Contains KCL code for infrastructure resources.
* `./deploy`: Contains KCL code for application deployment.
* `./install-ack-controllers.sh`: Example script to install ACK controllers.


## Example KCL Code (Subnet Creation)

```kcl
resources += [{
    id = subnet_config.name
    template = {
        # ... Subnet configuration details ...
    }
} for subnet_config in my_config.subnet_configs]
```

This example demonstrates a modern and efficient approach to Kubernetes deployments on AWS. By leveraging Kro, ACK, and KCL, you can significantly reduce complexity, improve maintainability, and boost productivity.  Refer to the [blog](https://dev.to/segoja7/creating-apis-with-aws-controllers-for-kubernetes-ack-and-kube-resource-orchestratorkro-using-3hb0) post for a comprehensive walkthrough.
```
