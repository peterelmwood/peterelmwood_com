# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
  description             = "VPC network for peterelmwood.com application"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  description   = "Subnet for peterelmwood.com VM instances"
}

# Firewall rule for SSH
resource "google_compute_firewall" "ssh" {
  name    = "${var.network_name}-allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]

  description = "Allow SSH access from anywhere"
}

# Firewall rule for HTTP
resource "google_compute_firewall" "http" {
  name    = "${var.network_name}-allow-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]

  description = "Allow HTTP access from anywhere"
}

# Firewall rule for HTTPS
resource "google_compute_firewall" "https" {
  name    = "${var.network_name}-allow-https"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]

  description = "Allow HTTPS access from anywhere"
}

# Static external IP
resource "google_compute_address" "static_ip" {
  name        = "${var.vm_name}-static-ip"
  region      = var.region
  description = "Static external IP for ${var.vm_name}"
}

# Cloud-init configuration for VM setup
locals {
  cloud_init = templatefile("${path.module}/cloud-init.yaml", {
    ssh_user = var.ssh_user
    region   = var.region
  })
}

# VM Instance
resource "google_compute_instance" "web_vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["ssh", "http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  metadata = {
    ssh-keys  = "${var.ssh_user}:${var.ssh_public_key}"
    user-data = local.cloud_init
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Log startup script execution
    exec > >(tee /var/log/startup-script.log)
    exec 2>&1
    
    echo "Starting VM initialization..."
    
    # Wait for cloud-init to complete
    cloud-init status --wait
    
    echo "VM initialization complete"
  EOF

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    application = "peterelmwood-com"
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  allow_stopping_for_update = true

  lifecycle {
    ignore_changes = [
      metadata_startup_script,
    ]
  }
}
