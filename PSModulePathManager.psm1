function Show-PSModulePathManager {
    <#
    .SYNOPSIS
        Launch the PSModulePath Manager GUI tool.
    
    .DESCRIPTION
        Opens a graphical interface to manage PowerShell module paths. 
        Allows adding, removing, and organizing paths in the PSModulePath environment variable.
    
    .EXAMPLE
        Show-PSModulePathManager
        
        Launches the PSModulePath Manager GUI.
    
    .EXAMPLE
        PSModPathMgr
        
        Uses the alias to launch the tool.
    
    .NOTES
        Requires administrator privileges to modify SYSTEM scope paths.
        USER scope paths can be modified without elevation.
    #>
    
    [CmdletBinding()]
    param()
    
    # Get the script path
    $scriptPath = Join-Path $PSScriptRoot "PSModulePath-Manager.ps1"
    
    if (Test-Path $scriptPath) {
        & $scriptPath
    } else {
        Write-Error "PSModulePath-Manager.ps1 not found at: $scriptPath"
    }
}

# Create alias
New-Alias -Name PSModPathMgr -Value Show-PSModulePathManager -Force

# Export functions and aliases
Export-ModuleMember -Function Show-PSModulePathManager -Alias PSModPathMgr
