variable "token" {
  type        = string
  default     = ""
  description = "Yandex.Cloud IAM token"
}

variable "cloud-id" {
  type    = string
  default = "<cloud-id>"
}
variable "folder-id" {
  type    = string
  default = "<folder_id>"
}
variable "zone" {
  default = "ru-central1-c"
}
