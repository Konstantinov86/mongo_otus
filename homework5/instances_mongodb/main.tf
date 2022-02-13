
# create instances for mongo cfg
resource "google_compute_instance" "mongo_cfg_instances" {
  count = var.mongo_cfg_instances
# dynamic creation names based on function floor  and number of replics
  name = "mongodb-cfg${floor(count.index % var.mongo_cfg_instances )}"
  machine_type = var.machine_type
  allow_stopping_for_update = true
# for high avaliablity create each instance in different zone
  zone  = data.google_compute_zones.available.names[count.index]
   labels = { 
    ansible-group = "cfg"
  }
  
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

resource "google_compute_instance" "mongo_shard_instances" {
  name = "mongodb-shard${floor(count.index / var.mongo_shardsvr_replicas )}svr${count.index % var.mongo_shardsvr_replicas}"
  machine_type = var.machine_type
  zone  = data.google_compute_zones.available.names[count.index % var.mongo_shardsvr_replicas]
  count = var.mongo_shard_count * var.mongo_shardsvr_replicas
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

# create instances for mongos
resource "google_compute_instance" "mongos_instances" {
  count = var.mongos_instances
# dynamic creation names based on function floor  and number of replics
  name = "mongos${floor(count.index % var.mongo_cfg_instances )}"
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

data "google_compute_zones" "available" {
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
   ports    = ["27019","27018","27017","22"]
   } 

}
# generate inventory file for Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/hosts.tpl",
    {
     mongo_cfg_instances = google_compute_instance.mongo_cfg_instances[*].network_interface.0.access_config.0.nat_ip
     mongo_shard_instances = google_compute_instance.mongo_shard_instances[*].network_interface.0.access_config.0.nat_ip
     mongos_instances = google_compute_instance.mongos_instances[*].network_interface.0.access_config.0.nat_ip
    }
  )
  filename = "${path.module}/ansible/ansbile_hosts.cfg"
}
