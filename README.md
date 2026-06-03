# Flow

Smart AI prompt management tool built with Flutter.

This project is maintained as a Windows-only desktop app.

## Run on Windows

Install Visual Studio with the `Desktop development with C++` workload. Flutter
uses this toolchain to build Windows desktop apps.

Enable Windows desktop support in Flutter if it is not already enabled:

```powershell
flutter config --enable-windows-desktop
```

Install dependencies and run the app:

```powershell
flutter pub get
flutter run -d windows
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

The installer is created under `build\installer`.

The installer:

- installs Flow per user under `%LOCALAPPDATA%\Programs\Flow`
- creates `%USERPROFILE%\Documents\Flow` for Flow backup files
- registers `.flow` as the Flow backup file type

Flow now exports backups as `.flow` files. Existing `.json` backups can still be
imported.
