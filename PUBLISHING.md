# Publishing to PowerShell Gallery

## Prerequisites

1. **PowerShell Gallery Account**
   - Create account at https://www.powershellgallery.com/
   - Get your API key from https://www.powershellgallery.com/account/apikeys

2. **Install Required Module**
   ```powershell
   Install-Module -Name PowerShellGet -Force -AllowClobber
   ```

## Pre-Publishing Checklist

- [ ] Update version number in `PSModulePathManager.psd1`
- [ ] Update CHANGELOG.md with new version
- [ ] Test the module locally
- [ ] Update README.md if needed
- [ ] Take a screenshot and save as `screenshot.png`

## Test Locally First

```powershell
# Import the module
Import-Module ".\PSModulePathManager\PSModulePathManager.psd1" -Force

# Test the command
Show-PSModulePathManager

# Test manifest
Test-ModuleManifest ".\PSModulePathManager\PSModulePathManager.psd1"
```

## Publish to PowerShell Gallery

### Step 1: Set Your API Key

```powershell
# Store your API key (one-time setup)
$apiKey = "YOUR-API-KEY-HERE"
```

### Step 2: Publish the Module

```powershell
# Publish to PowerShell Gallery
Publish-Module -Path ".\PSModulePathManager" -NuGetApiKey $apiKey -Verbose

# Or if you want to test publishing first:
Publish-Module -Path ".\PSModulePathManager" -NuGetApiKey $apiKey -WhatIf
```

### Step 3: Verify Publication

1. Go to https://www.powershellgallery.com/packages/PSModulePathManager
2. Verify the module appears correctly
3. Test installation on a different machine:
   ```powershell
   Install-Module -Name PSModulePathManager -Scope CurrentUser
   Show-PSModulePathManager
   ```

## Update an Existing Version

1. **Update version number** in `PSModulePathManager.psd1`:
   ```powershell
   ModuleVersion = '1.1.0'
   ```

2. **Update CHANGELOG.md** with changes

3. **Update ReleaseNotes** in the manifest

4. **Publish the update**:
   ```powershell
   Publish-Module -Path ".\PSModulePathManager" -NuGetApiKey $apiKey -Force
   ```

## Module Structure

```
PSModulePathManager/
├── PSModulePathManager.psd1    # Module manifest
├── PSModulePathManager.psm1    # Module script
├── PSModulePath-Manager.ps1    # Main GUI script
├── README.md                   # Documentation
├── LICENSE                     # MIT License
├── CHANGELOG.md                # Version history
└── screenshot.png              # Screenshot for README
```

## Troubleshooting

### "Module already exists"
- You can only publish each version once
- Increment the version number to publish again

### "Missing required field"
- Ensure all required fields in .psd1 are filled
- Run `Test-ModuleManifest` to validate

### "Invalid API key"
- Verify your API key at https://www.powershellgallery.com/account/apikeys
- Ensure no extra spaces in the key

## Best Practices

1. **Semantic Versioning**
   - MAJOR.MINOR.PATCH (e.g., 1.0.0)
   - MAJOR: Breaking changes
   - MINOR: New features (backward compatible)
   - PATCH: Bug fixes

2. **Testing**
   - Always test locally before publishing
   - Use `Test-ModuleManifest` to validate
   - Test on fresh PowerShell session

3. **Documentation**
   - Keep README.md up to date
   - Update CHANGELOG.md for each release
   - Include clear usage examples

## Quick Publish Script

Save this as `Publish-PSModulePathManager.ps1`:

```powershell
param(
    [Parameter(Mandatory)]
    [string]$ApiKey,
    
    [switch]$WhatIf
)

$modulePath = ".\PSModulePathManager"

# Validate manifest
Write-Host "Validating manifest..." -ForegroundColor Cyan
Test-ModuleManifest "$modulePath\PSModulePathManager.psd1"

# Publish
Write-Host "Publishing to PowerShell Gallery..." -ForegroundColor Cyan
$params = @{
    Path = $modulePath
    NuGetApiKey = $ApiKey
    Verbose = $true
}

if ($WhatIf) {
    $params.WhatIf = $true
}

Publish-Module @params

Write-Host "Done!" -ForegroundColor Green
```

Usage:
```powershell
.\Publish-PSModulePathManager.ps1 -ApiKey "YOUR-KEY" -WhatIf
.\Publish-PSModulePathManager.ps1 -ApiKey "YOUR-KEY"
```
