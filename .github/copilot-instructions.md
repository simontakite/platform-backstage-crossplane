# Enterprise AKS Internal Developer Platform (KubeIDP)

## Overview
This repository contains the codebase for the Enterprise Internal Developer Platform (IDP) built on Azure Kubernetes Service (AKS). The platform is designed to manage infrastructure, applications, and services efficiently across multiple environments (dev, stage, prod). Key components include:

- **Infrastructure as Code (IaC)**: Terraform modules for AKS, networking, and Key Vault.
- **Crossplane**: Compositions and definitions for managing cloud resources like PostgreSQL, Redis, and Azure Service Bus.
- **Backstage**: A developer portal for managing templates, plugins, and configurations.
- **Platform Services**: Observability, ingress, and policy enforcement tools.
- **GitOps with FluxCD**: FluxCD is used to manage and synchronize Kubernetes manifests across environments.

## Key Directories
- `infrastructure/`: Contains Terraform configurations for managing environments and modules.
- `crossplane/`: Defines Crossplane compositions and providers for cloud resource management.
- `backstage/`: Houses Backstage configurations, plugins, and templates.
- `platform-services/`: Includes services like cert-manager, ingress-nginx, and observability tools.
- `docs/`: Documentation for architecture, developer guides, and platform overview.
- `clusters/`: Includes cluster environments dev, stage, prod 
with their FluxCD kustomization configuration.

## Developer Workflows
### Building and Deploying Infrastructure
1. Navigate to the desired environment directory under `infrastructure/environments/` (e.g., `dev/`, `stage/`, `prod/`).
2. Run Terraform commands:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Managing Crossplane Resources
1. Update or create resource definitions in `crossplane/compositions/` or `crossplane/definitions/`.
2. Apply changes using `kubectl`:
   ```bash
   kubectl apply -f <file>.yaml
   ```

### Backstage Development
1. Modify configurations in `backstage/app-config.yaml`.
2. Add or update plugins in `backstage/plugins/`.
3. Test locally:
   ```bash
   yarn install
   yarn dev
   ```

### Platform Services
- Manage configurations for services like ingress-nginx or cert-manager under `platform-services/`.
- Apply changes using Helm or `kubectl`.

## Project Conventions
- **Terraform Modules**: Follow the structure in `infrastructure/modules/` for creating reusable modules.
- **Crossplane**: Use `xrd` files for defining resource types and `compositions` for resource templates.
- **Backstage Plugins**: Place custom plugins under `backstage/plugins/`.
- **Documentation**: Update `docs/` for any architectural or workflow changes.

## External Dependencies
- **Azure**: The platform heavily relies on Azure services (AKS, Key Vault, PostgreSQL, etc.).
- **Crossplane**: Ensure Crossplane is installed and configured in the cluster.
- **Terraform**: Use Terraform for infrastructure provisioning.
- **Helm**: Manage Kubernetes services using Helm charts.

## Examples
### Adding a New Environment
1. Copy an existing environment directory (e.g., `infrastructure/environments/dev/`).
2. Update `variables.tf` and `main.tf` as needed.
3. Run Terraform commands to provision the environment.

### Creating a New Crossplane Composition
1. Define a new `xrd` file in `crossplane/definitions/`.
2. Create a corresponding composition in `crossplane/compositions/`.
3. Apply the files using `kubectl`.

---

For further details, refer to the documentation in `docs/` or contact the platform engineering team.