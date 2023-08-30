/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module "project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 11.0"

  name              = "${var.project_name}-${var.environment}-${random_id.random_suffix.hex}"
  random_project_id = "false"
  org_id            = var.org_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account

  activate_apis = [
    "iam.googleapis.com",
    "run.googleapis.com",
    "vpcaccess.googleapis.com",
    "storage.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

resource "random_id" "random_suffix" {
  byte_length = 4
}

resource "google_service_account" "main" {
  project      = module.project.project_id
  account_id   = "${var.environment}-${random_id.random_suffix.hex}"
  display_name = "${var.environment}${random_id.random_suffix.hex}"
}


resource "google_cloud_run_service" "main" {
  provider                   = google-beta
  name                       = "${var.environment}-${random_id.random_suffix.hex}"
  location                   = var.region
  project                    = module.project.project_id
  autogenerate_revision_name = var.generate_revision_name

  metadata {
    labels      = var.service_labels
    annotations = var.service_annotations
  }

  template {
    spec {
      containers {
        image   = var.image
        command = var.container_command
        args    = var.argument

        ports {
          name           = var.ports["name"]
          container_port = var.ports["port"]
        }

        resources {
          limits   = var.limits
          requests = var.requests
        }

        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.value["name"]
            value = env.value["value"]
          }
        }

        dynamic "env" {
          for_each = var.env_secret_vars
          content {
            name = env.value["name"]
            dynamic "value_from" {
              for_each = env.value.value_from
              content {
                secret_key_ref {
                  name = value_from.value.secret_key_ref["name"]
                  key  = value_from.value.secret_key_ref["key"]
                }
              }
            }
          }
        }

        dynamic "volume_mounts" {
          for_each = var.volume_mounts
          content {
            name       = volume_mounts.value["name"]
            mount_path = volume_mounts.value["mount_path"]
          }
        }
      }                                                 // container
      container_concurrency = var.container_concurrency # maximum allowed concurrent requests 0,1,2-N
      timeout_seconds       = var.timeout_seconds       # max time instance is allowed to respond to a request
      service_account_name  = google_service_account.main.email

      dynamic "volumes" {
        for_each = var.volumes
        content {
          name = volumes.value["name"]
          dynamic "secret" {
            for_each = volumes.value.secret
            content {
              secret_name = secret.value["secret_name"]
              items {
                key  = secret.value.items["key"]
                path = secret.value.items["path"]
              }
            }
          }
        }
      }

    } // spec
    metadata {
      labels      = var.template_labels
      annotations = { "run.googleapis.com/client-name"   = "terraform",
                    "generated-by"                     = "terraform",
                    "autoscaling.knative.dev/maxScale" = 3,
                    "autoscaling.knative.dev/minScale" = 2,
                    "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.id
      }
      name        = var.generate_revision_name ? null : "${var.environment}-${random_id.random_suffix.hex}-${var.traffic_split[0].revision_name}"
    } // metadata
  }   // template

  # User can generate multiple scenarios here
  # Providing 50-50 split with revision names
  # latest_revision is true only when revision_name is not provided, else its false
  dynamic "traffic" {
    for_each = var.traffic_split
    content {
      percent         = lookup(traffic.value, "percent", 100)
      latest_revision = lookup(traffic.value, "latest_revision", null)
      revision_name   = lookup(traffic.value, "latest_revision") ? null : lookup(traffic.value, "revision_name")
      tag             = lookup(traffic.value, "tag", null)
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["client.knative.dev/user-image"],
      metadata[0].annotations["run.googleapis.com/client-name"],
      metadata[0].annotations["run.googleapis.com/client-version"],
      metadata[0].annotations["run.googleapis.com/operation-id"],
      template[0].metadata[0].annotations["client.knative.dev/user-image"],
      template[0].metadata[0].annotations["run.googleapis.com/client-name"],
      template[0].metadata[0].annotations["run.googleapis.com/client-version"],
    ]
  }
}

resource "google_cloud_run_domain_mapping" "domain_map" {
  for_each = toset(var.verified_domain_name)
  provider = google-beta
  location = var.region
  name     = each.value
  project  = module.project.project_id

  metadata {
    labels      = var.domain_map_labels
    annotations = var.domain_map_annotations
    namespace   = module.project.project_id
  }

  spec {
    route_name       = google_cloud_run_service.main.name
    force_override   = var.force_override
    certificate_mode = var.certificate_mode
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["run.googleapis.com/operation-id"],
    ]
  }
}

resource "google_cloud_run_service_iam_member" "authorize" {
  count    = length(var.members)
  location = var.region
  project  = module.project.project_id
  service  = google_cloud_run_service.main.name
  role     = "roles/run.invoker"
  member   = var.members[count.index]
}



resource "google_compute_network" "vpc_network" {
  project                 = module.project.project_id
  name                    = "${var.environment}-${random_id.random_suffix.hex}"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "workbench" {
  project                  = module.project.project_id
  name                     = "${var.environment}-${random_id.random_suffix.hex}-workbench"
  ip_cidr_range            = "10.2.0.0/16"
  region                   = var.region
  private_ip_google_access = true
  network                  = google_compute_network.vpc_network.name

}


resource "google_compute_firewall" "egress" {
  project            = module.project.project_id
  name               = "deny-all-egress"
  description        = "Block all egress ${var.environment}"
  network            = google_compute_network.vpc_network.name
  priority           = 1000
  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  deny {
    protocol = "all"
  }
}

resource "google_compute_firewall" "ingress" {
  project       = module.project.project_id
  name          = "deny-all-ingress"
  description   = "Block all Ingress ${var.environment}"
  network       = google_compute_network.vpc_network.name
  priority      = 1000
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  deny {
    protocol = "all"
  }
}

resource "google_compute_firewall" "googleapi_egress" {
  project            = module.project.project_id
  name               = "allow-googleapi-egress"
  description        = "Allow connectivity to storage ${var.environment}"
  network            = google_compute_network.vpc_network.name
  priority           = 999
  direction          = "EGRESS"
  destination_ranges = ["199.36.153.8/30"]
  allow {
    protocol = "tcp"
    ports    = ["443", "8080", "80"]
  }
}

resource "google_vpc_access_connector" "connector" {
  provider      = google-beta
  name          = "${var.environment}-${random_id.random_suffix.hex}"
  project       = module.project.project_id
  region        = var.region
  network       = google_compute_network.vpc_network.name
  ip_cidr_range            = "10.8.0.0/28"
  min_instances  = 2
  max_instances  = 3
}

resource "google_secret_manager_secret" "default" {
  project       = module.project.project_id
  secret_id = "${var.environment}-${random_id.random_suffix.hex}"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_iam_member" "default" {
  project       = module.project.project_id
  secret_id = google_secret_manager_secret.default.id
  role      = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${google_service_account.main.email}"
  depends_on = [google_secret_manager_secret.default]
}
