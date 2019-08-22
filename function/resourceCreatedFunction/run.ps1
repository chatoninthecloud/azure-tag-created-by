# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

Write-Information "Processing message"
$resourceUri = $QueueItem.data.resourceUri
$subscriptionId = $QueueItem.data.subscriptionId
$eventTime = $QueueItem.eventTime

Write-Information "resourceUri is $resourceUri"

$resource = Get-AzResource -ResourceId $resourceUri -ErrorAction SilentlyContinue
if (-not $resource) {
    Write-Information "Can't get resource with id $resourceUri"
    return
}
$resourceType = $resource.ResourceType

if (-not $resourceType) {
    Write-Information "No Resource Type"
    return
}

Write-Information "ResourceType is $resourceType"
if(-not (Test-ResourceTypeSupportTags -resourceType $resourceType -referentialFilePath ".\resourceCreatedFunction\tag-support.csv")) {
    return
}

$eventInitiator = Get-EventInitiatorDisplayName -queueItem $QueueItem
$displayName = Update-referential -resourceUri $resourceUri -subscriptionId $subscriptionId -creatorDisplayName $eventInitiator -eventTime $eventTime
Set-ResourceCreatedByTag -resourceTags $resource.Tags -creatorDisplayName $displayName -resourceUri $resourceUri

