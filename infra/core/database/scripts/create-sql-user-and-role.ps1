#Requires -Version 7.0

<#
.SYNOPSIS
    Creates a SQL user and assigns the user account to one or more roles.

.DESCRIPTION
    During an application deployment, the managed identity (and potentially the developer identity)
    must be added to the SQL database as a user and assigned to one or more roles.  This script
    does exactly that using the owner managed identity.

.PARAMETER SqlServerName
    The name of the SQL Server resource
.PARAMETER SqlDatabaseName
    The name of the SQL Database resource
.PARAMETER ObjectId
    The Object (Principal) ID of the user to be added.
.PARAMETER DisplayName
    The Object (Principal) display name of the user to be added.
.PARAMETER DatabaseRole
    The database role that needs to be assigned to the user.
#>

Param(
    [string] $SqlServerName,
    [string] $SqlDatabaseName,
    [string] $ObjectId,
    [string] $DisplayName,
    [string] $DatabaseRole
)

###
### MAIN SCRIPT
###
$sql = @"
DECLARE @username nvarchar(max) = N'$($DisplayName)';
DECLARE @clientId uniqueidentifier = '$($ObjectId)';
DECLARE @sid NVARCHAR(max) = CONVERT(VARCHAR(max), CONVERT(VARBINARY(16), @clientId), 1);
DECLARE @cmd NVARCHAR(max) = N'CREATE USER [' + @username + '] WITH SID = ' + @sid + ', TYPE = E;';
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @username)
BEGIN
    EXEC(@cmd)
    EXEC sp_addrolemember '$($DatabaseRole)', @username;
END
"@

Write-Output "`nSQL:`n$($sql)`n`n"

$token = (Get-AzAccessToken -ResourceUrl https://database.windows.net/).Token

# Save SQL to a file for sqlcmd
$sql | Out-File -FilePath temp.sql -Encoding utf8

# Run the SQL using sqlcmd and Azure AD access token
sqlcmd -S "$SqlServerName.database.windows.net" -d $SqlDatabaseName -G -U "AzureADUser" -P $token -i temp.sql
