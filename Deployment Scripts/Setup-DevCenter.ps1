# Ensure the powershell-yaml module is installed - everthing will land into a YAML file for overall structure
# Install-Module -Name powershell-yaml -Force -AllowClobber

# Set up a DevCenter in Azure 

# set up variables for dev center
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$DevCenterName = "DevCenter-$timestamp"
$ResourceGroupName = "azure-devbox-rg"
$Location = "UKSouth"

# Create the resource group
# Attempt to create a new resource group with verbose output
try {
    $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $location -Verbose
    Write-Host "Resource Group '$ResourceGroupName' created successfully."
} catch {
    Write-Error "Failed to create Resource Group. Error: $_"
}

$ResourceGroupID = (Get-AzResourceGroup -Name $ResourceGroupName).ResourceId


# Create the Dev Center
$DevCenter = New-AzDevCenterAdminDevCenter -Name $DevCenterName -ResourceGroupName $ResourceGroupName -Location $Location

$DevCenterID = (Get-AzDevCenterAdminDevCenter -Name $DevCenterName -ResourceGroupName $ResourceGroupName).Id

# Prepare the object to be converted to YAML
$YAMLObject = @{
    DevCenterName = $DevCenterName
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    ResourceGroupID = $ResourceGroupID
    DevCenterID = $DevCenterID
    
}

# Convert the object to YAML
$YAMLContent = ConvertTo-Yaml -Data $YAMLObject
$YAMLContent | Out-File -FilePath "DevCenterDetails.yaml"

