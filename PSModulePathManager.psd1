@{
    # Module manifest for module 'PSModulePathManager'
    RootModule = 'PSModulePathManager.psm1'
    ModuleVersion = '1.0.2'
    GUID = 'a1b2c3d4-e5f6-4789-a0b1-c2d3e4f56789'
    Author = 'Joe Dwumfour'
    CompanyName = 'dwumfour-io'
    Copyright = '(c) 2026 Joe Dwumfour. All rights reserved.'
    Description = 'A GUI tool to easily manage PowerShell module paths (PSModulePath environment variable). Add, remove, and organize paths with a user-friendly interface.'
    
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @('Show-PSModulePathManager')
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @('PSModPathMgr')
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('PSModulePath', 'Environment', 'GUI', 'Management', 'PowerShell', 'Modules', 'Path', 'Tool')
            
            # A URL to the license for this module
            LicenseUri = 'https://github.com/dwumfour-io/PSModulePathManager/blob/master/LICENSE'
            
            # A URL to the main website for this project
            ProjectUri = 'https://github.com/dwumfour-io/PSModulePathManager'
            
            # A URL to an icon representing this module
            IconUri = 'https://raw.githubusercontent.com/dwumfour-io/PSModulePathManager/master/icon.png'
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
## v1.0.2 - SESSION Paths Display

### New Features
- SESSION scope display (blue) for temporary paths
- Shows all paths visible to PowerShell (USER + SYSTEM + SESSION)
- Enhanced statistics with SESSION path count

## v1.0.1 - URL Corrections
- Fixed GitHub repository URLs
- Added .gitignore for binaries

## v1.0.0 - Initial Release
- GUI interface for managing PSModulePath
- Add/Remove paths from USER and SYSTEM scopes
- Browse for folders, Export/Import, Auto-backup
- Path validation and duplicate detection
- Keyboard shortcuts, Color-coded paths
- Help/About dialog
'@
            
            # Prerelease string of this module
            # Prerelease = 'beta'
            
            # Flag to indicate whether the module requires explicit user acceptance
            # RequireLicenseAcceptance = $false
            
            # External dependent modules of this module
            # ExternalModuleDependencies = @()
        }
    }
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
}
