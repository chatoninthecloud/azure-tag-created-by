[CmdletBinding()]
param(
    [switch]
    $unitTests,
    [switch]
    $deploymentTests,
    [switch]
    $acceptanceTests
)

function Connect-TestAzAccount {
    $password = $env:MAPPED_TERRAFORM_SP_SECRET | ConvertTo-SecureString -asPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ($env:TERRAFORM_SP_APPLICATIONID, $password)
    Connect-AzAccount -ServicePrincipal -Tenant $env:TERRAFORM_SP_TENANTID -Credential $credential
    Get-AzSubscription -SubscriptionId $env:TERRAFORM_SP_SUBSCRIPTIONID | Select-AzSubscription
}

if ($unitTests.IsPresent) {
    $filesToMesureCoverage = @(
        (Get-Item -Path ".\function\Modules\tagResource\tagResource.psm1").FullName,
        (Get-Item -Path ".\function\resourceCreatedFunction\run.ps1").FullName,
        (Get-Item -Path ".\function\resourceDeletedFunction\run.ps1").FullName
    )
    Invoke-Pester -Path ".\tests\unit_tests" -OutputFormat NUnitXml -OutputFile UnitTestResults.xml -CodeCoverage $filesToMesureCoverage -CodeCoverageOutputFile unitTestCoverage.xml -CodeCoverageOutputFileFormat JaCoCo
}

if ($deploymentTests.IsPresent) {    
    Connect-TestAzAccount
    Invoke-Pester -Path ".\tests\integration_tests" -OutputFormat NUnitXml -OutputFile IntegrationTestResults.xml    
}

if ($acceptanceTests.IsPresent) {
    Connect-TestAzAccount
    Invoke-Pester -Path ".\tests\acceptance_tests" -OutputFormat NUnitXml -OutputFile AcceptanceTestResults.xml 
}