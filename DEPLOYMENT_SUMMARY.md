# Azure ModernApp Deployment Summary

## Resource Group
- **Name**: ModernApp
- **Location**: Central US

## Networking

### Virtual Network
- **Name**: FQVN
- **Address Space**: 10.0.0.0/16
- **Subnets**:
  - Subnet1: 10.0.1.0/24 (webapp-sp VMSS)
  - Subnet2: 10.0.2.0/24 (employees-sp VMSS)
  - Subnet3: 10.0.3.0/24 (Application Gateway)

## Database
- **Type**: Azure Database for MySQL Flexible Server
- **Server Name**: modernapp-mysql-server
- **Endpoint**: modernapp-mysql-server.mysql.database.azure.com
- **Username**: ubuntu
- **Password**: Pels202570124$!$!
- **Database Name**: flexibleserverdb
- **Version**: 8.0.21

## Virtual Machine Scale Sets

### webapp-sp Scale Set
- **Name**: webapp-sp
- **Location**: Subnet1 (10.0.1.0/24)
- **Instance Count**: 2
- **Image**: Ubuntu 22.04
- **Application**: LiftShift-Application (Python)
- **Load Balancer**: webapp-sp-lb
- **Public IP**: webapp-sp-lbPublicIP

### employees-sp Scale Set
- **Name**: employees-sp
- **Location**: Subnet2 (10.0.2.0/24)
- **Instance Count**: 2
- **Image**: Ubuntu 22.04
- **Application**: Employee PHP Application
- **Load Balancer**: employees-sp-lb
- **Public IP**: employees-sp-lbPublicIP
- **DNS Name**: employees-sp-lb-modernapp.centralus.cloudapp.azure.com

## App Service
- **Name**: modernapp-employees-webapp-1761156419
- **Plan**: myAppServicePlan (Basic B1)
- **Runtime**: PHP 8.3
- **OS**: Linux
- **Location**: Central US
- **URL**: https://modernapp-employees-webapp-1761156419.azurewebsites.net

## Traffic Manager
- **Profile Name**: P2TF
- **DNS Name**: p2tf-modernapp.trafficmanager.net
- **Routing Method**: Weighted
- **Endpoints**:
  1. employees-sp-endpoint (External, Weight: 90)
     - Target: employees-sp-lb-modernapp.centralus.cloudapp.azure.com
  2. appservice-endpoint (External, Weight: 10)
     - Target: modernapp-employees-webapp-1761156419.azurewebsites.net

## Application Gateway
- **Name**: ModernAppGateway
- **Location**: Central US (Subnet3)
- **SKU**: Standard_v2
- **Capacity**: 2 instances
- **Public IP**: AppGatewayPublicIP
- **Frontend Port**: 8080

### Backend Pools
1. **webapp-sp-pool**: Points to webapp-sp load balancer
2. **trafficmanager-pool**: Points to Traffic Manager profile (p2tf-modernapp.trafficmanager.net)

### Routing Rules
- **Default Route**: → webapp-sp-pool (LiftShift Application)
- **Path-Based Route** (/employees/*): → trafficmanager-pool → Traffic Manager
  - 90% → employees-sp scale set
  - 10% → App Service

## Architecture Pattern
This deployment implements the **Strangler Fig Pattern** for application modernization:
1. **Lift and Shift**: Legacy application (employees-sp) running on VMs
2. **Canary Release**: Traffic Manager routes 90% to VMs, 10% to serverless App Service
3. **Load Balancers**: 
   - Public load balancers for scale sets
   - Application Gateway as entry point
4. **No Session Affinity**: Enabled for better scaling
5. **Applied Elasticity**: VM Scale Sets with auto-scaling capability
6. **Serverless Deployment**: Azure App Service for modernized component

## Testing the Deployment

### Test the Main Application (webapp-sp)
Access via Application Gateway on port 8080:
```
http://<AppGatewayPublicIP>:8080
```
This will show the LiftShift-Application interface.

### Test the Employees Application (Strangler Fig Pattern)
Access via path-based routing:
```
http://<AppGatewayPublicIP>:8080/employees/123
```
This will route through Traffic Manager:
- 90% of requests → employees-sp scale set (VMs)
- 10% of requests → App Service (serverless)

### Direct Access URLs
- **webapp-sp Load Balancer**: Check webapp-sp-lbPublicIP
- **employees-sp Load Balancer**: http://employees-sp-lb-modernapp.centralus.cloudapp.azure.com
- **App Service**: https://modernapp-employees-webapp-1761156419.azurewebsites.net
- **Traffic Manager**: http://p2tf-modernapp.trafficmanager.net

## Network Security
- Port 80 is open on both scale set NSGs (webapp-spNSG, employees-spNSG)
- Application Gateway listens on port 8080
- MySQL database allows connections from all Azure services

## Cost Optimization Notes
- Using Basic B1 tier for App Service Plan
- Standard_B1s VMs for scale sets
- Consider scaling down when not in use
- Free tier MySQL flexible server trial available for 30 days
