$jsonFileUrl = "https://raw.githubusercontent.com/345Nathan-Harrison/Testing/main/Image-Builder/Win11Template.json"
$jsonFileName = "Win11Template.json"

if ((Test-Path -Path "C:\dev\Dev Box\Testing\Image-Builder\Template") -eq $false) {
    New-Item -ItemType Directory -Path "C:\dev\Dev Box\Testing\Image-Builder\Template"
}

if ((Test-Path -Path "C:\dev\Dev Box\Testing\Image-Builder\Template\$jsonFileName") -eq $true){
    $confirmation = Read-Host "Are you sure you want to replace the template? (Y/N):"
    if ($confirmation -eq "Y" -or $confirmation -eq "y"){
        Invoke-WebRequest -Uri $jsonFileUrl -OutFile "C:\dev\Dev Box\Testing\Image-Builder\Template\$jsonFileName" -UseBasicParsing
    }
} else {
    Invoke-WebRequest -Uri $jsonFileUrl -OutFile "C:\dev\Dev Box\Testing\Image-Builder\Template\$jsonFileName" -UseBasicParsing
}

# GET SUBSCRIPTION ID
$subscriptionID = (Get-AzContext).Subscription.Id
Write-Host "Subscription ID: $subscriptionID"

# DEFINE THE LOCATION
$location = Read-Host "Enter the location for the image template"
Write-Output "Location: $location"

# CREATE A RESOURCE GROUP IN AZURE
# define the resource group name by inputting variables
$resourceGroupName = Read-Host "Enter the resource group name"
Write-Output "Resource Group Name: $resourceGroupName"
# create resource group in azure
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location
Write-Output "Resource Group '$resourceGroupName' created successfully."


# DEFINE THE OS DISK SIZE (256, 512, 1024)
do {
    $osDiskSize = Read-Host "Enter the OS Disk Size (256, 512, 1024)"
    if ($osDiskSize -eq "256" -or $osDiskSize -eq "512" -or $osDiskSize -eq "1024") {
        Write-Output "VM Size: $osDiskSize"
        $validInput = $true
    } else {
        Write-Output "Invalid VM size. Please enter 256, 512, or 1024"
        $validInput = $false
    }
} while (-not $validInput)

# DEFINE THE VM SIZE
$vmSize = Read-Host "Enter the VM Size (ensure correct, case sensitive, syntax)"
Write-Output "VM Size: $vmSize"

# DEFINE THE SKU (20H2, 21H1, 21H2)
do {
    $sku = Read-Host "Enter the SKU (20H2, 21H1, 21H2)"
    if ($sku -eq "20H2" -or $sku -eq "21H1" -or $sku -eq "21H2") {
        Write-Output "SKU: $sku"
        $validInput = $true
    } else {
        Write-Output "Invalid SKU. Please enter 20H2, 21H1, or 21H2"
        $validInput = $false
    }
} while (-not $validInput)

# DEFINE THE IMAGE NAME
$imageName = Read-Host "Enter the image name"
Write-Output "Image Name: $imageName"

# DEFINE THE IMAGE TEMPLATE NAME
$imageTemplateName = Read-Host "Enter the image template name"
Write-Output "Image Template Name: $imageTemplateName"

# DEFINE THE RUN OUTPUT NAME
$runOutputName = Read-Host "Enter the run output name"
Write-Output "Run Output Name: $runOutputName"



# UPDATE THE TEMPLATE
$jsonFilePath = "C:\dev\Dev Box\Testing\Image-Builder\Template\$jsonFileName"
((Get-Content -path $jsonFilePath -Raw) -replace '<SUBSCRIPTIONID>', $subscriptionID) | Set-Content -path $jsonFilePath
((Get-Content -path $jsonFilePath -Raw) -replace '<RESOURCEGROUPNAME>', $resourceGroupName) | Set-Content -path $jsonFilePath
((Get-Content -path $jsonFilePath -Raw) -replace '<LOCATION>', $location) | Set-Content -path $jsonFilePath
((Get-Content -path $jsonFilePath -Raw) -replace '<OSDISKSIZEGB>', $osDiskSize) | Set-Content -path $jsonFilePath
((Get-Content -path $jsonFilePath -Raw) -replace '<VMSIZE>', $vmSize) | Set-Content -path $jsonFilePath
((Get-Content -path $jsonFilePath -Raw) -replace '<SKU>', $sku) | Set-Content -path $jsonFilePath
((Get-Content -path $jsonFilePath -Raw) -replace '<IMAGENAME>', $imageName) | Set-Content -Path $jsonFilePath
((Get-Content -path $jsonFilePath -Raw) -replace '<IMAGETEMPLATENAME>', $imageTemplateName) | Set-Content -Path $jsonFilePath
((Get-Content -path $jsonFilePath -Raw) -replace '<RUNOUTPUTNAME>', $runOutputName) | Set-Content -Path $jsonFilePath
((Get-Content -path $jsonFilePath -Raw) -replace '<imgBuilderId>', $identityNamePrincipalID) | Set-Content -Path $jsonFilePath










# SORT MANAGED IDENTITY

# Create the managed identity
# Use current time to verify names are unique
[int]$timeInt = $(Get-date -UFormat '%s')
$imageRoleDefName = "Azure Image Builder Image Def $timeInt"
$identityName = "myIdentity$timeInt"

New-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $identityName 
$identityNamePrincipalID = (Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $identityName).PrincipalId

# Grant the role definition to the image builder service principle
# Assign permissions for identity to distribute images
# downloads a .json file with settings, update with subscription settings
$myRoleImageCreationUrl = 'https://raw.githubusercontent.com/345Nathan-Harrison/Testing/main/Image-Builder/AIBRoleImageCreator.json'
$myRoleImageCreationPath = "C:\dev\Dev Box\Testing\Image-Builder\myRoleImageCreation.json"

#Download the file
Invoke-WebRequest -Uri $myRoleImageCreationUrl -OutFile $myRoleImageCreationPath -UseBasicParsing



# Update the file
$Content = Get-Content -Path $myRoleImageCreationPath -Raw
$Content = $Content -replace '<subscriptionID>', $subscriptionID
$Content = $Content -replace '<rgName>', $resourceGroupName
$Content = $Content -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName
$Content | Out-File -FilePath $myRoleImageCreationPath -Force

New-AzRoleDefinition -InputFile $myRoleImageCreationPath

# Grant the role definition to the image builder service principle
$RoleAssignParams = @{
    ObjectId = $identityNamePrincipalID
    RoleDefinitionName = $imageRoleDefName
    Scope = "/subscriptions/$subscriptionID/resourceGroups/$resourceGroupName"
}
New-AzRoleAssignment @RoleAssignParams

# Verify role assignment
Get-AzRoleAssignment -ObjectId $identityNamePrincipalID | Select-Object DisplayName, RoleDefinitionName





# Create the image template
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $jsonFilePath -api-version "2024-02-01" -imageTemplateName $imageTemplateName -svclocation $location
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $jsonFilePath -TemplateParameterObject @{
    "imageTemplateName" = $imageTemplateName;
    "location" = $location;
    "api-version" = "2024-02-01";
    "svclocation" = $location;
}




