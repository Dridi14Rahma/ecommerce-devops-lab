# 📋 Checklist de Déploiement

## ✅ Avant de Commencer

- [ ] Fichier `lab-key` présent dans le répertoire racine
- [ ] `lab-key` a les permissions correctes (600)
- [ ] AWS CLI configuré avec les bonnes credentials
- [ ] Terraform installé (v1.0+)
- [ ] Ansible installé (v2.9+)
- [ ] Python 3.8+ installé localement

## 🚀 Phase 1: Provision (Terraform)

```bash
cd terraform
terraform init
terraform plan          # Revoir le plan
terraform apply         # Confirmer avec 'yes'
```

**À Vérifier:**
- [ ] 2 instances EC2 créées
- [ ] Load Balancer créé
- [ ] Groupes de sécurité configurés
- [ ] Outputs affichent les IPs et le DNS du LB

**Capture d'écran des Outputs:**
```
instance_public_ips = ["18.207.103.229", "100.52.207.6"]
alb_dns = "app-load-balancer-xxx.us-east-1.elb.amazonaws.com"
```

## 🚀 Phase 2: Inventaire (Generate)

```bash
cd ..
python3 generate-inventory.py
cat inventory.ini              # Vérifier les IPs
```

**À Vérifier:**
- [ ] inventory.ini contient les 2 IPs
- [ ] Les IPs correspondent à celles de Terraform
- [ ] Configuration SSH correcte

## 🚀 Phase 3: Déploiement (Ansible)

```bash
# Test de connectivité
ansible all -i inventory.ini -m ping

# Déploiement réel
ansible-playbook -i inventory.ini ansible/deploy.yml -v
```

**À Vérifier:**
- [ ] Ansible se connecte aux instances
- [ ] Setup gathering réussit
- [ ] Tous les tasks complètent avec [ok]
- [ ] Aucun FAILED dans le PLAY RECAP

**Exemple de succès:**
```
PLAY RECAP *****
18.207.103.229  : ok=12  changed=5   unreachable=0   failed=0
100.52.207.6    : ok=12  changed=5   unreachable=0   failed=0
```

## ✅ Phase 4: Vérification Post-Déploiement

### Test 1: SSH et Docker
```bash
ssh -i lab-key ec2-user@18.207.103.229
docker ps
exit
```

**À Vérifier:**
- [ ] Connexion SSH réussit
- [ ] Les conteneurs Docker tournent (mongodb, app, nginx)
- [ ] Pas d'erreurs Docker

### Test 2: Application via Load Balancer
```bash
ALB_DNS=$(cd terraform && terraform output -raw alb_dns)
curl http://$ALB_DNS
```

**À Vérifier:**
- [ ] Requête retourne HTTP 200
- [ ] Page HTML s'affiche
- [ ] Pas d'erreur 502/503

### Test 3: Health Check du Load Balancer
```bash
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:... \
  --region us-east-1
```

**À Vérifier:**
- [ ] Les 2 instances sont "healthy"
- [ ] État = "InService"

## 🛠️ Dépannage Rapide

### Les instances ne répondent pas à Ansible?
```bash
# 1. Vérifier la connectivité SSH
ssh -i lab-key ec2-user@<IP> echo "OK"

# 2. Attendre plus longtemps (les instances mettent 3-5 min à démarrer)
sleep 180
ansible-playbook -i inventory.ini ansible/deploy.yml

# 3. Vérifier les logs de l'instance
aws ec2 get-console-output --instance-ids i-xxxxx --region us-east-1
```

### Docker containers ne démarrent pas?
```bash
# SSH sur l'instance
ssh -i lab-key ec2-user@<IP>

# Vérifier les logs
docker-compose -f ~/app/docker-compose.yml logs

# Relancer les conteneurs
cd ~/app && docker-compose up -d
```

### Load Balancer retourne 502?
```bash
# 1. Vérifier que Nginx écoute sur le port 80
ssh -i lab-key ec2-user@<IP> docker ps | grep nginx

# 2. Vérifier la configuration Nginx
docker exec <nginx-container> cat /etc/nginx/conf.d/default.conf

# 3. Vérifier les logs Nginx
docker exec <nginx-container> tail -f /var/log/nginx/error.log
```

## 📊 Monitoring et Logs

### Logs Ansible (lors du déploiement)
```bash
ansible-playbook -i inventory.ini ansible/deploy.yml -vvv
```

### Logs Docker (sur les instances)
```bash
ssh -i lab-key ec2-user@<IP>
docker-compose -f ~/app/docker-compose.yml logs -f app
docker-compose -f ~/app/docker-compose.yml logs -f mongodb
docker-compose -f ~/app/docker-compose.yml logs -f nginx
```

### Logs AWS (Load Balancer)
```bash
# Vérifier les target groups
aws elbv2 describe-target-groups --region us-east-1

# Vérifier la santé des instances
aws elbv2 describe-target-health --target-group-arn <ARN> --region us-east-1
```

## 🧹 Nettoyage (Si Besoin)

```bash
# Détruire l'infrastructure
cd terraform
terraform destroy

# Confirmer avec 'yes'
```

## 📝 Notes Importantes

1. **Timing**: Après terraform apply, attendre **2-3 minutes** avant de lancer Ansible
2. **SSH Key**: S'assurer que `lab-key` a les permissions **600** (`chmod 600 lab-key`)
3. **Python**: L'erreur SyntaxError sur le positional-only parameter est résolue par Python 3.11
4. **Load Balancer**: Les health checks prennent **1-2 minutes** pour marquer les instances comme "healthy"
5. **URL Application**: Utiliser le **DNS du Load Balancer**, pas l'IP directe

## ✨ Succès!

Si toutes les vérifications passent, félicitations! 🎉
Votre application e-commerce est déployée sur 2 instances avec un load balancer.

---

**Questions?** Consultez:
- DEPLOYMENT_GUIDE.md - Guide détaillé
- TROUBLESHOOTING.md - Résolution des problèmes
