<#
.SYNOPSIS
Enters the NuGet Operations Console

.PARAMETER EnvironmentList

The path to an Environments.xml file to use as the environment list
#>

param(
	[Parameter(Mandatory=$false)][string]$EnvironmentList)

$MsftDomainNames = @("REDMOND","FAREAST","NORTHAMERICA","NTDEV")

$root = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$OpsProfile = $MyInvocation.MyCommand.Path
$OpsModules = Join-Path $root "Modules"
$OpsTools = Join-Path $root "Tools"
$env:PSModulePath = "$env:PSModulePath;$OpsModules"

if($EnvironmentList) {
	$env:NUGET_OPS_ENVIRONMENTS = $EnvironmentList;
}

if(!$env:NUGET_OPS_ENVIRONMENTS) {
	# Defaults for Microsoft CorpNet. If you're outside CorpNet, you'll have to VPN in. Of course, if you're hosting your own gallery, you have to build your own scripts :P
	if([Environment]::UserDomainName -and ($MsftDomainNames -contains [Environment]::UserDomainName) -and (Test-Path "\\nuget\Environments\Environments.xml")) {
		$env:NUGET_OPS_ENVIRONMENTS = "\\nuget\Environments\Environments.xml"
	}
	else {
		Write-Warning "NUGET_OPS_ENVIRONMENTS is not set. Either set it, or pass the path to an Environments.xml file in the -EnvironmentList parameter"
	}
}

$env:WinSDKRoot = "$(cat "env:\ProgramFiles(x86)")\Windows Kits\8.0"

$env:PATH = "$root;$OpsTools\bin;$env:PATH;$env:WinSDKRoot\bin\x86;$env:WinSDKRoot\Debuggers\x86"

function LoadOrReloadModule($name) {
	if(Get-Module $name) {
		Write-Host "Module $name already loaded, reloading."
		Remove-Module $name -Force
	}
	Import-Module $name
}

LoadOrReloadModule PS-CmdInterop
LoadOrReloadModule PS-VsVars

Import-VsVars -Architecture x86

if(Test-Path "$OpsTools\Paths.txt") {
	cat "$OpsTools\Paths.txt" | ForEach {
		$env:PATH = "$($env:PATH);$OpsTools\$_"
	}
}

if(!(Get-Module posh-git)) {
	Import-Module posh-git
} else {
	Write-Host "Module posh-git already loaded, can't reload"
}
LoadOrReloadModule WAPPSCmdlets
LoadOrReloadModule NuGetOps

$Global:_OldPrompt = $function:prompt;
function Global:prompt {
	if(Get-Module NuGetOps) {
		return Write-NuGetOpsPrompt
	} else {
		return $oldprompt.InvokeReturnAsIs()
	}
}