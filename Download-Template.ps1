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
}

else {
    Invoke-WebRequest -Uri $Win10Url -OutFile ".\Template\$Win10FileName" -UseBasicParsing
}