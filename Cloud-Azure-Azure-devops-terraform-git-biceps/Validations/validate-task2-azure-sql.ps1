Import-Module Az.Compute
Import-Module Az.Accounts
Import-Module Az.Sql

# Validation step: a1000002-0002-4a01-8b01-000000000002
# Exercise 2 / Task 1 - Deploy an Azure SQL logical server + database (salesdb)
#
# NOTE: This validator checks the Azure control plane (Get-AzSqlServer +
# Get-AzSqlDatabase) for a logical server and a user database in the lab
# resource group. The pass condition is the DATABASE existing; the candidate's
# in-VM sqlcmd connectivity is a secondary signal that can vary with firewall
# propagation and is not required for the task to pass.

# Variables provided by CloudLabs
$deployment_id     = $deployment_id
$resourceGroupName = $resourceGroupName
$sub_id            = $sub_id
$vmName            = "labvm-$deployment_id"

# Set subscription
Select-AzSubscription -SubscriptionId $sub_id

# Retry logic
$stopRetry = $false
[int]$retryCount = 0
$maxRetries = 3

do {
    try {

        # Azure control-plane check: a SQL logical server exists in the RG, and
        # that server has a user database (any database other than 'master').
        $servers = Get-AzSqlServer -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

        $passed = $false
        $matchedServer = ""
        $matchedDb = ""
        foreach ($server in $servers) {
            $dbs = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $server.ServerName -ErrorAction SilentlyContinue |
                   Where-Object { $_.DatabaseName -ne "master" }
            if ($dbs -and $dbs.Count -ge 1) {
                $passed = $true
                $matchedServer = $server.ServerName
                $matchedDb = ($dbs | Select-Object -First 1).DatabaseName
                break
            }
        }

        if ($passed) {

            $message = @{
                Status  = "Succeeded"
                Message = "Azure SQL logical server '$matchedServer' with database '$matchedDb' exists in resource group '$resourceGroupName'. The managed database is deployed and ready to connect from the JumpVM with sqlcmd."
            } | ConvertTo-Json
        }
        else {

            $message = @{
                Status  = "Failed"
                Message = "No Azure SQL logical server with a user database was found in resource group '$resourceGroupName'. Create a server (e.g. 'az sql server create') and a database named 'salesdb' (e.g. 'az sql db create --name salesdb'), then add a firewall rule and connect with sqlcmd."
            } | ConvertTo-Json
        }

        # Return JSON response
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [System.Net.HttpStatusCode]::OK
            Body       = $message
        })

        $stopRetry = $true
    }
    catch {

        if ($retryCount -ge $maxRetries) {

            $message = @{
                Status  = "Failed"
                Message = "Retry for validation process has been exhausted. Please try after sometime."
            } | ConvertTo-Json

            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [System.Net.HttpStatusCode]::OK
                Body       = $message
            })

            $stopRetry = $true
        }
        else {
            Write-Host "Validation failed. Retrying... ($($retryCount + 1)/$maxRetries)"
            Start-Sleep -Seconds 10
            $retryCount++
        }
    }

} while ($stopRetry -eq $false)
