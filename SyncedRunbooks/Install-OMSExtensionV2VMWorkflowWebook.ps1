workflow Install-OMSExtensionV2VMWorkflowWebhook 
{ 
 param ( 
        [Parameter(Mandatory=$false)] 
        [String]  
        $VMName, 
 
        [Parameter(Mandatory=$false)] 
        [String]  
        $VMResourceGroup, 
 
        [Parameter(Mandatory=$false)] 
        [String]  
        $VMLocation, 
         
        [Parameter(Mandatory=$false)] 
        [object]  
        $WebhookData         
    ) 
  
    # Set Error Preference and check this file
 $ErrorActionPreference = "Stop" 
 
 # Get Variables and Credentials 
 $AzureSubscriptionID    = Get-AutomationVariable ` 
                              -Name 'AzureSubscriptionID' 
 $OMSWorkspaceID         = Get-AutomationVariable ` 
                              -Name 'OMSWorkspaceID' 
    $OMSWorkspacePrimaryKey = Get-AutomationVariable ` 
                              -Name 'OMSWorkspacePrimaryKey' 
 $AzureCred              = Get-AutomationPSCredential ` 
                              -Name 'AzureCredentials' 
 
    # When webhook is used 
    if ($WebhookData -ne $null)  
    { 
        # Collect properties of WebhookData 
        $WebhookName    =   $WebhookData.WebhookName 
        $WebhookHeaders =   $WebhookData.RequestHeader 
        $WebhookBody    =   $WebhookData.RequestBody 
 
        $AuthorizationValue = $WebhookHeaders.AuthorizationValue 
        If ($AuthorizationValue -eq "OMSBook") 
        { 
            # Convert webhook body 
            $WebhookBodyObj = ConvertFrom-Json ` 
                                -InputObject $WebhookBody 
         
            # Get webhook input data 
            $VMName          = $WebhookBodyObj.VMName  
            $VMResourceGroup = $WebhookBodyObj.VMResourceGroup 
            $VMLocation      = $WebhookBodyObj.VMLocation 
        } 
        Else 
        { 
            $ErrorMessage = "Webhook was executed without authorization." 
            Write-Error ` 
            -Message $ErrorMessage ` 
            -ErrorAction Stop 
        } 
         
    } 
  
    # Create Checkpoint  
    Checkpoint-Workflow 
    inlinescript 
    { 
        Try 
        { 
            # Authenticate 
         $AzureAccount = Add-AzureRmAccount ` 
                            -Credential $Using:AzureCred ` 
                            -SubscriptionId $Using:AzureSubscriptionID  
        } 
        Catch 
        { 
            $ErrorMessage = 'Login to Azure failed.' 
            $ErrorMessage += " `n" 
            $ErrorMessage += 'Error: ' 
            $ErrorMessage += $_ 
            Write-Error ` 
            -Message $ErrorMessage ` 
            -ErrorAction Stop 
        } 
         
     
        # Set Variables 
     [string]$Settings          ='{"workspaceId":"' + $Using:OMSWorkspaceID + '"}'; 
     [string]$ProtectedSettings ='{"workspaceKey":"' + $Using:OMSWorkspacePrimaryKey + '"}'; 
 
     # Start extension installation 
     Write-Output ` 
        -InputObject 'OMS Extension Installation Started.' 
 
        Try 
        { 
            $ExtenstionStatus = Set-AzureRmVMExtension ` 
                                -ResourceGroupName $Using:VMResourceGroup ` 
                             -VMName $Using:VMName ` 
           -Name 'OMSExtension' ` 
           -Publisher 'Microsoft.EnterpriseCloud.Monitoring' ` 
           -TypeHandlerVersion '1.0' ` 
           -ExtensionType 'MicrosoftMonitoringAgent' ` 
           -Location $Using:VMLocation ` 
           -SettingString $Settings ` 
           -ProtectedSettingString $ProtectedSettings ` 
                                -ErrorAction Stop 
        } 
        Catch 
        { 
            $ErrorMessage = 'Failed to install OMS extension on Azure V2 VM.' 
            $ErrorMessage += " `n" 
            $ErrorMessage += 'Error: ' 
            $ErrorMessage += $_ 
            Write-Error ` 
            -Message $ErrorMessage ` 
            -ErrorAction Stop 
        } 
      
     # Output results 
     If ($ExtenstionStatus.IsSuccessStatusCode  -eq 'True') 
     { 
         Write-Output ` 
            -InputObject 'OMS Extension was installed successfully.' 
     } 
     Else 
     { 
         Write-Output ` 
            -InputObject 'OMS Extension was not installed.' 
 
            Write-Error ` 
            -Message $ExtenstionStatus.StatusCode ` 
            -ErrorAction Stop 
     } 
     
    }  
  
}  
