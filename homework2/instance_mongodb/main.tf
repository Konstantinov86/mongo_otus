resource "google_compute_instance" "vm_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  allow_stopping_for_update = true
  
  
  boot_disk {
    initialize_params {
      image = var.image_name
      size     = var.disk_size
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc_subnetwork.self_link
     access_config {
    }
  }

  metadata = {
    ssh-keys = "${var.admin}:${var.ssh_pub_key_file}"
  }
} 

resource "google_compute_network" "vpc_network" {  
  name                    = var.network_name
  auto_create_subnetworks = false
    }


resource "google_compute_subnetwork" "vpc_subnetwork" {
  name          = "mongodb-subnetwork"
  ip_cidr_range = "10.166.0.0/20"
  region        = var.region
  network       = google_compute_network.vpc_network.self_link
 
}


resource "google_compute_firewall" "default" {
  name    = "mongodb-firewall"
  network = google_compute_network.vpc_network.self_link
  description = "Creates firewall rule for mongodb"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }
  allow {
   protocol = "tcp"
   ports    = ["27019","22"]
   } 

}
