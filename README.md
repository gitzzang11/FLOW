# Flow

Smart AI prompt management tool built with Flutter.

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
