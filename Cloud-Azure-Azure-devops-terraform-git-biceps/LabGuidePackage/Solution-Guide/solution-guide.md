# CloudLabs by Spektra Systems | Facilitator Solution Guide (NOT for candidates)

## Azure Infrastructure — VNet, Azure SQL & Load Balancer (Lab 01): Answer Key + Walkthrough

This document mirrors the candidate exercise order. Each task lists the recommended approach, the build commands (Azure CLI via the JumpVM), the expected result, and the validation expectation. All work is performed over SSH on the Ubuntu JumpVM (`labvm-<DeploymentID>`, `10.0.0.4`), which has the **Azure CLI** and **sqlcmd** pre-installed. Candidates run `az login` first; every resource is created in the lab resource group (`$resourceGroupName`).

> Throughout, `RG="$(az group list --query "[?starts_with(name,'ODL') || starts_with(name,'RG')].name | [0]" -o tsv)"` resolves the lab resource group; `LOC="$(az group show -n "$RG" --query location -o tsv)"` resolves its region.

---

## Exercise 1 / Task 1 — Configure a VNet with subnets

**Objective:** A Virtual Network exists in `$resourceGroupName` with **at least two subnets**.

**Build:**

```bash
RG="<lab resource group>"
LOC="$(az group show -n "$RG" --query location -o tsv)"

# Create the VNet with its first subnet (app tier)
az network vnet create \
  --resource-group "$RG" \
  --name salesVnet \
  --location "$LOC" \
  --address-prefixes 10.10.0.0/16 \
  --subnet-name app \
  --subnet-prefixes 10.10.1.0/24

# Add a second subnet (data tier)
az network vnet subnet create \
  --resource-group "$RG" \
  --vnet-name salesVnet \
  --name data \
  --address-prefixes 10.10.2.0/24
```

**Verify:**

```bash
az network vnet subnet list -g "$RG" --vnet-name salesVnet --query "length(@)"   # >= 2
az network vnet show -g "$RG" -n salesVnet --query "subnets[].name" -o tsv
```

**Expected result:** `salesVnet` has two subnets (`app`, `data`) with non-overlapping prefixes inside `10.10.0.0/16`.

**Validation:** `validate-task1-vnet-subnets.ps1` calls `Get-AzVirtualNetwork` in `$resourceGroupName` and passes when at least one VNet has **>= 2 subnets** → `Succeeded`.

---

## Exercise 2 / Task 1 — Deploy an Azure SQL Database and connect from the VM

**Objective:** An Azure SQL logical server and a database (`salesdb`) exist in `$resourceGroupName`, reachable from the JumpVM via `sqlcmd`.

**Build:**

```bash
RG="<lab resource group>"
LOC="$(az group show -n "$RG" --query location -o tsv)"
SQLSERVER="salessql$RANDOM"          # must be globally unique, lowercase
SQLADMIN="sqladminuser"
SQLPASS='Sql@P4ssw0rd!2026'          # strong password

# Logical server + database
az sql server create -g "$RG" -n "$SQLSERVER" -l "$LOC" \
  --admin-user "$SQLADMIN" --admin-password "$SQLPASS"

az sql db create -g "$RG" --server "$SQLSERVER" --name salesdb \
  --service-objective S0

# Firewall: allow Azure services + the JumpVM public IP
az sql server firewall-rule create -g "$RG" --server "$SQLSERVER" \
  --name AllowAzure --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

MYIP="$(curl -s ifconfig.me)"
az sql server firewall-rule create -g "$RG" --server "$SQLSERVER" \
  --name AllowJumpVM --start-ip-address "$MYIP" --end-ip-address "$MYIP"
```

**Connect from the JumpVM:**

```bash
SQLCMD=/opt/mssql-tools18/bin/sqlcmd      # or /opt/mssql-tools/bin/sqlcmd (drop -C)
$SQLCMD -C -S "${SQLSERVER}.database.windows.net" -U "$SQLADMIN" -P "$SQLPASS" \
        -d salesdb -Q "SELECT name FROM sys.databases;"
```

**Expected result:** `az sql db show -g "$RG" --server "$SQLSERVER" --name salesdb` returns the DB; the `sqlcmd` query from the JumpVM lists `salesdb`.

**Validation:** `validate-task2-azure-sql.ps1` calls `Get-AzSqlServer` + `Get-AzSqlDatabase` in `$resourceGroupName` and passes when a logical server exists **and** a non-`master` database (e.g. `salesdb`) is present → `Succeeded`. (It optionally runs an in-VM `sqlcmd` connectivity probe via `Invoke-AzVMRunCommand`; the pass condition is the database existing.)

---

## Exercise 3 / Task 1 — Configure a Load Balancer fronting two VMs

**Objective:** A Load Balancer in `$resourceGroupName` has a backend pool with **two backend VMs**, a health probe, and a load-balancing rule.

**Build:**

```bash
RG="<lab resource group>"
LOC="$(az group show -n "$RG" --query location -o tsv)"

# Reuse salesVnet/app subnet from Exercise 1 (or create one)
# Two backend VMs (no public IP; they sit behind the LB)
for i in 1 2; do
  az vm create -g "$RG" -n "webvm$i" --image Ubuntu2204 \
    --vnet-name salesVnet --subnet app \
    --admin-username azureuser --generate-ssh-keys \
    --public-ip-address "" --nsg ""
done

# Standard Load Balancer with a frontend, backend pool, probe, and rule
az network public-ip create -g "$RG" -n salesLbPip --sku Standard

az network lb create -g "$RG" -n salesLb --sku Standard \
  --public-ip-address salesLbPip \
  --frontend-ip-name salesFe \
  --backend-pool-name salesPool

az network lb probe create -g "$RG" --lb-name salesLb \
  --name healthProbe --protocol Tcp --port 80

az network lb rule create -g "$RG" --lb-name salesLb \
  --name httpRule --protocol Tcp \
  --frontend-port 80 --backend-port 80 \
  --frontend-ip-name salesFe \
  --backend-pool-name salesPool \
  --probe-name healthProbe

# Add each VM's NIC IP config to the backend pool
for i in 1 2; do
  NIC="$(az vm show -g "$RG" -n "webvm$i" --query "networkProfile.networkInterfaces[0].id" -o tsv)"
  NICNAME="$(basename "$NIC")"
  IPCFG="$(az network nic show --ids "$NIC" --query "ipConfigurations[0].name" -o tsv)"
  az network nic ip-config address-pool add -g "$RG" \
    --nic-name "$NICNAME" --ip-config-name "$IPCFG" \
    --lb-name salesLb --address-pool salesPool
done
```

**Verify:**

```bash
az network lb show -g "$RG" -n salesLb \
  --query "{pool: length(backendAddressPools[0].loadBalancerBackendAddresses), rules: length(loadBalancingRules), probes: length(probes)}"
```

**Expected result:** `salesLb` has a backend pool with two members, one health probe, and one load-balancing rule.

**Validation:** `validate-task3-load-balancer.ps1` calls `Get-AzLoadBalancer` in `$resourceGroupName` and passes when a Load Balancer has a **backend pool with >= 2 backend IP configurations** **and** at least one load-balancing rule (a health probe is also expected) → `Succeeded`.

---

### Facilitator Notes

- All three validators run via the CloudLabs VM Agent (PowerShell HTTP-trigger functions). They query the **Azure control plane** with `Az` cmdlets (`Get-AzVirtualNetwork`, `Get-AzSqlServer`/`Get-AzSqlDatabase`, `Get-AzLoadBalancer`) against `$resourceGroupName`; HTTP is always `OK` and pass/fail lives in the JSON `Status` field. They are read-only state checks and safe to re-run.
- Resource creation needs the candidate to have run `az login` and have **Contributor** on the lab resource group. Azure SQL server names and Load Balancer public IPs are globally unique, so candidates may pick different names — the validators match on **type and configuration**, not on exact names.
- The Exercise 2 validator passes on the **existence of the database**; the in-VM `sqlcmd` connectivity probe is a best-effort secondary signal (it can fail transiently on firewall propagation without failing the task).
- Provisioning two VMs + a Standard Load Balancer can take several minutes; allow time before validating Exercise 3.



