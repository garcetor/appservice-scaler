Param(
 [string[]]
 # List of strings with the convention "<ResourceGroupName>|<AppServicePlanName>|<NumberOfWorkers>"
 $appserviceplan_config

 [int]
 # Number of worker instances to increase on each try
 $worker_increment_size = 1
)

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

# Connect using a Managed Service Identity
try
{
	$AzureContext = (Connect-AzAccount -Identity).context
}
catch
{
	Write-Output "There is no system-assigned user identity. Aborting.";
	exit
}

Write-Output $AzureContext

foreach ($appserviceplan in $appserviceplan_config) {
    $appserviceplan_tokens = $appserviceplan.split('|')

    $appserviceplan_rg = $appserviceplan_tokens[0]
    $appserviceplan_name = $appserviceplan_tokens[1]
    $desired_worker_count = [int]$appserviceplan_tokens[2]

    try
    {
        $current_worker_count = (Get-AzAppServicePlan -ResourceGroupName $appserviceplan_rg -Name $appserviceplan_name).Sku.Capacity

        if ($current_worker_count -lt $desired_worker_count)
        {
            $target_worker_count = $current_worker_count + $worker_increment_size;

            if ($target_worker_count -gt $desired_worker_count)
            {
                $target_worker_count = $desired_worker_count
            }

            Write-Output "App Service Plan '$appserviceplan_rg/$appserviceplan_name' not at desired worker count capacity '$current_worker_count', trying to increase to '$target_worker_count' workers"

            Set-AzAppServicePlan `
                -ResourceGroupName $appserviceplan_rg `
                -Name $appserviceplan_name `
                -NumberofWorkers $target_worker_count
        }
        else
        {
            Write-Output "App Service Plan '$appserviceplan_rg/$appserviceplan_name' already at desired worker count capacity '$current_worker_count'"
        }
    }
    catch
    {
        Write-Host "An error occurred when scaling out service plan '$appserviceplan_rg/$appserviceplan_name'"
        Write-Host $_
    }
}
