
$currentDirectory = split-path $MyInvocation.MyCommand.Definition

# See if we have the ClientSecret available
if([string]::IsNullOrEmpty($Env:SignClientSecret)){
	Write-Host "Client Secret not found, not signing packages"
	return;
}

$sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$targetNugetExe = "$currentDirectory\nuget.exe"
Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe

& $targetNugetExe install SignClient -Version 0.9.0 -SolutionDir "$currentDirectory\..\" -Verbosity quiet -ExcludeVersion

# Setup Variables we need to pass into the sign client tool

$appSettings = "$currentDirectory\appsettings.json"
$fileList = "$currentDirectory\filelist.txt"

$appPath = "$currentDirectory\..\packages\SignClient\tools\netcoreapp2.0\SignClient.dll"

$appxs = gci $Env:ArtifactDirectory\*.appxbundle -recurse | Select -ExpandProperty FullName

foreach ($appx in $appxs){
	Write-Host "Submitting $appx for signing"

	dotnet $appPath 'sign' -c $appSettings -i $appx -f $fileList -r $Env:SignClientUser -s $Env:SignClientSecret -n 'NuGet Package Explorer' -d 'NuGet Package Explorer' -u 'https://github.com/NuGetPackageExplorer/NuGetPackageExplorer' 

	Write-Host "Finished signing $appx"
}

Write-Host "Sign-package complete"