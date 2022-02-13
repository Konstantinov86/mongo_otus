variable "project_id" {
  default = "otus-mongodb"
}

variable "region" {
  default = "europe-north1"
}

variable "zone" {
  default = "europe-north1-a"
}

variable "machine_type" {
  default = "e2-small"
}
variable "disk_size" {
  default = "10"
}


variable "image_name" {
  default = "ubuntu-os-cloud/ubuntu-2004-lts"
}

variable "mongo_cfg_instances" {
description = "How many config instances"
default = "1"
}

variable "mongo_shard_count" {
  default = "2"
  description = "Number of shards"
  }

variable "mongo_shardsvr_replicas" {
  default = "3"
	description = "How many replicas per shard"
  } 
variable "mongos_instances" {
  default = "1"
	description = "How many replicas per shard"
  } 

variable "network_name" {
  default = "terraform_test"
}

variable "admin" {
  description = "OS user"
  default     = "ubuntu"
}

variable "ssh_pub_key_file" {
  description = "pub_file"
  default     = "id_rsa.pub"
}
variable "GOOGLE_APPLICATION_CREDENTIALS" {
  description = "GOOGLE_APPLICATION_CREDENTIALS"
  default     = "json"
}

