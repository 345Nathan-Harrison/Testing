# Set the template file path and the template file name
$Win10Url = "https://raw.githubusercontent.com/345Nathan-Harrison/Testing/main/Win10MultiTemplate.json"
$Win10FileName = "Win10MultiTemplate.json"

# Test to see if the path exists. Create it if not.
if ((test-path .\Template) -eq $false) {
    New-Item -ItemType Directory -name 'Template'
}


# Confirm to overwrite file if it already exists
if ((test-path .\Template\$Win10FileName) -eq $true) {
    $confirmation = Read-Host "Are you sure you want to replace the template? (Y/N):"
    if ($confirmation -eq "Y" -or $confirmation -eq "y"){
        Invoke-WebRequest -Uri $Win10Url -OutFile ".\Template\$Win10FileName" -UseBasicParsing
    } 
} else {
    Invoke-WebRequest -Uri $Win10Url -OutFile ".\Template\$Win10FileName" -UseBasicParsing
}


# setup the variables
# the first four need to match Enable-Idenity.ps1 script
# destination image resource group
$imageResourceGroup = 'aib-testing-rg'
$location = (Get-AzResourceGroup -Name $imageResourceGroup).Location
# Get your current subscription
$subscriptionID = (Get-AzContext).Subscription.Id
# name of the image to be created
$imageName = 'aibCustomImageWin10'
# image template name
$imageTemplateName = 'imageTemplateWin10Multi'
# distribution properties object name (runOutput), i.e. this gives you the properties of the managed image on completion
$runOutputName = 'Win10Client'
# Set the Template File Path
$templateFilePath = ".\Template\$Win10FileName"
# user assigned managed identity
$identityName = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup).Name
# get the user assigned identity id
$identityNameResourceID = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id


# Update the template
((Get-Content -path $templateFilePath -Raw) -replace '<subscriptionID>', $subscriptionID) | Set-Content -path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region>', $location) | Set-Content -path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<runOutputName>', $runOutputName) | Set-Content -path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imageName>', $imageName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>', $identityNameResourceID) | Set-Content -Path $templateFilePath





# run the deployment
New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $templateFilePath -api-version "2024-02-01" -imageTemplateName $imageTemplateName -svclocation $location

# verify the deployment
Get-AzImageBuilderTemplate -ImageTemplateName $imageTemplateName -ResourceGroupName $imageResourceGroup | Select-Object -Property Name, LastRunStatusRunState, LastRunStatusMessage, ProvisioningState, ProvisioningErrorMessage

# Start the Image Build Process
Start-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -ImageTemplateName $imageTemplateName






# # create a vm to test
# # the below code will be replaced with Dev Box code instead of VM

# ##Errors here - to be looked at Friday
# # Get credentials at the start
# $Cred = Get-Credential

# # Retrieve the template and artifact ID
# $template = Get-AzImageBuilderTemplate -ImageTemplateName $imageTemplateName -ResourceGroupName $imageResourceGroup
# $ArtifactId = $template.Name

# # Get the custom image object
# $image = Get-AzImage -ImageName $ArtifactId -ResourceGroupName $imageResourceGroup

# # Specify the VM configuration
# $vmName = "aibTestVM"
# $vmLocation = $image.Location
# $vmSize = "Standard_D2s_v3"

# New-AzVM -ResourceGroupName $imageResourceGroup -Name $vmName -Location $vmLocation -Image $image -Size $vmSize -Credential $Cred


# CREATE A DEV BOX

$Cred = Get-Credential

# Retrieve the template and artifact ID
$template = Get-AzImageBuilderTemplate -ImageTemplateName $imageTemplateName -ResourceGroupName $imageResourceGroup
$ArtifactId = $template.Name

# Get the custom image object
$image = Get-AzImage -ImageName $ArtifactId -ResourceGroupName $imageResourceGroup

# Specify the dev box defintion configuration
$devBoxDefinitionName = "aibDevBoxDefinition"
$galleryImageId = $image.Id
$devBoxSize = "Standard_D2s_v3" 

# Create the dev box definition with the custom image
New-AzDevBoxDefinition -Name $devBoxDefinitionName -DevCenterName "devcenter-testing" -ProjectName "testing-project" -GalleryImageId $galleryImageId -Sku $devBoxSize -Credential $Cred










# Find the publisher, offer and sku
# To use for the deployment template to identify 
# source marketplace images
# https://www.ciraltos.com/find-skus-images-available-azure-rm/
Get-AzVMImagePublisher -Location $location | where-object {$_.PublisherName -like "*win*"} | ft PublisherName, Location
$pubName - 'MicrosoftWindowsDesktop'
Get-AzImageOffer -Location $location -PublisherName $pubName | ft Offer, PublisherName, Location
# Set offer to 'office-365' for images with O365
# $offerName = 'office-365'
$offerName = 'Windows-10'
Get-AzVMImageSku -Location $location -PublisherName $pubName -Offer $offerName | ft Skus, Offer, PublisherName, Location
$skuName = '20h2-evd'
Get-AzVMImage -Location $location -PublisherName $pubName -Skus $skuName -Offer $offerName
$version = '19041.572.2010091946'
Get-AzVMImage -Location $location -PublisherName $pubName -Offer $offerName -Skus $skuName -Version $version