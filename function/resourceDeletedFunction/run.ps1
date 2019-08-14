# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "Processing message"
$resourceUri = $QueueItem.data.resourceUri
$subscriptionId = $QueueItem.data.subscriptionId

$cloudTable = Get-AzTableTable -storageAccountName $env:storageName -resourceGroup $env:resourceGroupName -TableName $env:tableName 
$formatedResourceUri = ($resourceUri -replace "/","-").ToLower()
$row = Get-AzTableRow -Table $cloudTable -PartitionKey $formatedResourceUri -RowKey $subscriptionId

if ($row) {
    Write-Host "Removing resource $resourceUri from referential"
    $row | Remove-AzTableRow -Table $cloudTable    
}
