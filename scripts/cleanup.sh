#!/bin/bash

# Azure Application Modernization Cleanup Script
# This script removes all resources created for the project

set -e

# Configuration
RESOURCE_GROUP="rg-stranglerfig-project"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🗑️  Azure Application Modernization Cleanup${NC}"
echo "=============================================="

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

# Check if resource group exists
if ! az group exists --name $RESOURCE_GROUP --output tsv | grep -q "true"; then
    echo -e "${YELLOW}ℹ️  Resource group '$RESOURCE_GROUP' does not exist or was already deleted.${NC}"
    exit 0
fi

# Show resources that will be deleted
echo -e "${YELLOW}📋 Resources in group '$RESOURCE_GROUP':${NC}"
az resource list --resource-group $RESOURCE_GROUP --output table

echo ""
echo -e "${RED}⚠️  WARNING: This will permanently delete ALL resources in the resource group!${NC}"
echo -e "${RED}⚠️  This action cannot be undone!${NC}"
echo ""
echo -e "${YELLOW}Resources that will be deleted include:${NC}"
echo "• Virtual Networks and Subnets"
echo "• Virtual Machine Scale Sets"
echo "• Load Balancers"
echo "• MySQL Database Server"
echo "• App Service and App Service Plan"
echo "• Traffic Manager Profile"
echo "• Application Gateway"
echo "• Public IP Addresses"
echo "• Network Security Groups"
echo "• All associated storage and networking components"
echo ""

# Confirmation prompt
read -p "Are you sure you want to delete ALL resources? (type 'YES' to confirm): " confirm

if [ "$confirm" != "YES" ]; then
    echo -e "${GREEN}✅ Cleanup cancelled. No resources were deleted.${NC}"
    exit 0
fi

# Final confirmation
echo ""
echo -e "${RED}⚠️  FINAL WARNING: About to delete resource group '$RESOURCE_GROUP' and ALL its contents!${NC}"
read -p "Last chance to cancel. Type 'DELETE' to proceed: " final_confirm

if [ "$final_confirm" != "DELETE" ]; then
    echo -e "${GREEN}✅ Cleanup cancelled. No resources were deleted.${NC}"
    exit 0
fi

# Delete the resource group and all resources
echo -e "${YELLOW}🗑️  Deleting resource group and all resources...${NC}"
echo "This may take several minutes..."

az group delete \
    --name $RESOURCE_GROUP \
    --yes \
    --no-wait

echo ""
echo -e "${GREEN}✅ Cleanup initiated successfully!${NC}"
echo "=============================================="
echo -e "${GREEN}📊 Cleanup Summary:${NC}"
echo "• Resource group '$RESOURCE_GROUP' deletion started"
echo "• All resources in the group will be removed"
echo "• Deletion is running in the background"
echo ""
echo -e "${YELLOW}ℹ️  Note:${NC}"
echo "• The deletion process may take 10-30 minutes to complete"
echo "• You can check the status in Azure Portal > Resource Groups"
echo "• Billing for resources will stop once deletion is complete"
echo ""
echo -e "${GREEN}💰 Your Azure costs for this project will stop accruing shortly!${NC}"
echo -e "${GREEN}🎉 Thank you for learning Azure with this modernization project!${NC}"