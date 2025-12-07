# VM Infrastructure Setup Guide

This directory contains Infrastructure as Code (IaC) for provisioning and managing a Google Cloud Platform (GCP) VM to host the peterelmwood.com application.

## Overview

The infrastructure includes:
- **VM Provisioning**: GCP Compute Engine instance with Ubuntu 22.04 LTS
- **Networking**: VPC network, subnet, firewall rules, and static IP
- **Software Installation**: Docker, Docker Compose, and required system packages
- **SSH Setup**: Secure SSH configuration with key-based authentication

## Prerequisites

Before deploying the infrastructure, ensure you have:

1. **GCP Account** with billing enabled
2. **GCP Project** created
3. **gcloud CLI** installed and configured ([Install Guide](https://cloud.google.com/sdk/docs/install))
4. **Terraform** installed ([Install Guide](https://www.terraform.io/downloads))
5. **SSH key pair** generated

### Generate SSH Key Pair

If you don't have an SSH key pair, generate one:

```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/peterelmwood_vm
```

## Quick Start

### 1. Configure Terraform Variables

Create a `terraform.tfvars` file from the example:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and update the following values:

```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
zone       = "us-central1-a"

ssh_user       = "ubuntu"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-email@example.com"

domain_name = "peterelmwood.com"  # Optional
```

### 2. Deploy Infrastructure

Use the deployment script to deploy the infrastructure:

```bash
# From the project root
./scripts/deploy_infrastructure.sh deploy
```

This will:
- Initialize Terraform
- Create an execution plan
- Prompt for confirmation
- Deploy the infrastructure

### 3. Access the VM

After deployment, you can SSH into the VM:

```bash
# Using the deployment script
./scripts/deploy_infrastructure.sh output

# Direct SSH using gcloud
gcloud compute ssh ubuntu@peterelmwood-web-vm --zone=us-central1-a

# Using standard SSH (after gcloud compute config-ssh)
ssh ubuntu@peterelmwood-web-vm.us-central1-a.your-project-id
```

## Infrastructure Components

### Network Configuration

- **VPC Network**: Isolated network for the application
- **Subnet**: 10.0.0.0/24 CIDR range
- **Firewall Rules**:
  - SSH (port 22): Access from anywhere
  - HTTP (port 80): Web traffic
  - HTTPS (port 443): Secure web traffic
- **Static IP**: Persistent external IP address

### VM Configuration

- **OS**: Ubuntu 22.04 LTS
- **Machine Type**: e2-medium (2 vCPU, 4 GB RAM)
- **Disk**: 30 GB persistent disk
- **Installed Software**:
  - Docker and Docker Compose
  - Git, vim, htop
  - UFW firewall
  - Fail2ban (SSH protection)
  - Google Cloud SDK
  - Automatic security updates

### Security Features

1. **SSH Hardening**:
   - Password authentication disabled
   - Root login disabled
   - Key-based authentication only

2. **Firewall**:
   - UFW enabled with minimal rules
   - Only necessary ports open

3. **Fail2ban**:
   - Protection against SSH brute force attacks
   - 3 failed attempts = 1 hour ban

4. **Automatic Updates**:
   - Unattended security updates enabled
   - Scheduled for 3:00 AM

## Application Deployment

After the VM is provisioned, deploy the application:

```bash
# Deploy the application
./scripts/deploy_application.sh deploy

# Check application status
./scripts/deploy_application.sh status

# View logs
./scripts/deploy_application.sh logs

# Restart application
./scripts/deploy_application.sh restart
```

## Manual Terraform Commands

If you prefer to use Terraform directly:

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show outputs
terraform output

# Destroy infrastructure
terraform destroy
```

## SSH Configuration

### Using gcloud SSH

The recommended way to SSH into the VM:

```bash
gcloud compute ssh ubuntu@peterelmwood-web-vm --zone=us-central1-a
```

### Using Standard SSH

Configure SSH config file for easier access:

```bash
# Add to ~/.ssh/config
Host peterelmwood-vm
    HostName <VM_EXTERNAL_IP>
    User ubuntu
    IdentityFile ~/.ssh/peterelmwood_vm
    StrictHostKeyChecking no
```

Then connect with:

```bash
ssh peterelmwood-vm
```

### SSH Key Management

The SSH public key is set in `terraform.tfvars`. To update it:

1. Update the `ssh_public_key` variable in `terraform.tfvars`
2. Run `terraform apply`

## Monitoring and Maintenance

### Check VM Status

```bash
# VM status
gcloud compute instances describe peterelmwood-web-vm --zone=us-central1-a

# SSH into VM and check services
gcloud compute ssh ubuntu@peterelmwood-web-vm --zone=us-central1-a --command="sudo systemctl status docker"
```

### View Logs

```bash
# Startup script logs
gcloud compute ssh ubuntu@peterelmwood-web-vm --zone=us-central1-a --command="sudo cat /var/log/startup-script.log"

# Cloud-init logs
gcloud compute ssh ubuntu@peterelmwood-web-vm --zone=us-central1-a --command="sudo cat /var/log/cloud-init-output.log"
```

### Update Application Environment

```bash
# SSH into VM
gcloud compute ssh ubuntu@peterelmwood-web-vm --zone=us-central1-a

# Edit environment file
sudo vim /opt/peterelmwood_com/.env.production

# Restart application
cd /opt/peterelmwood_com
docker compose restart
```

## Cost Estimation

Estimated monthly costs (us-central1):
- e2-medium VM: ~$25/month
- 30 GB persistent disk: ~$1/month
- Static IP: $3-7/month (depends on usage)
- Network egress: Variable

Total: ~$30-35/month (excluding network egress)

## Troubleshooting

### Cannot SSH into VM

```bash
# Check firewall rules
gcloud compute firewall-rules list

# Check VM is running
gcloud compute instances list

# Check SSH keys
gcloud compute instances describe peterelmwood-web-vm --zone=us-central1-a --format="get(metadata.items[0])"
```

### Docker not working

```bash
# SSH into VM and check Docker
gcloud compute ssh ubuntu@peterelmwood-web-vm --zone=us-central1-a

# Check Docker status
sudo systemctl status docker

# Check Docker logs
sudo journalctl -u docker -n 50
```

### Application not accessible

```bash
# Check firewall allows HTTP/HTTPS
gcloud compute firewall-rules list --filter="name~peterelmwood"

# Check application containers
gcloud compute ssh ubuntu@peterelmwood-web-vm --zone=us-central1-a --command="docker compose ps"
```

## Cleanup

To destroy all infrastructure:

```bash
./scripts/deploy_infrastructure.sh destroy
```

Or manually:

```bash
cd terraform
terraform destroy
```

## Additional Resources

- [GCP Compute Engine Documentation](https://cloud.google.com/compute/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Cloud-init Documentation](https://cloudinit.readthedocs.io/)
- [Docker Documentation](https://docs.docker.com/)
