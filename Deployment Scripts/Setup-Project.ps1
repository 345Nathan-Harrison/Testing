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

# Create a Project in the Dev Center
$ProjectName = "Project-ASDA-DevBox"
$Project = New-AzDevCenterAdminProject -Name $ProjectName -DevCenterId $DevCenterID -ResourceGroupName $ResourceGroupName -Location $Location
# obtain a project ID
$ProjectID = (Get-AzDevCenterAdminProject -Name $ProjectName -ResourceGroupName $ResourceGroupName).Id

# Add the project name and ID to the YAMLObject
$YAMLObject.ProjectName = $ProjectName
$YAMLObject.ProjectID = $ProjectID

#Convert the updated object back to YAML
$UpdatedYAMLContent = ConvertTo-Yaml -Data $YAMLObject
# Write the updated YAML back to the file
$UpdatedYAMLContent | Out-File -FilePath $YAMLPath

