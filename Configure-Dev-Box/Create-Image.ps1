# This PowerShell script creates a custom image using Azure Image Builder
# Make sure you have run the Prerequisites script before running this script



# Create variables to store information to use more than once

# get existing context
$currentAzContext = Get-AzContext

# get your current subscription ID
$subscriptionID = $currentAzContext.Subscription.Id

# destination image resource group
$imageResourceGroup = "rg-devboxpoc-nonprod-uksouth-001"

# location
$location = "uksouth"

# image distribution metadata reference name
$runOutputName = "aibCustWinManImg01"

# image template name
$imageTemplateName = "vscodewintemplate-devboxpoc-nonprod-uksouth-001"




# create a user assigned identity and set permissions on the resource group

# set up role definition names which need to be unique
$timeInt = (get-date -UFormat "%s")
$imageRoleDefName = "Azure Image Builder Image Def"+$timeInt
$identityName = "aibIdentity"+$timeInt

# create an identity
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName -Location $location

$identityNameResourceID = $(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id
$identityNamePrincipalID = $(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId

# assign permissions for the identity to distribute the images
# download an Azure role definition template and then update it with the required permissions
$aibRoleImageCreationUrl="https://raw.githubusercontent.com/azure/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json" 
$aibRoleImageCreationPath = "aibRoleImageCreation.json"

# Download the configuration 
Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing 
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleImageCreationPath 
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath 
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

# Create a role definition 
New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json

# Grant the role definition to the VM Image Builder service principal 
New-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"




# Create a Gallery

# gallery name (must only contain letters, numbers, periods, and underscores)
$galleryName = "gallerydevboxpoc"

# image definition name
$imageDefinitionName = "def-vscodewin01-devboxpoc-nonprod-uksouth-001"

# additional replication region
$replicationRegion = "ukwest"

# create the gallery 
New-AzGallery -GalleryName $galleryName -ResourceGroupName $imageResourceGroup -Location $location

$SecurityType = @{Name = 'SecurityType'; Value = 'TrustedLaunch'}
$features = @($SecurityType)

# create the image definition
New-AzGalleryImageDefinition -GalleryName $galleryName -ResourceGroupName $imageResourceGroup -Location $location -Name $imageDefinitionName -OsState generalized -OsType Windows -Publisher 'myCompany' -Offer 'vscodebox' -Sku '1-0-0' -Feature $features -HyperVGeneration "V2"




# Configure the image template

$templateFilePath = "C:\dev\Dev Box\Testing\mytemplate.json" # change this to the path of your template file

(Get-Content -path $templateFilePath -Raw ) -replace '<subscriptionID>',$subscriptionID | Set-Content -Path $templateFilePath 
(Get-Content -path $templateFilePath -Raw ) -replace '<rgName>',$imageResourceGroup | Set-Content -Path $templateFilePath 
(Get-Content -path $templateFilePath -Raw ) -replace '<runOutputName>',$runOutputName | Set-Content -Path $templateFilePath  
(Get-Content -path $templateFilePath -Raw ) -replace '<imageDefName>',$imageDefinitionName | Set-Content -Path $templateFilePath  
(Get-Content -path $templateFilePath -Raw ) -replace '<sharedImageGalName>',$galleryName| Set-Content -Path $templateFilePath  
(Get-Content -path $templateFilePath -Raw ) -replace '<region1>',$location | Set-Content -Path $templateFilePath  
(Get-Content -path $templateFilePath -Raw ) -replace '<region2>',$replicationRegion | Set-Content -Path $templateFilePath  
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>',$identityNameResourceID) | Set-Content -Path $templateFilePath




# submit your template to the service

# the following command downloads any dependant artifacts, such as scripts, and stores them in the staging resource group (prefixed with IT_)
New-AzResourceGroupDeployment  -ResourceGroupName $imageResourceGroup  -TemplateFile $templateFilePath -Api-Version "2020-02-14"  -imageTemplateName $imageTemplateName  -svclocation $location

# build the image by invoking the Run command on the template
Invoke-AzResourceAction -ResourceName $imageTemplateName -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2020-02-14" -Action Run 

# get information about the newly built image, including the run status and provisioning state
Get-AzImageBuilderTemplate -ImageTemplateName $imageTemplateName -ResourceGroupName $imageResourceGroup | Select-Object -Property Name, LastRunStatusRunState, LastRunStatusMessage, ProvisioningState
