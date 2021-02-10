<#
	Import-ContactsToTenant.ps1 v.1.2
    -------------------------------------------------------------------------------------------
    
    Import Script for the contacts previously exported from Exchange Online.
    Looks for a .CSV file with the name described in the parameter $FromTenant, and imports to
    the company's tenant descripted on parameter $ToTenant
    		
	Usage:
	.\Import-ContactsToTenant.ps1 -FromTenant <Office 365 Tenant Name> -ToTenant <Office 365 Tenant Name>
    
    [ValidateSet("")] - For adding specific names, in case you need (might need to allow monkeys to use the script). 
                        Otherwise remove this one.
#>

# Parameter intro
Param(
	[Parameter(Mandatory=$True,Position=1)]
#	[ValidateSet("")]
	[string]$FromTenant,
	[Parameter(Mandatory=$True,Position=2)]
#	[ValidateSet("")]
	[string]$ToTenant
)

# Variable Creation

$timeframe=Get-Date -Format ddMMyy_hhmmss
$log=".\Import_$ToTenant$timeframe.log"
Get-Date > $log
$FromTenant = $FromTenant.ToUpper()
$ToTenant = $ToTenant.ToUpper()
$CredFile = "$ToTenant.cred"

# Basic Check
If ($FromTenant -eq $ToTenant) {
    echo "Destination Tenant cannot be Source Tenant. Ending Script!" >> $log
	Break
}

#### Functions area - Here are created all the usable functions for the script
function MSOLConnected {
    Get-MsolDomain -ErrorAction SilentlyContinue | Out-Null
    $result = $?
    return $result
}

function ExchangeConnected {
    Get-Mailbox -ErrorAction SilentlyContinue | Out-Null
    $result = $?
    return $result
}

function Remove-DiacriticsAndSpaces {
    Param(
        [String]$inputString
    )
    #replace diacritics
    $sb = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($inputString))

    #remove spaces and anything the above function may have missed
    return($sb -replace '[^a-zA-Z0-9]', '')
}
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

echo "Connecting to Microsoft Services, and Exchange Online using $User credentials. Outputing to log oOoOoOo" >> $log
 
$Pass = Cat $CredFile | ConvertTo-SecureString
$MyCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass

Connect-MsolService -Credential $MyCred -ErrorAction SilentlyContinue 
Connect-ExchangeOnline -Credential $MyCred -ErrorAction SilentlyContinue

echo " " >> $log

# Connection checks, to see if the script is able to continue, otherwise closing it.

If (MSOLConnected -eq $True -and ExchangeConnected -eq $True){
    echo "Connection successful! Continuing with the process" >> $log
    echo " " >> $log
    }
Else {
    echo "Connection not detected! Script cannot continue, check your credentials and files!" >> $log
    Invoke-Expression ".\SendStatusMail.ps1 -messageSubject 'Error' -messageBody 'Connection Error'"
    Break
    }

# Importing contacts from the .CSV File to memory.

echo "oOoOoOo Importing CSV file oOoOoOo" >> $log
Import-CSV .\$FromTenant.csv | Sort-Object Name | ForEach-Object {
$sourceEmail=$_.UserPrincipalName
$sourceName=$_.Name
$sourceDisplayName=$_.DisplayName
$sourceFirstName=$_.FirstName -replace " ","-"
$sourceLastName=$_.LastName
$sourceDepartment=$_.Department
$sourceCompany=$_.Company -Replace "\'",""
$sourceStreetAddress=$_.StreetAddress
$sourceCity=$_.City
$sourcePostalCode=$_.PostalCode
$sourceOffice=$_.Office
$sourceTitle=$_.Title
$sourcePhone=$_.Phone
$sourceHomePhone=$_.Home
$sourceMobilePhone=$_.MobilePhone
$sourcePager=$_.Pager
$sourceFax=$_.Fax
$sourceWebPage=$_.WebPage

$targetDisplayName=$sourceDisplayName -Replace "\(","" -Replace "\)",""
$targetDisplayName=Remove-DiacriticsAndSpaces -inputString $targetDisplayName

$targetAlias=$sourceDisplayName
$targetAlias=$targetAlias -Replace "\(","" -Replace "\)",""
$targetAlias=Remove-DiacriticsAndSpaces -inputString $targetAlias
$targetAlias=$FromTenant + "." + $targetAlias
echo " " >> $log

# Creating inexistent contacts and setting updates for existing contacts.

If (Get-MailContact -Identity $sourceEmail) 
    {
    echo "Updating contact $sourceEmail"  >> $log

	Set-MailContact -Identity $sourceEmail -Alias $targetAlias -ForceUpgrade -WarningAction SilentlyContinue >> $log

    Set-Contact -Identity $sourceEmail `
	-Name “$sourceName” `
	-DisplayName $sourceDisplayName `
	-SimpleDisplayName $targetDisplayName `
	-FirstName $sourceFirstName `
	-LastName $sourceLastName `
	-Department $sourceDepartment `
	-Company $sourceCompany `
	-StreetAddress $sourceStreetAddress `
	-City $sourceCity `
	-PostalCode $sourcePostalCode `
	-Office $sourceOffice `
	-Title $sourceTitle `
	-Phone $sourcePhone `
	-Home $sourceHomePhone `
    -CountryOrRegion $sourceStreetAddressCountry `
	-MobilePhone $sourceMobilePhone `
	-Pager $sourcePager `
	-Fax $sourceFax `
	-WebPage $sourceWebPage `
	-WarningAction SilentlyContinue >> $log

<#
        This additional command serves to add custom attributes (example in case, customAttribute15) 
        which may be used in some tenants to create address lists. Uncomment if needed
#>

#	Set-MailContact -Identity $sourceEmail -customAttribute15 $FromTenant -WarningAction SilentlyContinue >> $log

    }
Else 
    {
    echo "Creating contact $sourceEmail" >> $log

    New-MailContact -Name “$sourceName” `
	-ExternalEmailAddress $sourceEmail `
	-Alias $targetAlias `
	-DisplayName $targetDisplayName `
	-FirstName $sourceFirstName `
	-LastName $sourceLastName >> $log

    echo "Contacto criado, adicionar campos em falta" >> $log

    Set-Contact -Identity $sourceEmail `
    -Department $sourceDepartment `
    -Company $sourceCompany `
	-StreetAddress $sourceStreetAddress `
	-City $sourceCity `
	-PostalCode $sourcePostalCode `
	-Office $sourceOffice `
	-Title $sourceTitle `
	-Phone $sourcePhone `
	-Home $sourceHomePhone `
    -CountryOrRegion $sourceStreetAddressCountry `
	-MobilePhone $sourceMobilePhone `
	-Pager $sourcePager `
	-Fax $sourceFax `
	-WebPage $sourceWebPage `
	-WarningAction SilentlyContinue >> $log

<#
        This additional command serves to add custom attributes (example in case, customAttribute15) 
        which may be used in some tenants to create address lists. Uncomment if needed.
#>

#	Set-MailContact -Identity $sourceEmail -customAttribute15 $FromTenant -WarningAction SilentlyContinue >> $log
    }
}

echo " " >> $log
echo "Import successful, memory cleanup starting!" >> $log

# Memory Cleanup

[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

Disconnect-ExchangeOnline -Confirm:$false >> $log

Invoke-Expression ".\SendStatusMail.ps1 -messageSubject 'Tenant $FromTenant Import - Success' -messageBody '$ToTenant Import was success'"

echo "End of script" >> $log
Get-Date >> $log