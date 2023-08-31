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
    "alloydb.googleapis.com",
    "servicenetworking.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

resource "random_id" "random_suffix" {
  byte_length = 4
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
  ip_cidr_range = "10.8.0.0/28"
  min_instances = 2
  max_instances = 3
}