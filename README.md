# terraform-google-prompt-injection

### Detailed
This module will deploy the infrastructure to demostrate mitagations for prompt injection.

The resources/services/activations/deletions that this module will create/trigger are:

- Creates a new Google Cloud project
- Creates a custom Service Account for the Cloud Run
- Creates a private instance of Cloud Run
- Creates a storage bucket for logs and archives
- Create a artifact repostory for application containers
- Creates a Identity Aware Proxy configuration for Cloud Run


### PreDeploy
To deploy this blueprint you must have an active billing account and billing permissions.

## Architecture
![Reference Architecture](diagram/prompt.png)

## Documentation
- [Prompt Samples](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/prompt-samples)


## Usage

1. Clone repo
```
git clone https://github.com/jasonbisson/terraform-google-prompt-injection.git
cd ~/terraform-google-prompt-injection/
```

2. Rename and update required variables in terraform.tvfars.template
```
mv terraform.tfvars.template terraform.tfvars
#Update required variables
```
3. Execute Terraform commands with existing identity (human or service account) to build Infrastructure
```
terraform init
terraform plan
terraform apply

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket\_name | The name of the bucket to create | `string` | n/a | yes |
| project\_id | The project ID to deploy to | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| bucket\_name | Name of the bucket |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

These sections describe requirements for using this module.

### Software

The following dependencies must be available:

- [Terraform][terraform] v0.13
- [Terraform Provider for GCP][terraform-provider-gcp] plugin v3.0

### Service Account

A service account with the following roles must be used to provision
the resources of this module:

- Project Creator 
- Project Deleter
- Billing User

The [Project Factory module][project-factory-module] and the
[IAM module][iam-module] may be used in combination to provision a
service account with the necessary roles applied.

### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- iam.googleapis.com
- compute.googleapis.com
- aiplatform.googleapis.com
- storage.googleapis.com
- run.googleapis.com

## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.

[iam-module]: https://registry.terraform.io/modules/terraform-google-modules/iam/google
[project-factory-module]: https://registry.terraform.io/modules/terraform-google-modules/project-factory/google
[terraform-provider-gcp]: https://www.terraform.io/docs/providers/google/index.html
[terraform]: https://www.terraform.io/downloads.html

## Security Disclosures

Please see our [security disclosure process](./SECURITY.md).
