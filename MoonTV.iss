[Setup]
AppName=MoonTV
AppVersion=1.0.0
AppPublisher=MoonTV Team
AppPublisherURL=https://moontv.cc.cd
AppSupportURL=https://moontv.cc.cd
AppUpdatesURL=https://moontv.cc.cd
DefaultDirName={autopf}\MoonTV
DefaultGroupName=MoonTV
OutputDir=.\installer
OutputBaseFilename=MoonTV-Setup
Compression=lzma2/ultra64
SolidCompression=yes
PrivilegesRequired=lowest
SetupIconFile=d:\MoonTV\logo.ico

[Languages]
Name: "chinese"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 0,6.1

[Files]
Source: "D:\MoonTV\build\windows\x64\runner\Release\MoonTV.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\MoonTV\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "D:\MoonTV\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\MoonTV"; Filename: "{app}\MoonTV.exe"
Name: "{commondesktop}\MoonTV"; Filename: "{app}\MoonTV.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\MoonTV"; Filename: "{app}\MoonTV.exe"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\MoonTV.exe"; Description: "{cm:LaunchProgram,MoonTV}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{app}\MoonTV.exe"; Parameters: "--uninstall"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"