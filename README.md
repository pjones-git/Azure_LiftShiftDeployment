# Azure Application Modernization Project

## Overview
This project demonstrates application modernization on Azure cloud using the Strangler Fig pattern. It showcases migrating legacy applications to cloud-native services while maintaining business continuity through gradual traffic shifting.

## Architecture
- **VM Scale Sets**: Host legacy applications with load balancing
- **Azure App Service**: Modern serverless hosting platform
- **Traffic Manager**: Global traffic routing and weighted distribution
- **Application Gateway**: Advanced routing and web application firewall
- **MySQL Flexible Server**: Managed database service
- **Virtual Network**: Secure network isolation and communication

## Project Structure
```
azure-modernization-app/
├── README.md                    # This file
├── Azure-Modernization-Guide.md # Complete step-by-step guide
├── src/                         # Application source code
├── docs/                        # Documentation and diagrams
├── scripts/                     # Deployment and utility scripts
├── config/                      # Configuration files
├── bicep/                       # Infrastructure as Code templates
└── .gitignore                   # Git ignore patterns
```

## Getting Started

### Prerequisites
- Azure account with student credits
- Basic knowledge of cloud computing
- Access to Azure Portal

### Quick Start
1. Follow the detailed guide in `Azure-Modernization-Guide.md`
2. Start with Phase 1 (Virtual Network setup)
3. Progress through all 7 phases sequentially
4. Test each component as you build

### Estimated Cost
**Monthly**: $25-35 USD for all services

### Key Learning Outcomes
- Cloud architecture patterns
- Azure services integration
- Load balancing strategies
- Traffic management
- Cost optimization
- Security best practices

## Important Notes
- Always clean up resources after completion
- Use auto-shutdown for VMs to save costs
- Monitor spending with Azure Cost Management
- Follow security best practices

## Support
Refer to the troubleshooting section in the main guide for common issues and solutions.

## Architecture Diagram
See `thumbnail.webp` for the visual representation of the complete architecture.
