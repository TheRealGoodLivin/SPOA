# MIT License

# Copyright (c) 2023 Austin L

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

Function Format-FileSize() { # https://community.spiceworks.com/topic/1955251-powershell-help
    Param ([int]$size)
    If ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
    ElseIf ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
    ElseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
    ElseIf ($size -gt 1KB) {[string]::Format("{0:0.00} KB", $size / 1KB)}
    ElseIf ($size -gt 0) {[string]::Format("{0:0.00} B", $size)}
    Else {""}
}

function reportCreate {
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportPath,
          [Parameter(Mandatory)][object[]]$reportData)

    if (test-path $reportPath) {
        $reportData | Export-Csv -Path $reportPath -Force -NoTypeInformation -Append
    } else {
        $reportData | Export-Csv -Path $reportPath -Force -NoTypeInformation
    }
}

#region SETUP FUNCTIONS
function showSetup {
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$SetupPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ReportPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DirtyWordsPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DirtyWordsFilePath)

    Clear-Host
    $isInstalled=Get-InstalledModule -Name PnP.PowerShell -ErrorAction silentlycontinue
    if($isInstalled.count -eq 0) {
        $Confirm = Read-Host "WOULD YOU LIKE TO INSTALL SHAREPOINT PNP MODULE? [Y] Yes [N] No"

        if($Confirm -match "[yY]") {
            Install-Module -Name PnP.PowerShell -Scope CurrentUser
        } else {
            Write-Host "SharePoint PnP module is needed to perform the functions of this script." -ForegroundColor red
            break
        }
    }

    if (-Not (test-path $SetupPath)) {
        New-Item -Path $SetupPath -ItemType Directory | Out-Null
    }

    if (-Not (test-path $ReportPath)) {
        New-Item -Path $ReportPath -ItemType Directory | Out-Null
    }

    if (-Not (test-path $DirtyWordsPath)) {
        New-Item -Path $DirtyWordsPath -ItemType Directory | Out-Null
    }

    if (-Not (test-path $DirtyWordsFilePath)) {
        $wordDefaultDirtySearchSet = @("\d{3}-\d{3}-\d{4}","\d{3}-\d{2}-\d{4}","MyFitness","CUI","UPMR","SURF","PA","2583","SF86","SF 86","FOUO","GTC","medical","AF469","AF 469","469","Visitor Request","VisitorRequest","Visitor","eQIP","EPR","910","AF910","AF 910","911","AF911","AF 911","OPR","eval","feedback","loc","loa","lor","alpha roster","alpha","roster","recall","SSN","SSAN","AF1466","1466","AF 1466","AF1566","AF 1566","1566","SGLV","SF182","182","SF 182","allocation notice","credit","allocation","2583","AF 1466","AF1466","1466","AF1566","AF 1566","1566","AF469","AF 469","469","AF 422","AF422","422","AF910","AF 910","910","AF911","AF 911","911","AF77","AF 77","77","AF475","AF 475","475","AF707","AF 707","707","AF709","AF 709","709","AF 724","AF724","724","AF912","AF 912","912","AF 931","AF931","931","AF932","AF 932","932","AF948","AF 948","948","AF 3538","AF3538","3538","AF3538E","AF 3538E","AF2096","AF 2096","2096","AF 2098","AF2098","AF 2098","AF 3538","AF3538","3538","1466","1566","469","422","travel","SF128","SF 128","128","SF 86","SF86","86","SGLV","SGLI","DD214","DD 214","214","DD 149","DD149","149") | Select-Object @{Name='Word';Expression={$_}} | Export-Csv $DirtyWordsFilePath -NoType
    }

    if (test-path $DirtyWordsPath) {
        $global:wordDirtySearch = Import-Csv $DirtyWordsFilePath
    }
}
#endregion

#region MAIN AND SETTING MENU FUNCTIONS
function showMenu {
    Write-Host "
###########################################################
#                                                         #
#             ░██████╗██████╗░░█████╗░░█████╗░            #
#             ██╔════╝██╔══██╗██╔══██╗██╔══██╗            #
#             ╚█████╗░██████╔╝██║░░██║███████║            #
#             ░╚═══██╗██╔═══╝░██║░░██║██╔══██║            #
#             ██████╔╝██║░░░░░╚█████╔╝██║░░██║            #
#             ╚═════╝░╚═╝░░░░░░╚════╝░╚═╝░░╚═╝            #
#                                                         #
#        WELCOME TO THE SHAREPOINT ONLINE ASSISTANT       #
#                                                         #
###########################################################`n
MAIN MENU -- SELECT A CATEGORY`n
`t1: PRESS '1' FOR SITE TOOLS.
`t2: PRESS '2' FOR USER TOOLS.
`t3: PRESS '3' FOR LIST TOOLS.
`t4: PRESS '4' FOR CUSTOM LIST TOOLS.
`t5: PRESS '5' FOR DOCUMENT TOOLS.
`tPRESS 'S' FOR SETTINGS OR 'Q' TO QUIT`n"
}

function showSettings {   
    Write-Host "`nSETTINGS -- SELECT AN OPTION`n
`t1: PRESS '1' TO OPEN SPOA FOLDER.
`t2: PRESS '2' TO OPEN THE DIRTY WORD LIST.
`tE: PRESS 'E' TO EXIT BACK TO THE MAIN MENU.`n"
}
#endregion

#region SITE TOOLS FUNCTIONS
function showSiteTools {   
    Write-Host "`nSITE TOOLS -- SELECT AN OPTION`n
`t1: PRESS '1' FOR SITE MAP REPORT.
`t2: PRESS '2' FOR PII SCAN REPORT.
`t3: PRESS '3' FOR SITE COLLECTION ADMIN REPORT.
`t4: PRESS '4' FOR ADD A SITE COLLECTION ADMIN.
`t4: PRESS '5' FOR DELETE A SITE COLLECTION ADMIN.
`t5: PRESS '6' FOR SITE COLLECTION GROUP REPORT.
`tE: PRESS 'E' TO EXIT BACK TO THE MAIN MENU.`n"
}

# OPTION "1"
function spoSiteMap {
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportName)

    $sitePath = Read-Host "`nENTER SITE COLLECTION URL"
    $results = @()

    Connect-PnPOnline -Url $sitePath -UseWebLogin -WarningAction SilentlyContinue

    $siteInfo = Get-PnPWeb -Includes Created | select Title, ServerRelativeUrl, Url, Created, Description
    $siteLists = Get-PnPList | Where-Object {$_.Hidden -eq $false}
    $subSites = Get-PnPSubWeb -Recurse | select Title, ServerRelativeUrl, Url, Created, Description

    $siteListCount = @()
    $siteItemCount = 0
    foreach ($list in $subSiteLists) {
        $siteListCount += $list
        $siteItemCount = $siteItemCount + $list.ItemCount
    }

    # GET PARENT SITE INFO AND LIST COUNT
    $results = New-Object PSObject -Property @{
        Title = $siteInfo.Title
        ItemCount = $siteItemCount
        ListCount = $siteListCount.Count
        ServerRelativeUrl = $siteInfo.ServerRelativeUrl
        Description = $siteInfo.Description
        Created = $siteInfo.Created
    }
    reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results

    foreach ($site in $subSites) {
        Connect-PnPOnline -Url $site.Url -UseWebLogin -WarningAction SilentlyContinue
        $subSiteLists = Get-PnPList | Where-Object {$_.Hidden -eq $false}

        $subSiteListCount = @()
        $subSiteItemCount = 0
        foreach ($list in $subSiteLists) {
            $subSiteListCount += $list
            $siteListCount += $list
            $subSiteItemCount = $subSiteItemCount + $list.ItemCount
            $siteItemCount = $siteItemCount + $list.ItemCount
        }

        $results = New-Object PSObject -Property @{
            Title = $site.Title
            ListCount = $subSiteListCount.Count
            ItemCount = $subSiteItemCount
            ServerRelativeUrl = $site.ServerRelativeUrl
            Description = $site.Description
            Created = $site.Created
        }
        reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results
    }

    # GET TOTAL COUNTS
    $results = New-Object PSObject -Property @{
        Title = "Total"
        ListCount = $siteListCount.Count
        ItemCount = $siteItemCount
        ServerRelativeUrl = $subSites.Count + 1
        Description = ""
        Created = ""
    }
    reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results

    Disconnect-PnPOnline
    Write-Host "`nCompleted: " -ForegroundColor DarkYellow -nonewline; Write-Host "$(get-date -format yyyy/MM/dd-HH:mm:ss)" -ForegroundColor White;
    Write-Host "Report Saved: " -ForegroundColor DarkYellow -nonewline; Write-Host "$($reportPath)\$($reportName)" -ForegroundColor White;
}

# OPTION "2"
function spoScanPII {
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportName)

    $sitePath = Read-Host "`nENTER SITE COLLECTION URL"
    $results = @()

    $Confirm = Read-Host "`nWOULD YOU LIKE TO SCAN ALL SUB-SITES? [Y] Yes [N] No"
    if($Confirm -match "[yY]") {
        $siteParentOnly = $false
    } else {
        $siteParentOnly = $true
    }

    Connect-PnPOnline -Url $sitePath -UseWebLogin -WarningAction SilentlyContinue
    $getDocLibs = Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 }

    Write-Host "Searching: $($sitePath)" -ForegroundColor Green

    foreach ($DocLib in $getDocLibs) {
        Get-PnPListItem -List $DocLib -Fields "FileRef", "File_x0020_Type", "FileLeafRef", "File_x0020_Size", "Created", "Modified" -PageSize 1000 | Where { $_["FileLeafRef"] -like "*.*" } | Foreach-Object {
            foreach ($word in $global:wordDirtySearch) {
                $wordSearch = "(?i)\b$($word.Word)\b"

                if (($_["FileLeafRef"] -match $wordSearch)) {
                    Write-Host "File found. " -ForegroundColor Red -nonewline; Write-Host "Under: '$($word.Word)' Path: $($_["FileRef"])" -ForegroundColor Yellow;

                    $permissions = @()
                    $perm = Get-PnPProperty -ClientObject $_ -Property RoleAssignments       
                    foreach ($role in $_.RoleAssignments) {
                        $loginName = Get-PnPProperty -ClientObject $role.Member -Property LoginName
                        $rolebindings = Get-PnPProperty -ClientObject $role -Property RoleDefinitionBindings
                        $permissions += "$($loginName) - $($rolebindings.Name)"
                    }
                    $permissions = $permissions | Out-String

                    if ($_ -eq $null) {
                        Write-Host "Error: 'Unable to pull file information'."
                    } else {
                        $size = Format-FileSize($_["File_x0020_Size"])
                               
                        $results = New-Object PSObject -Property @{
                            FileName = $_["FileLeafRef"]
                            FileExtension = $_["File_x0020_Type"]
                            FileSize = $size
                            Path = $_["FileRef"]
                            Permissions = $permissions
                            Criteria = $word.Word
                            Created = $_["Created"]
                            Modified = $_["Modified"]
                        }
                        reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results
                    }
                }
            }
        }
    }

    if ($siteParentOnly -eq $false) {
        $subSites = Get-PnPSubWeb -Recurse

        foreach ($site in $subSites) {
            Connect-PnPOnline -Url $site.Url -UseWebLogin -WarningAction SilentlyContinue
            $getSubDocLibs = Get-PnPList | Where-Object {$_.BaseTemplate -eq 101}

            Write-Host "Searching: $($site.Url)" -ForegroundColor Green

            foreach ($subDocLib in $getSubDocLibs) {
                Get-PnPListItem -List $subDocLib -Fields "FileRef", "File_x0020_Type", "FileLeafRef", "File_x0020_Size", "Created", "Modified" -PageSize 1000 | Where { $_["FileLeafRef"] -like "*.*" } | Foreach-Object {
                    foreach ($word in $global:wordDirtySearch) {
                        $wordSearch = "(?i)\b$($word.Word)\b"

                        if (($_["FileLeafRef"] -match $wordSearch)) {
                            Write-Host "File found. " -ForegroundColor Red -nonewline; Write-Host "Under: '$($word.Word)' Path: $($_["FileRef"])" -ForegroundColor Yellow;

                            $permissions = @()
                            $perm = Get-PnPProperty -ClientObject $_ -Property RoleAssignments       
                            foreach ($role in $_.RoleAssignments) {
                                $loginName = Get-PnPProperty -ClientObject $role.Member -Property LoginName
                                $rolebindings = Get-PnPProperty -ClientObject $role -Property RoleDefinitionBindings
                                $permissions += "$($loginName) - $($rolebindings.Name)" 
                            }
                            $permissions = $permissions | Out-String

                            if ($_ -eq $null) {
                                Write-Host "Error: 'Unable to pull file information'."
                            } else {
                                $size = Format-FileSize($_["File_x0020_Size"])
           
                                $results = New-Object PSObject -Property @{
                                    FileName = $_["FileLeafRef"]
                                    FileExtension = $_["File_x0020_Type"]
                                    FileSize = $size
                                    Path = $_["FileRef"]
                                    Permissions = $permissions
                                    Criteria = $word.Word
                                    Created = $_["Created"]
                                    Modified = $_["Modified"]
                                }
                                reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results
                            }
                        }
                    }
                }
            }
        }
    }

    Disconnect-PnPOnline
    Write-Host "`nCompleted: " -ForegroundColor DarkYellow -nonewline; Write-Host "$(get-date -format yyyy/MM/dd-HH:mm:ss)" -ForegroundColor White;
    Write-Host "Report Saved: " -ForegroundColor DarkYellow -nonewline; Write-Host "$($reportPath)\$($reportName)" -ForegroundColor White;
}

# OPTION "3"
function spoGetSiteCollectionAdmins {
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportName)
    
    $results = @()
    $sitePath = Read-Host "`nENTER SITE COLLECTION URL"
    Connect-PnPOnline -Url $sitePath -UseWebLogin -WarningAction SilentlyContinue

    Get-PnPSiteCollectionAdmin | Foreach-Object {
        $results = New-Object PSObject -Property @{
            Id = $_.Id
            Title = $_.Title
            Email = $_.Email
            LoginName = $_.LoginName
            IsSiteAdmin = $_IsSiteAdmin
            IsShareByEmailGuestUser = $_.IsShareByEmailGuestUser
            IsHiddenInUI = $_.IsHiddenInUI
            PrincipalType = $_.PrincipalType
        }
        reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results
    }

    Disconnect-PnPOnline
    Write-Host "`nCompleted: " -ForegroundColor DarkYellow -nonewline; Write-Host "$(get-date -format yyyy/MM/dd-HH:mm:ss)" -ForegroundColor White;
    Write-Host "Report Saved: " -ForegroundColor DarkYellow -nonewline; Write-Host "$($reportPath)\$($reportName)" -ForegroundColor White;
}

# OPTION "4"
function spoAddSiteCollectionAdmin {
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportName)
    
    $results = @()
    $sitePath = Read-Host "`nENTER SITE COLLECTION URL"
    $newAdmin = Read-Host "`nENTER NEW SITE COLLECTION ADMIN EMAIL"
    
    Connect-PnPOnline -Url $sitePath -UseWebLogin -WarningAction SilentlyContinue
    Add-PnPSiteCollectionAdmin -Owners $newAdmin

    $results = New-Object PSObject -Property @{
        AdminNew = $newAdmin
    }
    reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results

    Disconnect-PnPOnline
    Write-Host "`nCompleted: " -ForegroundColor DarkYellow -nonewline; Write-Host "$(get-date -format yyyy/MM/dd-HH:mm:ss)" -ForegroundColor White;
    Write-Host "Report Saved: " -ForegroundColor DarkYellow -nonewline; Write-Host "$($reportPath)\$($reportName)" -ForegroundColor White;
}

# OPTION "5"
function spoDeleteSiteCollectionAdmin {
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportName)
    
    $results = @()
    $sitePath = Read-Host "`nENTER SITE COLLECTION URL"
    
    Connect-PnPOnline -Url $sitePath -UseWebLogin -WarningAction SilentlyContinue

    $getAdmins = @()
    Get-PnPSiteCollectionAdmin | foreach-object { $getAdmins += $_ }

    do {
        Write-Host "`nPLEASE SELECT AN ADMIN`n"
        foreach ($admin in $getAdmins) {
            Write-Host "`t$($getAdmins.IndexOf($admin)+1): PRESS $($getAdmins.IndexOf($admin)+1) for $($admin.Title)"
        }
        $adminChoice = Read-Host "PLEASE MAKE A SELECTION"
    } while (-not($getAdmins[$adminChoice-1]))

    Remove-PnPSiteCollectionAdmin -Owners $getAdmins[$adminChoice-1].Title

    $results = New-Object PSObject -Property @{
        AdminDeleted = $getAdmins[$adminChoice-1].Title
    }
    reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results

    Disconnect-PnPOnline
    Write-Host "`nCompleted: " -ForegroundColor DarkYellow -nonewline; Write-Host "$(get-date -format yyyy/MM/dd-HH:mm:ss)" -ForegroundColor White;
    Write-Host "Report Saved: " -ForegroundColor DarkYellow -nonewline; Write-Host "$($reportPath)\$($reportName)" -ForegroundColor White;
}

# OPTION "6"
function spoGetSiteCollectionGroups {
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportName)

    $sitePath = Read-Host "`nENTER SITE COLLECTION URL"
    $results = @()

    Connect-PnPOnline -Url $sitePath -UseWebLogin -WarningAction SilentlyContinue
    Get-PnPGroup | Where {$_.IsHiddenInUI -eq $false -and $_.LoginName -notlike "Limited Access*" -and $_.LoginName -notlike "SharingLinks*"} | Select-Object "Id", "Title", "LoginName", "OwnerTitle" | Foreach-Object {
        $members = @()
        Get-PnPGroupMember -Identity $_.Title | Foreach-Object {
            $members += "$($_.Title)" 
        }
        $members = $members | Out-String

        $results = New-Object PSObject -Property @{
            ID = $_.Id
            GroupName = $_.Title
            LoginName = $_.LoginName
            OwnerTitle = $_.OwnerTitle
            Members = $members
        }
        reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results
    }

    Disconnect-PnPOnline
    Write-Host "`nCompleted: " -ForegroundColor DarkYellow -nonewline; Write-Host "$(get-date -format yyyy/MM/dd-HH:mm:ss)" -ForegroundColor White;
    Write-Host "Report Saved: " -ForegroundColor DarkYellow -nonewline; Write-Host "$($reportPath)\$($reportName)" -ForegroundColor White;
}
#endregion

#region USER TOOLS FUNCTIONS
function showUserTools {   
    Write-Host "`nUSER TOOLS -- SELECT AN OPTION`n
`t1: PRESS '1' FOR USER DELETION.
`t2: PRESS '2' FOR ALL ASSIGNED USER GROUP DELETION.
`tE: PRESS 'E' TO EXIT BACK TO THE MAIN MENU.`n"
}

# OPTION "1"
function spoDeleteUser {
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportName)

    $sitePath = Read-Host "`nENTER SITE COLLECTION URL"
    $userEmail = Read-Host "`nENTER USERS EMAIL"
    $results = @()

    Connect-PnPOnline -Url $sitePath -UseWebLogin -WarningAction SilentlyContinue
    $userInformation = Get-PnPUser | ? Email -eq $userEmail | ForEach-Object { 
        Remove-PnPUser -Identity $_.Title -Force
        Write-Host "User Deleted: $($_.Title)" -ForegroundColor Yellow

        $results = New-Object PSObject -Property @{
            UserDeleted = $_.Title
            UserEmail = $_.Email
        }
        reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results
    }

    Disconnect-PnPOnline
    Write-Host "`nCompleted: " -ForegroundColor DarkYellow -nonewline; Write-Host "$(get-date -format yyyy/MM/dd-HH:mm:ss)" -ForegroundColor White;
    Write-Host "Report Saved: " -ForegroundColor DarkYellow -nonewline; Write-Host "$($reportPath)\$($reportName)" -ForegroundColor White;
}

# OPTION "2"
function spoDeleteUserGroups {
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportName)

    $sitePath = Read-Host "`nENTER SITE COLLECTION URL"
    $userEmail = Read-Host "`nENTER USERS EMAIL"
    $results = @()

    Connect-PnPOnline -Url $sitePath -UseWebLogin -WarningAction SilentlyContinue
    $userInformation = Get-PnPUser | ? Email -eq $userEmail | ForEach-Object { $_.Title }
    $userGroups = Get-PnPUser | ? Email -eq $userEmail | Select -ExpandProperty Groups | Where { ($_.Title -notmatch "Limited Access*") -and ($_.Title -notmatch "SharingLinks*") } | ForEach-Object { 
        Write-Host "Name: $userInformation | Group Removed: " -ForegroundColor Yellow -NoNewline; Write-Host $($_.Title) -ForegroundColor Cyan

        Remove-PnPGroupMember -LoginName $userEmail -Identity $_.Title 

        $results = New-Object PSObject -Property @{
            UserDisplay = $userInformation
            UserGroup = $_.Title
        }
        reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results
    }

    Disconnect-PnPOnline
    Write-Host "`nCompleted: " -ForegroundColor DarkYellow -nonewline; Write-Host "$(get-date -format yyyy/MM/dd-HH:mm:ss)" -ForegroundColor White;
    Write-Host "Report Saved: " -ForegroundColor DarkYellow -nonewline; Write-Host "$($reportPath)\$($reportName)" -ForegroundColor White;
}
#endregion

#region LIST TOOLS FUNCTIONS
function showListTools {   
    Write-Host "`nCUSTOM LIST TOOLS -- SELECT AN OPTION`n
`t1: PRESS '1' SHOW LIST IN BROWSER.
`t2: PRESS '2' HIDE LIST FROM BROWSER.
`tE: PRESS 'E' TO EXIT BACK TO THE MAIN MENU.`n"
}

# OPTION "1"
function spoShowList {
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportName)

    $sitePath = Read-Host "`nENTER SITE URL THAT LIST RESIDES ON"
    $results = @()
    
    Connect-PnPOnline -Url $sitePath -UseWebLogin -WarningAction SilentlyContinue

    $listsGet = @()
    Get-PnPList | Where-Object { $_.Hidden -eq $true -and ($_.BaseTemplate -eq 100 -or $_.BaseTemplate -eq 101 -or $_.BaseTemplate -eq 102 -or $_.BaseTemplate -eq 103 -or $_.BaseTemplate -eq 104 -or $_.BaseTemplate -eq 105 -or $_.BaseTemplate -eq 106 -or $_.BaseTemplate -eq 107 -or $_.BaseTemplate -eq 108 -or $_.BaseTemplate -eq 109) } | ForEach-Object { $listsGet += $_ }

    if ($listsGet.count) {
        do {
            Write-Host "`nPLEASE SELECT A LIST`n"
            foreach ($list in $listsGet) {
                Write-Host "`t$($listsGet.IndexOf($list)+1): PRESS $($listsGet.IndexOf($list)+1) for $($list.Title)"
            }
            $listChoice = Read-Host "`nPLEASE MAKE A SELECTION"
        } while (-not($listsGet[$listChoice-1]))

        Set-PnPList -Identity $listsGet[$listChoice-1].Title -Hidden $false

        $results = New-Object PSObject -Property @{
            ShowList = $listsGet[$listChoice-1].Title
        }
        reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results

        Disconnect-PnPOnline
        Write-Host "`nCompleted: " -ForegroundColor DarkYellow -nonewline; Write-Host "$(get-date -format yyyy/MM/dd-HH:mm:ss)" -ForegroundColor White;
        Write-Host "Report Saved: " -ForegroundColor DarkYellow -nonewline; Write-Host "$($reportPath)\$($reportName)" -ForegroundColor White;
    } else {
        Write-Host "`nNO LISTS ARE HIDDEN." -ForegroundColor Red
    }
}

# OPTION "2"
function spoHideList {
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportName)

    $sitePath = Read-Host "`nENTER SITE URL THAT LIST RESIDES ON"
    $results = @()
    
    Connect-PnPOnline -Url $sitePath -UseWebLogin -WarningAction SilentlyContinue

    $listsGet = @()
    Get-PnPList | Where-Object { $_.Hidden -eq $false } | ForEach-Object { $listsGet += $_ }

    if ($listsGet.count) {
        do {
            Write-Host "`nPLEASE SELECT A LIST`n"
            foreach ($list in $listsGet) {
                Write-Host "`t$($listsGet.IndexOf($list)+1): PRESS $($listsGet.IndexOf($list)+1) for $($list.Title)"
            }
            $listChoice = Read-Host "`nPLEASE MAKE A SELECTION"
        } while (-not($listsGet[$listChoice-1]))

        Set-PnPList -Identity $listsGet[$listChoice-1].Title -Hidden $true

        $results = New-Object PSObject -Property @{
            HideList = $listsGet[$listChoice-1].Title
        }
        reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results

        Disconnect-PnPOnline
        Write-Host "`nCompleted: " -ForegroundColor DarkYellow -nonewline; Write-Host "$(get-date -format yyyy/MM/dd-HH:mm:ss)" -ForegroundColor White;
        Write-Host "Report Saved: " -ForegroundColor DarkYellow -nonewline; Write-Host "$($reportPath)\$($reportName)" -ForegroundColor White;
    } else {
        Write-Host "`nNO LISTS ARE HIDDEN." -ForegroundColor Red
    }
}
#endregion

#region CUSTOM LIST TOOLS FUNCTIONS
function showCustomListTools {   
    Write-Host "`nCUSTOM LIST TOOLS -- SELECT AN OPTION`n
`t1: PRESS '1' DELETE ALL LIST ITEMS.
`tE: PRESS 'E' TO EXIT BACK TO THE MAIN MENU.`n"
}

# OPTION "1"
function spoDeleteAllListItems {
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportName)

    $sitePath = Read-Host "`nENTER SITE URL THAT LIST RESIDES ON"
    $results = @()
    
    Connect-PnPOnline -Url $sitePath -UseWebLogin -WarningAction SilentlyContinue
    $listsGet = @()

    Get-PnPList | Where-Object { $_.Hidden -eq $false -and $_.BaseTemplate -eq 100 } | ForEach-Object { $listsGet += ($_) }

    do {
        Write-Host "`nPLEASE SELECT A LIST`n"
        foreach ($list in $listsGet) {
            Write-Host "`t$($listsGet.IndexOf($list)+1): PRESS $($listsGet.IndexOf($list)+1) for $($list.Title)"
        }
        $listChoice = Read-Host "`nPLEASE MAKE A SELECTION"
    } while (-not($listsGet[$listChoice-1]))

    $listItems =  Get-PnPListItem -List $listsGet[$listChoice-1].Title -PageSize 500
    $Batch = New-PnPBatch
    ForEach($item in $listItems) {    
         Remove-PnPListItem -List $listsGet[$listChoice-1].Title -Identity $item.Id -Recycle -Batch $Batch

         $results = New-Object PSObject -Property @{
            ListName = $listsGet[$listChoice-1].Title
            ItemDeletedID = $item.Id
        }
        reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results
    }
    Invoke-PnPBatch -Batch $Batch

    Disconnect-PnPOnline
    Write-Host "`nCompleted: " -ForegroundColor DarkYellow -nonewline; Write-Host "$(get-date -format yyyy/MM/dd-HH:mm:ss)" -ForegroundColor White;
    Write-Host "Report Saved: " -ForegroundColor DarkYellow -nonewline; Write-Host "$($reportPath)\$($reportName)" -ForegroundColor White;
}
#endregion

#region DOCUMENT TOOLS FUNCTIONS
function showDocumentTools {   
    Write-Host "`nDOCUMENT TOOLS -- SELECT AN OPTION`n
`t1: PRESS '1' TRANSFER FOLDER TO DOCUMENT LIBRARY
`tE: PRESS 'E' TO EXIT BACK TO THE MAIN MENU.`n"
}

# OPTION "1"
function spoUploadDocumentItems {
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportPath,
          [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$reportName)

    $results = @()
    $sitePath = Read-Host "ENTER SITE URL THAT DOCUMENT LIBRARY RESIDES ON"
    $sitePath = $sitePath.Trim(" ", "/")
    $localPath = Read-Host "ENTER LOCAL DIRECTORY LOCATION TO COPY"
    $selectedLibraryFolder = ""

    $getDocumentLibraries = @()
    
    if ((Get-Item $localPath) -is [System.IO.DirectoryInfo]) {
        Connect-PnPOnline -Url $sitePath -UseWebLogin -WarningAction SilentlyContinue

        Get-PnPList | Where-Object { $_.Hidden -eq $false -and $_.BaseTemplate -eq 101 -and $_.Title -ne "SiteCollectionDocuments" -and $_.Title -ne "Style Library" -and $_.Title -ne "FormServerTemplates" -and $_.Title -ne "Form Templates" } | foreach-object { $getDocumentLibraries += $_ }

        do {
            Write-Host "`nPLEASE SELECT A DOCUMENT LIBRARY`n"
            foreach ($documentLibrary in $getDocumentLibraries) {
                Write-Host "`t$($getDocumentLibraries.IndexOf($documentLibrary)+1): PRESS $($getDocumentLibraries.IndexOf($documentLibrary)+1) for $($documentLibrary.Title)"
            }
            $documentLibraryChoice = Read-Host "`nPLEASE MAKE A SELECTION"
        } while (-not($getDocumentLibraries[$documentLibraryChoice-1]))

        $selectedLibraryURLFolder = $getDocumentLibraries[$documentLibraryChoice-1].RootFolder.ServerRelativeUrl.replace($getDocumentLibraries[$documentLibraryChoice-1].ParentWebUrl,"")

        do {
            $selectedSubFolders = @()
            Get-PnPFolderItem -FolderSiteRelativeUrl $selectedLibraryURLFolder -ItemType Folder | Where { $_.Name -ne "Forms" } | foreach-object { $selectedSubFolders += $_ }

            if($selectedSubFolders.count) {
                Write-Host "`nPLEASE SELECT A FOLDER TO COPY TO`n"
                foreach ($child in $selectedSubFolders) {
                    Write-Host "$($selectedSubFolders.IndexOf($child)+1): PRESS $($selectedSubFolders.IndexOf($child)+1) for $($child.Name)"
                }
                Write-Host "S: PRESS S to Select Current Folder"
                $folderChoice = Read-Host "`nPLEASE MAKE A SELECTION"
            } else {
                $folderChoice = "S"
            }

            if($folderChoice -ne "S") {
                if(-not($selectedSubFolders[$folderChoice-1])) {
                } else {
                    $selectedLibraryURLFolder += "/$($selectedSubFolders[$folderChoice-1].Name)"
                }
            } else {
                $selectedLibraryFolder = $selectedLibraryURLFolder.Trim(" ", "/")
            }
        } while ($selectedLibraryFolder -eq "")

        $Confirm = Read-Host "WOULD YOU LIKE TO UPLOAD DOCUMENTS TO THIS FOLDER: $($selectedLibraryFolder)? [Y] Yes [N] No"
        if($Confirm -match "[yY]") {
            Write-host "`nProcessing Folder: $($localPath)" -f Yellow
            Resolve-PnPFolder -SiteRelativePath $selectedLibraryFolder | Out-Null    

            $files = Get-ChildItem -Path $localPath -File
            ForEach ($file in $files) {
                Add-PnPFile -Path "$($file.Directory)\$($file.Name)" -Folder $selectedLibraryFolder -Values @{"Title" = $($file.Name)} | Out-Null
                Write-host "`tUploaded File: $($file.FullName)" -f Green

                $results = New-Object PSObject -Property @{
                    Type = "File"
                    OriginalLocation = $file.FullName
                    NewLocation = "$($sitePath)/$selectedLibraryFolder/$($file.Name)"
                }
                reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results
            }

            Get-ChildItem -Path $localPath -Recurse -Directory | ForEach-Object {
                $folderToUpload = ($selectedLibraryFolder+$_.FullName.Replace($localPath,"")).Replace("\","/")

                Write-host "Processing Folder: $($_.FullName)" -ForegroundColor Yellow
                Resolve-PnPFolder -SiteRelativePath $folderToUpload | Out-Null

                $results = New-Object PSObject -Property @{
                    Type = "Folder"
                    OriginalLocation = $_.FullName
                    NewLocation = "$($sitePath)/$($folderToUpload)"
                }
                reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results

                $files = Get-ChildItem -Path $_.FullName -File
                ForEach ($file in $files) {
                    Add-PnPFile -Path "$($file.Directory)\$($file.Name)" -Folder $folderToUpload -Values @{"Title" = $($file.Name)} | Out-Null
                    Write-host "`tUploaded File: $($file.FullName)" -ForegroundColor Green

                    $results = New-Object PSObject -Property @{
                        Type = "File"
                        OriginalLocation = $file.FullName
                        NewLocation = "$($sitePath)/$($folderToUpload)/$($file.Name)"
                    }
                    reportCreate -reportPath "$($setupReportPath)\$($reportName)" -reportData $results
                }
            }
        }

        Disconnect-PnPOnline
        Write-Host "`nCompleted: " -ForegroundColor DarkYellow -nonewline; Write-Host "$(get-date -format yyyy/MM/dd-HH:mm:ss)" -ForegroundColor White;
        Write-Host "Report Saved: " -ForegroundColor DarkYellow -nonewline; Write-Host "$($reportPath)\$($reportName)" -ForegroundColor White;
    } else {
        Write-Host "`nPATH SUPPLIED WAS NOT A FOLDER! PLEASE CHECK YOUR LOCAL DIRECTORY PATH AND TRY AGAIN!" -ForegroundColor Red
    }
}
#endregion

#region MAIN
$setupPath = "C:\users\$env:USERNAME\Documents\SOPA"
$setupReportPath = $setupPath + "\Reports"
$setupDirtyWordsPath = $setupPath + "\DirtyWords"
$setupDirtyWordsFilePath = $setupDirtyWordsPath + "\DirtyWords.csv"

$global:wordDirtySearch = $null;

showSetup -SetupPath $setupPath -ReportPath $setupReportPath -DirtyWordsPath $setupDirtyWordsPath -DirtyWordsFilePath $setupDirtyWordsFilePath
do {
    showMenu
    $menuMain = Read-Host "PLEASE MAKE A SELECTION"
    switch ($menuMain) {
        #region SITE TOOLS
        "1" {
            do {
                showSiteTools
                $menuSub = Read-Host "PLEASE MAKE A SELECTION"
                switch ($menuSub) {
                    "1" {
                        spoSiteMap -reportPath $setupReportPath -reportName "SPOSITEMAP_$((Get-Date).ToString("yyyyMMdd_HHmmss")).csv"
                    }
                    "2" {
                        spoScanPII -reportPath $setupReportPath -reportName "SPOSCANPII_$((Get-Date).ToString("yyyyMMdd_HHmmss")).csv"
                    }
                    "3" {
                        spoGetSiteCollectionAdmins -reportPath $setupReportPath -reportName "SPOGETSITECOLLECTIONADMINS_$((Get-Date).ToString("yyyyMMdd_HHmmss")).csv"
                    }
                    "4" {
                        spoAddSiteCollectionAdmin -reportPath $setupReportPath -reportName "SPOADDSITECOLLECTIONADMIN_$((Get-Date).ToString("yyyyMMdd_HHmmss")).csv"
                    }
                    "5" {
                        spoDeleteSiteCollectionAdmin -reportPath $setupReportPath -reportName "SPODELETESITECOLLECTIONADMIN_$((Get-Date).ToString("yyyyMMdd_HHmmss")).csv"
                    }
                    "6" {
                        spoGetSiteCollectionGroups -reportPath $setupReportPath -reportName "SPOGETSITECOLLECTIONGROUPS_$((Get-Date).ToString("yyyyMMdd_HHmmss")).csv"
                    }
                }
            } until ($menuSub -eq "e")
        }
        #endregion

        #region USER TOOLS
        "2" {
            do {
                showUserTools
                $menuSub = Read-Host "PLEASE MAKE A SELECTION"
                switch ($menuSub) {
                    "1" {
                        spoDeleteUser -reportPath $setupReportPath -reportName "DELETEUSER_$((Get-Date).ToString("yyyyMMdd_HHmmss")).csv"
                    }
                    "2" {
                        spoDeleteUserGroups -reportPath $setupReportPath -reportName "DELETEUSERGROUPS_$((Get-Date).ToString("yyyyMMdd_HHmmss")).csv"
                    }
                }
            } until ($menuSub -eq "e")
        }
        #endregion

        #region LIST TOOLS
        "3" {
            do {
                showListTools
                $menuSub = Read-Host "PLEASE MAKE A SELECTION"
                switch ($menuSub) {
                    "1" {
                        spoShowList -reportPath $setupReportPath -reportName "SHOWLIST_$((Get-Date).ToString("yyyyMMdd_HHmmss")).csv"
                    }
                    "2" {
                        spoHideList -reportPath $setupReportPath -reportName "HIDELIST_$((Get-Date).ToString("yyyyMMdd_HHmmss")).csv"
                    }
                }
            } until ($menuSub -eq "e")
        }
        #endregion

        #region CUSTOM LIST TOOLS
        "4" {
            do {
                showCustomListTools
                $menuSub = Read-Host "PLEASE MAKE A SELECTION"
                switch ($menuSub) {
                    "1" {
                        spoDeleteAllListItems -reportPath $setupReportPath -reportName "DELETEDLISTITEMS_$((Get-Date).ToString("yyyyMMdd_HHmmss")).csv"
                    }
                }
            } until ($menuSub -eq "e")
        }
        #endregion

        #region DOCUMENT TOOLS
        "5" {
            do {
                showDocumentTools
                $menuSub = Read-Host "PLEASE MAKE A SELECTION"
                switch ($menuSub) {
                    "1" {
                        spoUploadDocumentItems -reportPath $setupReportPath -reportName "UPLOADDOCUMENTITEMS_$((Get-Date).ToString("yyyyMMdd_HHmmss")).csv"
                    }
                }
            } until ($menuSub -eq "e")
        }
        #endregion

        #region SETTINGS
        "s" {
            do {
                showSettings
                $menuSub = Read-Host "PLEASE MAKE A SELECTION"
                switch ($menuSub) {
                    "1" {
                        start $setupPath
                    }
                    "2" {
                        start $setupDirtyWordsFilePath
                    }
                }
            } until ($menuSub -eq "e")
            showSetup -SetupPath $setupPath -ReportPath $setupReportPath -DirtyWordsPath $setupDirtyWordsPath -DirtyWordsFilePath $setupDirtyWordsFilePath
        }
        #endregion
    }
} until ($menuMain -eq "q")
#endregion
