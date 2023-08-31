/**
 * Copyright 2023 Google LLC
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

resource "google_compute_global_address" "private_ip_alloc" {
  project       = module.project.project_id
  name          = "${var.environment}-${random_id.random_suffix.hex}"
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}


resource "google_alloydb_cluster" "default" {
  cluster_id   = "${var.environment}-${random_id.random_suffix.hex}"
  location     = var.region
  network      = google_compute_network.vpc_network.id
  display_name = "${var.environment}-${random_id.random_suffix.hex}"
  project      = module.project.project_id
}

resource "google_alloydb_instance" "primary" {
  cluster       = google_alloydb_cluster.default.name
  instance_id   = "${var.environment}-${random_id.random_suffix.hex}-primary"
  instance_type = "PRIMARY"
  display_name  = "${var.environment}-${random_id.random_suffix.hex}-primary"
  machine_config {
    cpu_count = var.machine_cpu_count
  }

  depends_on = [
    google_compute_global_address.private_ip_alloc,
    google_service_networking_connection.vpc_connection
  ]
}


resource "google_service_networking_connection" "vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}