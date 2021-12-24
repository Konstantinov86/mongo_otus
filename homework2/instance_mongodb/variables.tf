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
  default = "e2-medium"
}
variable "disk_size" {
  default = "30"
}

variable "instance_name" {
  default = "terraform"
}

variable "image_name" {
  default = "ubuntu-os-cloud/ubuntu-2004-lts"
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
