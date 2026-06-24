This Package Includes

Deliverables Included in the Package

• Lab Guide
• Master Document
• Inline Validations
• ARM Deployment + Custom Script Extension
• Solution Guide (facilitator-only)
• Instructor Brief (facilitator-only)

Inline Validations

Pre-configured inline validations enabled (3 task validations, via the CloudLabs VM Agent — PowerShell, querying the Azure control plane with Az cmdlets against the lab resource group). Each task maps to a validation script keyed by a validation-step UUID; see Validations/Validation.md.

Inline Assessment Questions

Not included in this package (knowledge-check questions are out of scope for this assessment).

Lab Environment Setup & Deployment

Lab provisioning and setup include one or more of the following components:

• ARM template deployment — ONE CloudLabs Linux JumpVM (Ubuntu Server 22.04 LTS, Standard_D2s_v3, labvm-<DeploymentID>, 10.0.0.4) on a base labvNet placeholder, in the lab resource group
• Custom Script Extension (CSE / Bash) — installs the Azure CLI (az) and sqlcmd/mssql-tools on the JumpVM so the candidate can build and connect to the assessed resources; CloudLabs injects the Azure user context (the candidate runs az login)
• NSG allows SSH (22) to the JumpVM; the candidate opens any further access (Azure SQL firewall rules, Load Balancer rules) as part of the exercises
• Supporting deployment configurations as required

Assessment Profile

• Domain: Azure / Azure DevOps / Terraform / Git / Bicep
• Level: Intermediate
• Target duration: 120 minutes (120 minutes provisioned)
• Hosting tier: A (native — one Azure Linux JumpVM, Standard_D2s_v3, with Azure CLI + sqlcmd)

Scenario & Validation Summary

• Exercise 1 / Task 1 — Configure a Virtual Network with at least two subnets → validate-task1-vnet-subnets.ps1
• Exercise 2 / Task 1 — Deploy an Azure SQL Database (salesdb) and connect from the JumpVM with sqlcmd → validate-task2-azure-sql.ps1
• Exercise 3 / Task 1 — Configure a Load Balancer fronting two VMs (backend pool + probe + rule) → validate-task3-load-balancer.ps1

LAB REQUIREMENT

Build the Azure foundation for a sales platform: a segmented Virtual Network (>= 2 subnets), a managed Azure SQL Database reachable from the JumpVM, and a Load Balancer fronting two backend VMs with a backend pool, a health probe, and a load-balancing rule. All assessed resources are created by the candidate in the lab resource group; validators check the Azure control plane for the required configuration.

Note: Azure resource creation requires the candidate to sign in with az login (CloudLabs supplies the Azure user context) and hold Contributor on the lab resource group. Package installation at deploy time needs internet access; the bootstrap guards every install step so the CSE never hard-fails.

Exclusions

This package does not include:

• Scoring or grading mechanisms beyond pass/fail inline validations
• Inline assessment questions
• Pre-created assessed resources (the VNet, Azure SQL server/database, and Load Balancer are built by the candidate)
