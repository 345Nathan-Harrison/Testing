# Set variables for the commands
# Destination image resource group name
$imageResourceGroup = 'aib-testing-rg'
# Azure region
$location = 'UKSouth'
#Get the subscription ID
$subscriptionID = (Get-AzContext).subscription.ID

# Get the PowerShell modules
'Az.ImageBuilder', 'Az.ManagedServiceIdentity' | ForEach-Object {Install-Module -Name $_ -AllowPrerelease}

# Start bu creating the Resource Group
# the identity will need rights to this group
New-AzResourceGroup -Name $imageResourceGroup -Location $location

# Create the managed identity
# Use current time to verify anmes are unique
[int]$timeInt = $(Get-date -UFormat '%s')
$imageRoleDefName = "Azure Image Builder Image Def $timeInt"
$identityName = "myIdentity$timeInt"

# Create the user identity
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName

# Assign the identity resource and principle ID's to a variable
$identityNamePrincipalID = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId

# Create the role definition
New-AzRoleDefinition -InputFile $myRoleImageCreationPath

# Grant the role definition to the image builder service principle
# Assign permissions for identity to distribute images
# downloads a .json file with settings, update with subscription settings
$myRoleImageCreationUrl = 'https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json'
$myRoleImageCreationPath = ".\myRoleImageCreation.json"
#Download the file
Invoke-WebRequest -Uri $myRoleImageCreationUrl -OutFile $myRoleImageCreationPath -UseBasicParsing

# Update the file
$Content = Get-Content -Path $myRoleImageCreationPath -Raw
$Content = $Content -replace '<subscriptionID>', $subscriptionID
$Content = $Content -replace '<rgName>', $imageResourceGroup
$Content = $Content -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName
$Content | Out-File -FilePath $myRoleImageCreationPath -Force

# Create the role definition
New-AzRoleDefinition -InputFile $myRoleImageCreationPath

# Grant the role definition to the image builder service principle
$RoleAssignParams = @{
    ObjectId = $identityNamePrincipalID
    RoleDefinitionName = $imageRoleDefName
    Scope = "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"
}
New-AzRoleAssignment @RoleAssignParams

# Verify role assignment
Get-AzRoleAssignment -ObjectId $identityNamePrincipalID | Select-Object DisplayName, RoleDefinitionName