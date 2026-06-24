# Exercise 1: Configure a Virtual Network with Subnets

### Estimated Duration: 30 Minutes

## Lab Overview

The sales platform needs an isolated network foundation before any compute or data services are deployed. You will create a **Virtual Network** in your lab resource group and carve it into **at least two subnets** so the application tier and the data tier can be segmented (and later protected with separate NSGs/route tables).

This is an **assessment**: each task gives you the **required outcome** — not click-by-click steps. Design the network yourself, then fix/build it. After the task, press **Validate** to score it.

> **Note:** Connect to the **JumpVM** over SSH and use the **Azure CLI** (`az login` first). Create all resources in your lab resource group (`az group list --query "[].name" -o tsv`).

## Task 1: Create a VNet with two or more subnets

**Required outcome:** A **Virtual Network exists in your lab resource group** with **at least two subnets**. For example, an address space of `10.10.0.0/16` with an `app` subnet (`10.10.1.0/24`) and a `data` subnet (`10.10.2.0/24`). The two subnets must be non-overlapping ranges within the VNet address space.

Use `az network vnet create` to create the VNet and its first subnet, then `az network vnet subnet create` to add the second subnet (or pass multiple subnets at creation). Confirm with `az network vnet show` / `az network vnet subnet list` that the VNet reports two or more subnets. You do not need to attach NICs to the subnets for this task.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="a1000001-0001-4a01-8b01-000000000001" />
