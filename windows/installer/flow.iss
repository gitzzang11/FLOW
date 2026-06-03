#ifndef MyAppVersion
#define MyAppVersion "1.4.1"
#endif

#ifndef BuildOutput
#define BuildOutput "..\..\build\windows\x64\runner\Release"
#endif

#ifndef InstallerOutput
#define InstallerOutput "..\..\build\installer"
#endif

#define MyAppName "Flow"
#define MyAppPublisher "Flow"
#define MyAppExeName "flow.exe"
#define MyAppAssocExt ".flow"
#define MyAppAssocKey "Flow.Backup"

[Setup]
AppId={{9835D5D3-8B2D-45FA-A159-3FBE737297FD}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir={#InstallerOutput}
OutputBaseFilename=FlowSetup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
ChangesAssociations=yes
CloseApplications=yes
SetupLogging=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "{#BuildOutput}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Dirs]
Name: "{userdocs}\Flow"

[Registry]
Root: HKCU; Subkey: "Software\Classes\{#MyAppAssocExt}"; ValueType: string; ValueName: ""; ValueData: "{#MyAppAssocKey}"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\{#MyAppAssocExt}"; ValueType: string; ValueName: "Content Type"; ValueData: "application/vnd.flow.backup+json"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\{#MyAppAssocExt}\OpenWithProgids"; ValueType: string; ValueName: "{#MyAppAssocKey}"; ValueData: ""; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\{#MyAppAssocKey}"; ValueType: string; ValueName: ""; ValueData: "Flow Backup File"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\{#MyAppAssocKey}\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"
Root: HKCU; Subkey: "Software\Classes\{#MyAppAssocKey}\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
