Import-Module Az.Compute
Import-Module Az.Accounts
Import-Module Az.Network

# Validation step: a1000001-0001-4a01-8b01-000000000001
# Exercise 1 / Task 1 - Configure a Virtual Network with at least two subnets

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

        # Azure control-plane check: at least one VNet in the RG has >= 2 subnets.
        # The base labvNet has a single subnet, so passing requires the candidate
        # to have created a VNet with two or more subnets.
        $vnets = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

        $passed = $false
        $matchedVnet = ""
        foreach ($vnet in $vnets) {
            if ($vnet.Subnets.Count -ge 2) {
                $passed = $true
                $matchedVnet = $vnet.Name
                break
            }
        }

        if ($passed) {

            $message = @{
                Status  = "Succeeded"
                Message = "Virtual Network '$matchedVnet' in resource group '$resourceGroupName' has 2 or more subnets, satisfying the network segmentation requirement."
            } | ConvertTo-Json
        }
        else {

            $message = @{
                Status  = "Failed"
                Message = "No Virtual Network with at least two subnets was found in resource group '$resourceGroupName'. Create a VNet (e.g. 'az network vnet create') and add a second subnet (e.g. 'az network vnet subnet create') so the VNet has 2 or more non-overlapping subnets."
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
