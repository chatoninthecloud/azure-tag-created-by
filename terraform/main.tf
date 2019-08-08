provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
 version = "=1.28.0"
}

data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "tagresourcegroup" {
  name     = var.resourceGroupName
  location = var.region
}

resource "azurerm_storage_account" "tagstorage" {
  name                     = var.storageAccountName
  resource_group_name      = "${azurerm_resource_group.tagresourcegroup.name}"
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_queue" "resourceCreatedQueue" {
  name                 = var.resourceCreatedQueue
  resource_group_name  = "${azurerm_resource_group.tagresourcegroup.name}"
  storage_account_name = "${azurerm_storage_account.tagstorage.name}"
}

resource "azurerm_storage_queue" "resourceDeletedQueue" {
  name                 = var.resourceDeletedQueue
  resource_group_name  = "${azurerm_resource_group.tagresourcegroup.name}"
  storage_account_name = "${azurerm_storage_account.tagstorage.name}"
}

resource "azurerm_storage_table" "tagTable" {
  name                 = var.tableName
  resource_group_name  = "${azurerm_resource_group.tagresourcegroup.name}"
  storage_account_name = "${azurerm_storage_account.tagstorage.name}"
}

resource "azurerm_eventgrid_event_subscription" "resourceCreatedSubscription" {
  name  = var.resourceCreatedSubscription
  scope = "${data.azurerm_subscription.current.id}"

  storage_queue_endpoint {
    storage_account_id = "${azurerm_storage_account.tagstorage.id}"
    queue_name         = "${azurerm_storage_queue.resourceCreatedQueue.name}"
  }

  included_event_types = ["Microsoft.Resources.ResourceWriteSuccess"] 
}

resource "azurerm_eventgrid_event_subscription" "resourceDeletedSubscription" {
  name  = var.resourceDeletedSubscription
  scope = "${data.azurerm_subscription.current.id}"

  storage_queue_endpoint {
    storage_account_id = "${azurerm_storage_account.tagstorage.id}"
    queue_name         = "${azurerm_storage_queue.resourceDeletedQueue.name}"
  }

  included_event_types = ["Microsoft.Resources.ResourceDeleteSuccess"] 
}

resource "azurerm_app_service_plan" "tagAppServicePlan" {
  name                = var.appServicePlanName
  location            = var.region
  resource_group_name = "${azurerm_resource_group.tagresourcegroup.name}"
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_application_insights" "tagAppInsight" {
  name                = var.applicationInsightName
  location            = var.region
  resource_group_name = "${azurerm_resource_group.tagresourcegroup.name}"
  application_type    = "other"
}

resource "azurerm_function_app" "tagFunctionApp" {
  name                      = var.functionAppName
  location                  = var.region
  resource_group_name       = "${azurerm_resource_group.tagresourcegroup.name}"
  app_service_plan_id       = "${azurerm_app_service_plan.tagAppServicePlan.id}"
  storage_connection_string = "${azurerm_storage_account.tagstorage.primary_connection_string}"
  version                   = "~2"
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME        = "powershell"
    APPINSIGHTS_INSTRUMENTATIONKEY  = "${azurerm_application_insights.tagAppInsight.instrumentation_key}",
    resourceGroupName               = var.resourceGroupName
    tableName                       = var.tableName
    storageName                     = var.storageAccountName
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "tagFunctionAppContributorRole" {
  scope                = "${data.azurerm_subscription.current.id}"
  role_definition_name = "Contributor"
  principal_id         = "${azurerm_function_app.tagFunctionApp.identity[0].principal_id}"
}