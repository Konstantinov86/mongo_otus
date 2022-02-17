variable "project_id" {
  default = "otus-mongodb"
}

variable "region" {
  default = "europe-north1"
}

variable "zone" {
  default = "europe-north1-a"
}

variable "cluster" {
  default = "otus-mongodb"
}

variable "num_nodes" {
  default     = 3
  description = "number of gke nodes"
}

variable "machine_type" {
  default = "e2-standard-2"
}
variable "disk_size" {
  default = "30"
}

variable "GOOGLE_APPLICATION_CREDENTIALS" {
  description = "GOOGLE_APPLICATION_CREDENTIALS"
  default     = "json"
}
variable "kubernetes_min_ver" {
  default = "1.21"
}

variable "kubernetes_max_ver" {
  default = "1.21"
}