resource "yandex_mdb_mongodb_cluster" "mongodb" {
  name                = "mongodb"
  environment         = "PRODUCTION"
  network_id          = yandex_vpc_network.net.id
  security_group_ids  = [ yandex_vpc_security_group.mongodb.id ]
  deletion_protection = false

  cluster_config {
    version = "4.4"
  }

  database {
    name = "stocks"
  }

  user {
    name     = "mongo"
    password = "password"
    permission {
      database_name = "stocks"
    }
  }

  resources {
    resource_preset_id = "s2.micro"
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  host {
    zone_id   = "ru-central1-c"
    subnet_id = yandex_vpc_subnet.mysubnet.id
  }
}

resource "yandex_vpc_network" "net" {
  name = "net"
}

resource "yandex_vpc_security_group" "mongodb" {
  name       = "mongodb"
  network_id = yandex_vpc_network.net.id

  ingress {
    description    = "MongoDB"
    port           = 27018
    protocol       = "TCP"
    v4_cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "yandex_vpc_subnet" "mysubnet" {
  name           = "mysubnet"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.5.0.0/24"]
}

