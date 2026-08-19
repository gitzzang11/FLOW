<div align="center">
  <img src="assets/icon/app_icon.png" alt="Flow logo" width="96" />
  <h1>Flow</h1>
  <p>Smart AI prompt management for Windows.</p>

  <p>
    <a href="https://github.com/gitzzang11/FLOW/releases/latest">
      <img src="https://img.shields.io/github/v/release/gitzzang11/FLOW?display_name=tag&style=flat-square" alt="Latest release" />
    </a>
    <a href="https://github.com/gitzzang11/FLOW/releases">
      <img src="https://img.shields.io/badge/platform-Windows%20x64-0078D4?style=flat-square&logo=windows&logoColor=white" alt="Windows x64" />
    </a>
    <img src="https://img.shields.io/badge/built%20with-Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Built with Flutter" />
  </p>
</div>

Flow is a local-first desktop workspace for writing, organizing, searching, and
reusing AI prompts. Keep prompts in folders, highlight important parts, attach
reference images, and copy a finished prompt to the clipboard in seconds.

> Flow is currently available for Windows only.

## Download

The current stable release is **v1.0.0**.

- [Download the Windows installer](https://github.com/gitzzang11/FLOW/releases/download/v1.0.0/FlowSetup-1.0.0.exe)
- [View release notes and checksums](https://github.com/gitzzang11/FLOW/releases/tag/v1.0.0)
- [Download the SHA-256 checksum](https://github.com/gitzzang11/FLOW/releases/download/v1.0.0/FlowSetup-1.0.0.exe.sha256)

The installer is per-user and does not require administrator privileges. It
installs Flow under `%LOCALAPPDATA%\Programs\Flow`, creates a Flow backup
folder under `%USERPROFILE%\Documents\Flow`, and registers the `.flow` file
type.

> The v1.0.0 installer is not digitally signed. Verify the SHA-256 checksum
> before running it if your environment requires artifact verification.

## Features

- **Prompt workspace** — Create, edit, duplicate, delete, pin, and copy prompts.
- **Folders and tags** — Organize prompts into folders and filter them with tags.
- **Fast search** — Search prompt titles, content, and tags from one search bar.
- **Prompt highlighting** — Color individual sections of a prompt to make
  variables and important instructions easy to scan.
- **Image attachments** — Attach reference images to prompts and include them
  in `.flow` backups.
- **Flexible browsing** — Use a responsive card grid, quick folder navigation,
  pinned prompts, and newest/oldest/title sorting.
- **Desktop shortcuts** — Configure keyboard shortcuts for common actions,
  including creating, searching, copying, duplicating, and locking.
- **Local app lock** — Optionally protect the workspace with a 4-digit PIN and
  a temporary lockout after repeated failed attempts.
- **Light and dark themes** — Adjust the appearance and interaction feedback in
  Settings.

## Installation

1. Download `FlowSetup-1.0.0.exe` from the [latest release](https://github.com/gitzzang11/FLOW/releases/latest).
2. Run the installer and optionally create a desktop shortcut.
3. Launch **Flow** from the Start menu or desktop.

No account, API key, or external service is required to use the desktop app.
Prompt data is stored locally on the Windows device.

## Backup and restore

Use **Settings → Backup** to export your workspace as a `.flow` file. A backup
contains prompts, folders, settings, and embedded prompt images. Flow can also
import existing `.json` backups.

Restoring a backup replaces the current Flow data after confirmation. Keep a
copy of important backup files in a separate location.

## Default keyboard shortcuts

Shortcuts can be changed from **Settings → Shortcut settings**.

| Action | Shortcut |
| --- | --- |
| New prompt | `Ctrl` + `N` |
| Search | `Ctrl` + `F` |
| Settings | `Ctrl` + `,` |
| Lock now | `Ctrl` + `L` |
| Close search/editor | `Esc` |
| Edit selected prompt | `Enter` |
| Copy selected prompt | `Space` |
| Delete selected prompt | `Delete` |
| Duplicate selected prompt | `Ctrl` + `D` |
| Pin selected prompt | `P` |

## Run from source

### Requirements

- Windows x64 environment
- [Flutter](https://docs.flutter.dev/get-started/install/windows) with Windows
  desktop support enabled
- Visual Studio with the **Desktop development with C++** workload

Enable Windows desktop support if needed:

```powershell
flutter config --enable-windows-desktop
```

Install dependencies and run Flow:

```powershell
flutter pub get
flutter run -d windows
```

Run the test suite:

```powershell
flutter test
```

Build a release executable:

```powershell
flutter build windows --release
```

The release output is created under `build\windows\x64\runner\Release`.

## Build the Windows installer

Install [Inno Setup 6](https://jrsoftware.org/isinfo.php), then run:

```powershell
.\scripts\build_windows_installer.ps1
```

The script reads the version from `pubspec.yaml`, builds the Windows release,
and creates `FlowSetup-<version>.exe` under `build\installer`.

## Project structure

```text
lib/
├── main.dart                 # App bootstrap and startup flow
├── models.dart               # Prompt, folder, settings, and shortcut models
├── screens.dart              # Main workspace, editor, settings, and lock screen
├── store.dart                # Local persistence and backup serialization
└── widgets.dart              # Reusable prompt, folder, editor, and settings UI
scripts/
└── build_windows_installer.ps1
test/
└── widget_test.dart
windows/installer/
└── flow.iss
```

## Status

Flow is actively evolving. The current public release is [v1.0.0](https://github.com/gitzzang11/FLOW/releases/tag/v1.0.0).
