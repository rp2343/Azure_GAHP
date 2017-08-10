Param
(
    [Parameter (Mandatory = $true)]
    [object] $WebhookData
)

$connectionName = "AzureRunAsConnection"

try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName
    
    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
    
    "Logging in to Azure AD..."
    Connect-AzureAD `
		-TenantId $servicePrincipalConnection.TenantId `
		-ApplicationId $servicePrincipalConnection.ApplicationId `
		-CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
}
catch 
{
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

#Get all the properties from Webhook
if($WebhookData -ne $null)
{
    #Get all the properties from Webhook
    $WebhookData = ConvertFrom-Json -InputObject $WebhookData
    Write-Output ("")
    Write-Output ("WebhookData - $WebhookData")
    Write-Output ("")
    
    #Get common properties
    $WebhookName = $WebhookData.WebhookName
    $WebhookHeader = $WebhookData.RequestHeader
    $WebhookBody = ConvertFrom-Json -InputObject $WebhookData.RequestBody    
    $DateTime = Get-Date    
    Write-Output ("Runbook started from Webhook $WebhookName")    
    Write-Output ("Runbook started at $DateTime")
    
    # Conditional information
    $SecureToken = $WebhookBody.SecureToken
    $ExecutionMode = $WebhookBody.ExecutionMode    
    Write-Output ("Execution Mode : $ExecutionMode")
    
    # DeleteResource execution mode
    $ResourceGroupName = $WebhookBody.ResourceGroupName
    $VmssName = $WebhookBody.VmssName    
    Write-Output ("Resource group : $ResourceGroupName | VMSS Name : $VmssName")    
    
    
    $JobResourceGroupName = $WebhookBody.JobResourceGroupName
    $JobCollectionName = $WebhookBody.JobCollection
    Write-Output ("Resource group : $JobResourceGroupName | Job collection : $JobCollectionName")
    
    
}

$token = "uu2q3rjf98eru9n3q4ofju934qojfnewijq3ioijef="
if($SecureToken -ne $token)
{    
    Write-Output "Token : $SecureToken";
    Write-Output "Unauthorized access to runbook";
    exit;
}
#Function Add-Entity: Adds an employee entity to a table.
function Add-Entity() {
    [CmdletBinding()]
    param(
       $table,
       [String]$PartitionKey,
       [String]$rowKey,
       [Boolean]$isSucceeded
    )
  
  $entity = New-Object -TypeName Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity -ArgumentList $partitionKey, $rowKey
  $entity.Properties.Add("IsSucceeded", $isSucceeded)

  $result = $table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Insert($entity))
}
switch($ExecutionMode)
{
    "DeleteResource" {
        try
        {
            $ResourceGroup = Get-AzureRmResourceGroup -name $ResourceGroupName
            if($VmssName -And $ResourceGroup)
            {
                $Resource = Get-AzureRmResource -ResourceName $VmssName -ResourceGroupName $ResourceGroupName
                if($Resource)
                {
                    $Message = "Deleting vmss"
                    Write-Output ("$Message $Resource.ResourceName")
                    $IsResourceDeleted = Remove-AzureRmResource -ResourceId $Resource.ResourceId -Force
                    if($IsResourceDeleted -eq "True")
                    {
                        Write-Output ("$Message $Resource.ResourceName : complete")
                    }
                    else
                    {
                        Write-Output ("$Message $Resource.ResourceName : failed")
                    }
                }
            }
            ElseIf($ResourceGroup)
            {
                $Message = "Deleting Resource Group"
                Write-Output ("$Message : '$ResourceGroupName'")
                $IsRgDeleted = Remove-AzureRmResourceGroup -Name $ResourceGroupName -Force
                if($IsRgDeleted -eq "True")
                {
                    Write-Output ("$Message $ResourceGroupName : complete")
                }
                else
                {
                    Write-Output ("$Message $ResourceGroupName : failed")
                }
            }
        }
        catch
        {
            if (!$ResourceGroup)
            {
                $ErrorMessage = "$Message $ResourceGroupName : failed"
                Write-Error -Message $_.Exception
                throw $ErrorMessage
                exit;
            }
            else
            {
                Write-Error -Message $_.Exception
                throw $_.Exception
                exit;
            }
        }
    }
    "DeleteExpiredJobs" {
        #Get all ARM resources from all resource groups
        try
        {
            $ResourceGroup = Get-AzureRmResourceGroup -name $JobResourceGroupName
            if($ResourceGroup)
            {
                $result = Get-AzureRmSchedulerJob -JobCollectionName $JobCollectionName -ResourceGroupName $JobResourceGroupName
                foreach($job in $result)
                {
                    if ((get-date) -gt (get-date $job.StartTime) -and ($job.JobName -ne "CleanerJob"))
                    {
                        Write-Output ("Job $job.JobName is expired (Start time - $job.StartTime UTC)")
                        Write-Output ("Deleting $job.JobName job...")
                        Remove-AzureRmSchedulerJob -JobCollectionName $JobCollectionName -JobName $job.JobName -ResourceGroupName $JobResourceGroupName
                        Write-Output ("Deleted $job.JobName job")
                    }    
                }
            }
            else
            {
                Write-Output ("Resource Group $JobResourceGroupName not found.")
            }
        }
        catch
        {
            Write-Error -Message $_.Exception
            throw $_.Exception
            exit;
        }
    }
    default { 
        Write-Output("No execution mode found in input webhook data.")
    }
}