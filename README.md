# maugp IaC (Bicep)

This repo contains Bicep templates to deploy:
- 10 resource groups and virtual networks (one per RG) with a default subnet and a single Ubuntu VM per VNet
- Azure Firewall Basic (with Basic policy) in VNet #1 only
- A one-off variant for VNet 11

> Important
>
> The code on branch `main` uses a loop-based VNet module deployment that runs in parallel. When AVNM IPAM is enabled, deploying many VNets concurrently can fail due to Azure Network Manager IPAM API throttling (PreconditionFailed/retry later). Use branch `serialized` for a sequential VNet deployment that avoids throttling.

## Structure
- `bicep/`
  - `main.bicep`: Orchestrates 10 RGs/VNets, Firewall in #1, VMs per RG. Supports AVNM IPAM and optional subnet route table.
  - `vnet-11.bicep`: One-off VNet + VM (#11).
  - `modules/`: `vnet.bicep`, `firewall.bicep`, `vm.bicep`.

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

Branch guidance:
- main: Loop/parallel VNet creation (may hit IPAM throttling; kept for reference).
- serialized: Explicit sequential VNet modules with enforced order to mitigate IPAM throttling.

Security reminders:
- Replace PoC VM password with SSH keys; store secrets in Key Vault.
- Tighten Firewall rules (remove allow-all) before any production use.
