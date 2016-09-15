cls
#Import SharePoint Online Management Shell
Import-Module Microsoft.Online.SharePoint.Powershell -ErrorAction SilentlyContinue

Add-PSSnapIn Microsoft.SharePoint.PowerShell  -ErrorAction SilentlyContinue

#region Input Variables 

$SiteUrl = "https://onewri.sharepoint.com/sites/paymentprocessing" #Replace the URL


$UserName = Read-Host -Prompt "Enter User Name"
$SecurePassword = Read-Host -Prompt "Enter password" -AsSecureString

$cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $UserName, $SecurePassword

#endregion

#region Connect to SharePoint Online tenant and Create Context using CSOM

Try
{
    #region Load SharePoint Client Assemblies

	Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
	Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
    Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.WorkflowServices.dll"

    #endregion

     
    #region connect/authenticate to SharePoint Online and get ClientContext object.. 	

    $clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl) 
    $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword) 
    $clientContext.Credentials = $credentials

    Write-Host "Connected to SharePoint Online site: " $SiteUrl -ForegroundColor Green
    Write-Host ""

    #endregion


}
Catch
{
    $SPOConnectionException = $_.Exception.Message
    Write-Host ""
    Write-Host "Error:" $SPOConnectionException -ForegroundColor Red
    Write-Host ""
    Break
}

#endregion


if (!$clientContext.ServerObjectIsNull.Value) 
{ 
        $web = $clientContext.Web
        $lists = $web.Lists
	    $clientContext.Load($lists);
	    $clientContext.ExecuteQuery();

        $workflowServicesManager = New-Object Microsoft.SharePoint.Client.WorkflowServices.WorkflowServicesManager($clientContext, $web);
        $workflowSubscriptionService = $workflowServicesManager.GetWorkflowSubscriptionService();
        $workflowInstanceSevice = $workflowServicesManager.GetWorkflowInstanceService();



        foreach ($list in $lists)       
        {  
			#Remove this if statement for all lists
			if ($list.Title -eq "WRI Payment Requests"){
				$workflowSubscriptions = $workflowSubscriptionService.EnumerateSubscriptionsByList($list.Id);
				$clientContext.Load($workflowSubscriptions);                
				$clientContext.ExecuteQuery();                
				foreach($workflowSubscription in $workflowSubscriptions)
				{   
				#Run for a particular Workflow Name
				#if($workflowSubscription.Name -eq "WRI Payment Processing WF001"){	
						$count = 0
						
						$wfSub = @()
						$wfSub += New-object -TypeName PSCustomObject -Property @{
							SubscriptionId = $workflowSubscription.Id
							Name = $workflowSubscription.Name
						}
				}
						
						$camlQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
						$camlQuery.ViewXml = "<View> <ViewFields><FieldRef Name='Title' /></ViewFields></View>";
						$listItems = $list.GetItems($camlQuery);
						$clientContext.Load($listItems);
						$clientContext.ExecuteQuery();

						foreach($listItem in $listItems)
						{
							$itNum = $listItem.ID
							#if($itNum -gt 3631){
								#if($itNum -lt 3664){							
								$workflowInstanceCollection = $workflowInstanceSevice.EnumerateInstancesForListItem($list.Id, $itNum);
								$clientContext.Load($workflowInstanceCollection);
								$clientContext.ExecuteQuery();
								foreach ($workflowInstance in $workflowInstanceCollection)
								{	
									$itemSubID = $workflowInstance.WorkflowSubscriptionId
									$itemWFName = $wfSub.Name | Where-Object {$_.SubscriptionId -eq $itemSubID}}
									$itemStatus = $workflowInstance.Status
									$itemProps = $workflowInstance.Properties
									$itemUStatus = $workflowInstance.UserStatus
									$itemError = $workflowInstance.FaultInfo
									$itemCreated = $workflowInstance.InstanceCreated
									$itemMod = $workflowInstance.LastUpdated
									Write-Host "Logging: "$itemWFName " on item ID: " $itNum " ; Status: " $itemStatus "; User Status: " $itemUStatus, 							
									# For a particular Workflow Status
									#if($workflowInstance.Status -eq "Started"){
										
										#If there is a workflow Error
										#if($itemError){	
										
											New-Object -TypeName PSCustomObject -Property @{
												WFName= $itemWFName
												Created= $itemCreated
												ItemNum= $itNum
												Status= $itemStatus
												UStatus= $itemUStatus
												WFError= $itemError
												Modified= $itemMod
												Properties= $itemProps
												} | export-csv -Path c:\temp\AllPaymentProcessingWorkflows2.csv -NoTypeInformation -Append							
										
										
												
												#Tally each workflow in the loop
												
												#[datetime]$date = "05/12/2016 12:00 AM"								
											#For Terminating the Workflow Instance

													#$workflowInstanceSevice.ResumeWorkflow($workflowInstance);
													#Write-Host "Workflow with ID " $itNum " was Resume"
													
													$count ++
													Write-Host "Workflow ID is "$workflowInstance.Id
											#}
										
										#}
									#}							
								}
								
							#}
								
						}
							
				
					
				#}
        }		
    }                         
   
   
    
    
    
    
