# Set the template file path and the template file name
$Win10Url = "https://raw.githubusercontent.com/345Nathan-Harrison/Testing/main/Win10MultiTemplate.json"
$Win10FileName = "Win10MultiTemplate.json"

# Test to see if the path exists. Create it if not.
if ((test-path .\Template) -eq $false) {
    new-item -ItemType Directory -name 'Template'
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
$imageResourceGroup = 'rg-devbox230724-testing'
$location = (Get-AzResourceGroup -Name $imageResourceGroup).Location
# Get your current subscription
$subscriptionID = (Get-AzContext).Subscription.Id
# name of the image to be created
$imageName = 'devboxCustomImageWin10'
# image template name
$imageTemplateName = 'imageTemplateWin10DevBox'
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


# create a vm to test
$Cred = Get-Credential 
$ArtifactId = (Get-AzImageBuilderTemplateRunOutput -ImageTemplateName $imageTemplateName -ResourceGroupName $imageResourceGroup).ArtifactId
New-AzVM -ResourceGroupName $imageResourceGroup -Image $ArtifactId -Name myWinVM01 -Credential $Cred











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