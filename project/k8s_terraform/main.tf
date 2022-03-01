resource "google_container_cluster" "primary" {
  name     = var.cluster
  location = var.zone
  min_master_version = var.kubernetes_min_ver

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  # other settings...
  master_auth {
        # Setting an empty username and password explicitly disables basic auth
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name               = "${google_container_cluster.primary.name}-node-pool"
  cluster            = var.cluster
  location           = var.zone
  node_count = var.num_nodes

 

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      env = var.project_id
    }
  }
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = "10.10.0.0/24"

}
resource "google_compute_firewall" "default" {
  name    = "mongodb-firewall"
  network = google_compute_network.vpc.self_link
  description = "Creates firewall rule for mongodb"
  source_ranges = ["0.0.0.0/0"]

  allow {
   protocol = "tcp"
   ports    = ["80","443","30001"]
   } 

}