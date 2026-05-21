# Guide de Déploiement E-Commerce DevOps Lab

## Problèmes Corrigés

### 1. **Erreur Python - SyntaxError sur positional-only parameters**
   - **Cause**: Amazon Linux 2 avait Python 3.7, Ansible nécessite 3.8+
   - **Solution**: Installation de Python 3.11 dans user_data et configuration du playbook pour l'utiliser

### 2. **Absence de Load Balancer**
   - **Ajout**: Application Load Balancer avec Target Group et Health Checks
   - **Configuration**: ALB écoute sur le port 80 et distribue le trafic entre les 2 instances

### 3. **Configuration Ansible Incorrecte**
   - **Ancien**: Utilisait user "riri" (n'existe pas sur Amazon Linux 2)
   - **Nouveau**: Utilise "ec2-user" (utilisateur par défaut)
   - **Amélioration**: Ajout de pre_tasks pour attendre la disponibilité du système

## Étapes de Déploiement

### Étape 1: Provision Infrastructure avec Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Outputs importants:**
- `instance_public_ips`: IPs pour SSH et test
- `alb_dns`: DNS du load balancer (utiliser celui-ci en production)

### Étape 2: Générer l'Inventaire Ansible

```bash
cd ..
python3 generate-inventory.py
```

Cela mettra à jour `inventory.ini` avec les IPs réelles des instances EC2.

### Étape 3: Déployer l'Application

```bash
ansible-playbook -i inventory.ini ansible/deploy.yml -v
```

## Architecture de Déploiement

```
Internet
    ↓
[Application Load Balancer] (DNS: app-load-balancer-xxx.us-east-1.elb.amazonaws.com)
    ↓                           ↓
[EC2 Instance 1]        [EC2 Instance 2]
- Docker                - Docker
- Docker Compose        - Docker Compose
- Node.js App           - Node.js App
- Nginx                 - Nginx
- Port 80               - Port 80
```

## Vérification du Déploiement

### 1. SSH sur les instances

```bash
ssh -i lab-key ec2-user@<PUBLIC_IP>
docker ps
```

### 2. Vérifier le Load Balancer

```bash
curl http://<ALB_DNS>
```

### 3. Vérifier la santé des instances

```bash
cd terraform
terraform output alb_dns
aws elbv2 describe-target-health \
  --target-group-arn <TARGET_GROUP_ARN> \
  --region us-east-1
```

## Points d'Attention

- **SSH Key**: Assurez-vous que `lab-key` est dans le répertoire courant
- **Permissions**: Le fichier `lab-key` doit avoir les permissions 600
- **Sécurité**: Le groupe de sécurité permet le SSH de n'importe où - à restreindre en production
- **Timing**: Attendez 2-3 minutes après `terraform apply` que les instances soient prêtes
- **Logs**: Vérifiez les logs Ansible avec `-v` pour plus de détails

## Fichiers Modifiés

1. **terraform/main.tf**
   - Python 3.11 dans user_data
   - Application Load Balancer ajouté
   - Subnet privée pour ALB

2. **ansible/deploy.yml**
   - Utilisateur: ec2-user au lieu de riri
   - Pre_tasks pour attendre la disponibilité du système
   - Correction de la syntaxe Ansible
   - Yum au lieu de apt (Amazon Linux 2)

3. **inventory.ini**
   - Placeholders pour les IPs réelles
   - Configuration SSH appropriée pour ec2-user

4. **generate-inventory.py** (nouveau)
   - Script pour auto-générer l'inventaire depuis Terraform
