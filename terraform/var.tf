variable "region" {
    type        = string
    default     = "NorthEurope" 
    description = "Region where resources will be created"
}
variable "resourceGroupName" {
    type        = string
    default     = "tag-rg"
    description = "Name of the Resource Group where resources will be created"
}
variable "storageAccountName" {
    type        = string
    description = "Name of the Resource Group used for queue and Function App"
}
variable "resourceCreatedQueue" {
    type        = string
    default     = "createdresources"
    description = "Name of the queue used as endpoint for the created resources Event Grid Subscription"
}
variable "resourceDeletedQueue" {
    type        = string
    default     = "deletedresources"
    description = "Name of the queue used as endpoint for the deleted resources Event Grid Subscription"
}
variable "tableName" {
    type        = string
    default     = "resourcereferential"
    description = "Name of the Table Storage used for stocking resources creators"
}
variable "resourceCreatedSubscription" {
    type        = string
    default     = "resourceCreatedSubscription"
    description = "Name of the Event Grid Subscription for created resources"
}
variable "resourceDeletedSubscription" {
    type        = string
    default     = "resourceDeletedSubscription"
    description = "Name of the Event Grid Subscription for deleted resources"
}
variable "appServicePlanName" {
    type        = string
    default     = "tagappservice"
    description = "Name of the App Service Plan"
}
variable "functionAppName" {
    type        = string
    description = "Name of the Function App"
}
variable "applicationInsightName" {
    type        = string
    default     = "taggappinsight"
    description = "Name of the Application Insight used to monitor the Function App"
}

