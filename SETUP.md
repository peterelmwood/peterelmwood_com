# VM Setup Quick Reference

## Prerequisites Checklist

- [ ] GCP account with billing enabled
- [ ] GCP project created
- [ ] gcloud CLI installed and configured
- [ ] Terraform installed (>= 1.0)
- [ ] SSH key pair generated
- [ ] docker installed locally (for application deployment)

## Setup Steps

### 1. Generate SSH Key (if needed)

```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/peterelmwood_vm
```

### 2. Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
project_id     = "your-gcp-project-id"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-email@example.com"
```

### 3. Deploy Infrastructure

```bash
./scripts/deploy_infrastructure.sh deploy
```

### 4. Verify VM

```bash
# Get VM details
./scripts/deploy_infrastructure.sh output

# SSH into VM
gcloud compute ssh ubuntu@peterelmwood-web-vm --zone=us-central1-a
```

### 5. Deploy Application

```bash
./scripts/deploy_application.sh deploy
```

### 6. Access Application

```bash
# Get the external IP
terraform output vm_external_ip

# Access at http://<EXTERNAL_IP>
```

## Common Commands

### Infrastructure Management

```bash
# Plan changes
./scripts/deploy_infrastructure.sh plan

# Show outputs
./scripts/deploy_infrastructure.sh output

# Destroy infrastructure
./scripts/deploy_infrastructure.sh destroy
```

### Application Management

```bash
# Deploy/update application
./scripts/deploy_application.sh deploy

# View logs
./scripts/deploy_application.sh logs

# Check status
./scripts/deploy_application.sh status

# Restart application
./scripts/deploy_application.sh restart

# SSH into VM
./scripts/deploy_application.sh ssh
```

### Direct Terraform Commands

```bash
cd terraform

terraform init
terraform plan
terraform apply
terraform output
terraform destroy
```

## Troubleshooting

### Cannot connect to VM

```bash
# Check VM is running
gcloud compute instances list

# Check firewall rules
gcloud compute firewall-rules list

# Test SSH
gcloud compute ssh ubuntu@peterelmwood-web-vm --zone=us-central1-a
```

### Docker issues on VM

```bash
# SSH into VM
gcloud compute ssh ubuntu@peterelmwood-web-vm --zone=us-central1-a

# Check Docker
sudo systemctl status docker
docker version
docker compose version
```

### Application issues

```bash
# Check containers
./scripts/deploy_application.sh status

# View logs
./scripts/deploy_application.sh logs

# Restart application
./scripts/deploy_application.sh restart
```

## Security Notes

- SSH password authentication is disabled
- Only key-based authentication is allowed
- Fail2ban protects against SSH brute force attacks
- UFW firewall is enabled with minimal rules
- Automatic security updates are enabled

## Cost Optimization

- Use `gcloud compute instances stop peterelmwood-web-vm --zone=us-central1-a` to stop VM when not in use
- Static IP costs apply even when VM is stopped
- Consider using `e2-micro` for development/testing (free tier eligible)

## Next Steps

1. Configure custom domain DNS to point to VM external IP
2. Set up HTTPS with Let's Encrypt
3. Configure backups for PostgreSQL database
4. Set up monitoring and alerting
5. Configure log aggregation
