#!/usr/bin/env python3
"""
Generate Ansible inventory from Terraform outputs
"""
import json
import subprocess
import sys
import os

def get_terraform_output():
    """Get Terraform outputs as JSON"""
    try:
        os.chdir('./terraform')
        result = subprocess.run(
            ['terraform', 'output', '-json'],
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error getting Terraform output: {e.stderr}", file=sys.stderr)
        return None
    finally:
        os.chdir('..')

def generate_inventory(outputs):
    """Generate inventory file from Terraform outputs"""
    if not outputs or 'instance_public_ips' not in outputs:
        print("Error: No instance_public_ips in Terraform output", file=sys.stderr)
        return False

    ips = outputs['instance_public_ips']['value']
    
    inventory_content = """[web]
"""
    
    for ip in ips:
        inventory_content += f"{ip}\n"
    
    inventory_content += """
[web:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=./lab-key
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=/usr/bin/python3.11
"""
    
    with open('inventory.ini', 'w') as f:
        f.write(inventory_content)
    
    print("✓ inventory.ini generated successfully")
    print(f"✓ Instances configured: {', '.join(ips)}")
    return True

if __name__ == '__main__':
    outputs = get_terraform_output()
    if outputs:
        generate_inventory(outputs)
    else:
        sys.exit(1)
