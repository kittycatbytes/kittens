cls
#Import SharePoint Online Management Shell
Import-Module Microsoft.Online.SharePoint.Powershell -ErrorAction SilentlyContinue

Add-PSSnapIn Microsoft.SharePoint.PowerShell  -ErrorAction SilentlyContinue


$SiteUrl = "https://onewri.sharepoint.com/sites/paymentprocessing" 


$UserName = Read-Host -Prompt "Enter User Name"
portal_admin@onewri.onmicrosoft.com
$SecurePassword = Read-Host -Prompt "Enter password" -AsSecureString
@Portal002

$cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $UserName, $SecurePassword


Try
{

	Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
	Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
    Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.WorkflowServices.dll"


     
                

    $clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl) 
    $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword) 
    $clientContext.Credentials = $credentials

    Write-Host "Connected to SharePoint Online site: " $SiteUrl -ForegroundColor Green
    Write-Host ""



}
Catch
{
    $SPOConnectionException = $_.Exception.Message
    Write-Host ""
    Write-Host "Error:" $SPOConnectionException -ForegroundColor Red
    Write-Host ""
    Break
}



if (!$clientContext.ServerObjectIsNull.Value) 
{ 
        $web = $clientContext.Web
        $lists = $web.Lists
			$clientContext.Load($lists);
			$clientContext.ExecuteQuery();

        $workflowServicesManager = New-Object Microsoft.SharePoint.Client.WorkflowServices.WorkflowServicesManager($clientContext, $web);
        $workflowSubscriptionService = $workflowServicesManager.GetWorkflowSubscriptionService();
        $workflowInstanceService = $workflowServicesManager.GetWorkflowInstanceService();

        Write-Host ""
        Write-Host "Exporting Lists" -ForegroundColor Green
        Write-Host ""

        foreach ($list in $lists)       
        {  
			
			#if ($list.Title -eq "WRI Payment Processing Tasks"){
			Write-Host "Checking List: " $list.Title
			$workflowSubscriptions = $workflowSubscriptionService.EnumerateSubscriptionsByList($list.Id);
			$clientContext.Load($workflowSubscriptions);                
			$clientContext.ExecuteQuery();                
			$wfSubs = @()
			foreach($workflowSubscription in $workflowSubscriptions)
			{   
			
				$wfSubs += New-Object -TypeName PSCustomObject -Property @{
					Name = $workflowSubscription.Name
					wfSubId = $workflowSubscription.Id
					}
				}

					$camlQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
					#$camlQuery.ViewXml = "<View Override='TRUE'><ViewFields><FieldRef Name='Title' /></ViewFields><RowLimit>5000</RowLimit></View>";
					$camlQuery.ViewXml = "<View><ViewFields><FieldRef Name='Title' /></ViewFields><Query><Where><Geq><FieldRef Name='ID'/>" + "<Value Type='Number'>1</Value></Geq></Where></Query><RowLimit>5000</RowLimit></View>";
					#$camlQuery.Query = " <Where><Geq><FieldRef Name='Modified' /><Value Type='DateTime'><Today OffsetDays='-365' /></Value></Geq></Where>"
					$listItems = $list.GetItems($camlQuery);
					$clientContext.Load($listItems);
					$clientContext.ExecuteQuery();
	
					foreach($listItem in $listItems)
					{
						$itNum = $listItem.ID
						$workflowInstanceCollection = $workflowInstanceService.EnumerateInstancesForListItem($list.Id, $itNum);
						$clientContext.Load($workflowInstanceCollection);
						$clientContext.ExecuteQuery();
						foreach ($workflowInstance in $workflowInstanceCollection)
						{              
							$listName = $list.Title
							$itemStatus = $workflowInstance.Status
							$itemProps = $workflowInstance.Properties
							$itemUStatus = $workflowInstance.UserStatus
							$itemError = $workflowInstance.FaultInfo
							$itemCreated = $workflowInstance.InstanceCreated
							$itemMod = $workflowInstance.LastUpdated
							$wfId = $workflowInstance.Id
							$wfSId = $workflowInstance.WorkflowSubscriptionId
							foreach ($wfSub in $wfSubs){
																																																																if ($wfSub.wfSubId -eq $wfSId){
																																																																	$wfName = $wfSub.Name
									}
								}
                                if($itemStatus -eq "Suspended"){
																																																																	New-Object -TypeName PSCustomObject -Property @{
																																																																		List = $listName
																																																																		WFName = $wfName
																																																																		Created = $itemCreated
																																																																		ItemNum = $itNum
																																																																		Status = $itemStatus
																																																																		UStatus = $itemUStatus
																																																																		WFError = $itemError
																																																																		Modified = $itemMod
																																																																		Properties = $itemProps
																																																																		WFId = $wfId
                                                                                                                                                                                                                                                                           } | export-csv -Path c:\AllSuspendedWorkflows3.csv -NoTypeInformation -Append                                                                                                 
                                                                                                                                                                                                                                                
																																																																		# if($itemUStatus -eq "Completed" -And $itemStatus -eq "Suspended"){
                                          if($itemStatus -eq "Suspended"){
										  $workflowInstanceService.TerminateWorkflow($workflowInstance);
										  $object = New-Object 'system.collections.generic.dictionary[string,object]'
										  $object.Add("WorkflowStart", "StartWorkflow");
										  $workflowInstanceService.StartWorkflowOnListItem($workflowSubscription, $itNum, $object);
										  Write-Host "Workflow "$wfName " Terminated on item ID: " $itNum " ; Status: " $itemStatus "; User Status: " $itemUStatus " with ID: " $wfId
										  }
																																																																		Write-Host "Logging: "$wfName " on item ID: " $itNum " ; Status: " $itemStatus "; User Status: " $itemUStatus " with ID: " $wfId
                                                                                                                                                                                                                                
                                        }                                                                                                                                                                                             
                         }
                         Write-Host "List Item ID: " $itNum   
					}
                                                                                                                                                
            #}
                                                                                
    }                            
}                     
  

