# Instructor Brief — Azure Infrastructure (Lab 01)

**Domain / Level:** Azure / Azure DevOps / Terraform / Git / Bicep · Intermediate · **Hosting tier A** (one native CloudLabs Linux JumpVM, Ubuntu Server 22.04 LTS, with Azure CLI + sqlcmd; the candidate builds the assessed Azure resources in the lab resource group).
**Target time:** ~90 min work · **120 min** provisioned.
**Cloud field:** `azure` · **Level field:** `Intermediate`.

## Scenario

The candidate is a Cloud Infrastructure Engineer standing up the foundation for a sales platform on Azure. From a Linux JumpVM (Azure CLI + `sqlcmd` pre-installed), they must: (1) build a **Virtual Network** segmented into at least two subnets; (2) deploy a managed **Azure SQL Database** (`salesdb`) on a logical server, open a firewall rule, and connect to it from the JumpVM with `sqlcmd`; and (3) configure an **Azure Load Balancer** fronting **two backend VMs** with a backend pool, a health probe, and a load-balancing rule. All assessed resources are created by the candidate in the lab resource group (`$resourceGroupName`).

## Environment (seeded by `DeploymentPackage/bootstrap-01.sh`)

- **One Ubuntu 22.04 JumpVM** (`Standard_D2s_v3`): `labvm-<DeploymentID>` (`10.0.0.4`, hostname `labvm`) in the lab resource group, on a base `labvNet` placeholder. The bootstrap installs **azure-cli** and **mssql-tools/sqlcmd**, and writes `/home/labuser/README.txt` with topology and per-scenario hints.
- **CloudLabs injects the Azure user context.** The bootstrap does **not** log in or create assessed resources; the candidate runs `az login` and builds everything themselves. Every install step is guarded so the CSE never hard-fails.
- The NSG allows SSH (22) to the JumpVM. The candidate opens any further ports (e.g. Azure SQL firewall rules, LB rules) as part of the exercises.

## Answer key

- **Ex1 (VNet + subnets):**

  ```bash
  az network vnet create -g "$RG" -n salesVnet --address-prefixes 10.10.0.0/16 \
      --subnet-name app --subnet-prefixes 10.10.1.0/24
  az network vnet subnet create -g "$RG" --vnet-name salesVnet --name data \
      --address-prefixes 10.10.2.0/24
  ```

  A VNet with **>= 2 subnets** in `$resourceGroupName` satisfies the validator.

- **Ex2 (Azure SQL):**

  ```bash
  az sql server create -g "$RG" -n salessql$RANDOM -l "$LOC" \
      --admin-user sqladminuser --admin-password 'Sql@P4ssw0rd!2026'
  az sql db create -g "$RG" --server <server> --name salesdb --service-objective S0
  az sql server firewall-rule create -g "$RG" --server <server> \
      --name AllowAzure --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
  /opt/mssql-tools18/bin/sqlcmd -C -S <server>.database.windows.net \
      -U sqladminuser -P 'Sql@P4ssw0rd!2026' -d salesdb -Q "SELECT @@VERSION;"
  ```

  A logical server + a user database (`salesdb`) in `$resourceGroupName` satisfies the validator.

- **Ex3 (Load Balancer):** Create two backend VMs, a Standard Load Balancer with a backend pool, a health probe, and a load-balancing rule, then add both VMs' NIC IP configs to the pool. (Full commands in `LabGuidePackage/Solution-Guide/solution-guide.md`.) Pass = backend pool with **>= 2 members** and a rule.

## Scoring rubric (100 pts)

| Item | Pts | Pass criteria (validator) |
|---|---|---|
| Ex1 — VNet with >= 2 subnets exists in the RG | 34 | validate-task1-vnet-subnets.ps1 → Succeeded |
| Ex2 — Azure SQL logical server + database (`salesdb`) exists | 33 | validate-task2-azure-sql.ps1 → Succeeded |
| Ex3 — Load Balancer with 2-VM backend pool + probe + rule | 33 | validate-task3-load-balancer.ps1 → Succeeded |

Pass ≥ 34 (at least one task fully complete). Intermediate sign-off = 100 with **all three** tasks passing.

## Notes / caveats

- Validators query the **Azure control plane** against `$resourceGroupName` (not in-VM state), so they pass regardless of the exact resource names the candidate chooses — they match on **type and configuration** (subnet count, server+database presence, backend-pool membership + rule). HTTP is always `OK`; pass/fail lives in the JSON `Status` field. They are read-only and safe to re-run.
- The candidate must have run `az login` and hold **Contributor** on the lab resource group. Azure SQL server names and Load Balancer public IP labels are globally unique — candidates pick their own.
- The Ex2 validator passes on the **existence of the database**; an in-VM `sqlcmd` connectivity probe is an optional secondary signal that can fail transiently on firewall propagation and is not required for the task to pass.
- Resource provisioning (especially two VMs + a Standard Load Balancer for Ex3) can take several minutes; allow time before validating. Package install at deploy time needs internet access; the bootstrap guards every step so the CSE never hard-fails — if `az`/`sqlcmd` are absent, the candidate can install them or proceed via the portal/Cloud Shell.
- The working user is `labuser` (ARM `trainerUserName` / `adminUsername`); `README.txt` with topology and hints is written to `/home/labuser`.
