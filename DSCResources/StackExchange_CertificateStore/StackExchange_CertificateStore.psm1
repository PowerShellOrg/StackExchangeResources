

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,
        [parameter()]
        [ValidateSet('LocalMachine','CurrentUser')]
        [string]
        $Location = 'LocalMachine',
        [parameter()]        
        [string]
        $Store = 'My',
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    
    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Ensure = 'Present'

    if (Test-TargetResource @PSBoundParameters)
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }

    $Configuration = @{
        Name = $Name
        Path = $Path
        Location = $Location
        Store = $Store
        Ensure = $Ensure
    }

    return $Configuration
}

function Set-TargetResource
{
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,
        [parameter()]
        [ValidateSet('LocalMachine','CurrentUser')]
        [string]
        $Location = 'LocalMachine',
        [parameter()]        
        [string]
        $Store = 'My',
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present',
        [parameter()]
        [string]
		$Password
    )

    $CertificateBaseLocation = "cert:\$Location\$Store"
    
    if ($Ensure -like 'Present')
    {   
		write-verbose "Is Password Null:  $($password -eq $null)"
		
		if ($password -ne $null){
			write-verbose "Import PFX Cert using password"
			if ((Get-WmiObject Win32_OperatingSystem  | select -ExpandProperty Version) -eq "6.3.9600"){
				write-verbose "Windows 2012 detected"
				$SPassword = ($Password | ConvertTo-SecureString -AsPlainText -Force)
				Import-PfxCertificate -CertStoreLocation $CertificateBaseLocation -FilePath $Path -Password $SPassword
			}else{
				write-verbose "Windows 2008 detected"
				certutil -f -importpfx -p $Password $Path
			}
		}else
		{
			write-verbose "Import PFX Cert without using password"
			if ((Get-WmiObject Win32_OperatingSystem  | select -ExpandProperty Version) -eq "6.3.9600"){
				write-verbose "Windows 2012 detected"
				Import-PfxCertificate -CertStoreLocation $CertificateBaseLocation -FilePath $Path
			}else{
				write-verbose "Windows 2008 detected"
				certutil -f -importpfx $Path
			}
		}
    }
    else
    {
        $CertificateLocation = Join-path $CertificateBaseLocation $Name
        Write-Verbose "Removing $name from $CertificateBaseLocation."
        gci $CertificateBaseLocation | ?{$_.Subject -match $name.Replace('*','')} | Remove-Item -Force -Confirm:$false
    }
}

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,
        [parameter()]
        [ValidateSet('LocalMachine','CurrentUser')]
        [string]
        $Location = 'LocalMachine',
        [parameter()]        
        [string]
        $Store = 'My',
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present',
        [parameter()]
        [string]
        $Password
    )

    $IsValid = $false
    
    $CertificateBaseLocation = "cert:\$Location\$Store\"

    if ($Ensure -like 'Present')
    {
        Write-Verbose "Checking for $Name to be present in the $CertificateBaseLocation store under $store."
        if (gci $CertificateBaseLocation | ?{$_.Subject -match $name.Replace('*','')})
        {
            Write-Verbose "Found a matching certficate at $CertificateBaseLocation"
            $IsValid = $true
        }
        else
        {
            Write-Verbose "Unable to find a matching certficate at $CertificateBaseLocation"
        }
    }
    else
    {
        Write-Verbose "Checking for $Name to be absent in the $CertificateBaseLocation store under $store."
        if (gci $CertificateBaseLocation | ?{$_.Subject -match $name.Replace('*','')})
        {
            Write-Verbose "Found a matching certficate at $CertificateBaseLocation"            
        }
        else
        {
            Write-Verbose "Unable to find a matching certficate at $CertificateBaseLocation"
            $IsValid = $true
        }
    }

    #Needs to return a boolean  
    return $IsValid
}



