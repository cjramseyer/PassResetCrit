# PasswordResetCrit

Tools scripts for operations to reset critical account passwords, MINIMUM VIABLE PRODUCT, UPDATES WILL COME LATER

**Request/Incident Description:**

Need to reset account passwords for critical accounts

**Background:**

Operational changes

**The Problem:**

Need to reset account passwords for critical accounts

**The Solution:**

Use the tools in this repo to reset passwords on critical accounts

**Business Project Benefits:**

Improved Security

**Requirements:**

Assumes appropriate credentials for each environment, logged in to $$UTL server.  Assumes correctly working replication and no conflicts.

**Execution Steps for each environment (DEVAD/QAD/PROD). Checkpoint review of evidence and approval required before deploying to next environment.**

**Implementation Steps:**

1. Get newest script from this repo: https://github.ford.com/Directory-Services-Team/PasswordResetCrit
2. Execute .\Reset-CritPassword.ps1 -Account hford000 -or- .\Reset-CritPassword.ps1

**NOTE:** Script will change the password for the specified account (No need to generate a password separately), The password will be recorded for each domain in a text file: C:\INSTAPPS\CritInfo.txt  The file will be destroyed 2 minutes after being created so the passwords for each domain can be recorded.
If no account is specified, the script will automatically reset the krbtgt account.
The script can also be set to perform the password change in one domain.  If a domain is not specified, the script will attempt to perform the change in all domains

**Validation Steps:**
Below are validation steps specifically for the ticket granting ticket account
1. Validate replication foreach ($GC in (get-adforest).globalcatalogs) {AdFind.exe -h $gc -default -f "&(objectcategory=user)(name=PUTTHEACTUALACCOUNTNAMEHERE)" pwdlastset -alldc -csvxl -csvnoheader }
2. Restart KDC -  foreach ($GC in (get-adforest).globalcatalogs) {Invoke-Command -ComputerName $GC -ScriptBlock {get-service -name kdc | restart-service -passthru }}
3. Collect all logs and send to AD Engineering.

Document Version: v2.0.0
Reference Ticket (If Any):
Proprietary
Record Series:  17.01
Record Type:  Official
Retention Period: C+3,T
