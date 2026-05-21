<#
AWS Cleanup Script - Remove ecommerce-prod-* resources
Usage:
  - Dry-run (default): run without -Execute to print the AWS CLI commands that would be run
  - Execute: run with -Execute to perform destructive actions

Example:
  PowerShell (dry-run): .\aws-cleanup-ecommerce-prod.ps1 -Region us-east-1
  PowerShell (execute): .\aws-cleanup-ecommerce-prod.ps1 -Region us-east-1 -Execute

IMPORTANT: Ensure your AWS CLI credentials are valid (aws configure). This script is destructive when run with -Execute.
#>
param(
    [string]$Region = "us-east-1",
    [switch]$Execute
)

function Run-Action {
    param(
        [string]$Description,
        [ScriptBlock]$Action
    )
    Write-Host "`n$Description" -ForegroundColor Cyan
    if ($Execute) {
        try {
            & $Action
        } catch {
            Write-Host "  ERROR: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  DRY-RUN: would run -> $Action"
    }
}

Write-Host "🧹 Starting AWS cleanup for ecommerce-prod resources in region $Region..." -ForegroundColor Yellow

# 1. Terminate EC2 instances whose Name tag starts with web-
$instanceQuery = aws ec2 describe-instances --region $Region --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" --output json 2>$null
if ($instanceQuery) {
    $reservations = ($instanceQuery | ConvertFrom-Json).Reservations
    $instanceIds = @()
    foreach ($reservation in $reservations) {
        foreach ($instance in $reservation.Instances) {
            $nameTag = ($instance.Tags | Where-Object { $_.Key -eq 'Name' } | Select-Object -ExpandProperty Value -First 1)
            if ($nameTag -and $nameTag -match '^(web-|ecommerce-prod-web-)') {
                $instanceIds += $instance.InstanceId
            }
        }
    }

    if ($instanceIds.Count -gt 0) {
        foreach ($id in $instanceIds | Sort-Object -Unique) {
            Run-Action "1️⃣ Terminating EC2 instance: $id" { aws ec2 terminate-instances --instance-ids $id --region $Region }
        }
    } else {
        Write-Host "1️⃣ No matching EC2 instances found for Name prefix web- or ecommerce-prod-web-" -ForegroundColor Green
    }
} else {
    Write-Host "1️⃣ No EC2 instances returned by AWS CLI" -ForegroundColor Green
}

# Wait briefly for terminations (only if executing)
if ($Execute) { Write-Host "  Waiting 30s for terminations..."; Start-Sleep -Seconds 30 }

# 2. Delete Application Load Balancer (named ecommerce-prod-alb)
$albName = "ecommerce-prod-alb"
$albArn = (aws elbv2 describe-load-balancers --region $Region --names $albName --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>$null) 
if ($albArn -and $albArn -ne 'None') {
    Run-Action "2️⃣ Deleting ALB: $albArn" { aws elbv2 delete-load-balancer --load-balancer-arn $albArn --region $Region }
} else { Write-Host "2️⃣ ALB not found (OK)" -ForegroundColor Green }

if ($Execute) { Start-Sleep -Seconds 10 }

# 3. Delete Target Groups (ecommerce-prod-tg)
$tgName = "ecommerce-prod-tg"
$tgArn = (aws elbv2 describe-target-groups --region $Region --names $tgName --query 'TargetGroups[0].TargetGroupArn' --output text 2>$null)
if ($tgArn -and $tgArn -ne 'None') {
    Run-Action "3️⃣ Deleting target group: $tgArn" { aws elbv2 delete-target-group --target-group-arn $tgArn --region $Region }
} else { Write-Host "3️⃣ Target group not found (OK)" -ForegroundColor Green }

# 4. Delete Security Groups
$sgNames = @("ecommerce-prod-alb-sg", "ecommerce-prod-ec2-sg")
foreach ($sgName in $sgNames) {
    $sgId = (aws ec2 describe-security-groups --region $Region --filters "Name=group-name,Values=$sgName" --query 'SecurityGroups[0].GroupId' --output text 2>$null)
    if ($sgId -and $sgId -ne 'None') {
        Run-Action "4️⃣ Deleting security group: $sgName ($sgId)" { aws ec2 delete-security-group --group-id $sgId --region $Region }
    } else {
        Write-Host "4️⃣ Security group '$sgName' not found (OK)" -ForegroundColor Green
    }
}

# 5. Delete IAM Instance Profile and Role
$profileName = "ecommerce-prod-app-profile"
$roleName = "ecommerce-prod-app-role"
# Remove role from instance profile if exists
$instanceProfile = (aws iam list-instance-profiles-for-role --role-name $roleName --query 'InstanceProfiles[0].InstanceProfileName' --output text 2>$null)
if ($instanceProfile -and $instanceProfile -ne 'None') {
    Run-Action "5️⃣ Removing role $roleName from instance profile $instanceProfile" { aws iam remove-role-from-instance-profile --instance-profile-name $instanceProfile --role-name $roleName }
}
# Delete instance profile
$profileCheck = (aws iam get-instance-profile --instance-profile-name $profileName --query 'InstanceProfile.InstanceProfileName' --output text 2>$null)
if ($profileCheck -and $profileCheck -ne 'None') {
    Run-Action "5️⃣ Deleting instance profile: $profileName" { aws iam delete-instance-profile --instance-profile-name $profileName }
} else { Write-Host "5️⃣ Instance profile not found (OK)" -ForegroundColor Green }

# Delete IAM role
$roleCheck = (aws iam get-role --role-name $roleName --query 'Role.RoleName' --output text 2>$null)
if ($roleCheck -and $roleCheck -ne 'None') {
    Write-Host "6️⃣ Detaching inline policies from role: $roleName"
    $policies = (aws iam list-role-policies --role-name $roleName --query 'PolicyNames[]' --output text 2>$null)
    if ($policies) {
        $policies -split '\s+' | ForEach-Object {
            if ($_ -ne "") { Run-Action "    Deleting policy: $_" { aws iam delete-role-policy --role-name $roleName --policy-name $_ } }
        }
    }
    Run-Action "6️⃣ Deleting role: $roleName" { aws iam delete-role --role-name $roleName }
} else { Write-Host "6️⃣ IAM role not found (OK)" -ForegroundColor Green }

Write-Host "`n✅ Cleanup script completed (dry-run mode unless -Execute was specified)." -ForegroundColor Green
