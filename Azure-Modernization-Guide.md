# Azure Application Modernization Complete Guide for College Students

## Project Overview
This guide will help you build a cloud-native application modernization architecture on Azure using the most cost-effective services. The project demonstrates strangler fig pattern migration with load balancing and traffic routing.

## Estimated Monthly Cost: $25-35 USD
*Cost breakdown at end of guide*

---

## Phase 1: Create the Foundation (Virtual Network)

### Step 1: Login to Azure Portal
1. Go to https://portal.azure.com
2. Sign in with your Azure account (use student account for credits)

### Step 2: Create a Resource Group
1. Click "Create a resource" → Search "Resource Group"
2. Click "Create"
3. **Name**: `rg-stranglerfig-project`
4. **Region**: East US (typically cheapest)
5. Click "Review + create" → "Create"

**Why this step**: Resource groups organize all your Azure resources for easy management and billing tracking.

### Step 3: Create Virtual Network
1. Go to "Create a resource" → Search "Virtual Network"
2. Click "Create"
3. **Basics tab**:
   - Resource group: `rg-stranglerfig-project`
   - Name: `vnet-stranglerfig`
   - Region: East US

4. **IP Addresses tab**:
   - IPv4 address space: `10.0.0.0/16`
   - Delete the default subnet
   - Add 3 subnets:
     - Subnet 1: Name: `subnet-vmss-1`, Address range: `10.0.1.0/24`
     - Subnet 2: Name: `subnet-vmss-2`, Address range: `10.0.2.0/24`
     - Subnet 3: Name: `subnet-appgateway`, Address range: `10.0.3.0/24`

5. Click "Review + create" → "Create"

**Why this step**: Virtual networks provide secure communication between Azure resources and isolate traffic.

---

## Phase 2: Create the Database

### Step 4: Create Azure Database for MySQL
1. Go to "Create a resource" → Search "Azure Database for MySQL"
2. Select "Flexible server" (more cost-effective)
3. Click "Create"
4. **Basics tab**:
   - Resource group: `rg-stranglerfig-project`
   - Server name: `mysql-stranglerfig-[yourname]` (must be unique)
   - Region: East US
   - MySQL version: 8.0
   - Workload type: "For development or hobby projects" (cheapest)
   - Compute + storage: Click "Configure server"
     - Select "Burstable" → "B1ms" (cheapest option)
     - Storage: Keep at 20 GiB
   - Admin username: `adminuser`
   - Password: Create a strong password (save this!)

5. **Networking tab**:
   - Connectivity method: "Public access"
   - Allow public access: "Yes"
   - Add firewall rule:
     - Name: `AllowAll`
     - Start IP: `0.0.0.0`
     - End IP: `255.255.255.255`
   - Check "Allow access to Azure services"

6. Click "Review + create" → "Create"

**Important**: Note down:
- Server name (full URL will be: `[servername].mysql.database.azure.com`)
- Admin username
- Password
- Database name: Create one called `mydatabase` after deployment

**Why this step**: Managed MySQL database eliminates server maintenance and provides automatic backups.

---

## Phase 3: Deploy Virtual Machine Scale Sets

### Step 5: Create First VM Scale Set (webapp-sp)
1. Go to "Create a resource" → Search "Virtual machine scale set"
2. Click "Create"
3. **Basics tab**:
   - Resource group: `rg-stranglerfig-project`
   - Name: `vmss-webapp-sp`
   - Region: East US
   - Availability zone: "No infrastructure redundancy required" (cheaper)
   - Orchestration mode: "Uniform"
   - Image: "Ubuntu Server 20.04 LTS - Gen2"
   - Size: Click "See all sizes" → Select "B1s" (cheapest - 1 vCPU, 1 GiB RAM)
   - Username: `azureuser`
   - Authentication: "Password" (create and save password)

4. **Disks tab**:
   - OS disk type: "Standard HDD" (cheapest)

5. **Networking tab**:
   - Virtual network: `vnet-stranglerfig`
   - Subnet: `subnet-vmss-1`
   - Check "Use a load balancer"
   - Load balancing options: "Azure load balancer"
   - Select a load balancer: "Create a load balancer"
     - Name: `lb-webapp`
     - Type: "Public"
     - SKU: "Basic" (free tier)
     - Public IP: Create new → Name: `pip-webapp`

6. **Scaling tab**:
   - Initial instance count: 1 (start small)
   - Scaling policy: "Manual"

7. **Management tab**:
   - Enable auto-shutdown: Check this and set to 7 PM (saves money)

8. **Advanced tab** - Custom data (paste this script):

```bash
#!/bin/bash 
APP_NAME=LiftShift-Application
apt update -y && apt -y install python3-pip zip
cd /opt
wget https://d6opu47qoi4ee.cloudfront.net/loadbalancer/simuapp-v1.zip
unzip simuapp-v1.zip
rm -f simuapp-v1.zip
sed -i "s=MOD_APPLICATION_NAME=$APP_NAME=g" templates/index.html
pip3 install -r requirements.txt
nohup python3 simu_app.py >> application.log 2>&1 &
```

9. Click "Review + create" → "Create"

**Why this step**: VMSS provides auto-scaling capabilities and distributes load across multiple VM instances.

### Step 6: Create Second VM Scale Set (Employees-sp)
Repeat step 5 with these changes:
- Name: `vmss-employees-sp`
- Subnet: `subnet-vmss-2`
- Load balancer name: `lb-employees`
- Public IP name: `pip-employees`
- Custom data: Use this script (replace `[YOUR_DB_PASSWORD]` and `[YOUR_MYSQL_SERVER_NAME]`):

```bash
#!/bin/bash
# Define variables
DB_USER=adminuser
DB_PASS=[YOUR_DB_PASSWORD]
DB_NAME=mydatabase
URL=[YOUR_MYSQL_SERVER_NAME].mysql.database.azure.com

# Update packages and install required software
apt-get update
apt-get install -y apache2 php mysql-client
cd /opt
mkdir crud
cd /opt/crud

# Download the PHP application code
wget https://d6opu47qoi4ee.cloudfront.net/labs/option3/index.php

# Update the database connection details
sed -i "s/DB_USER/$DB_USER/g" index.php
sed -i "s/DB_PASS/$DB_PASS/g" index.php
sed -i "s/DB_NAME/$DB_NAME/g" index.php
sed -i "s/DBServer/$URL/g" index.php
cp index.php /var/www/html

# Create the database tables
wget https://d6opu47qoi4ee.cloudfront.net/employees.sql
mysql -h $URL -u $DB_USER -p$DB_PASS $DB_NAME < employees.sql

# Update Apache configuration
sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' /etc/apache2/mods-enabled/dir.conf

# Restart Apache
systemctl restart apache2
```

### Step 7: Configure Network Security Groups
1. Go to Resource Groups → `rg-stranglerfig-project`
2. Find and click on each NSG (network security group)
3. Add inbound rule:
   - Source: "Any"
   - Destination port ranges: 80
   - Protocol: "TCP"
   - Action: "Allow"
   - Priority: 100
   - Name: `Allow_HTTP`

**Why this step**: Security groups act as virtual firewalls controlling network traffic.

---

## Phase 4: Deploy Azure App Service

### Step 8: Create App Service
1. Go to "Create a resource" → Search "Web App"
2. Click "Create"
3. **Basics tab**:
   - Resource group: `rg-stranglerfig-project`
   - Name: `app-stranglerfig-[yourname]` (must be unique)
   - Publish: "Code"
   - Runtime stack: "PHP 8.0"
   - Operating System: "Linux"
   - Region: East US

4. **Pricing plans**:
   - Linux Plan: Create new → `plan-stranglerfig`
   - SKU and size: Click "Change size" → Dev/Test tab → Select "F1 (Free)"

5. Click "Review + create" → "Create"

### Step 9: Deploy Code to App Service
1. After creation, go to your App Service
2. Left menu → "Deployment Center"
3. Source: "Local Git"
4. Save
5. Note the Git Clone URI
6. Download the PHP code and modify database connection
7. Push code via Git

**Why this step**: App Service provides serverless hosting with automatic scaling and built-in CI/CD.

---

## Phase 5: Create Traffic Manager

### Step 10: Create Traffic Manager Profile
1. Go to "Create a resource" → Search "Traffic Manager profile"
2. Click "Create"
3. Name: `tm-stranglerfig`
4. Routing method: "Weighted"
5. Resource group: `rg-stranglerfig-project`
6. Click "Create"

### Step 11: Configure Traffic Manager Endpoints
1. Go to your Traffic Manager profile
2. Settings → "Endpoints"
3. Add endpoint 1:
   - Type: "Azure endpoint"
   - Name: `employees-vmss`
   - Target resource type: "Public IP address"
   - Target resource: `pip-employees`
   - Weight: 90

4. Add endpoint 2:
   - Type: "Azure endpoint"
   - Name: `app-service`
   - Target resource type: "App Service"
   - Target resource: Your App Service
   - Weight: 10

**Why this step**: Traffic Manager enables global load balancing and implements the strangler fig pattern by gradually shifting traffic.

---

## Phase 6: Create Application Gateway

### Step 12: Create Application Gateway
1. Go to "Create a resource" → Search "Application Gateway"
2. **Basics tab**:
   - Resource group: `rg-stranglerfig-project`
   - Name: `appgw-stranglerfig`
   - Region: East US
   - Tier: "Standard_v2"
   - Enable autoscaling: "No"
   - Instance count: 1
   - SKU size: "Standard_v2"
   - Virtual network: `vnet-stranglerfig`
   - Subnet: `subnet-appgateway`

3. **Frontends tab**:
   - Frontend IP: "Public"
   - Public IP: Create new → `pip-appgateway`

4. **Backends tab**:
   - Add backend pool 1:
     - Name: `pool-webapp`
     - Add targets: IP address or FQDN
     - Target: Get IP from webapp VMSS instances
   - Add backend pool 2:
     - Name: `pool-traffic-manager`
     - Target: FQDN
     - Target: `tm-stranglerfig.trafficmanager.net`

5. **Configuration tab**:
   - Add routing rule:
     - Name: `rule-main`
     - Priority: 100
     - Listener:
       - Name: `listener-8080`
       - Frontend IP: Public
       - Port: 8080
       - Protocol: HTTP
     - Backend targets:
       - Target type: Backend pool
       - Backend target: `pool-webapp`
       - Backend settings: Create new → Name: `http-setting`, Port: 80
     - Add path-based routing:
       - Path: `/employees/*`
       - Target name: `employees`
       - Backend target: `pool-traffic-manager`
       - Backend settings: Use same `http-setting`

6. Click "Review + create" → "Create"

**Why this step**: Application Gateway provides advanced routing, SSL termination, and Web Application Firewall capabilities.

---

## Phase 7: Testing

### Step 13: Test Your Deployment
1. **Test VMSS directly**:
   - `http://[pip-webapp-ip]` (Should show LiftShift-Application)
   - `http://[pip-employees-ip]` (Should show employee application)

2. **Test Application Gateway**:
   - `http://[pip-appgateway-ip]:8080` (Should show webapp)
   - `http://[pip-appgateway-ip]:8080/employees/` (Should route to Traffic Manager)

3. **Test Traffic Manager**:
   - `http://tm-stranglerfig.trafficmanager.net` (Should route based on weights)

**Why this step**: Testing ensures all components work together and traffic flows correctly.

---

## Monthly Cost Breakdown (Estimated)

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| **Virtual Network** | Standard VNet | $0 (Free) |
| **MySQL Flexible Server** | B1ms (1 vCore, 2GB RAM, 20GB storage) | $12-15 |
| **VM Scale Set 1** | B1s (1 vCPU, 1GB RAM) × 1 instance | $8-10 |
| **VM Scale Set 2** | B1s (1 vCPU, 1GB RAM) × 1 instance | $8-10 |
| **Load Balancers (2)** | Basic SKU | $0 (Free) |
| **App Service** | F1 Free tier | $0 (Free) |
| **Traffic Manager** | Standard | $0.54 + $0.40/million queries |
| **Application Gateway** | Standard_v2 (1 instance) | $18-22 |
| **Public IP Addresses (4)** | Basic SKU | $1-2 |
| **Data Transfer** | Minimal for testing | $1-2 |

**Total Estimated Monthly Cost: $25-35 USD**

## Cost Optimization Tips

1. **Use Azure Student Credits**: Most students get $100-200 in free credits
2. **Auto-shutdown VMs**: Configure VMs to shut down at night
3. **Monitor Usage**: Use Azure Cost Management to track spending
4. **Clean Up Resources**: Delete resources when not needed
5. **Use Free Tiers**: Leverage F1 App Service and Basic Load Balancer
6. **Region Selection**: East US typically has lowest costs

## Learning Outcomes

After completing this project, you will understand:

1. **Cloud Architecture Patterns**: Strangler fig migration pattern
2. **Load Balancing**: Different types of load balancers and their use cases
3. **Network Design**: Virtual networks, subnets, and security groups
4. **Database Management**: Managed database services vs. self-hosted
5. **Application Deployment**: Multiple deployment methods (VMSS, App Service)
6. **Traffic Management**: Global and regional traffic routing
7. **Cost Optimization**: Choosing appropriate service tiers and configurations

## Troubleshooting Common Issues

### Database Connection Issues
- Verify firewall rules allow your IP
- Check connection string format
- Ensure database exists and has correct permissions

### VM Scale Set Not Starting
- Check custom data script for syntax errors
- Verify network security group rules
- Review activity logs in Azure portal

### Application Gateway Not Routing
- Verify backend pool health
- Check routing rules and priorities
- Ensure backend services are responding on correct ports

### High Costs
- Enable auto-shutdown for VMs
- Use Azure Advisor recommendations
- Monitor usage with Azure Cost Management

## Next Steps for Advanced Learning

1. **Add Monitoring**: Implement Azure Monitor and Application Insights
2. **Security Enhancement**: Add Azure Key Vault and managed identities
3. **CI/CD Pipeline**: Set up Azure DevOps or GitHub Actions
4. **Container Migration**: Move applications to Azure Container Instances
5. **Microservices**: Break applications into smaller services
6. **Infrastructure as Code**: Use ARM templates or Terraform

---

## Conclusion

This project demonstrates a complete application modernization scenario using Azure's most cost-effective services. The architecture shows how to gradually migrate from legacy applications (VMSS) to modern platforms (App Service) using traffic management techniques.

Remember to delete all resources after completing your assignment to avoid ongoing charges!

## Resource Cleanup Commands

```bash
# Delete the entire resource group (this removes everything)
az group delete --name rg-stranglerfig-project --yes --no-wait
```

**Important**: Always clean up resources after your project to avoid unexpected charges.