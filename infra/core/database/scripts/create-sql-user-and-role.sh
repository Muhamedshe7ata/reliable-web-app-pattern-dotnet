#!/bin/bash
set -e

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -SqlServerName) SqlServerName="$2"; shift ;;
    -SqlDatabaseName) SqlDatabaseName="$2"; shift ;;
    -ObjectId) ObjectId="$2"; shift ;;
    -DisplayName) DisplayName="$2"; shift ;;
    -DatabaseRole) DatabaseRole="$2"; shift ;;
  esac
  shift
done

sql="
DECLARE @username nvarchar(max) = N'$DisplayName';
DECLARE @clientId uniqueidentifier = '$ObjectId';
DECLARE @sid NVARCHAR(max) = CONVERT(VARCHAR(max), CONVERT(VARBINARY(16), @clientId), 1);
DECLARE @cmd NVARCHAR(max) = N'CREATE USER [' + @username + '] WITH SID = ' + @sid + ', TYPE = E;';
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @username)
BEGIN
    EXEC(@cmd)
    EXEC sp_addrolemember '$DatabaseRole', @username;
END
"

echo "Running SQL:"
echo "$sql"

 sqlcmd -S "${SqlServerName}.database.windows.net" -d "$SqlDatabaseName" -G -Q "$sql"