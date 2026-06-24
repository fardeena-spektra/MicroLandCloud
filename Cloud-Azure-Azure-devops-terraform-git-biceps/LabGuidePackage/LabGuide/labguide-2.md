# **Scenario 2: Deploy an Azure SQL Database and Connect From the VM**

## **Lab Overview**

The sales platform needs a managed relational database. You will deploy an **Azure SQL Database** on a logical server in your lab resource group, open a **firewall rule** so the JumpVM can reach it, and prove connectivity by querying it with **`sqlcmd`** from the JumpVM.

This is an **assessment**: the task gives you the **required outcome**, not the exact commands. Choose your own approach using the **Azure CLI** and `sqlcmd`. After the task, press **Validate** to score it.

> **Note:** Connect to the **JumpVM** over SSH, run `az login`, and create all resources in your lab resource group. `sqlcmd` is pre-installed (`/opt/mssql-tools18/bin/sqlcmd -C` or `/opt/mssql-tools/bin/sqlcmd`).

## **Task 1: Deploy an Azure SQL logical server + database and connect to it**

**Required outcome:**

- An **Azure SQL logical server** exists in your lab resource group with an admin login you set.
- A **database named `salesdb`** exists on that server.
- A **firewall rule** allows access (e.g. "Allow Azure services" and/or the JumpVM's public IP) so you can connect.
- You can **connect from the JumpVM** with `sqlcmd` and run a simple query (e.g. `SELECT @@VERSION` or `SELECT name FROM sys.databases`) against `salesdb`.

Use `az sql server create` (set `--admin-user` and a strong `--admin-password`), then `az sql db create --name salesdb`. Add access with `az sql server firewall-rule create`. Then connect with `sqlcmd -S <server>.database.windows.net -U <admin> -P '<password>' -d salesdb -C` and run a test query. Do not delete the server or database after validating.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.

<validation step="79227acb-d73a-4b14-8724-6d3cceda6c78" />

**If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.**