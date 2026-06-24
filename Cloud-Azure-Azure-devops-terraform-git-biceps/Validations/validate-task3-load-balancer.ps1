Import-Module Az.Compute
Import-Module Az.Accounts
Import-Module Az.Network

# Validation step: a1000003-0003-4a01-8b01-000000000003
# Exercise 3 / Task 1 - Configure a Load Balancer fronting two VMs
#
# Passes when a Load Balancer in the lab resource group has a backend pool with
# >= 2 backend IP configurations (two VMs) AND at least one load-balancing rule.
# A health probe is also expected and reported in the message.

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

        # Azure control-plane check: a Load Balancer with a backend pool holding
        # 2 backend members, a rule, and (expected) a probe.
        $lbs = Get-AzLoadBalancer -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

        $passed = $false
        $matchedLb = ""
        $poolCount = 0
        $probeCount = 0
        foreach ($lb in $lbs) {
            $ruleCount = ($lb.LoadBalancingRules | Measure-Object).Count
            $probeCountThis = ($lb.Probes | Measure-Object).Count

            # Count the largest backend pool membership across this LB's pools.
            $maxPoolMembers = 0
            foreach ($pool in $lb.BackendAddressPools) {
                $members = 0
                if ($pool.BackendIpConfigurations) {
                    $members = ($pool.BackendIpConfigurations | Measure-Object).Count
                }
                # Standard LB may also express members as LoadBalancerBackendAddresses.
                if ($pool.LoadBalancerBackendAddresses) {
                    $lbAddrs = ($pool.LoadBalancerBackendAddresses | Measure-Object).Count
                    if ($lbAddrs -gt $members) { $members = $lbAddrs }
                }
                if ($members -gt $maxPoolMembers) { $maxPoolMembers = $members }
            }

            if ($maxPoolMembers -ge 2 -and $ruleCount -ge 1) {
                $passed = $true
                $matchedLb = $lb.Name
                $poolCount = $maxPoolMembers
                $probeCount = $probeCountThis
                break
            }
        }

        if ($passed) {

            $message = @{
                Status  = "Succeeded"
                Message = "Load Balancer '$matchedLb' in resource group '$resourceGroupName' has a backend pool with $poolCount backend members (two VMs), a load-balancing rule, and $probeCount health probe(s). High-availability fronting is configured."
            } | ConvertTo-Json
        }
        else {

            $message = @{
                Status  = "Failed"
                Message = "No Load Balancer with a 2-VM backend pool and a load-balancing rule was found in resource group '$resourceGroupName'. Create a Load Balancer (e.g. 'az network lb create'), add a health probe ('az network lb probe create') and a rule ('az network lb rule create'), and add two VMs' NIC IP configurations to the backend pool."
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
