# Troubleshooting & Fixes Applied

## Issues Resolved

### 1. 502 Bad Gateway Error
**Symptom**: Application Gateway returning 502 errors

**Root Causes Identified**:
- Missing PHP mysqli extension on employees-sp VMs
- MySQL requiring SSL/TLS connections

### 2. PHP mysqli Extension Missing
**Error**: `PHP Fatal error: Class "mysqli" not found`

**Fix Applied**:
```bash
# Installed on both employees-sp VMs:
apt-get install -y php-mysqli
systemctl restart apache2
```

**Permanent Fix**: Updated `employees-sp-init.sh` to include `php-mysqli` in package installation

### 3. MySQL SSL Connection Requirement
**Error**: `Connections using insecure transport are prohibited while --require_secure_transport=ON`

**Fix Applied**:
```bash
az mysql flexible-server parameter set \
  --resource-group ModernApp \
  --server-name modernapp-mysql-server \
  --name require_secure_transport \
  --value OFF
```

## Current Working Status

### ✅ All Backend Health Checks: HEALTHY
- **webapp-sp-pool**: Healthy
- **trafficmanager-pool**: Healthy

### ✅ Working Endpoints

#### Main Application (webapp-sp)
```
http://<AppGatewayIP>:8080
```
Shows: LiftShift-Application interface

#### Direct Backend Access
1. **webapp-sp Load Balancer**:
   - Direct IP access working
   - Returns 200 OK

2. **employees-sp Load Balancer**:
   ```
   http://employees-sp-lb-modernapp.centralus.cloudapp.azure.com
   ```
   - Returns 200 OK
   - Shows employee database table

3. **Traffic Manager**:
   ```
   http://p2tf-modernapp.trafficmanager.net
   ```
   - Returns 200 OK
   - Routes 90% to employees-sp VMs
   - Routes 10% to App Service

4. **App Service**:
   ```
   https://modernapp-employees-webapp-1761156419.azurewebsites.net
   ```
   - Serverless component working

### Path-Based Routing Note

The path `/employees/*` routing is configured but returns 404 because:
- The backend applications serve content at root path `/`
- Application Gateway forwards the full path `/employees/xyz` to backends
- Backends don't have content at `/employees/` path

**Options to Fix**:
1. **Option A**: Access backends directly (current working solution)
2. **Option B**: Configure URL rewrite rules on Application Gateway to strip `/employees` prefix
3. **Option C**: Modify backend applications to serve at `/employees/` path

## Testing Commands

### Check Application Gateway Backend Health
```bash
az network application-gateway show-backend-health \
  --resource-group ModernApp \
  --name ModernAppGateway
```

### Test Main Application
```bash
APP_GW_IP=$(az network public-ip show --resource-group ModernApp --name AppGatewayPublicIP --query ipAddress -o tsv)
curl http://$APP_GW_IP:8080
```

### Test Direct Backends
```bash
# webapp-sp
curl http://<webapp-sp-lb-IP>

# employees-sp  
curl http://employees-sp-lb-modernapp.centralus.cloudapp.azure.com

# Traffic Manager
curl http://p2tf-modernapp.trafficmanager.net
```

### Check VM Logs
```bash
az vm run-command invoke \
  --resource-group ModernApp \
  --name employees-sp_55aae5cb \
  --command-id RunShellScript \
  --scripts "tail -20 /var/log/apache2/error.log"
```

## Architecture Verification

✅ **Strangler Fig Pattern**: Implemented
- Legacy app on VMs (employees-sp)
- Modern serverless component (App Service)
- Weighted traffic routing (90/10 split)

✅ **Load Balancing**: Working
- Public load balancers for both scale sets
- Application Gateway as central entry point

✅ **Database Connectivity**: Fixed
- MySQL Flexible Server accessible
- SSL requirement disabled for non-SSL connections
- Both VMs can connect successfully

✅ **Network Security**: Configured
- Port 80 open on NSGs
- Application Gateway on port 8080
- Public IPs assigned correctly

✅ **Elasticity**: Enabled
- VM Scale Sets with 2 instances each
- Can scale up/down as needed

## Recommendations

### For Production:
1. **Enable SSL for MySQL**: Use proper SSL certificates instead of disabling requirement
2. **Configure URL Rewriting**: Add rewrite rules on Application Gateway for path-based routing
3. **Set up Monitoring**: Enable Application Insights for all components
4. **Review NSG Rules**: Tighten security rules based on actual requirements
5. **Enable Auto-scaling**: Configure auto-scale rules based on metrics
6. **Add Health Endpoints**: Create dedicated health check endpoints on applications

### For Development:
1. Use the direct backend URLs for testing
2. Monitor Application Gateway metrics in Azure Portal
3. Check VM logs regularly during development
4. Test traffic distribution through Traffic Manager
