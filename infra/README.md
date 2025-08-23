# Infra (Bicep)

Subscription-scope Bicep that deploys a 10-RG/10-VNet PoC, one Ubuntu VM per VNet, and an Azure Firewall Basic (with a Basic policy) in the first VNet.

## What it deploys
- 10 resource groups: `rg-maugp-poc-<i>-plc` for i=1..10
- 10 VNets: `vnet-maugp-poc-<i>-plc` with address spaces `10.<i>.0.0/16`
  - Default subnet: `10.<i>.0.0/24`
- VMs: `vm-maugp-poc-<i>-plc` (Ubuntu 22.04, no public IP), one per VNet
- In VNet 1 only:
  - Azure Firewall Basic with policy and management/data Public IPs
  - Default Rule Collection Group containing an "allowall" Network rule collection (priority 100) that allows any-to-any

## Structure
- `main.bicep` — Subscription-scope orchestrator (RGs, VNets via module, optional firewall in VNet 1 via module, one VM per VNet)
- `modules/vnet.bicep` — Creates a VNet, default subnet, and the two firewall subnets; outputs subnet IDs
- `modules/firewall.bicep` — Azure Firewall Basic + Basic Policy + RCG with "allowall" Network rule; attaches to firewall subnets
- `modules/vm.bicep` — NIC + Ubuntu VM (no public IP)
- `main.parameters.json` — Legacy from early single-RG sample; not used by `main.bicep`

## Quick start
Preview (what-if) at subscription scope:

```bash
az deployment sub what-if \
  --location polandcentral \
  --template-file infra/main.bicep
```

Deploy:

```bash
az deployment sub create \
  --location polandcentral \
  --template-file infra/main.bicep
```

Parameters you can override:
- `location` (default: current deployment location)
- `tags` (default: `{}`)

Example with tags:

```bash
az deployment sub create \
  --location polandcentral \
  --template-file infra/main.bicep \
  --parameters tags='{ "env": "poc", "owner": "michal" }'
```

## Editing tips
- Change the count, names, or CIDRs in `main.bicep`:
  - Range of VNets: `var indices = range(1, 10)` (1..10)
  - Per-item plan: update `vnetsPlan` entries (names and address plan)
- Firewall rules: edit `modules/firewall.bicep` (the default "allowall" Network rule collection lives under the default Rule Collection Group)
- VM size/OS/user: edit `modules/vm.bicep` parameters and the `vmDeploy` call in `main.bicep`

## Notes
- All subnets use `addressPrefixes` (plural) and 2024-05-01+ API versions.
- This PoC hardcodes a local admin password in `main.bicep` for convenience. Rotate it, or parameterize/Key Vault it before any real use.
- Azure Firewall Basic requires both `AzureFirewallSubnet` and `AzureFirewallManagementSubnet` and a dedicated management public IP; the modules handle this for VNet 1.