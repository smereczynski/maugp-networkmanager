# maugp IaC (Bicep + Terraform)

This repo contains:
- Bicep (subscription-scope) to deploy 10 VNets/RGs with one Ubuntu VM per VNet and Azure Firewall Basic in VNet 1, plus a single-stack variant for VNet 11.
- Terraform modules and two roots that mirror the Bicep setup, using Azure CLI authentication.

## Structure
- `bicep/`
  - `main.bicep`: Orchestrates 10 RGs/VNets, Firewall in #1, VMs per RG. Supports AVNM IPAM and optional subnet route table.
  - `vnet-11.bicep`: One-off VNet + VM (#11).
  - `modules/`: `vnet.bicep`, `firewall.bicep`, `vm.bicep`.
- `terraform/`
  - `providers.tf`: azurerm (use_cli=true) and azapi providers; backend local.
  - `main/`: 10 RGs/VNets, Firewall in #1, VMs per RG.
  - `vnet11/`: single VNet + VM.
  - `modules/`: vnet (with AVNM IPAM via AzAPI), firewall, vm.

## Bicep
Preview (what-if):

```bash
az deployment sub what-if \
  --location polandcentral \
  --template-file bicep/main.bicep \
  --parameters ipamPoolId="/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/networkManagers/<nm>/ipamPools/<pool>"
```

Deploy as a deployment stack:

```bash
az stack sub create \
  --name <stack-name> \
  --location polandcentral \
  --template-file bicep/main.bicep \
  --parameters ipamPoolId="/subscriptions/.../ipamPools/pool1" \
  --action-on-unmanage deleteAll \
  --deny-settings-mode none
```

VNet 11 variant:

```bash
az stack sub create \
  --name <stack-name-vnet11> \
  --location polandcentral \
  --template-file bicep/vnet-11.bicep \
  --parameters ipamPoolId="/subscriptions/.../ipamPools/pool1"
```

Notes:
- IPAM: Template avoids mixing addressPrefixes with ipamPoolPrefixAllocations.
- Default subnet route table is opt-in via parameter to preserve existing AVNM routing if any.

## Terraform (Azure CLI auth)
Prereq: sign in to Azure and select subscription.

```bash
az login
az account set --subscription <your-subscription-id>
```

Initialize and plan main (10 VNets + Firewall + VMs):

```bash
terraform -chdir=terraform/main init
terraform -chdir=terraform/main plan \
  -var ipam_pool_id="/subscriptions/.../ipamPools/pool1" \
  -var route_table_id="/subscriptions/.../routeTables/..."
```

Initialize and plan vnet11:

```bash
terraform -chdir=terraform/vnet11 init
terraform -chdir=terraform/vnet11 plan \
  -var ipam_pool_id="/subscriptions/.../ipamPools/pool1"
```

Security reminders:
- Replace PoC VM password with SSH keys; store secrets in Key Vault.
- Tighten Firewall rules (remove allow-all) before any production use.
