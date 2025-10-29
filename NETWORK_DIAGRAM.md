# Network Architecture Diagram

## Complete Infrastructure Topology

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            INTERNET / PUBLIC ACCESS                          │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   │ HTTPS/HTTP
                                   ▼
                    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
                    ┃   Application Gateway     ┃
                    ┃   ModernAppGateway        ┃
                    ┃   Public IP: AppGatewayIP ┃
                    ┃   Port: 8080              ┃
                    ┃   SKU: Standard_v2        ┃
                    ┗━━━━━━━━━━━━┳━━━━━━━━━━━━━━┛
                                 │
                    ┌────────────┴────────────┐
                    │   Path-Based Router     │
                    └────┬──────────────┬─────┘
                         │              │
         ┌───────────────┘              └──────────────┐
         │ Default Route (/)                           │ /employees/*
         ▼                                             ▼
┏━━━━━━━━━━━━━━━━━━━┓                        ┏━━━━━━━━━━━━━━━━━━━━┓
┃  Backend Pool:     ┃                        ┃  Backend Pool:      ┃
┃  webapp-sp-pool    ┃                        ┃  trafficmanager-pool┃
┗━━━━━━━━┳━━━━━━━━━━┛                        ┗━━━━━━━━┳━━━━━━━━━━━┛
         │                                             │
         ▼                                             ▼
┌──────────────────────┐                    ┌──────────────────────┐
│  Azure Load Balancer │                    │  Traffic Manager     │
│  webapp-sp-lb        │                    │  P2TF                │
│  Public IP           │                    │  DNS-based routing   │
│  Port: 80            │                    │  Method: Weighted    │
└──────────┬───────────┘                    └──────────┬───────────┘
           │                                           │
           │                              ┌────────────┴───────────┐
           │                              │                        │
           │                          90% │                    10% │
           ▼                              ▼                        ▼
┌─────────────────────┐        ┌──────────────────────┐  ┌────────────────┐
│  VM Scale Set       │        │  Azure Load Balancer │  │  Azure App     │
│  webapp-sp          │        │  employees-sp-lb     │  │  Service       │
│  ┌───────────────┐  │        │  Public IP + DNS     │  │  ┌──────────┐  │
│  │ VM Instance 1 │  │        │  Port: 80            │  │  │ Serverless│ │
│  │  Python App   │  │        └──────────┬───────────┘  │  │ PHP 8.3   │ │
│  └───────────────┘  │                   │              │  └──────────┘  │
│  ┌───────────────┐  │                   ▼              │  Runtime: Linux │
│  │ VM Instance 2 │  │        ┌──────────────────────┐ │  Plan: Basic B1 │
│  │  Python App   │  │        │  VM Scale Set        │ └────────┬───────┘
│  └───────────────┘  │        │  employees-sp        │          │
│                     │        │  ┌───────────────┐   │          │
│  OS: Ubuntu 22.04   │        │  │ VM Instance 1 │   │          │
│  Port: 80           │        │  │ PHP + Apache  │   │          │
│  Subnet: Subnet1    │        │  └───────────────┘   │          │
│  (10.0.1.0/24)      │        │  ┌───────────────┐   │          │
└─────────────────────┘        │  │ VM Instance 2 │   │          │
                               │  │ PHP + Apache  │   │          │
                               │  └───────────────┘   │          │
                               │                      │          │
                               │  OS: Ubuntu 22.04    │          │
                               │  Port: 80            │          │
                               │  Subnet: Subnet2     │          │
                               │  (10.0.2.0/24)       │          │
                               └──────────┬───────────┘          │
                                          │                      │
                                          └──────────┬───────────┘
                                                     │
                                                     │ MySQL Protocol
                                                     ▼
                                         ┏━━━━━━━━━━━━━━━━━━━━━━┓
                                         ┃  Azure MySQL         ┃
                                         ┃  Flexible Server     ┃
                                         ┃  ─────────────────   ┃
                                         ┃  Server:             ┃
                                         ┃  modernapp-mysql-    ┃
                                         ┃  server              ┃
                                         ┃  ─────────────────   ┃
                                         ┃  Database:           ┃
                                         ┃  flexibleserverdb    ┃
                                         ┃  ─────────────────   ┃
                                         ┃  Version: 8.0.21     ┃
                                         ┃  Tier: Burstable     ┃
                                         ┃  SKU: Standard_B1ms  ┃
                                         ┃  Public Access: ON   ┃
                                         ┗━━━━━━━━━━━━━━━━━━━━━━┛
```

## Virtual Network Topology

```
┌───────────────────────────────────────────────────────────────┐
│  Virtual Network: FQVN                                        │
│  Address Space: 10.0.0.0/16                                   │
│  Location: Central US                                         │
│  Resource Group: ModernApp                                    │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  Subnet1: 10.0.1.0/24                               │     │
│  │  ─────────────────────────────────────────────      │     │
│  │  Purpose: webapp-sp VM Scale Set                    │     │
│  │  NSG: webapp-spNSG                                  │     │
│  │  Rules:                                             │     │
│  │    - Allow HTTP (Port 80) from Internet             │     │
│  │    - Allow SSH (Port 22) for management             │     │
│  │  ┌──────────────┐  ┌──────────────┐                │     │
│  │  │ webapp-sp VM1│  │ webapp-sp VM2│                │     │
│  │  └──────────────┘  └──────────────┘                │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  Subnet2: 10.0.2.0/24                               │     │
│  │  ─────────────────────────────────────────────      │     │
│  │  Purpose: employees-sp VM Scale Set                 │     │
│  │  NSG: employees-spNSG                               │     │
│  │  Rules:                                             │     │
│  │    - Allow HTTP (Port 80) from Internet             │     │
│  │    - Allow SSH (Port 22) for management             │     │
│  │  ┌──────────────┐  ┌──────────────┐                │     │
│  │  │employees VM1 │  │employees VM2 │                │     │
│  │  └──────────────┘  └──────────────┘                │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  Subnet3: 10.0.3.0/24                               │     │
│  │  ─────────────────────────────────────────────      │     │
│  │  Purpose: Application Gateway                       │     │
│  │  Requirements:                                      │     │
│  │    - Dedicated subnet for App Gateway               │     │
│  │    - No other resources allowed                     │     │
│  │  ┌──────────────────────────────────┐               │     │
│  │  │  Application Gateway              │               │     │
│  │  │  ModernAppGateway                │               │     │
│  │  └──────────────────────────────────┘               │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

## Traffic Flow Diagram

### Scenario 1: Main Application Request

```
User Request: http://<AppGatewayIP>:8080/
                    │
                    ▼
        ┌───────────────────────┐
        │ Application Gateway   │
        │ Listener: Port 8080   │
        └───────────┬───────────┘
                    │
                    │ Path: / (matches default)
                    ▼
        ┌───────────────────────┐
        │ Backend Pool:         │
        │ webapp-sp-pool        │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Azure Load Balancer   │
        │ webapp-sp-lb          │
        │ Round Robin           │
        └───────────┬───────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
┌──────────────┐        ┌──────────────┐
│ webapp-sp VM1│   OR   │ webapp-sp VM2│
│ Python App   │        │ Python App   │
└──────────────┘        └──────────────┘
```

### Scenario 2: Employees Application Request (Strangler Fig Pattern)

```
User Request: http://<AppGatewayIP>:8080/employees/
                    │
                    ▼
        ┌───────────────────────┐
        │ Application Gateway   │
        │ Path-based routing    │
        └───────────┬───────────┘
                    │
                    │ Path: /employees/* (matches rule)
                    ▼
        ┌───────────────────────┐
        │ Backend Pool:         │
        │ trafficmanager-pool   │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Traffic Manager       │
        │ Weighted Routing:     │
        │  - 90% → VMs          │
        │  - 10% → App Service  │
        └───────────┬───────────┘
                    │
        ┌───────────┴───────────────────┐
        │ 90% probability               │ 10% probability
        ▼                               ▼
┌──────────────────┐          ┌──────────────────┐
│ Azure LB         │          │ App Service      │
│ employees-sp-lb  │          │ (Serverless)     │
└────────┬─────────┘          │ PHP 8.3          │
         │                    └──────────────────┘
         │ Round Robin                 │
    ┌────┴────┐                        │
    │         │                        │
    ▼         ▼                        │
┌────────┐ ┌────────┐                 │
│ emp VM1│ │ emp VM2│                 │
│ PHP    │ │ PHP    │                 │
└───┬────┘ └───┬────┘                 │
    │          │                      │
    └──────────┴──────────────────────┘
               │
               │ MySQL Connection
               ▼
    ┌──────────────────────┐
    │ MySQL Flexible Server│
    │ flexibleserverdb     │
    └──────────────────────┘
```

## Security Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                      SECURITY LAYERS                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Layer 7 (Application)                                         │
│  ┌──────────────────────────────────────────────────────┐      │
│  │ Application Gateway                                  │      │
│  │ - WAF capabilities (Standard_v2)                    │      │
│  │ - SSL/TLS termination                               │      │
│  │ - URL-based routing rules                           │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                │
│  Layer 4 (Transport)                                           │
│  ┌──────────────────────────────────────────────────────┐      │
│  │ Network Security Groups (NSGs)                       │      │
│  │                                                      │      │
│  │ webapp-spNSG:                                       │      │
│  │   Priority 100: Allow HTTP (80) Inbound             │      │
│  │   Priority 200: Allow SSH (22) from Admin IPs       │      │
│  │                                                      │      │
│  │ employees-spNSG:                                    │      │
│  │   Priority 100: Allow HTTP (80) Inbound             │      │
│  │   Priority 200: Allow SSH (22) from Admin IPs       │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                │
│  Layer 3 (Network)                                             │
│  ┌──────────────────────────────────────────────────────┐      │
│  │ Virtual Network (VNet) Isolation                     │      │
│  │ - Private IP addressing (RFC 1918)                  │      │
│  │ - Subnet segmentation                               │      │
│  │ - No direct internet access to VMs                  │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                │
│  Data Layer                                                    │
│  ┌──────────────────────────────────────────────────────┐      │
│  │ MySQL Firewall Rules                                 │      │
│  │ - Allow Azure Services                              │      │
│  │ - Public access controlled                          │      │
│  │ - Connection encryption available                   │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Component Summary Table

| Component | Name | Type | Location | IP/DNS | Purpose |
|-----------|------|------|----------|--------|---------|
| **Application Gateway** | ModernAppGateway | Standard_v2 | Subnet3 | Public IP | Entry point, L7 routing |
| **Traffic Manager** | P2TF | DNS-based | Global | p2tf-modernapp.trafficmanager.net | Weighted routing (90/10) |
| **LB - webapp** | webapp-sp-lb | Standard | N/A | Public IP | Load balancing webapp VMs |
| **LB - employees** | employees-sp-lb | Standard | N/A | employees-sp-lb-modernapp.centralus.cloudapp.azure.com | Load balancing employee VMs |
| **VMSS - webapp** | webapp-sp | Flexible | Subnet1 | Private IPs | Python app (2 instances) |
| **VMSS - employees** | employees-sp | Flexible | Subnet2 | Private IPs | PHP app (2 instances) |
| **App Service** | modernapp-employees-webapp-* | PaaS | Azure Managed | *.azurewebsites.net | Serverless PHP app |
| **Database** | modernapp-mysql-server | Flexible Server | Azure Managed | *.mysql.database.azure.com | Shared MySQL 8.0 |
| **VNet** | FQVN | Virtual Network | Central US | 10.0.0.0/16 | Network isolation |

## Port Mapping

| Service | External Port | Internal Port | Protocol | Access |
|---------|--------------|---------------|----------|--------|
| Application Gateway | 8080 | N/A | HTTP | Public |
| webapp-sp VMs | 80 | 80 | HTTP | Via Load Balancer |
| employees-sp VMs | 80 | 80 | HTTP | Via Load Balancer |
| App Service | 443/80 | N/A | HTTPS/HTTP | Public |
| MySQL Server | 3306 | 3306 | MySQL | Azure Services |
| SSH (Management) | 22 | 22 | SSH | Restricted |

---

**Legend:**
- 🟢 Healthy / Active
- 🔵 Load Balanced
- 🟡 Weighted Distribution
- 🔴 Public Internet Access
- 🟣 Database Connection
