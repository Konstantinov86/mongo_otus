output "mongo_cfg_instances-name" {
  description = " id of created instances. "
  value       = google_compute_instance.mongo_cfg_instances[*].name
}


output "mongo_cfg_instances_public_ip" {
  value = google_compute_instance.mongo_cfg_instances[*].network_interface.0.access_config.0.nat_ip
}

output "mongo_shard_instances-name" {
  description = " id of created instances. "
  value       = google_compute_instance.mongo_shard_instances[*].name
}

output "mongo_shard_instance_public_ip" {
  value = google_compute_instance.mongo_shard_instances[*].network_interface.0.access_config.0.nat_ip
}

output "mongos_instances-name" {
  description = " id of created instances. "
  value       = google_compute_instance.mongos_instances[*].name
}


output "mongos_instances_public_ip" {
  value = google_compute_instance.mongos_instances[*].network_interface.0.access_config.0.nat_ip
}