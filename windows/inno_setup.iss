[Setup]
; Identificativo univoco per questa applicazione. 
; NON cambiare questo AppId nei futuri aggiornamenti dell'app!
AppId={{8B321528-FF58-47EE-8975-01C5E4B56C7D}
AppName=SQNPI Audit Manager
AppVersion=1.0.0
AppPublisher=Flavio Pipitone
AppPublisherURL=https://bios-srl.it
AppSupportURL=https://bios-srl.it
AppUpdatesURL=https://bios-srl.it
; Cartella di default dove verrà installata l'app
DefaultDirName={autopf}\SQNPI_Audit_Manager
; Nome del menu Start
DefaultGroupName=SQNPI Audit Manager
; Rimuove la schermata che chiede all'utente in che cartella installare l'app (per renderlo più facile)
DisableProgramGroupPage=yes
; Dove verrà salvato il file setup.exe una volta generato
OutputDir=..\build\windows\installer
; Il nome del file che manderai agli ispettori
OutputBaseFilename=Setup_SQNPI_Audit_Manager
; Icona per l'installer e per Windows
SetupIconFile=runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
; IMPORTANTE: Prende l'eseguibile principale
Source: "..\build\windows\x64\runner\Release\SQNPI_Audit_Manager.exe"; DestDir: "{app}"; Flags: ignoreversion
; Prende tutte le DLL e la cartella data
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTA: Non usare "Flags: ignoreversion" su file di sistema condivisi. In questo caso va bene perché sono locali.

[Icons]
; Crea il collegamento nel menu Start
Name: "{group}\SQNPI Audit Manager"; Filename: "{app}\SQNPI_Audit_Manager.exe"
; Crea il collegamento per la disinstallazione nel menu Start
Name: "{group}\{cm:UninstallProgram,SQNPI Audit Manager}"; Filename: "{uninstallexe}"
; Crea il collegamento sul Desktop
Name: "{autodesktop}\SQNPI Audit Manager"; Filename: "{app}\SQNPI_Audit_Manager.exe"; Tasks: desktopicon

[Run]
; Consente di avviare l'app subito dopo la fine dell'installazione
Filename: "{app}\SQNPI_Audit_Manager.exe"; Description: "{cm:LaunchProgram,SQNPI Audit Manager}"; Flags: nowait postinstall skipifsilent
