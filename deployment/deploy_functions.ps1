$password = $env:MAPPED_TERRAFORM_SP_SECRET | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($env:TERRAFORM_SP_APPLICATIONID, $password)
Connect-AzAccount -ServicePrincipal -Tenant $env:TERRAFORM_SP_TENANTID -Credential $credential
Get-AzSubscription -SubscriptionId $env:TERRAFORM_SP_SUBSCRIPTIONID | Select-AzSubscription | Out-Null
Set-Location ./function 
func azure functionapp publish tagfunctionapp --powershell
