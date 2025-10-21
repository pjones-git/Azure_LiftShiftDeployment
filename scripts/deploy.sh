#!/bin/bash

# Azure Application Modernization Deployment Script
# This script automates the deployment of Azure resources using Bicep

set -e

# Configuration
RESOURCE_GROUP="rg-stranglerfig-project"
LOCATION="eastus"
DEPLOYMENT_NAME="stranglerfig-deployment-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Azure Application Modernization Deployment${NC}"
echo "=================================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if user is logged in to Azure
echo -e "${YELLOW}🔍 Checking Azure authentication...${NC}"
if ! az account show > /dev/null 2>&1; then
    echo -e "${RED}❌ Not logged in to Azure. Please run 'az login' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Azure authentication verified${NC}"

# Get MySQL password securely
echo -e "${YELLOW}🔐 Please enter MySQL admin password (minimum 8 characters):${NC}"
read -s MYSQL_PASSWORD
echo

if [ ${#MYSQL_PASSWORD} -lt 8 ]; then
    echo -e "${RED}❌ Password must be at least 8 characters long${NC}"
    exit 1
fi

# Create resource group
echo -e "${YELLOW}📦 Creating resource group: $RESOURCE_GROUP${NC}"
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --output table

# Deploy Bicep template
echo -e "${YELLOW}🏗️  Deploying Azure resources...${NC}"
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --name $DEPLOYMENT_NAME \
    --template-file ../bicep/main.bicep \
    --parameters mysqlAdminPassword="$MYSQL_PASSWORD" \
    --output table

# Get deployment outputs
echo -e "${YELLOW}📋 Retrieving deployment information...${NC}"
OUTPUTS=$(az deployment group show \
    --resource-group $RESOURCE_GROUP \
    --name $DEPLOYMENT_NAME \
    --query properties.outputs \
    --output json)

# Extract values
VNET_NAME=$(echo $OUTPUTS | jq -r '.vnetName.value')
MYSQL_SERVER_NAME=$(echo $OUTPUTS | jq -r '.mysqlServerName.value')
APP_SERVICE_NAME=$(echo $OUTPUTS | jq -r '.appServiceName.value')
TRAFFIC_MANAGER_NAME=$(echo $OUTPUTS | jq -r '.trafficManagerName.value')

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo "=================================================="
echo -e "${GREEN}📊 Deployment Summary:${NC}"
echo "• Resource Group: $RESOURCE_GROUP"
echo "• Virtual Network: $VNET_NAME"
echo "• MySQL Server: $MYSQL_SERVER_NAME"
echo "• App Service: $APP_SERVICE_NAME"
echo "• Traffic Manager: $TRAFFIC_MANAGER_NAME"
echo ""
echo -e "${YELLOW}⚠️  Next Steps:${NC}"
echo "1. Create VM Scale Sets manually (not included in Bicep template)"
echo "2. Create Application Gateway"
echo "3. Configure Traffic Manager endpoints"
echo "4. Deploy application code"
echo ""
echo -e "${YELLOW}💰 Cost Management:${NC}"
echo "• Monitor costs in Azure Portal > Cost Management"
echo "• Enable auto-shutdown for VMs"
echo "• Clean up resources when done: ./cleanup.sh"
echo ""
echo -e "${GREEN}🎉 Happy learning!${NC}"