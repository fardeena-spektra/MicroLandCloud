# **Scenario 3: Configure a Load Balancer Fronting Two VMs**

## **Lab Overview**

The sales platform's web tier must survive the loss of a single VM and spread traffic across instances. You will configure an **Azure Load Balancer** in your lab resource group that fronts **two backend VMs**, with a **backend pool**, a **health probe**, and a **load-balancing rule** distributing inbound traffic.

This is an **assessment**: the task gives you the **required outcome**, not the exact commands. Choose your own approach using the **Azure CLI**. After the task, press **Validate** to score it.

> **Note:** Connect to the **JumpVM** over SSH, run `az login`, and create all resources in your lab resource group. Put the Load Balancer and both backend VMs in the same VNet/subnet so the backend pool can reach them.

## **Task 1: Build a Load Balancer with a 2-VM backend pool, probe, and rule**

**Required outcome:**

- A **Load Balancer** exists in your lab resource group with a frontend IP configuration.
- Its **backend pool contains two backend IP configurations** — i.e. **two VMs** (each NIC's IP config) are members of the pool.
- A **health probe** is configured (e.g. TCP/22 or HTTP/80).
- A **load-balancing rule** maps a frontend port to the backend pool (e.g. frontend `80` → backend `80`) and references the probe.

Create the two backend VMs (Linux is fine), then `az network lb create` with a backend pool, `az network lb probe create` for the probe, and `az network lb rule create` for the rule. Add each VM's NIC IP configuration to the backend pool (`az network nic ip-config address-pool add`). Confirm with `az network lb show` that the backend pool has two members and a rule exists. Do not delete the Load Balancer or VMs after validating.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.

<validation step="e0c29ec1-b782-4788-8fce-3a6453bb4a7e" />

**If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.**