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
| argument | Arguments passed to the ENTRYPOINT command, include these only if image entrypoint needs arguments | `list(string)` | `[]` | no |
| billing\_account | The billing account id associated with the project, e.g. XXXXXX-YYYYYY-ZZZZZZ | `string` | n/a | yes |
| certificate\_mode | The mode of the certificate (NONE or AUTOMATIC) | `string` | `"NONE"` | no |
| container\_command | Leave blank to use the ENTRYPOINT command defined in the container image, include these only if image entrypoint should be overwritten | `list(string)` | `[]` | no |
| container\_concurrency | Concurrent request limits to the service | `number` | `null` | no |
| domain\_map\_annotations | Annotations to the domain map | `map(string)` | `{}` | no |
| domain\_map\_labels | A set of key/value label pairs to assign to the Domain mapping | `map(string)` | `{}` | no |
| env\_secret\_vars | [Beta] Environment variables (Secret Manager) | <pre>list(object({<br>    name = string<br>    value_from = set(object({<br>      secret_key_ref = map(string)<br>    }))<br>  }))</pre> | `[]` | no |
| env\_vars | Environment variables (cleartext) | <pre>list(object({<br>    value = string<br>    name  = string<br>  }))</pre> | `[]` | no |
| environment | Environment tag to help identify the entire deployment | `string` | n/a | yes |
| folder\_id | The folder to deploy project in | `string` | n/a | yes |
| force\_override | Option to force override existing mapping | `bool` | `false` | no |
| generate\_revision\_name | Option to enable revision name generation | `bool` | `true` | no |
| image | GCR hosted image URL to deploy | `string` | `"us-docker.pkg.dev/cloudrun/container/hello"` | no |
| limits | Resource limits to the container | `map(string)` | `null` | no |
| members | Users/SAs to be given invoker access to the service | `list(string)` | `[]` | no |
| org\_id | The numeric organization id | `string` | n/a | yes |
| ports | Port which the container listens to (http1 or h2c) | <pre>object({<br>    name = string<br>    port = number<br>  })</pre> | <pre>{<br>  "name": "http1",<br>  "port": 8080<br>}</pre> | no |
| project\_name | Prefix of Google Project name | `string` | `"prj"` | no |
| region | The GCP region to create and test resources in | `string` | `"us-central1"` | no |
| requests | Resource requests to the container | `map(string)` | `{}` | no |
| service\_annotations | Annotations to the service. Acceptable values all, internal, internal-and-cloud-load-balancing | `map(string)` | <pre>{<br>  "run.googleapis.com/ingress": "internal"<br>}</pre> | no |
| service\_labels | A set of key/value label pairs to assign to the service | `map(string)` | `{}` | no |
| template\_annotations | Annotations to the container metadata including VPC Connector and SQL. See [more details](https://cloud.google.com/run/docs/reference/rpc/google.cloud.run.v1#revisiontemplate) | `map(string)` | <pre>{<br>  "autoscaling.knative.dev/maxScale": 3,<br>  "autoscaling.knative.dev/minScale": 2,<br>  "generated-by": "terraform",<br>  "run.googleapis.com/client-name": "terraform"<br>}</pre> | no |
| template\_labels | A set of key/value label pairs to assign to the container metadata | `map(string)` | `{}` | no |
| timeout\_seconds | Timeout for each request | `number` | `120` | no |
| traffic\_split | Managing traffic routing to the service | <pre>list(object({<br>    latest_revision = bool<br>    percent         = number<br>    revision_name   = string<br>    tag             = string<br>  }))</pre> | <pre>[<br>  {<br>    "latest_revision": true,<br>    "percent": 100,<br>    "revision_name": "v1-0-0",<br>    "tag": null<br>  }<br>]</pre> | no |
| verified\_domain\_name | List of Custom Domain Name | `list(string)` | `[]` | no |
| volume\_mounts | [Beta] Volume Mounts to be attached to the container (when using secret) | <pre>list(object({<br>    mount_path = string<br>    name       = string<br>  }))</pre> | `[]` | no |
| volumes | [Beta] Volumes needed for environment variables (when using secret) | <pre>list(object({<br>    name = string<br>    secret = set(object({<br>      secret_name = string<br>      items       = map(string)<br>    }))<br>  }))</pre> | `[]` | no |
| zone | The GCP zone to create the instance in | `string` | `"us-central1-a"` | no |

## Outputs

No output.

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
- storage.googleapis.com
- run.googleapis.com
- vpcaccess.googleapis.com
- secretmanager.googleapis.com

## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.

[iam-module]: https://registry.terraform.io/modules/terraform-google-modules/iam/google
[project-factory-module]: https://registry.terraform.io/modules/terraform-google-modules/project-factory/google
[terraform-provider-gcp]: https://www.terraform.io/docs/providers/google/index.html
[terraform]: https://www.terraform.io/downloads.html

## Security Disclosures

Please see our [security disclosure process](./SECURITY.md).
