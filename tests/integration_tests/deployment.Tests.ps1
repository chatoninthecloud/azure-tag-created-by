Describe "Deployment of createdBy Tag tool" -Tag @("deploymentTests","integration_tests") {
    Context "The deployment has been done" {

        # Read configuration files to get values
        $defaultConfig = Get-Content -Raw -Path ".\terraform\var.tf.json" | ConvertFrom-Json
        $environmentConfigObject = Get-Content -Raw -Path ".\terraform\environment\dev.tfvars.json" | ConvertFrom-Json

        $environmentConfigHash = @{}
        foreach($currentSetting in $environmentConfigObject.PSObject.Properties) {
            $environmentConfigHash[$currentSetting.Name] = $currentSetting.Value
        }

        $deployedConfig = @{}
        foreach ($currentSetting in $defaultConfig.variable.PSObject.Properties) {
            $currentSettingName = $currentSetting.Name            
            if($environmentConfigHash.ContainsKey($currentSettingName)) {
                $deployedConfig[$currentSettingName] = $environmentConfigHash[$currentSettingName]
            }
            else {
                $deployedConfig[$currentSettingName] = $currentSetting.Value.default
            }            
        }
        

        It "The Resource Group should be created" {
            $resouceGroup = Get-AzResourceGroup -Name $deployedConfig["resourceGroupName"] -Location $deployedConfig["region"] -ErrorAction SilentlyContinue
            $resouceGroup | Should -Not -Be $null
        }

        It "The Storage Account should be created" {
            $storage = Get-AzStorageAccount -ResourceGroupName $deployedConfig["resourceGroupName"] -Name $deployedConfig["storageAccountName"]
            $storage | Should -Not -Be $null
        }

        It "The Storage Account should be created in the specified region" {
            $storage = Get-AzStorageAccount -ResourceGroupName $deployedConfig["resourceGroupName"] -Name $deployedConfig["storageAccountName"]
            $storage.Location | Should -Be $deployedConfig["region"]
        }

        It "The resource created queue should be created" {
            $storage = Get-AzStorageAccount -ResourceGroupName $deployedConfig["resourceGroupName"] -Name $deployedConfig["storageAccountName"]
            $resourceCreatedQueue = Get-AzStorageQueue -Name $deployedConfig["resourceCreatedQueue"] -Context $storage.Context -ErrorAction SilentlyContinue
            $resourceCreatedQueue | Should -Not -Be $null
        }

        It "The resource deleted queue should be created" {
            $storage = Get-AzStorageAccount -ResourceGroupName $deployedConfig["resourceGroupName"] -Name $deployedConfig["storageAccountName"]
            $resourceDeletedQueue = Get-AzStorageQueue -Name $deployedConfig["resourceDeletedQueue"] -Context $storage.Context -ErrorAction SilentlyContinue
            $resourceDeletedQueue | Should -Not -Be $null
        }

        It "The referential table should be created" {
            $storage = Get-AzStorageAccount -ResourceGroupName $deployedConfig["resourceGroupName"] -Name $deployedConfig["storageAccountName"]
            $referentialTable = Get-AzStorageTable -Name $deployedConfig["tableName"] -Context $storage.Context
            $referentialTable | Should -Not -Be $null
        }

        It "The resource created Event Grid Subscription should be created" {
            $resourceCreatedSubscription = Get-AzEventGridSubscription -EventSubscriptionName $deployedConfig["resourceCreatedSubscription"] -ErrorAction SilentlyContinue
            $resourceCreatedSubscription | Should -Not -Be $null
        }

        It "The resource deleted Event Grid Subscription should be created" {
            $resourceDeletedSubscription = Get-AzEventGridSubscription -EventSubscriptionName $deployedConfig["resourceDeletedSubscription"] -ErrorAction SilentlyContinue
            $resourceDeletedSubscription | Should -Not -Be $null
        }

        It "The App Service Plan should be created" {
            $appServicePlan = Get-AzAppServicePlan -ResourceGroupName $deployedConfig["resourceGroupName"] -Name $deployedConfig["appServicePlanName"] -ErrorAction SilentlyContinue
            $appServicePlan | Should -Not -Be $null            
        }

        It "The Function App should be created" {
            $functionApp = Get-AzResource -Name $deployedConfig["functionAppName"] -ResourceGroupName $deployedConfig["resourceGroupName"]
            $functionApp | Should -Not -Be $null
        }

        It "The Application Insight should be created" {
            $appInsight = Get-AzApplicationInsights -ResourceGroupName $deployedConfig["resourceGroupName"] -Name $deployedConfig["applicationInsightName"]
            $appInsight | Should -Not -Be $null
        }
    }
}