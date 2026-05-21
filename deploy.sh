#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     E-Commerce DevOps Lab - Deployment Script${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

# Check prerequisites
echo -e "${BLUE}[1/5] Vérification des prérequis...${NC}"

command -v terraform >/dev/null 2>&1 || { echo -e "${RED}❌ Terraform n'est pas installé${NC}"; exit 1; }
command -v ansible-playbook >/dev/null 2>&1 || { echo -e "${RED}❌ Ansible n'est pas installé${NC}"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo -e "${RED}❌ Python3 n'est pas installé${NC}"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo -e "${RED}❌ AWS CLI n'est pas installé${NC}"; exit 1; }

if [ ! -f "lab-key" ]; then
    echo -e "${RED}❌ Fichier 'lab-key' manquant${NC}"
    exit 1
fi

chmod 600 lab-key
echo -e "${GREEN}✓ Tous les prérequis sont OK${NC}\n"

# Step 1: Terraform
echo -e "${BLUE}[2/5] Provision de l'infrastructure avec Terraform...${NC}"
cd terraform
terraform init -upgrade > /dev/null 2>&1 || true
echo -e "${GREEN}✓ Terraform initialized${NC}"

echo "Plan Terraform:"
terraform plan -out=tfplan
echo ""
read -p "Voulez-vous appliquer ce plan? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply tfplan
    echo -e "${GREEN}✓ Infrastructure provisionnée${NC}"
else
    echo -e "${RED}Déploiement annulé${NC}"
    exit 1
fi

cd ..
echo ""

# Step 2: Generate inventory
echo -e "${BLUE}[3/5] Génération de l'inventaire Ansible...${NC}"
python3 generate-inventory.py
echo -e "${GREEN}✓ Inventaire généré${NC}\n"

# Step 3: Wait for instances
echo -e "${BLUE}[4/5] Attente de la disponibilité des instances (peut prendre 3-5 minutes)...${NC}"
sleep 30
for i in {1..60}; do
    if ansible-playbook -i inventory.ini -c ssh ansible/deploy.yml -e "ansible_connection=ssh" --check > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Instances prêtes${NC}"
        break
    fi
    echo -n "."
    sleep 5
done
echo ""

# Step 4: Deploy application
echo -e "${BLUE}[5/5] Déploiement de l'application...${NC}"
ansible-playbook -i inventory.ini ansible/deploy.yml -v
echo -e "${GREEN}✓ Application déployée${NC}\n"

# Summary
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Déploiement réussi!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}\n"

echo "URLs d'accès:"
ALB_DNS=$(cd terraform && terraform output -raw alb_dns 2>/dev/null || echo "N/A")
echo -e "  ${BLUE}Load Balancer:${NC} http://$ALB_DNS"

echo ""
echo "Commandes utiles:"
echo -e "  ${BLUE}SSH sur l'instance 1:${NC}"
INSTANCE_1=$(cd terraform && terraform output -json instance_public_ips 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin)[0])" || echo "N/A")
echo "    ssh -i lab-key ec2-user@$INSTANCE_1"

echo -e "  ${BLUE}Vérifier l'application:${NC}"
echo "    curl http://$ALB_DNS"

echo -e "  ${BLUE}Voir les logs:${NC}"
echo "    ssh -i lab-key ec2-user@$INSTANCE_1 'docker-compose -f ~/app/docker-compose.yml logs -f'"

echo ""
