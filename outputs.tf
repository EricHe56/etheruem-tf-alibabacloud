output "this_instance_ids" {
  description = "The instance ids."
  value       = module.ecs.this_instance_id
}

output "this_instance_names" {
  description = "The instance names."
  value       = module.ecs.this_instance_name
}

output "this_instance_private_ip" {
  description = "The instance private ip."
  value       = module.ecs.this_private_ip
}

output "this_instance_public_ip" {
  description = "The instance public ip."
  value       = module.ecs.this_public_ip
}

output "this_nas_mount_target_domain" {
  value = module.file_system.this_mount_target_domain
}

output "this_nas_file_system_id"{
  value = module.file_system.this_file_system_id
}
