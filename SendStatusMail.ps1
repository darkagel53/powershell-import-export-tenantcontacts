<#
    SendStatusMail.ps1
    ---------------------------------
    
    Basic notification script, sends an e-mail to the defined mail address in smtpTo
    To be used in conjunction with the Import-ContactstToTenant.ps1 script

    Will be expecting a "Helpdesk.cred" file, which can be made using the 
    Create-PasswordFile script to create a credentials file.
    
#>

Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$messageSubject,
    [Parameter(Mandatory=$True,Position=2)]
    [string]$messageBody
)

$CredFileEmail = "Helpdesk.cred"
$Pass = Cat $CredFileEmail | ConvertTo-SecureString

$User="helpdesk@test.pt"

$smtpTo = “email@test.pt”

$smtpServer = “smtp.office365.com”

$emailCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass
Send-MailMessage -from $User -to $smtpTo -Subject $messageSubject -Body $messageBody -Credential $emailCreds -UseSsl -SmtpServer $smtpServer -Port 587