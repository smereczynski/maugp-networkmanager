# Terraform for maugp

This mirrors the Bicep setup:
- main/: 10 RGs + VNets, Azure Firewall Basic in VNet 1, one Ubuntu VM per RG
- vnet11/: single RG + VNet + VM (#11)
- modules/: vnet, firewall, vm

Providers:
- azurerm ~> 3.113, azapi ~> 1.13
- Subscription: e2dda714-1e15-49ca-961c-377a63fb5769
- Tenant: 6d338245-9261-4f6d-a5a1-cd18b014a259

IPAM:
- When `var.ipam_pool_id` is set, the module avoids address_space/prefixes and uses azapi_update_resource to set `ipamPoolPrefixAllocations` for the VNet and default subnet.

Auth options:
- Azure CLI: `az login` (Terraform picks up automatically)
- Managed Identity: run from an Azure agent with Identity assigned
- Service Principal: export ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID

Usage

terraform -chdir=terraform/main init
terraform -chdir=terraform/main plan -var ipam_pool_id="/subscriptions/.../ipamPools/pool1" -var route_table_id="/subscriptions/.../routeTables/..."

terraform -chdir=terraform/vnet11 init
terraform -chdir=terraform/vnet11 plan -var ipam_pool_id="/subscriptions/.../ipamPools/pool1"

Terraform setup mirroring the Bicep templates.

Structure:
- providers.tf: AzureRM provider and backend (local by default)
- variables.tf: shared variables
- main/ (10 VNets + Firewall + VMs)
- vnet11/ (single VNet + one VM)
- modules/
  - vnet/: VNet + subnets (supports AVNM IPAM via AzAPI)
  - firewall/: Azure Firewall Basic + Basic policy + RCG
  - vm/: Ubuntu VM without public IP

Authentication options:
1) Azure CLI (Developer): `az login` (uses your default subscription/tenant)
2) Managed Identity (CI/CD in Azure): set `use_msi = true` and granted permissions
3) Service Principal (CI/CD outside Azure): set `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`
