<#
	Export-ContactsFromTenant.ps1 v.1.0
	----------------------
	
    Export Script - exports to .CSV a list of the contacts in the especified tenant, 
    for later use in the import phase.
    The .CSV file's name is defined by the Tenant parameter, which in turn is used 
    on the later import phase script.
	
	Parameter:
		- Tenant			--> Company name to export contacts list from (mandatory).
	
	Usage:
	.\Export-ContactsFromTenant.ps1 -Tenant <Company>

	[ValidateSet("")] - For adding specific names, in case you need (might need to allow monkeys to use the script). 
                        Otherwise remove this one
#>

Param(
	[Parameter(Mandatory=$True,Position=1)]
#	[ValidateSet("")]
	[string]$Tenant
)

$Tenant = $Tenant.ToUpper()
$CredFile = "$Tenant.cred"
$FileName = ".\"+$Tenant+"_nofilter.csv"
$FileNameClean = ".\$Tenant.csv"

#### Functions area - Here are created all the usable functions for the script

#### End of Function Area

## Start Script

# Select the Office 365 for connection to the tenant, based on $Tenant value

Switch ($ToTenant) {
	"example"			{$User="ListSync@example.onmicrosoft.com"
                        $Domain="example.com"}
<#
    Either fill this list with different values, 
    or create a function that resolves them for you, 
    since I don't know the mail addresses you want to use for Tenant connections
#>
	default 			{Break}
}

# Office 365 connection
 
$Pass = Cat $CredFile | ConvertTo-SecureString
$MyCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass
Connect-MsolService -Credential $MyCred

# Export users on tenant as contacts

Get-MsolUser | Select-Object Name, UserPrincipalName, DisplayName, FirstName, LastName, Department, Company, streetAddress, City, PostalCode, Office, Title, Phone, Home, MobilePhone, Pager, Fax, WebPage | Export-Csv $FileName -NoTypeInformation -Encoding UTF8

# Cleaning up users that don't fit the criteria (in this case, that have anything other than "example.com" in the UPN)

Import-Csv $FileName |  where UserPrincipalName -like *$Domain | Export-Csv $FileNameClean -NoTypeInformation -Encoding UTF8