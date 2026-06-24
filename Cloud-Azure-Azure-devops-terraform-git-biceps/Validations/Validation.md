[CloudLabs Validator](https://spektra-systems.visualstudio.com/CloudLabs-Validator)

Lab Code: AZUREDEVOPSLAB01

> Validations for this assessment run via the CloudLabs VM Agent (PowerShell HTTP-trigger functions)
> and query the **Azure control plane** with `Az` cmdlets (`Get-AzVirtualNetwork`, `Get-AzSqlServer` /
> `Get-AzSqlDatabase`, `Get-AzLoadBalancer`) against the lab resource group (`$resourceGroupName`).
> Each task maps to a script in this folder, keyed by its `<validation step="…"/>` UUID. Every validator
> retries up to 3 times (`Start-Sleep -Seconds 10`), always returns HTTP `OK`, and carries the pass/fail in
> the JSON `Status` field (`Succeeded`/`Failed`).

| Task | Validation step UUID | Script |
|---|---|---|
| Exercise 1 / Task 1 — Configure a VNet with two or more subnets | a1000001-0001-4a01-8b01-000000000001 | validate-task1-vnet-subnets.ps1 |
| Exercise 2 / Task 1 — Deploy an Azure SQL Database (salesdb) and connect from the VM | a1000002-0002-4a01-8b01-000000000002 | validate-task2-azure-sql.ps1 |
| Exercise 3 / Task 1 — Configure a Load Balancer fronting two VMs | a1000003-0003-4a01-8b01-000000000003 | validate-task3-load-balancer.ps1 |
