# 🚀 Quick Reference Card

## 3-Step Deployment (10-15 minutes)

### Step 1️⃣: Terraform (3-5 min)
```bash
cd terraform
terraform init
terraform apply
# Note the ALB DNS and instance IPs
```

### Step 2️⃣: Generate Inventory (30 sec)
```bash
cd ..
python3 generate-inventory.py
```

### Step 3️⃣: Deploy App (5-10 min)
```bash
ansible-playbook -i inventory.ini ansible/deploy.yml -v
```

---

## Quick Verification

| Test | Command |
|------|---------|
| **SSH Access** | `ssh -i lab-key ec2-user@<IP>` |
| **Docker Status** | `docker ps` |
| **App URL** | `curl http://<ALB_DNS>` |
| **Health Check** | `aws elbv2 describe-target-health ...` |
| **Logs** | `docker-compose -f ~/app logs -f` |

---

## Key Files

| File | Purpose |
|------|---------|
| `terraform/main.tf` | Infrastructure with Python 3.11 + ALB |
| `ansible/deploy.yml` | App deployment on ec2-user |
| `generate-inventory.py` | Auto-generate inventory |
| `inventory.ini` | Dynamic hosts config |
| `DEPLOYMENT_GUIDE.md` | 📘 Full guide |
| `TROUBLESHOOTING.md` | 🐛 Problem solving |

---

## What Was Fixed

✅ **Python 3.11** - Fixes SyntaxError  
✅ **ec2-user** - Correct Amazon Linux 2 user  
✅ **Load Balancer** - Distribution de charge  
✅ **Dynamic Inventory** - Auto-generated from Terraform  
✅ **Health Checks** - Pre_tasks for readiness  

---

## Architecture

```
ALB (app-load-balancer-xxx.us-east-1.elb.amazonaws.com)
 ├─ Instance 1 (Docker + App + Nginx)
 └─ Instance 2 (Docker + App + Nginx)
```

---

## Common Issues

| Issue | Solution |
|-------|----------|
| Timeout connecting | Wait 3 min after terraform |
| Permission denied | `chmod 600 lab-key` |
| 502 error | Check nginx logs: `docker logs <nginx>` |
| No inventory | Run `python3 generate-inventory.py` |
| Python error | Python 3.11 now in user_data |

---

## Files to Review

1. `SUMMARY.md` - Overview of all changes
2. `DEPLOYMENT_GUIDE.md` - Step-by-step guide
3. `TROUBLESHOOTING.md` - Error solutions
4. `DEPLOYMENT_CHECKLIST.md` - Detailed checklist

---

**Ready?** → Start with Step 1 above! 🎯
