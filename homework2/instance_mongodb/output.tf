output "instance_name" {
  description = " id of created instances. "
  value       = google_compute_instance.vm_instance.name
}


output "public_ip" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}
