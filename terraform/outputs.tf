output "vm_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.web_vm.name
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.web_vm.network_interface[0].network_ip
}

output "vm_external_ip" {
  description = "External IP address of the VM"
  value       = google_compute_address.static_ip.address
}

output "vm_zone" {
  description = "Zone where the VM is deployed"
  value       = google_compute_instance.web_vm.zone
}

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "ssh_command" {
  description = "Command to SSH into the VM"
  value       = "gcloud compute ssh ${var.ssh_user}@${google_compute_instance.web_vm.name} --zone=${var.zone}"
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${google_compute_address.static_ip.address}"
}
