function Find-WindowsUpdate
{
    <#
    .Synopsis
        Finds updates for windows and other products
    .Description
        Finds updates for windows and other products that use the Microsoft Update system.
    .Example
        Find-WindowsUpdate
    .Link
        Get-InstalledUpdate
    #>
    param(
    # Update types
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateSet("Driver","Update", "Security", "Critical")]
    [string[]]
    $UpdateType,
    
    # If set, only finds recommended updates
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]
    $Recommended,
    
    # If set, only finds optional updates
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]
    $Optional,
    
    # If set, applies all updates released before the date
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [DateTime]
    $ReleasedBefore,
    
    # If set, applies all updates released after the date
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [DateTime]
    $ReleasedAfter,
    
    # If set, will find updates that have been installed, not updates that are available    
    [Switch]
    $FindInstalled,
    
    # If set, will find updates that have been hidden (like rollups)
    [switch]
    $FindHidden        
    )
    
    process {
    
        $objServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"
        $objSession = New-Object -ComObject "Microsoft.Update.Session"
    	$objSearcher = $objSession.CreateUpdateSearcher()
    	
        #check source of updates   
    	if($MicrosoftUpdate) {
            $objSearcher.ServerSelection = 2
    		$serviceName = "Microsoft Update"
        } else {
            foreach ($objService in $objServiceManager.Services) {
                if($ServiceID) {
                    if($objService.ServiceID -eq $ServiceID) {
                        $objSearcher.ServiceID = $ServiceID
                        $objSearcher.ServerSelection = 3
                        $serviceName = $objService.Name
                    }
                } else {
                    if($objService.IsDefaultAUService -eq $True) {
                        $serviceName = $objService.Name
                    }
                }
            }
        }
        
        $objCollection = New-Object -ComObject "Microsoft.Update.UpdateColl"
        try {
            $criteria = "IsInstalled=$(($FindInstalled) -as [bool] -as [int]) and IsHidden=$($FindHidden -as [bool] -as [int])"
            $objResults = $objSearcher.Search($criteria )        
        } catch {
            if ($_ -match "HRESULT: 0x80072EE2") {
                Write-Error "Cannot connect to Windows Update"
            }
            return
        }
    
        foreach($Update in $objResults.Updates) {
            if ($UpdateType -and 
                $UpdateType -notcontains $Update.Categories.Item(0).Name) {
                continue
            }
            
            if ($Recommended) {
                if (-not $update.AutoSelectOnWebSites) { 
                    continue
                }
            }
            
            if ($optionial) {
                if ($update.AutoSelectOnWebSites) { 
                    continue
                }
            }
            
            if ($psBoundParameters.ContainsKey('ReleasedBefore')) {
                if ($update.LastDeploymentChangeTime -gt $ReleasedBefore) {
                    continue
                }                        
            }
            
            if ($psBoundParameters.ContainsKey('ReleasedAfter')) {
                if ($update.LastDeploymentChangeTime -lt $ReleasedAfter) {
                    continue
                }                        
            }
            
            $update
        }        
    
    }
} 
