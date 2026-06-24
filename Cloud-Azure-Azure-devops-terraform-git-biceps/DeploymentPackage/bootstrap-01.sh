#!/usr/bin/env bash
# =============================================================================
# Lab 01 - Azure Infrastructure (VNet, Azure SQL & Load Balancer)
# bootstrap-01.sh  -  CloudLabs Custom Script Extension bootstrap
#
# Runs on the single Linux JumpVM:
#   * labvm-<DeploymentID> (hostname "labvm", 10.0.0.4, Ubuntu 22.04,
#     Standard_D2s_v3) -> the workstation the candidate uses to run 'az'
#     (Azure CLI) and 'sqlcmd' against the resources they create.
#
# This script installs the candidate's toolbelt and never provisions the
# assessed resources itself (the candidate creates those):
#   - installs Azure CLI (az),
#   - installs sqlcmd + mssql-tools (to connect to Azure SQL from the VM),
#   - writes a README.txt describing the three scenarios.
#
# Scenario 1 (s1): Configure a VNet with at least two subnets in the lab
#                  resource group ($resourceGroupName).
# Scenario 2 (s2): Deploy an Azure SQL logical server + database (e.g.
#                  salesdb), add a firewall rule, and connect from this VM
#                  with sqlcmd.
# Scenario 3 (s3): Configure a Load Balancer fronting two backend VMs with a
#                  backend pool, a health probe, and a load-balancing rule.
#
# NOTE on the Azure user context: CloudLabs injects the candidate's Azure
#   credentials into the lab; the candidate runs 'az login' (device code or
#   the provided service principal / user) themselves before creating
#   resources. This bootstrap only INSTALLS tooling; it does not log in or
#   create the assessed resources.
#
# NOTE: package install needs INTERNET ACCESS at deploy time. Every install
#       step is guarded (try/continue) and must NOT hard-fail the CSE.
#
# Usage: bash bootstrap-01.sh <labuser>   (default: labuser)
# =============================================================================
set -uo pipefail

LAB_USER="${1:-labuser}"
LAB_HOME="/home/${LAB_USER}"

# Lab topology / naming hints (documented for candidates in README.txt).
JUMPVM_IP="10.0.0.4"           # JumpVM private IP
DB_NAME="salesdb"             # suggested Azure SQL database name (s2)

log() { echo "[bootstrap] $*"; }

HOSTNAME_NOW="$(hostname 2>/dev/null || echo unknown)"
log "Starting Lab 01 Azure-Networking bootstrap for user '${LAB_USER}' on host '${HOSTNAME_NOW}'"

# Ensure the lab user/home exists (CloudLabs normally provisions it; be safe).
if ! id "${LAB_USER}" >/dev/null 2>&1; then
    log "User ${LAB_USER} missing - creating it"
    useradd -m -s /bin/bash "${LAB_USER}" || true
fi
mkdir -p "${LAB_HOME}"

export DEBIAN_FRONTEND=noninteractive

# -----------------------------------------------------------------------------
# Base packages (best-effort)
# -----------------------------------------------------------------------------
log "Ensuring base packages (curl, gnupg, apt-transport-https, lsb-release) are present"
apt-get update -y >/dev/null 2>&1 || log "apt-get update failed (continuing)"
apt-get install -y curl gnupg apt-transport-https software-properties-common lsb-release ca-certificates >/dev/null 2>&1 || \
    log "base package install reported issues (continuing)"

# -----------------------------------------------------------------------------
# Install Azure CLI (az) - guarded, never hard-fail
# -----------------------------------------------------------------------------
install_azure_cli() {
    if command -v az >/dev/null 2>&1; then
        log "[az] Azure CLI already present - skipping install"
        return 0
    fi
    log "[az] Installing Azure CLI via Microsoft apt repo (Ubuntu 22.04)"
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null \
        | gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg 2>/dev/null \
        || { log "[az] WARNING: could not fetch signing key (needs internet) - skipping az install"; return 0; }

    AZ_REPO="$(lsb_release -cs 2>/dev/null || echo jammy)"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ ${AZ_REPO} main" \
        > /etc/apt/sources.list.d/azure-cli.list 2>/dev/null \
        || { log "[az] WARNING: could not write azure-cli repo list - skipping az install"; return 0; }

    apt-get update -y >/dev/null 2>&1 || log "[az] apt-get update (azure-cli repo) failed (continuing)"
    apt-get install -y azure-cli >/dev/null 2>&1 \
        || { log "[az] WARNING: azure-cli install failed (needs internet) - continuing"; return 0; }
    log "[az] Azure CLI installed: $(az version --query '\"azure-cli\"' -o tsv 2>/dev/null || echo unknown)"
}

# -----------------------------------------------------------------------------
# Install sqlcmd + mssql-tools (to connect to Azure SQL from this VM) - guarded
# -----------------------------------------------------------------------------
install_sql_tools() {
    if [ -x /opt/mssql-tools18/bin/sqlcmd ] || [ -x /opt/mssql-tools/bin/sqlcmd ]; then
        log "[sqlcmd] mssql-tools already present - skipping install"
        return 0
    fi
    log "[sqlcmd] Installing mssql-tools (sqlcmd) + unixodbc-dev"
    curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/prod.list 2>/dev/null \
        -o /etc/apt/sources.list.d/msprod.list \
        || { log "[sqlcmd] WARNING: could not fetch prod repo list for tools - skipping tools install"; return 0; }
    apt-get update -y >/dev/null 2>&1 || true
    ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev >/dev/null 2>&1 \
        || ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev >/dev/null 2>&1 \
        || { log "[sqlcmd] WARNING: mssql-tools install failed (needs internet) - continuing"; return 0; }
}

install_azure_cli
install_sql_tools

# =============================================================================
# README for the candidate
# =============================================================================
cat > "${LAB_HOME}/README.txt" <<EOF
Lab 01 - Azure Infrastructure (VNet, Azure SQL & Load Balancer)
===============================================================

A single Linux JumpVM is provisioned for you:

  JumpVM : labvm-<DeploymentID>   private IP ${JUMPVM_IP} (hostname labvm, Ubuntu 22.04)
           -> your workstation for running 'az' (Azure CLI) and 'sqlcmd'.

This VM has the Azure CLI and sqlcmd installed. CloudLabs supplies your Azure
user context; sign in before creating resources:

  az login            # follow the device-code / credential prompt
  az account show     # confirm the active subscription
  az account set --subscription "<SubscriptionId>"   # if more than one

Create every assessed resource in your lab resource group. Discover its name:

  az group list --query "[].name" -o tsv

(referred to below as <resourceGroupName>; a value like ODL-... or RG-...).

-------------------------------------------------------------------
Scenario 1 - Configure a Virtual Network with subnets
-------------------------------------------------------------------
  Goal: a Virtual Network exists in <resourceGroupName> with AT LEAST TWO
        subnets (e.g. an app/web subnet and a data/db subnet).
  Hints: az network vnet create ... --subnet-name <s1> ...
         az network vnet subnet create ... (add the second subnet)

-------------------------------------------------------------------
Scenario 2 - Deploy an Azure SQL Database and connect from the VM
-------------------------------------------------------------------
  Goal: an Azure SQL logical server and a database (suggested name '${DB_NAME}')
        exist in <resourceGroupName>; you can connect to it from this VM.
  Hints: az sql server create -l <region> -u <admin> -p '<StrongP@ss!>'
         az sql db create --name ${DB_NAME} --server <server> ...
         az sql server firewall-rule create ... (allow this VM / Azure services)
         sqlcmd -S <server>.database.windows.net -U <admin> -P '<pwd>' -d ${DB_NAME} -C

-------------------------------------------------------------------
Scenario 3 - Configure a Load Balancer fronting two VMs
-------------------------------------------------------------------
  Goal: a Load Balancer exists in <resourceGroupName> with a backend pool
        holding TWO backend VMs, a health probe, and a load-balancing rule.
  Hints: az network lb create ... --backend-pool-name <pool>
         az network lb probe create ... (e.g. TCP/HTTP probe)
         az network lb rule create ... (frontend:80 -> backend:80)
         Create two VMs and add their NICs to the backend pool.

Support: cloudlabs-support@spektrasystems.com | https://cloudlabs.ai/labs-support
EOF

# Ownership: lab user owns everything under its home.
log "Setting ownership of ${LAB_HOME} to ${LAB_USER}"
chown -R "${LAB_USER}:${LAB_USER}" "${LAB_HOME}" 2>/dev/null || \
    chown -R "${LAB_USER}" "${LAB_HOME}" 2>/dev/null || \
    log "WARNING: chown of ${LAB_HOME} failed"

log "Bootstrap complete. JumpVM ready: az + sqlcmd installed (guarded)."
exit 0
