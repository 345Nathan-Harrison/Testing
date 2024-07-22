# get existing yaml file
$YAMLPath = "DevCenterDetails.yaml"
$YAMLContent = Get-Content -Path $YAMLPath -Raw
# Check existing YAML has been assigned to the variable
Write-Output $YAMLContent
# Convert the YAML content to a PowerShell object
$YAMLObject = ConvertFrom-Yaml -Yaml $YAMLContent

# obtain the data from the YAML to set up the project
$DevCenterID = $YAMLObject.DevCenterID
$ResourceGroupName = $YAMLObject.ResourceGroupName
$Location = $YAMLObject.Location

# Create a definition
# prompt the user to enter a definition name
$UserInput = Read-Host -Prompt "Enter a definition name for the project"
$DefinitionName = $UserInput
Write-Output "Definition Name: $DefinitionName"

# Create a definition in the Dev Center
$Definition = New-AzDevCenterAdminDefinition -Name $DefinitionName -DevCenterId $DevCenterID -ResourceGroupName $ResourceGroupName -Location $Location
# Obtain a definition ID
$DefinitionID = (Get-AzDevCenterAdminDefinition -Name $DefinitionName -ResourceGroupName $ResourceGroupName).Id

# Add the definition name and ID to the YAMLObject
$YAMLObject.DefinitionName = $DefinitionName
$YAMLObject.DefinitionID = $DefinitionID

