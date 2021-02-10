<#
	Create-PasswordFile.ps1 v.1.0
	-----------------------------

	Encrypted password file generator for usage on other autologon scripts

    Parameters:
		- Company			--> Name of company/tenant that we'll be exporting (mostly for the output file's name).

	Usage:
	.\Create-PasswordFile.ps1 -Tenant <Company>

     - 	[ValidateSet("")] - For adding specific names, in case you need. Otherwise remove this one
#>

Param(
	[Parameter(Mandatory=$True,Position=1)]
#   [ValidateSet("")]
	[string]$Tenant
)

$FileName = "$Tenant.cred"
Read-host -Prompt "P.f. introduza a password de $Tenant." -AsSecureString | ConvertFrom-SecureString | Out-File $FileName