# Check your provider registrations.
Get-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages | Format-table -Property ResourceTypes,RegistrationState 
Get-AzResourceProvider -ProviderNamespace Microsoft.Storage | Format-table -Property ResourceTypes,RegistrationState  
Get-AzResourceProvider -ProviderNamespace Microsoft.Compute | Format-table -Property ResourceTypes,RegistrationState 
Get-AzResourceProvider -ProviderNamespace Microsoft.KeyVault | Format-table -Property ResourceTypes,RegistrationState 
Get-AzResourceProvider -ProviderNamespace Microsoft.Network | Format-table -Property ResourceTypes,RegistrationState
# If the provider is not registered, register it.
Register-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages  
Register-AzResourceProvider -ProviderNamespace Microsoft.Storage  
Register-AzResourceProvider -ProviderNamespace Microsoft.Compute  
Register-AzResourceProvider -ProviderNamespace Microsoft.KeyVault  
Register-AzResourceProvider -ProviderNamespace Microsoft.Network
# Install PowerShell modules
'Az.ImageBuilder', 'Az.ManagedServiceIdentity' | ForEach-Object {Install-Module -Name $_ -AllowPrerelease}
