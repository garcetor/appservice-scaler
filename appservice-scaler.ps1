Param(
 [string[]]$appserviceplan_config
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
    $appserviceplan_workers = [int]$appserviceplan_tokens[2]

    Set-AzAppServicePlan `
        -NumberofWorkers $appserviceplan_workers `
        -Name $appserviceplan_name `
        -ResourceGroupName $appserviceplan_rg
}
