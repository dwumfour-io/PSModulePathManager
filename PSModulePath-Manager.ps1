## PSModulePath Manager - GUI Tool
<#
.SYNOPSIS
    Manage PSModulePath environment variable with GUI
.DESCRIPTION
    Add, remove, and view PSModulePath entries (User-level and System-level)
.NOTES
    Author: Joe Dwumfour
    Version: 1.0.0
    GitHub: https://github.com/dwumfour-io/PowerShell
    License: MIT
#>

[CmdletBinding()]
param()

$script:Version = "1.0.2"
$script:GitHubRepo = "https://github.com/dwumfour-io/PSModulePathManager"
$script:BackupFolder = "$env:LOCALAPPDATA\PSModulePathManager\Backups"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Create backup folder if it doesn't exist
if (-not (Test-Path $script:BackupFolder)) {
    New-Item -ItemType Directory -Path $script:BackupFolder -Force | Out-Null
}

# Auto-backup function
function Backup-PSModulePath {
    try {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $backupFile = Join-Path $script:BackupFolder "PSModulePath_$timestamp.txt"
        
        $userPath = [Environment]::GetEnvironmentVariable("PSModulePath", "User")
        $machinePath = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
        
        $content = @"
# PSModulePath Backup
# Created: $(Get-Date)

[USER]
$($userPath -replace ';', "`n")

[SYSTEM]
$($machinePath -replace ';', "`n")
"@
        $content | Out-File -FilePath $backupFile -Encoding UTF8
        
        # Keep only last 10 backups
        Get-ChildItem $script:BackupFolder -Filter "PSModulePath_*.txt" | 
            Sort-Object LastWriteTime -Descending | 
            Select-Object -Skip 10 | 
            Remove-Item -Force
        
        return $backupFile
    } catch {
        return $null
    }
}

# Check admin and STA
$isAdmin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$needsSta = [System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA'

if (-not $isAdmin -or $needsSta) {
    $psExe = (Get-Process -Id $PID).Path
    $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden')
    if ($needsSta) { $args += '-STA' }
    $args += '-File', "`"$PSCommandPath`""
    
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $psExe
    $startInfo.Arguments = $args -join ' '
    $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $startInfo.CreateNoWindow = $true
    
    if (-not $isAdmin) {
        $startInfo.Verb = 'RunAs'
        $startInfo.UseShellExecute = $true
    } else {
        $startInfo.UseShellExecute = $false
    }
    
    [System.Diagnostics.Process]::Start($startInfo) | Out-Null
    exit
}

try {
# Build UI
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PSModulePath Manager v$($script:Version)" Width="850" Height="750"
        WindowStartupLocation="CenterScreen" Background="#F0F0F0">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <Grid Grid.Row="0" Margin="0,0,0,15">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Text="PSModulePath Manager" FontSize="22" FontWeight="Bold"/>
            <Button Grid.Column="1" x:Name="HelpBtn" Content="Help" Width="80" Height="28" 
                    ToolTip="Keyboard shortcuts and help (F1)"/>
        </Grid>
        
        <!-- Stats and Actions Row -->
        <Grid Grid.Row="1" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" x:Name="StatsText" FontSize="12" Foreground="#666" VerticalAlignment="Center"/>
            <Button Grid.Column="1" x:Name="RefreshBtn" Content="Refresh" Width="80" Height="28" Margin="0,0,8,0"/>
            <Button Grid.Column="2" x:Name="ExportBtn" Content="Export..." Width="80" Height="28" Margin="0,0,8,0"/>
            <Button Grid.Column="3" x:Name="ImportBtn" Content="Import..." Width="80" Height="28"/>
        </Grid>
        
        <Border Grid.Row="2" BorderBrush="#999" BorderThickness="1" Background="White" Margin="0,0,0,12">
            <ListBox x:Name="PathList" FontFamily="Consolas" FontSize="11" BorderThickness="0"/>
        </Border>
        
        <TextBlock Grid.Row="4" Text="Add/Remove Paths" FontSize="14" FontWeight="SemiBold" Margin="0,5,0,8"/>
        
        <Grid Grid.Row="5" Margin="0,0,0,12">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBox x:Name="PathInput" Grid.Column="0" Height="32" Padding="6" 
                     VerticalContentAlignment="Center" Margin="0,0,8,0"/>
            <Button x:Name="BrowseBtn" Grid.Column="1" Content="Browse..." Width="80" Height="32" Margin="0,0,8,0"/>
            <ComboBox x:Name="ScopeCombo" Grid.Column="2" Width="90" Height="32" Margin="0,0,8,0" SelectedIndex="0" HorizontalContentAlignment="Center" VerticalContentAlignment="Center">
                <ComboBoxItem Content="USER" HorizontalContentAlignment="Center"/>
                <ComboBoxItem Content="SYSTEM" HorizontalContentAlignment="Center"/>
            </ComboBox>
            <Button x:Name="AddBtn" Grid.Column="3" Content="+ Add" Width="90" Height="32" 
                    Background="#107C10" Foreground="White" Margin="0,0,8,0" BorderThickness="0"/>
            <Button x:Name="RemoveBtn" Grid.Column="4" Content="- Remove" Width="90" Height="32" 
                    Background="#D13438" Foreground="White" BorderThickness="0"/>
        </Grid>
        
        <Grid Grid.Row="6">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock x:Name="StatusMsg" Grid.Column="0" FontSize="12" VerticalAlignment="Center"/>
            <Button x:Name="CloseBtn" Grid.Column="1" Content="Close" Width="90" Height="32"/>
        </Grid>
    </Grid>
</Window>
"@

$win = [Windows.Markup.XamlReader]::Parse($xaml)
$list = $win.FindName('PathList')
$pathInput = $win.FindName('PathInput')
$status = $win.FindName('StatusMsg')
$statsText = $win.FindName('StatsText')
$scopeCombo = $win.FindName('ScopeCombo')
$addBtn = $win.FindName('AddBtn')
$removeBtn = $win.FindName('RemoveBtn')
$browseBtn = $win.FindName('BrowseBtn')
$refreshBtn = $win.FindName('RefreshBtn')
$exportBtn = $win.FindName('ExportBtn')
$importBtn = $win.FindName('ImportBtn')
$closeBtn = $win.FindName('CloseBtn')
$helpBtn = $win.FindName('HelpBtn')

# Keyboard shortcuts
$win.Add_KeyDown({
    param($sender, $e)
    
    # F1 - Help
    if ($e.Key -eq 'F1') {
        $helpBtn.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
        $e.Handled = $true
    }
    # F5 - Refresh
    elseif ($e.Key -eq 'F5') {
        $refreshBtn.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
        $e.Handled = $true
    }
    # Delete - Remove selected
    elseif ($e.Key -eq 'Delete' -and $list.SelectedItem) {
        $selected = $list.SelectedItem.Content.ToString()
        if ($selected -match '^\[(USER|SYSTEM)\]\s*(.+)$') {
            $pathInput.Text = $matches[2]
            $removeBtn.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
        }
        $e.Handled = $true
    }
    # Ctrl+C - Copy selected path
    elseif ($e.Key -eq 'C' -and $e.KeyboardDevice.Modifiers -eq 'Control' -and $list.SelectedItem) {
        $selected = $list.SelectedItem.Content.ToString()
        if ($selected -match '^\[(USER|SYSTEM)\]\s*(.+)$') {
            [System.Windows.Clipboard]::SetText($matches[2])
            $status.Text = "Path copied to clipboard"
            $status.Foreground = "Green"
        }
        $e.Handled = $true
    }
    # Escape - Close
    elseif ($e.Key -eq 'Escape') {
        $win.Close()
        $e.Handled = $true
    }
})

function RefreshList {
    $userPath = [Environment]::GetEnvironmentVariable("PSModulePath", "User")
    $machinePath = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
    $currentSession = $env:PSModulePath
    
    $userPaths = if($userPath) { $userPath.Split(';') | Where-Object {$_} } else { @() }
    $machinePaths = if($machinePath) { $machinePath.Split(';') | Where-Object {$_} } else { @() }
    $sessionPaths = if($currentSession) { $currentSession.Split(';') | Where-Object {$_} } else { @() }
    
    # Find session-only paths (paths in current session but not in User or Machine)
    $persistentPaths = $userPaths + $machinePaths
    $sessionOnlyPaths = $sessionPaths | Where-Object { $_ -notin $persistentPaths }
    
    $list.Items.Clear()
    
    # Add user paths
    foreach ($p in $userPaths) {
        $item = New-Object System.Windows.Controls.ListBoxItem
        $item.Content = "[USER] $p"
        $item.Background = [System.Windows.Media.Brushes]::LightGreen
        $list.Items.Add($item) | Out-Null
    }
    
    # Add machine paths
    foreach ($p in $machinePaths) {
        $item = New-Object System.Windows.Controls.ListBoxItem
        $item.Content = "[SYSTEM] $p"
        $item.Background = [System.Windows.Media.Brushes]::LightGoldenrodYellow
        $list.Items.Add($item) | Out-Null
    }
    
    # Add session-only paths (temporary, not persistent)
    foreach ($p in $sessionOnlyPaths) {
        $item = New-Object System.Windows.Controls.ListBoxItem
        $item.Content = "[SESSION] $p"
        $item.Background = [System.Windows.Media.Brushes]::LightSkyBlue
        $item.Foreground = [System.Windows.Media.Brushes]::DarkBlue
        $list.Items.Add($item) | Out-Null
    }
    
    # Update stats
    $statsText.Text = "Total: $($list.Items.Count) paths ($($userPaths.Count) USER, $($machinePaths.Count) SYSTEM, $($sessionOnlyPaths.Count) SESSION)"
    
    if (-not $userPaths -and -not $machinePaths) {
        $status.Text = "No paths configured"
        $status.Foreground = "Orange"
    }
}

# Help dialog function
function Show-HelpDialog {
    $helpXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Help - PSModulePath Manager" Width="600" Height="550"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
    <ScrollViewer VerticalScrollBarVisibility="Auto">
        <StackPanel Margin="20">
            <TextBlock FontSize="18" FontWeight="Bold" Margin="0,0,0,10">PSModulePath Manager</TextBlock>
            <TextBlock FontSize="12" Foreground="#666" Margin="0,0,0,20">Version $($script:Version)</TextBlock>
            
            <TextBlock FontSize="14" FontWeight="SemiBold" Margin="0,10,0,5">About</TextBlock>
            <TextBlock TextWrapping="Wrap" Margin="0,0,0,10">
                Easily manage PowerShell module paths with a graphical interface. 
                Add, remove, and organize paths where PowerShell searches for modules.
            </TextBlock>
            
            <TextBlock FontSize="14" FontWeight="SemiBold" Margin="0,10,0,5">Keyboard Shortcuts</TextBlock>
            <Grid Margin="0,0,0,10">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="120"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                
                <TextBlock Grid.Row="0" Grid.Column="0" FontFamily="Consolas" Margin="0,2">F1</TextBlock>
                <TextBlock Grid.Row="0" Grid.Column="1" Margin="0,2">Show this help dialog</TextBlock>
                
                <TextBlock Grid.Row="1" Grid.Column="0" FontFamily="Consolas" Margin="0,2">F5</TextBlock>
                <TextBlock Grid.Row="1" Grid.Column="1" Margin="0,2">Refresh path list</TextBlock>
                
                <TextBlock Grid.Row="2" Grid.Column="0" FontFamily="Consolas" Margin="0,2">Delete</TextBlock>
                <TextBlock Grid.Row="2" Grid.Column="1" Margin="0,2">Remove selected path</TextBlock>
                
                <TextBlock Grid.Row="3" Grid.Column="0" FontFamily="Consolas" Margin="0,2">Ctrl+C</TextBlock>
                <TextBlock Grid.Row="3" Grid.Column="1" Margin="0,2">Copy selected path to clipboard</TextBlock>
                
                <TextBlock Grid.Row="4" Grid.Column="0" FontFamily="Consolas" Margin="0,2">Escape</TextBlock>
                <TextBlock Grid.Row="4" Grid.Column="1" Margin="0,2">Close window</TextBlock>
            </Grid>
            
            <TextBlock FontSize="14" FontWeight="SemiBold" Margin="0,10,0,5">Usage Tips</TextBlock>
            <TextBlock TextWrapping="Wrap" Margin="0,0,0,5">
                • Green paths = USER scope (only for your account)
            </TextBlock>
            <TextBlock TextWrapping="Wrap" Margin="0,0,0,5">
                • Orange paths = SYSTEM scope (all users on this computer)
            </TextBlock>
            <TextBlock TextWrapping="Wrap" Margin="0,0,0,5">
                • Blue paths = SESSION scope (temporary, current session only)
            </TextBlock>
            <TextBlock TextWrapping="Wrap" Margin="0,0,0,5">
                • Double-click a path to copy or open in Explorer
            </TextBlock>
            <TextBlock TextWrapping="Wrap" Margin="0,0,0,5">
                • Backups are saved automatically before changes
            </TextBlock>
            <TextBlock TextWrapping="Wrap" Margin="0,0,0,10">
                • Export/Import to save or restore configurations
            </TextBlock>
            
            <TextBlock FontSize="14" FontWeight="SemiBold" Margin="0,10,0,5">GitHub</TextBlock>
            <TextBlock>
                <Hyperlink x:Name="GitHubLink" NavigateUri="$($script:GitHubRepo)">
                    $($script:GitHubRepo)
                </Hyperlink>
            </TextBlock>
            
            <TextBlock FontSize="14" FontWeight="SemiBold" Margin="0,10,0,5">Backup Location</TextBlock>
            <TextBlock FontFamily="Consolas" FontSize="10" TextWrapping="Wrap">
                %LOCALAPPDATA%\PSModulePathManager\Backups
            </TextBlock>
            
            <Button x:Name="CloseHelpBtn" Content="Close" Width="100" Height="32" Margin="0,20,0,0" HorizontalAlignment="Right"/>
        </StackPanel>
    </ScrollViewer>
</Window>
"@
    
    $helpWin = [Windows.Markup.XamlReader]::Parse($helpXaml)
    $helpWin.FindName('CloseHelpBtn').Add_Click({ $helpWin.Close() })
    
    $githubLink = $helpWin.FindName('GitHubLink')
    if ($githubLink) {
        $githubLink.Add_RequestNavigate({
            param($sender, $e)
            Start-Process $e.Uri.AbsoluteUri
            $e.Handled = $true
        })
    }
    
    $helpWin.ShowDialog() | Out-Null
}

# Browse button - folder picker
$browseBtn.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select a folder to add to PSModulePath"
    $dialog.ShowNewFolderButton = $true
    
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $pathInput.Text = $dialog.SelectedPath
        $status.Text = "Folder selected. Click '+ Add' to add it."
        $status.Foreground = "Blue"
    }
})

# Add button with validation, scope selection, and auto-backup
# Add button with validation, scope selection, and auto-backup
$addBtn.Add_Click({
    $newPath = $pathInput.Text.Trim()
    if (-not $newPath) {
        $status.Text = "WARNING: Enter a path first"
        $status.Foreground = "Red"
        return
    }
    
    # Create backup before modification
    $backupFile = Backup-PSModulePath
    if ($backupFile) {
        Write-Verbose "Backup created: $backupFile"
    }
    
    # Path validation
    if (-not (Test-Path $newPath)) {
        $result = [System.Windows.MessageBox]::Show(
            "The path does not exist. Add it anyway?",
            "Path Not Found",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )
        if ($result -eq [System.Windows.MessageBoxResult]::No) { return }
    }
    
    $scope = $scopeCombo.SelectedItem.Content
    $current = [Environment]::GetEnvironmentVariable("PSModulePath", $scope)
    $paths = if($current){$current.Split(';')}else{@()}
    
    # Check for duplicates in same scope
    if ($paths -contains $newPath) {
        $status.Text = "WARNING: Path already exists in $scope scope"
        $status.Foreground = "Orange"
        return
    }
    
    # Check for duplicates in other scope
    $otherScope = if($scope -eq "User"){"Machine"}else{"User"}
    $otherPath = [Environment]::GetEnvironmentVariable("PSModulePath", $otherScope)
    if ($otherPath -and ($otherPath.Split(';') -contains $newPath)) {
        $result = [System.Windows.MessageBox]::Show(
            "This path already exists in $otherScope scope. Add to $scope scope anyway?",
            "Duplicate Path",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Question
        )
        if ($result -eq [System.Windows.MessageBoxResult]::No) { return }
    }
    
    $updated = (@($paths) + $newPath) -join ';'
    [Environment]::SetEnvironmentVariable("PSModulePath", $updated, $scope)
    $env:PSModulePath = $env:PSModulePath + ";$newPath"
    
    $status.Text = "SUCCESS: Path added to $scope scope (backup created)"
    $status.Foreground = "Green"
    $pathInput.Clear()
    RefreshList
})

# Remove button
$removeBtn.Add_Click({
    $pathToRemove = $pathInput.Text.Trim()
    if (-not $pathToRemove) {
        $status.Text = "WARNING: Enter a path first"
        $status.Foreground = "Red"
        return
    }
    
    # Create backup before modification
    $backupFile = Backup-PSModulePath
    if ($backupFile) {
        Write-Verbose "Backup created: $backupFile"
    }
    
    $removed = $false
    
    # Try USER scope first
    $userCurrent = [Environment]::GetEnvironmentVariable("PSModulePath", "User")
    if ($userCurrent -and ($userCurrent.Split(';') -contains $pathToRemove)) {
        $userPaths = $userCurrent.Split(';') | Where-Object {$_ -and $_ -ne $pathToRemove}
        $userUpdated = $userPaths -join ';'
        [Environment]::SetEnvironmentVariable("PSModulePath", $userUpdated, "User")
        $removed = $true
        $scope = "USER"
    }
    
    # Try MACHINE scope if not found in USER
    if (-not $removed) {
        $machineCurrent = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
        if ($machineCurrent -and ($machineCurrent.Split(';') -contains $pathToRemove)) {
            $machinePaths = $machineCurrent.Split(';') | Where-Object {$_ -and $_ -ne $pathToRemove}
            $machineUpdated = $machinePaths -join ';'
            [Environment]::SetEnvironmentVariable("PSModulePath", $machineUpdated, "Machine")
            $removed = $true
            $scope = "SYSTEM"
        }
    }
    
    if ($removed) {
        $env:PSModulePath = ($env:PSModulePath.Split(';') | Where-Object {$_ -ne $pathToRemove}) -join ';'
        $status.Text = "SUCCESS: Path removed from $scope scope"
        $status.Foreground = "Green"
        $pathInput.Clear()
        RefreshList
    } else {
        $status.Text = "WARNING: Path not found in USER or SYSTEM scope"
        $status.Foreground = "Red"
    }
})

# Refresh button
$refreshBtn.Add_Click({
    RefreshList
    $status.Text = "List refreshed"
    $status.Foreground = "Blue"
})

# Export button
$exportBtn.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
    $saveDialog.Title = "Export PSModulePath Configuration"
    $saveDialog.FileName = "PSModulePath_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $userPath = [Environment]::GetEnvironmentVariable("PSModulePath", "User")
            $machinePath = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
            
            $content = @"
# PSModulePath Configuration Export
# Generated: $(Get-Date)

[USER]
$($userPath -replace ';', "`n")

[SYSTEM]
$($machinePath -replace ';', "`n")
"@
            $content | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
            $status.Text = "SUCCESS: Configuration exported"
            $status.Foreground = "Green"
        } catch {
            $status.Text = "ERROR: Failed to export - $($_.Exception.Message)"
            $status.Foreground = "Red"
        }
    }
})

# Import button
$importBtn.Add_Click({
    $openDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
    $openDialog.Title = "Import PSModulePath Configuration"
    
    if ($openDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $content = Get-Content $openDialog.FileName -Raw
            
            $result = [System.Windows.MessageBox]::Show(
                "This will replace your current PSModulePath configuration. Continue?",
                "Confirm Import",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            
            if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                # Parse USER and SYSTEM sections
                if ($content -match '\[USER\](.*?)\[SYSTEM\](.*)') {
                    $userPaths = $matches[1].Trim() -replace "`n", ';'
                    $systemPaths = $matches[2].Trim() -replace "`n", ';'
                    
                    [Environment]::SetEnvironmentVariable("PSModulePath", $userPaths, "User")
                    [Environment]::SetEnvironmentVariable("PSModulePath", $systemPaths, "Machine")
                    
                    $env:PSModulePath = $userPaths + ';' + $systemPaths
                    
                    RefreshList
                    $status.Text = "SUCCESS: Configuration imported"
                    $status.Foreground = "Green"
                } else {
                    $status.Text = "ERROR: Invalid file format"
                    $status.Foreground = "Red"
                }
            }
        } catch {
            $status.Text = "ERROR: Failed to import - $($_.Exception.Message)"
            $status.Foreground = "Red"
        }
    }
})

$closeBtn.Add_Click({ $win.Close() })

# Help/About button must be defined after HelpBtn is found
$helpBtn.Add_Click({
    Show-HelpDialog
})

# ListBox mouse handler to deselect when clicking empty space
$list.Add_MouseDown({
    param($sender, $e)
    $pos = $e.GetPosition($list)
    $hit = [System.Windows.Media.VisualTreeHelper]::HitTest($list, $pos)
    
    if ($hit -and $hit.VisualHit) {
        # Check if click was on ListBoxItem or empty space
        $item = $hit.VisualHit
        while ($item -and $item -isnot [System.Windows.Controls.ListBoxItem]) {
            $item = [System.Windows.Media.VisualTreeHelper]::GetParent($item)
        }
        
        # If we didn't hit a ListBoxItem, clear selection
        if (-not $item) {
            $list.SelectedItem = $null
        }
    }
})

# ListBox selection handler
$list.Add_SelectionChanged({
    if ($list.SelectedItem) {
        $selected = $list.SelectedItem.Content.ToString()
        if ($selected -match '^\[(USER|SYSTEM)\]\s*(.+)$') {
            $pathInput.Text = $matches[2]
            $status.Text = "Click '- Remove' to delete this [$($matches[1])] path"
            $status.Foreground = "Blue"
        }
    } else {
        # Clear text field when clicking empty space
        $pathInput.Clear()
        $status.Text = ""
    }
})

# Double-click handler - copy or open folder
$list.Add_MouseDoubleClick({
    if ($list.SelectedItem) {
        $selected = $list.SelectedItem.Content.ToString()
        if ($selected -match '^\[(USER|SYSTEM)\]\s*(.+)$') {
            $path = $matches[2]
            
            $result = [System.Windows.MessageBox]::Show(
                "Copy path to clipboard or open in Explorer?`n`n$path",
                "Double-Click Action",
                [System.Windows.MessageBoxButton]::YesNoCancel,
                [System.Windows.MessageBoxImage]::Question
            )
            
            if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                [System.Windows.Clipboard]::SetText($path)
                $status.Text = "Path copied to clipboard"
                $status.Foreground = "Green"
            } elseif ($result -eq [System.Windows.MessageBoxResult]::No) {
                if (Test-Path $path) {
                    explorer.exe $path
                    $status.Text = "Opened folder in Explorer"
                    $status.Foreground = "Green"
                } else {
                    $status.Text = "ERROR: Path does not exist"
                    $status.Foreground = "Red"
                }
            }
        }
    }
})

RefreshList
$win.ShowDialog() | Out-Null

} catch {
    [System.Windows.MessageBox]::Show(
        "ERROR: $($_.Exception.Message)`n`nStack Trace: $($_.ScriptStackTrace)",
        "Error",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    )
}
