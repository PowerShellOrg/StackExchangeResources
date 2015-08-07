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
        [pscredential]
        $Password
    )

    $CertificateBaseLocation = "cert:\$Location\$Store"
    
    if ($Ensure -like 'Present')
    {        
        Write-Verbose "Adding $path to $CertificateBaseLocation."

        $passwordSplat = @{}
        if ($Password)
        {
            $passwordSplat['Password'] = $Password.Password
        }

        Import-PfxCertificate -CertStoreLocation $CertificateBaseLocation -FilePath $Path @passwordSplat
    }
    else
    {
        $CertificateLocation = Join-path $CertificateBaseLocation $Name
        Write-Verbose "Removing $CertificateLocation."
        dir $CertificateLocation | Remove-Item -Force -Confirm:$false   
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
        [pscredential]
        $Password
    )

    $IsValid = $false

    $CertificateLocation = "cert:\$Location\$Store\$Name"

    if ($Ensure -like 'Present')
    {
        Write-Verbose "Checking for $Name to be present in the $location store under $store."
        if (Test-Path $CertificateLocation)
        {
            Write-Verbose "Found a matching certficate at $CertificateLocation"

            $cert = Get-Item $CertificateLocation

            if ($cert.HasPrivateKey)
            {
                Write-Verbose "Certficate at $CertificateLocation has a private key installed."
                $IsValid = $true
            }
            else
            {
                Write-Verbose "Certficate at $CertificateLocation does not have a private key installed."
            }
        }
        else
        {
            Write-Verbose "Unable to find a matching certficate at $CertificateLocation"
        }
    }
    else
    {
        Write-Verbose "Checking for $Name to be absent in the $location store under $store."
        if (Test-Path $CertificateLocation)
        {
            Write-Verbose "Found a matching certficate at $CertificateLocation"            
        }
        else
        {
            Write-Verbose "Unable to find a matching certficate at $CertificateLocation"
            $IsValid = $true
        }
    }

    #Needs to return a boolean  
    return $IsValid
}



