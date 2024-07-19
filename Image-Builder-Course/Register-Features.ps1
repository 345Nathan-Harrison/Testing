# Register Features
# Resgist the Virtual Machine Template Preview feature
Register-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview
# Do not continue until the feature is registered
# Verify status with this command
Get-AzProviderFeature -ProviderNamespace Microsoft.VirtualMachineImages -FeatureName VirtualMachineTemplatePreview

#Register resource providers if not already registered
Get-AzResourceProvider -ProviderNamespace Microsoft.Compute, Microsoft.KeyVault, Microsoft.Storage, Microsoft.VirtualMachineImages |
    Where-Object RegistrationState -ne Registered |
        Register-AzResourceProvider