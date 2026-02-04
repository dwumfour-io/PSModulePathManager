# Changelog

All notable changes to PSModulePath Manager will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2026-02-04

### Added
- SESSION scope display showing temporary paths (blue color-coded entries)
- Now displays all paths visible to PowerShell, including session-only paths
- Enhanced statistics to show breakdown of USER, SYSTEM, and SESSION paths

### Changed
- RefreshList function now reads $env:PSModulePath to capture current session state
- Help dialog updated with SESSION scope explanation

## [1.0.1] - 2026-02-04

### Fixed
- Corrected GitHub repository URLs throughout project (README badges, manifest links, script metadata)
- Added .gitignore to exclude binary files from version control

## [1.0.0] - 2026-02-03

### Added
- Initial release
- GUI interface for managing PSModulePath
- Add/Remove paths from USER and SYSTEM scopes
- Browse for folders with graphical folder picker
- Export/Import configurations to backup/restore paths
- Auto-backup functionality (creates backup before changes)
- Path validation (warns if path doesn't exist)
- Duplicate detection across scopes
- Keyboard shortcuts:
  - F1: Help dialog
  - F5: Refresh list
  - Delete: Remove selected path
  - Ctrl+C: Copy selected path
  - Escape: Close window
- Double-click to copy path or open in Explorer
- Color-coded paths (Green=USER, Orange=SYSTEM)
- Statistics display showing path counts
- Help/About dialog with:
  - Version information
  - GitHub link
  - Usage instructions
  - Keyboard shortcuts reference
  - Backup location
- Self-elevating UAC prompt for admin privileges
- Keeps last 10 backups automatically

### Security
- Requires administrator privileges for SYSTEM scope modifications
- USER scope can be modified without elevation

[1.0.0]: https://github.com/dwumfour-io/PowerShell/releases/tag/v1.0.0
