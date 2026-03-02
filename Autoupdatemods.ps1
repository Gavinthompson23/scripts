<#Automatically updated mods for HytaleServermods plugin Meant to be run once a day or whenever the user wants to 
update the HytaleServer.jar file in the libs folder of the HytaleServermods plugin.
This script will download the latest release of the HytaleServer.jar file using the hytale-downloader executable, 
extract it from the latest release zip, and place it in the libs folder of the HytaleServermods plugin.
The script also includes error handling to check if the file is available in the zip before attempting to extract it.
The check may not be needed now but it is there because of the directory issues that i ran into.(Variable $zipPath needed to have a / instead of a \.)
If the file is not found, it will exit with an error message. #>
## Import
Add-Type -AssemblyName System.IO.Compression.FileSystem

#go to directory of the hytale-downloader
cd C:\Users\maver\Desktop\Folders\Development\Hytaleserver

# Download the latest release of the HytaleServer.jar file using the hytale-downloader executable
./hytale-downloader-windows-amd64.exe -download-path latestRelease

## This script extracts The Updated HytaleServer.jar file from the latest release zip and places it in the libs folder of the HytaleServermods plugin
$zipPath = "C:\Users\maver\Desktop\Folders\Development\Hytaleserver\latestRelease.zip"
$fileInsideZip = "Server/HytaleServer.jar"
$destinationPath = "C:\Users\maver\Desktop\Folders\Development\HytaleServermods\libs\HytaleServer.jar"



## This method works but it doesn't have error handling or an exit from the OpenRead method and could cause an error when running this script frequently.
#$zip=$zipPath; $file=$fileInsideZip; [System.IO.Compression.ZipFile]::OpenRead($zip).Entries | Where-Object FullName -ieq $file | ForEach-Object { $_.ExtractToFile($destinationPath, $true) } 

## run a check to see if the file is availabe.

$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
$fileExists = $zip.Entries | Where-Object { $_.FullName -ieq $fileInsideZip }
write-host "Zip is $_ or $fileExists"
#$zip.Dispose()

if ($fileExists) {
    Write-Host "File exists in zip"
    $zip.Dispose()
} else {
    Write-Host "File does not exist in zip and will exit on check."
    exit(1)
}
## Alternative method using try-catch for error handling. But for some reason it doesn't work, maybe because the file is still being downloaded and is not yet available for extraction.(Variable $zipPath needed to have a / instead of a \. I guess Zips are not windows directories.)
## FIXED: .NET version problem where ExtractToFile method is not available in .NET 4.5, which is the version used by PowerShell 5.1. Updated to use CopyTo method instead, which is compatible with .NET 4.5.
Start-Sleep -Seconds 1 # Wait for the download to complete and the ZIP file to be available. Maybe
try {
    # Open the ZIP archive
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)

    # Find the file inside the ZIP
    $entry = $zip.Entries | Where-Object { $_.FullName -ieq $fileInsideZip }

    if ($entry) {
        # Extract the file
        $entry | ForEach-Object {
            $stream = $_.Open()
            $fileStream = [System.IO.File]::Create($destinationPath)
            $stream.CopyTo($fileStream)
            $fileStream.Close()
            $stream.Close()
        }
        Write-Host "File extracted to $destinationPath"
    }
    else {
        Write-Host "File '$fileInsideZip' not found in ZIP."
    }

    # Close the ZIP
    $zip.Dispose()
}
catch {
    Write-Host "An error occurred: $_"
}
#echo "HytaleServer.jar has been updated and placed in the libs folder of the HytaleServermods plugin."