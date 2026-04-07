unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IniFiles, Buttons, ExtCtrls, ComCtrls, OleCtrls, SHDocVw,
  WinInet, ActiveX, ShellAPI, Menus, ClipBrd, SHA1, ComObj, StrUtils,
  Registry, ShlObj;

type
  TDownloadParams = record
    Url: string;
    Path: string;
    Hash: string;
    SilentParams: string;
    NoArchiveNoInstaller: boolean;
    DownloadOnly: boolean;
    ArchiveDesktopShortcuts: string;
    ArchiveHasInstaller: boolean;
    ArchiveInstallerName: string;
end;

type
  TDownloadDoneEvent = procedure(Success: boolean; const FileName: string) of object;

  TDownloadError = (deNone, deNoInternet, deFileNotFound, deIncomplete, deInvalidHash);
  TActionType = (atDefault, atDownloadDB, atSilent);

  TDownloadThread = class(TThread)
  private
    FParams: TDownloadParams;
    FDownloadedFileName: string;
    FSuccess: boolean;
    FProgress: integer;
    FError: TDownloadError;
    FErrorDetail: string;
    procedure SyncProgress;
    procedure DownloadDone;
  protected
    procedure Execute; override;
  public
    constructor Create(const Params: TDownloadParams; ActionType: TActionType);
  end;

type
  TUpdatesThread = class(TThread)
  private
    FSilent: Boolean;
  protected
    procedure Execute; override;
  end;

type
  TUpdateSearchThread = class(TThread)
  protected
    procedure Execute; override;
  end;

type
  TMain = class(TForm)
    MainPanel: TPanel;
    DownloadsBtn: TSpeedButton;
    StatusBar: TStatusBar;
    RemoveBtn: TSpeedButton;
    WebView: TWebBrowser;
    MainMenu: TMainMenu;
    HelpBtn: TMenuItem;
    AboutBtn: TMenuItem;
    LocaleNameBtn: TMenuItem;
    DebugLine: TMenuItem;
    CopyFileHashBtn: TMenuItem;
    OpenDialog: TOpenDialog;
    GetHashesCfgBtn: TMenuItem;
    DebugBtn: TMenuItem;
    FileBtn: TMenuItem;
    CheckUpdatesBtn: TMenuItem;
    N3: TMenuItem;
    ExitBtn: TMenuItem;
    SettingsBtn: TMenuItem;
    N6: TMenuItem;
    SearchEdt: TEdit;
    DonateBtn: TSpeedButton;
    ProgramsBtn: TSpeedButton;
    CatalogBtn: TSpeedButton;
    ReportProblemBtn: TMenuItem;
    N1: TMenuItem;
    StatisticsBtn: TMenuItem;
    N2: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure DownloadsBtnClick(Sender: TObject);
    procedure WebViewBeforeNavigate2(Sender: TObject;
      const pDisp: IDispatch; var URL, Flags, TargetFrameName, PostData,
      Headers: OleVariant; var Cancel: WordBool);
    procedure WebViewDocumentComplete(Sender: TObject;
      const pDisp: IDispatch; var URL: OleVariant);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure AboutBtnClick(Sender: TObject);
    procedure RemoveBtnClick(Sender: TObject);
    procedure LocaleNameBtnClick(Sender: TObject);
    procedure CopyFileHashBtnClick(Sender: TObject);
    procedure GetHashesCfgBtnClick(Sender: TObject);
    procedure ExitBtnClick(Sender: TObject);
    procedure SettingsBtnClick(Sender: TObject);
    procedure SearchEdtKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SearchEdtKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SearchEdtMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
    procedure DonateBtnClick(Sender: TObject);
    procedure ProgramsBtnClick(Sender: TObject);
    procedure CatalogBtnClick(Sender: TObject);
    procedure ReportProblemBtnClick(Sender: TObject);
    procedure StatisticsBtnClick(Sender: TObject);
    procedure CheckUpdatesBtnClick(Sender: TObject);
  private
    procedure MessageHandler(var Msg: TMsg; var Handled: Boolean);
    procedure DownloadFile(Params: TDownloadParams; ActionType: TActionType);
    { Private declarations }
  public
    ScreenWidth, ScreenHeight, OldScreenWidth, OldScreenHeight: integer;
    DownloadThread: TDownloadThread;
    procedure UpdateSearchDB;
    procedure GetHashesCfg(FileName: string);
    procedure CheckUpdates(Silent: boolean);
    { Public declarations }
  end;

type
  TAppInfo = record
    Name, Icon, Header, Details, RequiredComponents, Notes, Screenshots, Buttons, OldVersions: WideString;
  end;

var
  Main: TMain;
  RunOnce: boolean = false;
  IsDebug, GetStatistics: boolean;
  AppFilePath, AppVersion, DBVersion: string;
  OldWidth, OldHeight: integer;
  DBPath, DBDefaultPath, CurCatFolder, CurCatName, CurAppFile, CurAppName: string;
  NavBarHTML: string;
  ViewImageLink: string;
  UserLocalCode: string;
  FActionType: TActionType;
  DownloadsPath, ProgramsPath, DesktopPath: string;
  DownloadAborted: boolean;
  IsDownloadedRun, DeleteAfterRun, IsSilentInstall: boolean;
  IsSearch, IsRecommendations: boolean;
  SearchList: TStringList;
  StatisticsAllApps, StatisticsDownloadApps: integer;

  FError: TDownloadError;

  IDS_RECOMMENDATIONS, IDS_CAT_INTERNET_NETWORKING, IDS_CAT_OFFICE_PRODUCTIVITY,
  IDS_CAT_MULTIMEDIA, IDS_CAT_GAMES_UTILITIES, IDS_CAT_SYSTEM_UTILITIES,
  IDS_CAT_DEVELOPMENT_ENGINEERING, IDS_CAT_G_TOOLS, IDS_CAT_OTHER: string;

  IDS_DONATE_MESSAGE, IDS_SEARCH, IDS_SEARCH_TITLE, IDS_CATALOG, IDS_CATEGORY, IDS_DOWNLOAD, IDS_MORE,
  IDS_OLD_VERSIONS, IDS_SCREENSHOTS, IDS_ADDITIONAL_INFORMATION, IDS_VERSION, IDS_LICENSE, IDS_DOWNLOAD_PAGE,
  IDS_DESCRIPTION, IDS_SITE, IDS_SIZE, IDS_SIZE_KB, IDS_SIZE_MB, IDS_SIZE_GB, IDS_REQUIRED_COMPONENTS,
  IDS_NOTES, IDS_OS: string;

  IDS_DOWNLOAD_TITLE, IDS_DB_UPDATE, IDS_EXTRACTING, IDS_OK, IDS_CANCEL, IDS_SCREENSHOT,
  IDS_DOWNLOAD_FOLDER, IDS_SELECT, IDS_SELECT_FOLDER, IDS_PROGRAMS_FOLDER, IDS_RUN_AFTER_DOWNLOAD,
  IDS_DELETE_INSTALLER, IDS_SILENT_INSTALL: string;

  IDS_DOWNLOAD_ERROR, IDS_NO_INTERNET_OR_SERVER, IDS_FILE_NOT_FOUND_SERVER, IDS_DOWNLOAD_INCOMPLETE,
  IDS_INVALID_HASH, IDS_EXTRACTION_IN_PROGRESS, IDS_APPLICATION_INSTALLED, IDS_DATABASE_UPDATED,
  IDS_UPDATE_APP_LIST, IDS_UPDATE_APP, IDS_SKIP_UPDATE, IDS_NO_UPDATES_FOUND: string;

  IDS_LAST_UPDATE: string;

  FOleInPlaceActiveObject: IOleInPlaceActiveObject;
  SaveMessageHandler: TMessageEvent;

const
  AppSite = 'https://litecatalog.github.io';
  AppName = 'Lite catalog';
  HTMLStyleFolder = 'Style';
  UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0';
  //UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Trident/7.0; rv:11.0) like Gecko)';

implementation

uses Unit2, Unit3, Unit4;

{$R *.dfm}
{$R UAC.res}

function GetUserDefaultUILanguage: LANGID; stdcall; external 'kernel32.dll';

function GetUserLocaleCode: string;
var
  Lang, Country: array[0..15] of Char;
  MyLCID: LCID;
begin
  MyLCID:=GetUserDefaultLCID;

  if GetLocaleInfo(MyLCID, LOCALE_SISO639LANGNAME, Lang, SizeOf(Lang)) = 0 then
    Lang[0]:=#0;

  if GetLocaleInfo(MyLCID, LOCALE_SISO3166CTRYNAME, Country, SizeOf(Country)) = 0 then
    Country[0]:=#0;

  Result:=string(Lang);

  if Country[0] <> #0 then
    Result:=Result + '-' + string(Country);
end;

function GetLocaleInformation(Flag: integer): string; // If there are multiple languages in the system (with sorting) / Если в системе несколько языков (с сортировкой)
var
  pcLCA: array [0..63] of Char;
begin
  if GetLocaleInfo((DWORD(SORT_DEFAULT) shl 16) or Word(GetUserDefaultUILanguage), Flag, pcLCA, Length(pcLCA)) <= 0 then
    pcLCA[0]:=#0;
  Result:=pcLCA;
end;

function GetIniStr(Ini: TCustomIniFile; Section, Parameter: string): WideString;
begin
  Result:=UTF8Decode(UTF8String(Ini.ReadString(Section + '.Locale.' + UserLocalCode, Parameter, '')));
  if Trim(Result) = '' then
    Result:=UTF8Decode(UTF8String(Ini.ReadString(Section + '.Locale.' + Copy(UserLocalCode, 1, 2), Parameter, '')));
  if Trim(Result) = '' then
    Result:=UTF8Decode(UTF8String(Ini.ReadString(Section, Parameter, '')));
end;

procedure FindDBFiles(const CatFolder, CatName: string; List: TStringList);
var
  SR: TSearchRec; Ini: TMemIniFile;
  DownloadX86, DownloadX64: WideString;
begin
  if FindFirst(DBPath + CatFolder + '\*', faAnyFile, SR) = 0 then begin
    repeat
      if (SR.Attr and faDirectory) <> 0 then begin
        if (SR.Name <> '.') and (SR.Name <> '..') then
          FindDBFiles(DBPath + CatFolder + '\' + SR.Name, CatName, List);
      end else
        if ExtractFileExt(SR.Name) = '.ini' then begin
          List.Add(AnsiLowerCase(Copy(SR.Name, 1, Length(SR.Name) - 4)) + '|' + DBPath + CatFolder + '\' + SR.Name + '|' + CatFolder + '|' + CatName);

          if GetStatistics then begin
            Inc(StatisticsAllApps);
            Ini:=TMemIniFile.Create(DBPath + CatFolder + '\' + SR.Name);
            try
              DownloadX86:=GetIniStr(Ini, 'App', 'DownloadURL.x86');
              DownloadX64:=GetIniStr(Ini, 'App', 'DownloadURL.x64');
            finally
              Ini.Free;
            end;
            if (Trim(DownloadX86) <> '') or (Trim(DownloadX64) <> '') then Inc(StatisticsDownloadApps);
          end;

        end;
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;

procedure TMain.UpdateSearchDB;
begin
  SearchList.Clear;
  FindDBFiles('Internet and Networking', IDS_CAT_INTERNET_NETWORKING, SearchList);
  FindDBFiles('Office and Productivity', IDS_CAT_OFFICE_PRODUCTIVITY, SearchList);
  FindDBFiles('Multimedia', IDS_CAT_MULTIMEDIA, SearchList);
  FindDBFiles('Games and Utilities', IDS_CAT_GAMES_UTILITIES, SearchList);
  FindDBFiles('System Utilities', IDS_CAT_SYSTEM_UTILITIES, SearchList);
  FindDBFiles('Development and Engineering', IDS_CAT_DEVELOPMENT_ENGINEERING, SearchList);
  FindDBFiles('Other', IDS_CAT_OTHER, SearchList);
end;

function GetDesktopPath: string;
var
  Path: array[0..MAX_PATH] of Char;
begin
  SHGetSpecialFolderPath(0, Path, CSIDL_DESKTOPDIRECTORY, False);
  Result := StrPas(Path);
end;

procedure TUpdateSearchThread.Execute;
begin
  Main.UpdateSearchDB;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  WND: HWND; Ini: TIniFile; Reg: TRegistry;
  SystemLang, LangFileName: string;
  UpdateSearchThread: TUpdateSearchThread;
begin
  Constraints.MinWidth:=600;
  Constraints.MinHeight:=420;
  WND:=FindWindow('TMain', AppName);
  if WND <> 0 then begin
    SetForegroundWindow(WND);
    Halt;
  end;
  Caption:=AppName;
  Application.Title:=Caption;
  AppFilePath:=ExtractFilePath(ParamStr(0));

  WebView.Navigate(AppFilePath + HTMLStyleFolder + '/categories.html');
  DesktopPath:=GetDesktopPath + '\';
  SearchList:=TStringList.Create;

  Ini:=TIniFile.Create(AppFilePath + 'Config.ini');
  AppVersion:=Ini.ReadString('App', 'Version', '1.0.0');
  DBVersion:=Ini.ReadString('App', 'DBVersion', '1');
  Width:=Ini.ReadInteger('App', 'Width', Width);
  Height:=Ini.ReadInteger('App', 'Height', Height);
  OldWidth:=Width;
  OldHeight:=Height;

  ScreenWidth:=Ini.ReadInteger('App', 'ScreenWidth', 640);
  ScreenHeight:=Ini.ReadInteger('App', 'ScreenHeight', 480);
  OldScreenWidth:=ScreenWidth;
  OldScreenHeight:=ScreenHeight;

  if Ini.ReadBool('App', 'FirstRun', true) then begin
    Ini.WriteBool('App', 'FirstRun', false);
    Reg:=TRegistry.Create;
    Reg.RootKey:=HKEY_CURRENT_USER;

    // Режим эмуляции IE11
    if Reg.OpenKey('\Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION', true) then begin
        Reg.WriteInteger(ExtractFileName(ParamStr(0)), 11000);
      Reg.CloseKey;
    end;

    // Аппаратное ускорение GPU
    if Reg.OpenKey('\Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_GPU_RENDERING', true) then begin
      Reg.WriteInteger(ExtractFileName(ParamStr(0)), 1);
      Reg.CloseKey;
    end;
    Reg.Free;
  end;

  IsDownloadedRun:=Ini.ReadBool('Main', 'DownloadedRun', false);
  ProgramsPath:=Ini.ReadString('Main', 'ProgramsPath', 'C:\Programs\');
  if not DirectoryExists(ProgramsPath) then CreateDir(ProgramsPath);
  DownloadsPath:=Ini.ReadString('Main', 'DownloadPath', '');
  if Trim(DownloadsPath) = '' then
    DownloadsPath:=GetEnvironmentVariable('USERPROFILE') + '\Downloads\';
  if not DirectoryExists(DownloadsPath) then CreateDir(DownloadsPath);

  DeleteAfterRun:=Ini.ReadBool('Main', 'DeleteAfterRun', false);

  IsSilentInstall:=Ini.ReadBool('Main', 'SilentInstall', false);

  IsDebug:=Ini.ReadBool('Main', 'Debug', false);
  if IsDebug = false then begin
    DBPath:=AppFilePath + 'Apps\';
    DebugBtn.Visible:=false;
    DebugLine.Visible:=false;
  end else // Debug mode
    DBPath:=AppFilePath + 'AppsDefault\';
  DBDefaultPath:=AppFilePath + 'Apps\';

  Ini.Free;

  UserLocalCode:=AnsiLowerCase(GetUserLocaleCode);
  SystemLang:=GetLocaleInformation(LOCALE_SENGLANGUAGE);
  //UserLocalCode:='en'; SystemLang:='English';
  if SystemLang = 'Chinese' then
    SystemLang:='Chinese (Simplified)'
  else if Pos('Spanish', SystemLang) > 0 then
    SystemLang:='Spanish'
  else if Pos('Portuguese', SystemLang) > 0 then
    SystemLang:='Portuguese';

  LangFileName:=SystemLang + '.ini';
  if not FileExists(AppFilePath + 'Languages\' + LangFileName) then
    LangFileName:='English.Ini';
  Ini:=TIniFile.Create(AppFilePath + 'Languages\' + LangFileName);

  FileBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'FILE', 'File'));
  CheckUpdatesBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'CHECK_UPDATES', 'Check for updates'));
  SettingsBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'SETTINGS', 'Settings'));
  ExitBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'EXIT', 'Exit'));
  HelpBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'HELP', 'Help'));
  ReportProblemBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'REPORT_PROBLEM', 'Report a problem'));
  DebugBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'DEBUG', 'Debug'));
  LocaleNameBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'LOCALE_NAME', 'Language'));
  CopyFileHashBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'COPY_HASH', 'Copy file hash to clipboard'));
  GetHashesCfgBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'CALCULATE_HASHES_CONFIG', 'Calculate hashes of the config''s URL addresses'));
  StatisticsBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'STATISTICS', 'Statistics'));
  DownloadsBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'DOWNLOADS', 'Downloads'));
  ProgramsBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'PROGRAMS', 'Programs'));
  RemoveBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'REMOVE', 'Remove'));
  DonateBtn.Caption:=UTF8ToAnsi(Ini.ReadString('Main', 'DONATE', 'Donate'));
  IDS_DONATE_MESSAGE:=UTF8ToAnsi(Ini.ReadString('Main', 'DONATE_MESSAGE', 'Thank you for your support! Your contribution helps the project grow and improve.'));

  IDS_CATALOG:=UTF8ToAnsi(Ini.ReadString('Main', 'CATALOG', 'Catalog'));
  CatalogBtn.Caption:=IDS_CATALOG;
  IDS_CATEGORY:=UTF8ToAnsi(Ini.ReadString('Main', 'CATEGORY', 'Category'));
  IDS_DOWNLOAD:=UTF8ToAnsi(Ini.ReadString('Main', 'DOWNLOAD', 'Download'));
  IDS_DOWNLOAD_TITLE:=UTF8ToAnsi(Ini.ReadString('Main', 'DOWNLOAD_TITLE', 'Download'));
  IDS_MORE:=UTF8ToAnsi(Ini.ReadString('Main', 'MORE', 'More'));
  IDS_SCREENSHOTS:=UTF8ToAnsi(Ini.ReadString('Main', 'SCREENSHOTS', 'Screenshots'));
  IDS_ADDITIONAL_INFORMATION:=UTF8ToAnsi(Ini.ReadString('Main', 'ADDITIONAL_INFORMATION', 'Additional information'));
  IDS_VERSION:=UTF8ToAnsi(Ini.ReadString('Main', 'VERSION', 'Version'));
  IDS_LICENSE:=UTF8ToAnsi(Ini.ReadString('Main', 'LICENSE', 'License'));
  IDS_DESCRIPTION:=UTF8ToAnsi(Ini.ReadString('Main', 'DESCRIPTION', 'Description'));
  IDS_SITE:=UTF8ToAnsi(Ini.ReadString('Main', 'SITE', 'Site'));
  IDS_DOWNLOAD_PAGE:=UTF8ToAnsi(Ini.ReadString('Main', 'DOWNLOAD_PAGE', 'Download Page'));
  IDS_SIZE:=UTF8ToAnsi(Ini.ReadString('Main', 'SIZE', 'Size'));
  IDS_SIZE_KB:=UTF8ToAnsi(Ini.ReadString('Main', 'SIZE_KB', 'KB'));
  IDS_SIZE_MB:=UTF8ToAnsi(Ini.ReadString('Main', 'SIZE_MB', 'MB'));
  IDS_SIZE_GB:=UTF8ToAnsi(Ini.ReadString('Main', 'SIZE_GB', 'GB'));
  IDS_REQUIRED_COMPONENTS:=UTF8ToAnsi(Ini.ReadString('Main', 'REQUIRED_COMPONENTS', 'Required components'));
  IDS_NOTES:=UTF8ToAnsi(Ini.ReadString('Main', 'NOTES', 'Notes'));
  IDS_OS:=UTF8ToAnsi(Ini.ReadString('Main', 'OS', 'OS'));
  IDS_OLD_VERSIONS:=UTF8ToAnsi(Ini.ReadString('Main', 'OLD_VERSIONS', 'Old Versions'));
  IDS_LAST_UPDATE:=UTF8ToAnsi(Ini.ReadString('Main', 'LAST_UPDATE', 'Last Update'));
  IDS_SEARCH_TITLE:=UTF8ToAnsi(Ini.ReadString('Main', 'SEARCH_TITLE', 'Search...'));
  IDS_SEARCH:=UTF8ToAnsi(Ini.ReadString('Main', 'SEARCH', 'Search'));
  SearchEdt.Text:=IDS_SEARCH_TITLE;
  AboutBtn.Caption:= UTF8ToAnsi(Ini.ReadString('Main', 'ABOUT', 'About...'));

  // Категории
  IDS_RECOMMENDATIONS:=UTF8ToAnsi(Ini.ReadString('Categories', 'RECOMMENDATIONS', 'Recommendations'));
  IDS_CAT_INTERNET_NETWORKING:=UTF8ToAnsi(Ini.ReadString('Categories', 'INTERNET_NETWORKING', 'Internet and Networking'));
  IDS_CAT_OFFICE_PRODUCTIVITY:=UTF8ToAnsi(Ini.ReadString('Categories', 'OFFICE_PRODUCTIVITY', 'Office and Productivity'));
  IDS_CAT_MULTIMEDIA:=UTF8ToAnsi(Ini.ReadString('Categories', 'MULTIMEDIA', 'Multimedia'));
  IDS_CAT_GAMES_UTILITIES:=UTF8ToAnsi(Ini.ReadString('Categories', 'GAMES_UTILITIES', 'Games and Utilities'));
  IDS_CAT_SYSTEM_UTILITIES:=UTF8ToAnsi(Ini.ReadString('Categories', 'SYSTEM_UTILITIES', 'System and Utilities'));
  IDS_CAT_DEVELOPMENT_ENGINEERING:=UTF8ToAnsi(Ini.ReadString('Categories', 'DEVELOPMENT_ENGINEERING', 'Development and Engineering'));
  IDS_CAT_OTHER:=UTF8ToAnsi(Ini.ReadString('Categories', 'OTHER', 'Other'));

  IDS_DOWNLOAD_TITLE:=UTF8ToAnsi(Ini.ReadString('Main', 'DOWNLOAD_TITLE', 'Download'));
  IDS_DB_UPDATE:=UTF8ToAnsi(Ini.ReadString('Main', 'DB_UPDATE', 'Updating database'));
  IDS_EXTRACTING:=UTF8ToAnsi(Ini.ReadString('Main', 'EXTRACTING', 'Extracting'));
  IDS_OK:=UTF8ToAnsi(Ini.ReadString('Main', 'OK', 'Ok'));
  IDS_CANCEL:=UTF8ToAnsi(Ini.ReadString('Main', 'CANCEL', 'Cancel'));
  IDS_SCREENSHOT:=UTF8ToAnsi(Ini.ReadString('Main', 'SCREENSHOT', 'Screenshot'));
  IDS_DOWNLOAD_FOLDER:=UTF8ToAnsi(Ini.ReadString('Main', 'DOWNLOAD_FOLDER', 'Download folder'));
  IDS_SELECT:=UTF8ToAnsi(Ini.ReadString('Main', 'SELECT', 'Select'));
  IDS_SELECT_FOLDER:=UTF8ToAnsi(Ini.ReadString('Main', 'SELECT_FOLDER', 'Select folder'));
  IDS_PROGRAMS_FOLDER:=UTF8ToAnsi(Ini.ReadString('Main', 'PROGRAMS_FOLDER', 'Programs folder (silent install)'));
  IDS_RUN_AFTER_DOWNLOAD:=UTF8ToAnsi(Ini.ReadString('Main', 'RUN_AFTER_DOWNLOAD', 'Run after download'));
  IDS_DELETE_INSTALLER:=UTF8ToAnsi(Ini.ReadString('Main', 'DELETE_INSTALLER', 'Delete installer after closing'));
  IDS_SILENT_INSTALL:=UTF8ToAnsi(Ini.ReadString('Main', 'SILENT_INSTALL', 'Silent installation (if supported)'));

  IDS_DOWNLOAD_ERROR:=UTF8ToAnsi(Ini.ReadString('Main', 'DOWNLOAD_ERROR', 'Download error'));
  IDS_NO_INTERNET_OR_SERVER:=UTF8ToAnsi(Ini.ReadString('Main', 'NO_INTERNET_OR_SERVER', 'No connection to the internet or server unavailable.'));
  IDS_FILE_NOT_FOUND_SERVER:=UTF8ToAnsi(Ini.ReadString('Main', 'FILE_NOT_FOUND_SERVER', 'File not found on server (possibly inaccessible).'));
  IDS_DOWNLOAD_INCOMPLETE:=UTF8ToAnsi(Ini.ReadString('Main', 'DOWNLOAD_INCOMPLETE', 'Download interrupted: file downloaded incompletely.'));
  IDS_INVALID_HASH:=UTF8ToAnsi(Ini.ReadString('Main', 'INVALID_HASH', 'Invalid hash.'));
  IDS_EXTRACTION_IN_PROGRESS:=UTF8ToAnsi(Ini.ReadString('Main', 'EXTRACTION_IN_PROGRESS', 'File extraction in progress'));
  IDS_APPLICATION_INSTALLED:=UTF8ToAnsi(Ini.ReadString('Main', 'APPLICATION_INSTALLED', 'Application is installed: %s'));
  IDS_DATABASE_UPDATED:=UTF8ToAnsi(Ini.ReadString('Main', 'DATABASE_UPDATED', 'The database has been updated'));

  IDS_UPDATE_APP_LIST:=UTF8ToAnsi(Ini.ReadString('Main', 'UPDATE_APP_LIST', 'An update to the application list is available. Update?'));
  IDS_UPDATE_APP:=UTF8ToAnsi(Ini.ReadString('Main', 'UPDATE_APP', 'A new version of the program is available. Update?'));
  IDS_SKIP_UPDATE:=UTF8ToAnsi(Ini.ReadString('Main', 'SKIP_UPDATE', 'Skip this update?'));
  IDS_NO_UPDATES_FOUND:=UTF8ToAnsi(Ini.ReadString('Main', 'NO_UPDATES_FOUND', 'No updates found.'));
  Ini.Free;

  //UpdateSearchDB; // Исключительно для поиска, после загрузки перевода категорий
  UpdateSearchThread:=TUpdateSearchThread.Create(true);
  UpdateSearchThread.FreeOnTerminate:=true;
  UpdateSearchThread.Resume;
end;

function HTTPGet(URL: string): string;
var
  hSession, hUrl: HINTERNET;
  Buffer: array [1..8192] of Byte;
  dwFlags, BufferLen: DWORD;
  StrStream: TStringStream;
begin
  Result:='';
  hSession:=InternetOpen(UserAgent, INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(hSession) then begin

  dwFlags := INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_CACHE_WRITE;
  if Copy(LowerCase(URL), 1, 8) = 'https://' then
    dwFlags:=dwFlags or INTERNET_FLAG_SECURE;

    hUrl:=InternetOpenUrl(hSession, PChar(URL), nil, 0, dwFlags, 0);
    if Assigned(hUrl) then begin
      StrStream:=TStringStream.Create('');
      try
        try
          repeat
            FillChar(Buffer, SizeOf(Buffer), 0);
            BufferLen:=0;
            if InternetReadFile(hURL, @Buffer, SizeOf(Buffer), BufferLen) then
              StrStream.WriteBuffer(Buffer, BufferLen)
            else
              Break;
            Application.ProcessMessages;
          until BufferLen = 0;
          Result:=StrStream.DataString;
        except
          Result:='';
        end;
      finally
        StrStream.Free;
      end;

      InternetCloseHandle(hUrl);
    end;

    InternetCloseHandle(hSession);
  end;
end;

{ TDownloadThread }

function URLDecode(const S: string): string;
var
  i, idx, len, n_coded: Integer;
  function WebHexToInt(HexChar: Char): Integer;
    begin
      if HexChar < '0' then
        Result:=Ord(HexChar) + 256 - Ord('0')
      else if HexChar <= Chr(Ord('A') - 1) then
        Result:=Ord(HexChar) - Ord('0')
      else if HexChar <= Chr(Ord('a') - 1) then
        Result:=Ord(HexChar) - Ord('A') + 10
      else
        Result:=Ord(HexChar) - Ord('a') + 10;
      end;
begin
  len:=0;
  n_coded:=0;
  for i:=1 to Length(S) do
    if n_coded >= 1 then begin
      n_coded := n_coded + 1;
        if n_coded >= 3 then
          n_coded := 0;
    end else begin
      len:=len + 1;
      if S[i] = '%' then
        n_coded:=1;
    end;
  SetLength(Result, len);
  idx:=0;
  n_coded:=0;
  for i:=1 to Length(S) do
    if n_coded >= 1 then begin
      n_coded := n_coded + 1;
      if n_coded >= 3 then begin
        Result[idx]:=Chr((WebHexToInt(S[i - 1]) * 16 +
        WebHexToInt(S[i])) mod 256);
        n_coded:=0;
      end;
    end else begin
      idx:=idx + 1;
      if S[i] = '%' then
        n_coded:=1;
      if S[i] = '+' then
        Result[idx]:=' '
      else
        Result[idx]:=S[i];
    end;
end;

constructor TDownloadThread.Create(const Params: TDownloadParams; ActionType: TActionType);
begin
  inherited Create(True); // False = сразу запускать
  FreeOnTerminate:=false;
  FParams.Url:=Params.Url;
  FParams.Path:=Params.Path;
  FParams.Hash:=Params.Hash;
  FParams.SilentParams:=Params.SilentParams;
  FParams.NoArchiveNoInstaller:=Params.NoArchiveNoInstaller;
  FParams.DownloadOnly:=Params.DownloadOnly;
  FParams.ArchiveDesktopShortcuts:=URLDecode( StringReplace(Params.ArchiveDesktopShortcuts, '\', '/', [rfReplaceAll]) );
  FParams.ArchiveHasInstaller:=Params.ArchiveHasInstaller;
  FParams.ArchiveInstallerName:=StringReplace(Params.ArchiveInstallerName, '\', '/', [rfReplaceAll]);
end;

function GetHttpStatusCode(hFile: HINTERNET): DWORD;
var
  dwStatus, dwLen, dwIndex: DWORD;
begin
  Result:=0;
  dwStatus:=0;
  dwLen:=SizeOf(dwStatus);
  dwIndex:=0;
  HttpQueryInfo(hFile, HTTP_QUERY_STATUS_CODE or HTTP_QUERY_FLAG_NUMBER, @dwStatus, dwLen, dwIndex);
  Result:=dwStatus;
end;

function HTTPGetSize(const URL: string; out OutError: TDownloadError): Int64;
var
  hSession, hFile: HINTERNET;
  dwBuffer: array[1..32] of Char;
  dwIndex, dwBufferLen, dwFlags: DWORD;
  HttpStatus: DWORD;
begin
  Result:=0;
  OutError:=deNone;
  hSession:=InternetOpen(UserAgent, INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if not Assigned(hSession) then begin OutError:=deNoInternet; Exit; end;
  try
    if Copy(LowerCase(URL), 1, 8) = 'https://' then
      dwFlags:=INTERNET_FLAG_SECURE or INTERNET_FLAG_RELOAD
    else
      dwFlags:=INTERNET_FLAG_RELOAD;

    hFile:=InternetOpenURL(hSession, PChar(URL), nil, 0, dwFlags, 0);
    if not Assigned(hFile) then begin
      OutError:=deNoInternet;
      Exit;
    end;
    try
      HttpStatus:=GetHttpStatusCode(hFile);
      if (HttpStatus <> 0) and (HttpStatus <> 200) then begin
        OutError:=deFileNotFound;  // 404, 403, 500 и т.д.
        Exit;
      end;
      dwIndex:=0;
      dwBufferLen := SizeOf(dwBuffer);
      FillChar(dwBuffer, SizeOf(dwBuffer), 0);
      if HttpQueryInfo(hFile, HTTP_QUERY_CONTENT_LENGTH, @dwBuffer, dwBufferLen, dwIndex) then
        Result:=StrToIntDef(StrPas(@dwBuffer), 0);
      if (Result = 0) and (HttpStatus = 200) then
        Result:=-1;  // сервер не дал размер, но файл есть
    finally
      InternetCloseHandle(hFile);
    end;
  finally
    InternetCloseHandle(hSession);
  end;
end;

procedure TDownloadThread.Execute;
var
  hSession, hFile: HINTERNET;
  Buffer: array[1..8192] of Byte;
  BufferLen: DWORD;
  F: file;
  FileSize, FileExistsCounter: int64;
  CopySize: int64;
  SR: TSearchRec;
  DoneMethod: TThreadMethod;
  dwFlags: DWORD;
  BaseFileName: string;
begin
  CopySize:=0;
  FSuccess:=false;

  FError:=deNone;
  FileSize:=HTTPGetSize(FParams.Url, FError);
  if FError <> deNone then begin
    Synchronize(DownloadDone);
    Exit;
  end;

  hSession:=InternetOpen(UserAgent, INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if not Assigned(hSession) then Exit;

  try
    if Copy(LowerCase(FParams.Url), 1, 8) = 'https://' then
      dwFlags:=INTERNET_FLAG_SECURE or INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_CACHE_WRITE
    else
      dwFlags:=INTERNET_FLAG_RELOAD;
    hFile:=InternetOpenURL(hSession, PChar(FParams.Url), nil, 0, dwFlags, 0);

    if not Assigned(hFile) then begin
      FError:=deNoInternet;
      Synchronize(DownloadDone);
      Exit;
    end;

    try
      FDownloadedFileName:=URLDecode( ExtractFileName(StringReplace(FParams.Url, '/', '\', [rfReplaceAll])) );
      BaseFileName:=FDownloadedFileName;
      if FileExists(FParams.Path + FDownloadedFileName) then begin
        FileExistsCounter:=1;
        while True do begin
          FDownloadedFileName:=Copy(BaseFileName, 1, Length(BaseFileName) - 4) + '(' + IntToStr(FileExistsCounter) + ')' + ExtractFileExt(BaseFileName);
          if not FileExists(FParams.Path + FDownloadedFileName) then Break;
          Inc(FileExistsCounter);
        end;
      end;

      AssignFile(F, FParams.Path + FDownloadedFileName);
      ReWrite(F, 1);
      try
        repeat
          if Terminated then Break;
          if InternetReadFile(hFile, @Buffer, SizeOf(Buffer), BufferLen) then begin
            BlockWrite(F, Buffer, BufferLen);
            Inc(CopySize, BufferLen);

            if FileSize > 0 then
              FProgress:=Round(CopySize / (FileSize / 100))
            else
              FProgress:=0;
            Synchronize(SyncProgress);
          end else
            Break;
        until BufferLen = 0;
      finally
        CloseFile(F);
      end;
    finally
      InternetCloseHandle(hFile);
    end;
  finally
    InternetCloseHandle(hSession);
  end;

  FSuccess:=false;

  if not Terminated then begin
    if FindFirst(FParams.Path + FDownloadedFileName, faAnyFile, SR) = 0 then begin
      if (FileSize <= 0) or (SR.Size = FileSize) then
        FSuccess:=true
      else
        DeleteFile(FParams.Path + FDownloadedFileName);
      FindClose(SR);
    end;

    if (FParams.Hash <> '0') and (GetSha1File(FParams.Path + FDownloadedFileName) <> FParams.Hash) then begin
      FError:=deInvalidHash;
      DeleteFile(FParams.Path + FDownloadedFileName);
      FSuccess:=false;
    end;
  end else
    DeleteFile(FParams.Path + FDownloadedFileName);

  DoneMethod:=DownloadDone;
  Synchronize(DoneMethod);
end;

procedure CopyFolderRecursive(const SourceDir, TargetDir: string);
var SearchRec: TSearchRec; Src, Dest: string;
begin
  Src := IncludeTrailingPathDelimiter(SourceDir); Dest := IncludeTrailingPathDelimiter(TargetDir);
  if not DirectoryExists(Dest) then CreateDir(Dest);
  if FindFirst(Src + '*.*', faAnyFile, SearchRec) = 0 then
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        if (SearchRec.Attr and faDirectory) = faDirectory then
          CopyFolderRecursive(Src + SearchRec.Name, Dest + SearchRec.Name)
        else
          CopyFile(PChar(Src + SearchRec.Name), PChar(Dest + SearchRec.Name), false);
    until FindNext(SearchRec) <> 0;
  FindClose(SearchRec);
end;

procedure DeleteFolderContents(const Folder: string);
var
  SearchRec: TSearchRec; Item: string; Path: string;
begin
  Path:=IncludeTrailingPathDelimiter(Folder);
  if FindFirst(Path + '*.*', faAnyFile, SearchRec) = 0 then
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then begin
        Item := Path + SearchRec.Name;
        if (SearchRec.Attr and faDirectory) = faDirectory then begin
          DeleteFolderContents(Item);
          RemoveDir(Item);
        end else
          DeleteFile(Item);
      end;
    until FindNext(SearchRec) <> 0;
  FindClose(SearchRec);
end;

procedure ShellRunAndWait(const FileName, SilentParams: string; IsHidden: boolean);
var
  SEI: TShellExecuteInfo;
begin
  ZeroMemory(@SEI, SizeOf(SEI));
  SEI.cbSize:=SizeOf(SEI);
  SEI.fMask:=SEE_MASK_NOCLOSEPROCESS;
  SEI.lpVerb:='open';
  SEI.lpFile:=PChar(FileName);
  if IsHidden then
    SEI.nShow:=SW_HIDE
  else
    SEI.nShow:=SW_SHOWNORMAL;
  if SilentParams <> '' then
    SEI.lpParameters:=PChar(SilentParams);
  if ShellExecuteEx(@SEI) then begin
    WaitForSingleObject(SEI.hProcess, INFINITE);
    CloseHandle(SEI.hProcess);
  end;
end;

procedure CreateDesktopShortcut(const FileName, ShortcutName: string);
var
  WShell, Shortcut: Variant;
  TargetPath: string;
begin
  if not FileExists(FileName) then Exit;
  TargetPath:=ExtractFilePath(FileName);
  WShell:=CreateOleObject('WScript.Shell');
  Shortcut:=WShell.CreateShortcut(DesktopPath + ShortcutName + '.lnk');
  Shortcut.TargetPath:=FileName;
  Shortcut.WorkingDirectory:=ExcludeTrailingPathDelimiter(TargetPath);
  Shortcut.IconLocation:=FileName + ',0';
  Shortcut.Description:=ShortcutName;
  Shortcut.Save;
end;

procedure CreateShortcutsFromString(const InputStr, AppPath: string);
var
  Pairs, Pair: TStringList;
  i: integer;
begin
  Pairs:=TStringList.Create;
  try
    Pairs.Text:=StringReplace(InputStr, ';', #13#10, [rfReplaceAll]);
    for i:=0 to Pairs.Count - 1 do
    begin
      Pair:=TStringList.Create;
      try
        Pair.Text:=StringReplace(Trim(Pairs[i]), '=', #13#10, [rfReplaceAll]);
        if Pair.Count = 2 then begin
          //ShowMessage(Pair[0]);
          //ShowMessage(AppPath + Pair[1]);
          CreateDesktopShortcut(AppPath + Pair[1], Pair[0]);
          //if FIleExists(AppPath + Pair[1]) then ShowMessage('Существует');
        end;
      finally
        Pair.Free;
      end;
    end;
  finally
    Pairs.Free;
  end;
end;

procedure TDownloadThread.DownloadDone;
var
  SR: TSearchRec; ArchiveExt: string;
begin
  if FSuccess then begin

    if FActionType = atDownloadDB then begin
      if not DirectoryExists(AppFilePath + 'Temp') then CreateDir(AppFilePath + 'Temp');

      // Хак завершения прогресс бара
      DownloadForm.ProgressBar.Max:=101;
      DownloadForm.ProgressBar.Position:=101;
      DownloadForm.ProgressBar.Max:=100;

      ShellRunAndWait(AppFilePath + 'Utilities\7z.exe', 'x "' + DownloadsPath + FDownloadedFileName +'" -o"' + AppFilePath + 'Temp\' + '" -y', true);

      DeleteFolderContents(DBDefaultPath);
      CopyFolderRecursive(AppFilePath + 'Temp\AppsDB-master', DBDefaultPath);

      DeleteFolderContents(AppFilePath + 'Temp');

      RemoveDir(AppFilePath + 'Temp');

      DeleteFile(DownloadsPath + FDownloadedFileName);
    end else
      if IsDownloadedRun then begin //IsDownloadedRun
        //RunAndWait(DownloadsPath + FDownloadedFileName);

        // Хак завершения прогресс бара
        DownloadForm.ProgressBar.Max:=101;
        DownloadForm.ProgressBar.Position:=101;
        DownloadForm.ProgressBar.Max:=100;

        // ZIP
        ArchiveExt:=AnsiLowerCase(ExtractFileExt(FDownloadedFileName));
        if (ArchiveExt = '.zip') or (ArchiveExt = '.7z') or (ArchiveExt = '.rar') then begin

          Main.StatusBar.SimpleText:=' ' + IDS_EXTRACTION_IN_PROGRESS;
          Application.ProcessMessages;

          // Archive install
          if FParams.ArchiveHasInstaller = false then begin

            if FParams.DownloadOnly then
              ShellExecute(0, 'open', 'explorer', PChar('/select, "' + DownloadsPath + FDownloadedFileName + '"'), nil, SW_SHOW)

            else begin // Make dir and shortcut
              if not DirectoryExists(ProgramsPath + CurAppName) then CreateDir(ProgramsPath + CurAppName);

              ShellRunAndWait(AppFilePath + 'Utilities\7z.exe', 'x "' + DownloadsPath + FDownloadedFileName +'" -o"' + ProgramsPath + CurAppName + '\' + '" -y', true);

              // Создать ярлык для exe
              if FParams.ArchiveDesktopShortcuts = '*' then begin
                if FindFirst(ProgramsPath + CurAppName + '\*.*', faAnyFile, SR) = 0 then begin
                  repeat
                    if (SR.Attr <> faDirectory) and (AnsiLowerCase(ExtractFileExt(SR.Name)) = '.exe') then begin
                      CreateDesktopShortcut(ProgramsPath + CurAppName + '\' + SR.Name, CurAppName);
                      break;
                    end;
                  until FindNext(SR) <> 0;
                  FindClose(SR);
                end;
              end else if FParams.ArchiveDesktopShortcuts <> '' then
                CreateShortcutsFromString(FParams.ArchiveDesktopShortcuts, ProgramsPath + CurAppName + '\');

            end;

          // Intall in archive (unpack)
          end else begin
            ShellRunAndWait(AppFilePath + 'Utilities\7z.exe', 'x "' + DownloadsPath + FDownloadedFileName +'" -o"' + DownloadsPath + CurAppName + '\' + '" -y', true);

            // Search Installer app
            if (FParams.ArchiveInstallerName = '*') or (FParams.ArchiveInstallerName = '') then
	            if FindFirst(DownloadsPath + CurAppName + '\*.*', faAnyFile, SR) = 0 then begin
                repeat
                  if SR.Attr = faDirectory then Continue;
                  ArchiveExt:=AnsiLowerCase(ExtractFileExt(SR.Name));
                  if (ArchiveExt = '.exe') or (ArchiveExt = '.msi') then begin
                    FParams.ArchiveInstallerName:=SR.Name;
                    Break;
                  end;
		            until FindNext(SR) <> 0;
	              FindClose(SR);
                if FParams.ArchiveInstallerName = '*' then FParams.ArchiveInstallerName:='';
              end;

            if FParams.ArchiveInstallerName <> '' then begin
              ShellRunAndWait(DownloadsPath + CurAppName + '\' + FParams.ArchiveInstallerName, FParams.SilentParams, FParams.SilentParams <> '');
              DeleteFolderContents(DownloadsPath + CurAppName + '\');
              RemoveDir(DownloadsPath + CurAppName);
            end else begin
              ShellExecute(0, 'open', 'explorer', PChar('"' + DownloadsPath + CurAppName  + '"'), nil, SW_SHOW);
              // Silent
              FActionType:=atSilent;
            end;

          end;

        end else begin // exe, msi, cmd, bat...


          // Installer
          if FParams.NoArchiveNoInstaller = false then
            ShellRunAndWait(DownloadsPath + FDownloadedFileName, FParams.SilentParams, FParams.SilentParams <> '')

          else begin // Standalone exe, msi, cmd, bat...
            if FParams.DownloadOnly then begin
              ShellExecute(0, 'open', 'explorer', PChar('/select, "' + DownloadsPath + FDownloadedFileName + '"'), nil, SW_SHOW)

            end else begin // Standalone app install
              if not DirectoryExists(ProgramsPath + CurAppName) then CreateDir(ProgramsPath + CurAppName);
              CopyFile(PChar(DownloadsPath + FDownloadedFileName), PChar(ProgramsPath + CurAppName + '\' + FDownloadedFileName), false);
              CreateDesktopShortcut(ProgramsPath + CurAppName + '\' + FDownloadedFileName, CurAppName);
            end;
          end;

        end;

        if (DeleteAfterRun) and (FParams.DownloadOnly = false) then
          DeleteFile(DownloadsPath + FDownloadedFileName);
      end;

      Main.StatusBar.SimpleText:='';

      if (FActionType = atDefault) and (FParams.DownloadOnly = false) then begin

        if ExtractFileExt(AnsiLowerCase(FDownloadedFileName)) = '.exe' then begin
          if (FParams.SilentParams <> '') or (FParams.NoArchiveNoInstaller) then
            MessageBox(0, PChar(Format(IDS_APPLICATION_INSTALLED, [CurAppName])), PChar(Main.Caption), MB_ICONINFORMATION);
        end else if FParams.ArchiveHasInstaller = false then
          MessageBox(0, PChar(Format(IDS_APPLICATION_INSTALLED, [CurAppName])), PChar(Main.Caption), MB_ICONINFORMATION);

      end else if FActionType = atDownloadDB then
        MessageBox(0, PChar(IDS_DATABASE_UPDATED), PChar(Main.Caption), MB_ICONINFORMATION);

  end else if DownloadAborted = false then begin
    case FError of
      deNone: MessageBox(0, PChar(IDS_DOWNLOAD_ERROR), PChar(Main.Caption), MB_ICONERROR or MB_OK);
      deNoInternet: MessageBox(0, PChar(IDS_NO_INTERNET_OR_SERVER), PChar(Main.Caption), MB_ICONERROR or MB_OK);
      deFileNotFound: MessageBox(0, PChar(IDS_FILE_NOT_FOUND_SERVER), PChar(Main.Caption), MB_ICONERROR or MB_OK);
      deIncomplete: MessageBox(0, PChar(IDS_DOWNLOAD_INCOMPLETE), PChar(Main.Caption), MB_ICONERROR or MB_OK);
      deInvalidHash: MessageBox(0, PChar(IDS_INVALID_HASH), PChar(Main.Caption), MB_ICONERROR or MB_OK);
    end;
  end;
  if Assigned(DownloadForm) then
    DownloadForm.Close;
  Main.StatusBar.SimpleText:='';
end;

procedure TDownloadThread.SyncProgress;
begin
  DownloadForm.ProgressBar.Position:=FProgress;
  DownloadForm.PercentDownloadLbl.Caption:=IntToStr(FProgress) + '%';
end;

procedure TMain.DownloadsBtnClick(Sender: TObject);
begin
  if not DirectoryExists(DownloadsPath) then CreateDir(DownloadsPath);
  ShellExecute(0, 'open', PChar(DownloadsPath), nil, nil, SW_SHOWNORMAL);
end;

function FormatFileSize(ABytes: Int64): string;
var
  SizeKB, SizeMB, SizeGB: Double;
begin
  if ABytes < 1024 * 1024 then begin // Меньше 1 МБ
    SizeKB:=ABytes / 1024;
    if SizeKB > 0 then
      Result:=Format('%.0f %s', [SizeKB, IDS_SIZE_KB])
    else
      Result:='';
  end else if ABytes < 1024 * 1024 * 1024 then begin // Меньше 1 ГБ
    SizeMB:=ABytes / (1024 * 1024);
    Result:=Format('%.1f %s', [SizeMB, IDS_SIZE_MB]);
  end else begin // 1 ГБ и больше
    SizeGB:=ABytes / (1024 * 1024 * 1024);
    Result:=Format('%.1f %s', [SizeGB, IDS_SIZE_GB]);
  end;
end;

procedure TMain.DownloadFile(Params: TDownloadParams; ActionType: TActionType);
begin
  if not DirectoryExists(DownloadsPath) then CreateDir(DownloadsPath);
  DownloadAborted:=false;
  FActionType:=ActionType;
  DownloadThread:=TDownloadThread.Create(Params, ActionType);
  DownloadThread.Resume; // теперь запускаем
  if ActionType <> atSilent then begin
    DownloadForm.Show;
    if ActionType = atDownloadDB then
      DownloadForm.Caption:=IDS_DB_UPDATE
    else
      DownloadForm.Caption:=IDS_DOWNLOAD_TITLE;
    DownloadForm.AppTitleLbl.Caption:=CurAppName;
    DownloadForm.PercentDownloadLbl.Caption:='0%';
    DownloadForm.ProgressBar.Position:=0;
  end;
end;

procedure TMain.WebViewBeforeNavigate2(Sender: TObject;
  const pDisp: IDispatch; var URL, Flags, TargetFrameName, PostData,
  Headers: OleVariant; var Cancel: WordBool);
var
  URLParams: string;
  DownloadURL, SHA, SilentParams, ArchiveDesktopShortcuts, ArchiveInstallerName: string;
  NoArchiveNoInstaller, ArchiveHasInstallerStr, DownloadOnly: string;
  ArchiveHasInstaller: boolean;
  Doc: Variant;
  TempPos: Integer;
  DownloadParams: TDownloadParams;
begin
  // WebBrowser добавляет "/" в конец если видит "/"

  if Copy(Url, 1, 9) = 'folder://' then begin
    CurAppName:='';
    Cancel:=true;
    URLParams:=URLDecode(Copy(Url, 10, MaxInt));
    CurCatFolder:=Copy(URLParams, 1, Pos('|', URLParams) - 1);
    CurCatName:=Copy(URLParams, Pos('|', URLParams) + 1, MaxInt);
    SetLength(CurCatName, Length(CurCatName) - 1);
    WebView.Navigate(AppFilePath + HTMLStyleFolder + '/category.html');
    Exit;
  end;

  if Copy(Url, 1, 11) = 'download://' then begin
    Cancel:=true;
    //ShowMessage(URL);
    //if Assigned(DownloadForm) then Exit;
    URLParams:=Copy(Url, 12, MaxInt); // полный путь к .ini
    //SetLength(sParam, Length(sParam) - 1);

    // Download URL
    TempPos:= Pos('|', URLParams);
    DownloadURL:=Copy(URLParams, 1, TempPos - 1);
    Delete(URLParams, 1, TempPos);

    // SHA
    TempPos:=Pos('|', URLParams);
    SHA:=Copy(URLParams, 1, TempPos - 1);
    Delete(URLParams, 1, TempPos);

    // Silent params
    TempPos:=Pos('|', URLParams);
    SilentParams:=URLDecode(Copy(URLParams, 1, TempPos - 1));
    Delete(URLParams, 1, TempPos);

    // NoArchiveNoInstaller
    TempPos:=Pos('|', URLParams);
    NoArchiveNoInstaller:=URLDecode(Copy(URLParams, 1, TempPos - 1));
    Delete(URLParams, 1, TempPos);

    // DownloadOnly
    TempPos:=Pos('|', URLParams);
    DownloadOnly:=URLDecode(Copy(URLParams, 1, TempPos - 1));
    Delete(URLParams, 1, TempPos);

    // Archive Desktop Shortcuts
    TempPos:=Pos('|', URLParams);
    ArchiveDesktopShortcuts:=Copy(URLParams, 1, TempPos - 1);
    Delete(URLParams, 1, TempPos);

    // ArchiveHasInstaller
    TempPos:=Pos('|', URLParams);
    ArchiveHasInstallerStr:=Copy(URLParams, 1, TempPos - 1);
    ArchiveHasInstaller:=Trim(ArchiveHasInstallerStr) = '1';
    Delete(URLParams, 1, TempPos);

    // ArchiveInstallerName
    TempPos:=Pos('|', URLParams);
    ArchiveInstallerName:=Trim(Copy(URLParams, 1, TempPos - 1));
    Delete(URLParams, 1, TempPos);

    // App name
    CurAppName:=UrlDecode(URLParams);

    {ShowMessage(DownloadURL);
    ShowMessage('SHA=' + SHA);
    ShowMessage('SilentParams=' + SilentParams);
    ShowMessage(NoArchiveNoInstaller);
    ShowMessage(DownloadOnly);
    ShowMessage('ArchiveDesktopShortcuts=' + ArchiveDesktopShortcuts);
    ShowMessage('AppName=' + CurAppName);
    Exit;}

    DownloadParams.Url:=DownloadURL;
    DownloadParams.Path:=DownloadsPath;
    DownloadParams.Hash:=SHA;
    DownloadParams.SilentParams:=SilentParams;
    DownloadParams.NoArchiveNoInstaller:=NoArchiveNoInstaller = '1';
    DownloadParams.DownloadOnly:=DownloadOnly = '1';
    DownloadParams.ArchiveDesktopShortcuts:=ArchiveDesktopShortcuts;
    DownloadParams.ArchiveHasInstaller:=ArchiveHasInstaller;
    DownloadParams.ArchiveInstallerName:=ArchiveInstallerName;

    DownloadFile(DownloadParams, atDefault);
    Exit;
  end;

  if Copy(Url, 1, 6) = 'app://' then begin
    Cancel:=true;

    URLParams:=URLDecode(Copy(Url, 7, MaxInt)); // полный путь к .ini
    SetLength(URLParams, Length(URLParams) - 1);

    TempPos:=Pos('|', URLParams);
    CurAppFile:=URLDecode(Copy(URLParams, 1, TempPos - 1));
    Delete(URLParams, 1, TempPos);

    if IsSearch or IsRecommendations then begin
      TempPos:=Pos('|', URLParams);
      CurCatFolder:=URLDecode(Copy(URLParams, 1, TempPos - 1));
      Delete(URLParams, 1, TempPos);
      CurCatName:=URLParams;
    end;

    WebView.Navigate(AppFilePath + HTMLStyleFolder + '/app.html');
    Exit;
  end;

  if Copy(Url, 1, 13) = 'screenshot://' then begin
    Cancel:=true;
    ViewImageLink:=Copy(Url, 14, MaxInt);

    ScreenForm.WebView.Navigate('about:blank');
    ScreenForm.Show;
    ScreenForm.BringToFront;
    Exit;
  end;

  if Copy(Url, 1, 4) = 'http' then begin
    Cancel:=true;
    ShellExecute(0, 'open', PChar(String(Url)), nil, nil, SW_SHOWNORMAL);
    Exit;
  end;

  if (Copy(Url, 1, 7) = 'edit://') or (Copy(Url, 1, 7) = 'size://') or (Copy(Url, 1, 11) = 'explorer://') then begin
    Cancel:=true;
    URLParams:=URL;
    TempPos:=Pos('://', URLParams);
    URLParams:=DBPath + CurCatFolder + '\' + URLDecode(Copy(URLParams, TempPos + 3, Length(URLParams) - (TempPos + 2) - 1));
    if Copy(Url, 1, 7) = 'edit://' then
      ShellExecute(0, 'open', PChar(String(URLParams)), nil, nil, SW_SHOWNORMAL)
    else if Copy(Url, 1, 7) = 'size://' then begin
      GetHashesCfg(URLParams);
      WebView.Navigate(AppFilePath + HTMLStyleFolder + '/app.html');
    end else
      ShellExecute(0, 'open', 'explorer', PChar('/select, "' + URLParams + '"'), nil, SW_SHOW);
    Exit;
  end;

  if Pos('.html', Url) = 0 then Cancel:=true;
end;

procedure AddCat(FolderName, CategoryName, IconName: string; var HTMLContent: WideString);
begin
  HTMLContent:=HTMLContent +
    '<div class="cat-item" onclick="document.location=''folder://' + FolderName + '|' + CategoryName + ''';">' +
    '<div class="icon"><img src="icons/cats/' + IconName + '" alt="" /></div>' +
    '<div class="label">' + CategoryName + '</div>' +
    '<div class="clear"></div>' +
    '</div>';
end;

function DigitToHex(Digit: Integer): Char;
  begin
    case Digit of
      0..9: Result := Chr(Digit + Ord('0'));
      10..15: Result := Chr(Digit - 10 + Ord('A'));
    else
      Result := '0';
  end;
end; // DigitToHex

function URLEncode(const S: string): string;
var
  i, idx, len: Integer;
begin
  len := 0;
  for i := 1 to Length(S) do
    if ((S[i] >= '0') and (S[i] <= '9')) or
      ((S[i] >= 'A') and (S[i] <= 'Z')) or
      ((S[i] >= 'a') and (S[i] <= 'z')) or (S[i] = ' ') or
      (S[i] = '_') or (S[i] = '*') or (S[i] = '-') or (S[i] = '.') then
      len := len + 1
    else
      len := len + 3;
  SetLength(Result, len);
  idx := 1;
  for i := 1 to Length(S) do
    if S[i] = ' ' then begin
      Result[idx] := '+';
      idx := idx + 1;
    end else
      if ((S[i] >= '0') and (S[i] <= '9')) or
        ((S[i] >= 'A') and (S[i] <= 'Z')) or
        ((S[i] >= 'a') and (S[i] <= 'z')) or
        (S[i] = '_') or (S[i] = '*') or (S[i] = '-') or (S[i] = '.') then begin
          Result[idx] := S[i];
          idx := idx + 1;
        end
        else
        begin
          Result[idx] := '%';
          Result[idx + 1] := DigitToHex(Ord(S[i]) div 16);
          Result[idx + 2] := DigitToHex(Ord(S[i]) mod 16);
          idx := idx + 3;
        end;
end;

procedure AddItem(FileName, ItemCatFolder, ItemCatName: string; var HTMLContent: WideString);
var
  Ini: TMemIniFile;
  AppName, AppDescr, AppIcon, Site, DownloadPage, DownloadX86, DownloadX64, DownloadX86Hash, DownloadX64Hash,
  SilentParams, ArchiveDesktopShortcuts: WideString;
  ArchiveHasInstaller, ArchiveInstallerName: WideString;
  NoArchiveNoInstaller, DownloadOnly: string;
begin
  Ini:=TMemIniFile.Create(FileName);
  try
    DownloadX86:=GetIniStr(Ini, 'App', 'DownloadURL.x86');
    DownloadX64:=GetIniStr(Ini, 'App', 'DownloadURL.x64');
    SilentParams:=URLEncode( StringReplace(Trim(GetIniStr(Ini, 'App', 'SilentParameters')), '%PROGRAMS%', ProgramsPath, []));
    NoArchiveNoInstaller:=IntToStr(Ord(Ini.ReadBool('App', 'NoArchiveNoInstaller', false)));
    DownloadOnly:=IntToStr(Ord(Ini.ReadBool('App', 'DownloadOnly', false)));
    ArchiveDesktopShortcuts:=StringReplace( Trim(GetIniStr(Ini, 'App', 'ArchiveDesktopShortcuts')) , '\', '/', [rfReplaceAll]);
    ArchiveHasInstaller:=Trim(GetIniStr(Ini, 'App', 'ArchiveHasInstaller'));
    ArchiveInstallerName:=StringReplace( Trim(GetIniStr(Ini, 'App', 'ArchiveInstallerName')) , '\', '/', [rfReplaceAll]);

    if Ini.ReadBool('App', 'HashCheck', true) then begin
      DownloadX86Hash:=AnsiLowerCase(GetIniStr(Ini, 'App', 'SHA1.x86'));
      DownloadX64Hash:=AnsiLowerCase(GetIniStr(Ini, 'App', 'SHA1.x64'));
    end else begin
      DownloadX86Hash:='0';
      DownloadX64Hash:='0';
    end;

    if DownloadX64 = '' then begin
      DownloadX64:=DownloadX86;
      DownloadX64Hash:=DownloadX86Hash;
    end;

    AppName:=UTF8Decode(UTF8String(Ini.ReadString('App', 'Name', '')));
    AppDescr:=GetIniStr(Ini, 'App', 'Description');

    AppIcon:=Trim(UTF8Decode(UTF8String(Ini.ReadString('App', 'Icon', ''))));
    if AppIcon = 'library.png' then
      AppIcon:=AppFilePath + HTMLStyleFolder + '/icons/library.png'
    else if (AppIcon = 'app.png') or (AppIcon = '') then
      AppIcon:=AppFilePath + HTMLStyleFolder + '/icons/app.png'
    else
      AppIcon:=StringReplace(ExtractFilePath(FileName), '\', '/', [rfReplaceAll]) + '/icons/' + AppIcon;

    HTMLContent:=HTMLContent +
      '<div class="app-item">' +
      '<div class="app-item-inner">' +
      '<div class="icon"><img src="file:///' + AppIcon + '"/></div>' +
      '<div class="info">' +
      '<strong>' + AppName + '</strong>' +
      '<span class="desc" title="' + AppDescr + '">' + AppDescr + '</span>';

      if (not IsSearch) and (not IsRecommendations) then
        HTMLContent:=HTMLContent +'<span class="meta">' + IDS_CATEGORY + ': ' + CurCatName + '</span>'
      else
        HTMLContent:=HTMLContent +'<span class="meta">' + IDS_CATEGORY + ': ' + ItemCatName + '</span>';

      if DownloadX64 <> '' then
        HTMLContent:=HTMLContent + '<button class="btn btn-download" onclick="document.location=''download://' + DownloadX64 + '|' + DownloadX64Hash + '|' + SilentParams + '|' + NoArchiveNoInstaller + '|' + DownloadOnly + '|' + ArchiveDesktopShortcuts + '|' + ArchiveHasInstaller + '|' + ArchiveInstallerName + '|' + AppName + '''"><img src="icons/download.png" alt="" />' + IDS_DOWNLOAD + '</button>';

      // Сайт и страница загрузки
      Site:=Trim( UTF8Decode( UTF8String(Ini.ReadString('App', 'Website', '')) ) );
      DownloadPage:=Trim( UTF8Decode( UTF8String(Ini.ReadString('App', 'DownloadPage', '')) ) );
      if (DownloadX64 = '') and (DownloadX86 = '') then
        if DownloadPage <> '' then
          HTMLContent:=HTMLContent + '<button class="btn btn-download" onclick="document.location=''' + DownloadPage + '''"><img src="icons/download.png" alt="" />' + IDS_SITE + '</button>'
        else if Site <> '' then
          HTMLContent:=HTMLContent +  '<button class="btn btn-download" onclick="document.location=''' + Site + '''"><img src="icons/download.png" alt="" />' + IDS_SITE + '</button>';

      HTMLContent:=HTMLContent + '<button class="btn" onclick="document.location=''app://' + UrlEncode(ExtractFileName(FileName));

      if (not IsSearch) and (not IsRecommendations) then
        HTMLContent:=HTMLContent +'|-|-'
      else
        HTMLContent:=HTMLContent +'|' + ItemCatFolder + '|' + ItemCatName;

      HTMLContent:=HTMLContent +'''"><img src="icons/info.png" alt="" />' + IDS_MORE + '</button></div>' +
      '<div class="clear"></div>' +
      '</div>' +
      '</div>';
  finally
    Ini.Free;
  end;
end;

function BuildScreenshotsHTML(const Screenshots: string): string;
var
  List: TStringList; i: integer; ScreenshotURL: string;
begin
  Result:='';
  List:=TStringList.Create;
  try
    List.Delimiter:= ';';
    List.DelimitedText:=Screenshots;
    for i:=0 to List.Count - 1 do begin
      ScreenshotURL:=Trim(List[i]);
      if ScreenshotURL <> '' then
        Result:=Result + '<img onclick="document.location = ''screenshot://' + ScreenshotURL + '''" src="' + ScreenshotURL + '" />' + sLineBreak;
    end;
  finally
    List.Free;
  end;
end;

function RemoveHttp(const Url: string): string;
begin
  Result:=Url;
  if Pos('http://', Result) = 1 then
    Delete(Result, 1, 7)
  else if Pos('https://', Result) = 1 then
    Delete(Result, 1, 8);
  if Pos('www.', Result) = 1 then
    Delete(Result, 1, 4);
end;

procedure AddOldVersionBlock(Ini: TCustomIniFile; const Section, OSLabel: string; var AppInfo: TAppInfo);
var
  DownloadPage, DownloadX86, DownloadX64, DownloadX86Hash, DownloadX64Hash, SilentParams, ArchiveDesktopShortcuts: WideString;
  AppSize, AppSize2, AppsSizes: string;
  AppNotes, ArchiveHasInstaller, ArchiveInstallerName: WideString;
  NoArchiveNoInstaller, DownloadOnly: string;
begin
  DownloadPage:=Trim(GetIniStr(Ini, Section, 'DownloadPage'));
  if DownloadPage = '' then DownloadPage:=Trim(GetIniStr(Ini, Section, 'Website'));
  DownloadX86:=Trim(GetIniStr(Ini, Section, 'DownloadURL.x86'));
  DownloadX64:=Trim(GetIniStr(Ini, Section, 'DownloadURL.x64'));
  SilentParams:=URLEncode( StringReplace(Trim(GetIniStr(Ini, Section, 'SilentParameters')), '%PROGRAMS%', ProgramsPath, []) );
  NoArchiveNoInstaller:=IntToStr(Ord(Ini.ReadBool(Section, 'NoArchiveNoInstaller', false)));
  DownloadOnly:=IntToStr(Ord(Ini.ReadBool(Section, 'DonwloadOnly', false)));
  ArchiveDesktopShortcuts:=StringReplace( Trim(GetIniStr(Ini, Section, 'ArchiveDesktopShortcuts')) , '\', '/', [rfReplaceAll]);
  ArchiveHasInstaller:=Trim(GetIniStr(Ini, Section, 'ArchiveHasInstaller'));
  ArchiveInstallerName:=StringReplace( Trim(GetIniStr(Ini, Section, 'ArchiveInstallerName')) , '\', '/', [rfReplaceAll]);

  if Ini.ReadBool(Section, 'HashCheck', true) then begin
    DownloadX86Hash:=GetIniStr(Ini, Section, 'SHA1.x86');
    DownloadX64Hash:=GetIniStr(Ini, Section, 'SHA1.x64');
  end else begin
    DownloadX86Hash:='0';
    DownloadX64Hash:='0';
  end;

  AppSize:=FormatFileSize(StrToIntDef(GetIniStr(Ini, Section, 'SizeBytes.x64'), 0));
  AppSize2:=FormatFileSize(StrToIntDef(GetIniStr(Ini, Section, 'SizeBytes.x86'), 0));
  AppsSizes:=AppSize + IfThen((AppSize <> '') and (AppSize2 <> ''), ', ') + AppSize2;
  if AppsSizes = '' then AppsSizes:='-';

  if (Trim(DownloadX86) <> '') or (Trim(DownloadX64) <> '') or (DownloadPage <> '') then begin
    AppInfo.OldVersions:=AppInfo.OldVersions +
      '<div class="old-version-block"><div class="details" id="app-details">' +
      '<div class="detail"><div class="detail-title">' + IDS_OS + '</div><div class="detail-descr">' + OSLabel + '</div></div>' +
      '<div class="detail"><div class="detail-title">' + IDS_VERSION + '</div><div class="detail-descr">' + GetIniStr(Ini, Section, 'Version') + '</div></div>' +
      '<div class="detail"><div class="detail-title">' + IDS_SIZE + '</div><div class="detail-descr">' + AppsSizes + '</div></div>' +
      '<div class="clear"></div></div>';

    end;

    AppNotes:=GetIniStr(Ini, Section, 'Notes');
    if AppNotes <> '' then begin
      AppInfo.OldVersions:=AppInfo.OldVersions + '<div class="details"><div class="detail-header">' + IDS_NOTES + '</div><div class="detail-content">';
      AppInfo.OldVersions:=AppInfo.OldVersions + StringReplace(AppNotes, '\n', '<br/>', [rfReplaceAll])  + '</div><div class="clear"></div></div>';
    end;

  if (Trim(DownloadX86) <> '') or (Trim(DownloadX64) <> '') or (DownloadPage <> '') then begin
    if DownloadX64 <> '' then
      AppInfo.OldVersions:=AppInfo.OldVersions +
        '<button class="btn btn-download" onclick="document.location=''download://' +
        DownloadX64 + '|' + DownloadX64Hash + '|' + SilentParams  + '|' + NoArchiveNoInstaller + '|' + DownloadOnly + '|' + ArchiveDesktopShortcuts + '|' + ArchiveHasInstaller + '|' + ArchiveInstallerName + '|' + AppInfo.Name + '''"><img src="icons/download.png" alt="" />' +
        IDS_DOWNLOAD + ' (x64)</button>';

    if DownloadX86 <> '' then
      AppInfo.OldVersions:=AppInfo.OldVersions +
        '<button class="btn btn-download" onclick="document.location=''download://' +
        DownloadX86 + '|' + DownloadX86Hash + '|' + SilentParams  + '|' + NoArchiveNoInstaller + '|' + DownloadOnly + '|' + ArchiveDesktopShortcuts + '|' + ArchiveHasInstaller + '|' + ArchiveInstallerName + '|' + AppInfo.Name + '''"><img src="icons/download.png" alt="" />' +
        IDS_DOWNLOAD + ' ' + IfThen(Trim(DownloadX64) <> '','(x86)') + '</button>';

    if (DownloadX86 = '') and (DownloadX64 = '') and (DownloadPage <> '') then
        AppInfo.OldVersions:=AppInfo.OldVersions + '<button class="btn btn-download" onclick="document.location=''' + DownloadPage + '''"><img src="icons/download.png" alt="" />' + IDS_SITE + '</button>';

    AppInfo.OldVersions:=AppInfo.OldVersions + '</div></div>';
  end;
end;

procedure GetAppInfo(FileName: string; var AppInfo: TAppInfo);
var
  Ini: TMemIniFile;
  AppDescr, Site, DownloadX86, DownloadX64, DownloadX86Hash, DownloadX64Hash,
  SilentParams, RequiredComponents, AppNotes, ArchiveDesktopShortcuts: WideString;
  NoArchiveNoInstaller, DownloadOnly, AppSize, AppSize2, AppsSizes: string;
  DonatePage, DownloadPage, ArchiveHasInstaller, ArchiveInstallerName: WideString;
begin
  Ini:=TMemIniFile.Create(FileName);
  try

    DonatePage:=GetIniStr(Ini, 'App', 'DonatePage');
    DownloadX86:=Trim(GetIniStr(Ini, 'App', 'DownloadURL.x86'));
    DownloadX64:=Trim(GetIniStr(Ini, 'App', 'DownloadURL.x64'));
    SilentParams:=URLEncode( StringReplace(Trim(GetIniStr(Ini, 'App', 'SilentParameters')), '%PROGRAMS%', ProgramsPath, []) );
    NoArchiveNoInstaller:=IntToStr(Ord(Ini.ReadBool('App', 'NoArchiveNoInstaller', false)));
    DownloadOnly:=IntToStr(Ord(Ini.ReadBool('App', 'DownloadOnly', false)));
    ArchiveDesktopShortcuts:=StringReplace( Trim(GetIniStr(Ini, 'App', 'ArchiveDesktopShortcuts')), '\', '/', [rfReplaceAll]);
    ArchiveHasInstaller:=Trim(GetIniStr(Ini, 'App', 'ArchiveHasInstaller'));
    ArchiveInstallerName:=Trim(GetIniStr(Ini, 'App', 'ArchiveInstallerName'));
    RequiredComponents:=Trim(GetIniStr(Ini, 'App', 'RequiredComponents'));
    AppNotes:=Trim(GetIniStr(Ini, 'App', 'Notes'));
    if (Length(RequiredComponents) > 0) and (RequiredComponents[Length(RequiredComponents)] = ';') then
      Delete(RequiredComponents, Length(RequiredComponents), 1);

    if Ini.ReadBool('App', 'HashCheck', true) then begin
      DownloadX86Hash:=GetIniStr(Ini, 'App', 'SHA1.x86');
      DownloadX64Hash:=GetIniStr(Ini, 'App', 'SHA1.x64');
    end else begin
      DownloadX86Hash:='0';
      DownloadX64Hash:='0';
    end;

    AppInfo.Name:=UTF8Decode(UTF8String(Ini.ReadString('App', 'Name', '')));

    AppInfo.Icon:=UTF8Decode(UTF8String(Ini.ReadString('App', 'Icon', '')));
    if AppInfo.Icon = 'library.png' then
      AppInfo.Icon:=StringReplace(AppFilePath + HTMLStyleFolder, '\', '/', [rfReplaceAll]) + '/icons/library.png'
    else if (AppInfo.Icon = 'app.png') or (AppInfo.Icon = '') then
      AppInfo.Icon:=StringReplace(AppFilePath + HTMLStyleFolder, '\', '/', [rfReplaceAll]) + '/icons/app.png'
    else
      AppInfo.Icon:=StringReplace(DBPath + CurCatFolder, '\', '/', [rfReplaceAll]) + '/icons/' + AppInfo.Icon;

    AppInfo.Header:='<table><tbody><tr><td valign="middle"><img width="48px" src="' + AppInfo.Icon + '" alt="' + AppInfo.Name + '" /></td>' +
    '<td width="8"></td><td valign="middle"><h3>' + AppInfo.Name + '</h3>' + GetIniStr(Ini, 'App', 'Description') + '</td></tr></tbody></table>';

    if DownloadX64 <> '' then
      AppInfo.Buttons:='<button class="btn btn-download" onclick="document.location=''download://' + DownloadX64 + '|' + DownloadX64Hash + '|' + SilentParams + '|' + NoArchiveNoInstaller + '|' + DownloadOnly + '|' + ArchiveDesktopShortcuts + '|' + ArchiveHasInstaller + '|' + ArchiveInstallerName + '|' + AppInfo.Name + '''"><img src="icons/download.png" alt="" />' + IDS_DOWNLOAD + ' (x64)</button>';

    if DownloadX86 <> '' then
      AppInfo.Buttons:=AppInfo.Buttons + '<button class="btn btn-download" onclick="document.location=''download://' + DownloadX86 + '|' + DownloadX86Hash + '|' + SilentParams + '|' + NoArchiveNoInstaller + '|' + DownloadOnly + '|' + ArchiveDesktopShortcuts + '|' + ArchiveHasInstaller + '|' + ArchiveInstallerName + '|' + AppInfo.Name + '''"><img src="icons/download.png" alt="" />' + IDS_DOWNLOAD + ' ' + IfThen(Trim(DownloadX64) <> '','(x86)') + '</button>';

    // Сайт и страница загрузки
    Site:=Trim( UTF8Decode( UTF8String(Ini.ReadString('App', 'Website', '')) ) );
    DownloadPage:=Trim( UTF8Decode( UTF8String(Ini.ReadString('App', 'DownloadPage', '')) ) );
    if (DownloadX64 = '') and (DownloadX86 = '') then
      if DownloadPage <> '' then
        AppInfo.Buttons:=AppInfo.Buttons + '<button class="btn btn-download" onclick="document.location=''' + DownloadPage + '''"><img src="icons/download.png" alt="" />' + IDS_DOWNLOAD_PAGE + '</button>'
      else if Site <> '' then
        AppInfo.Buttons:=AppInfo.Buttons + '<button class="btn btn-download" onclick="document.location=''' + Site + '''"><img src="icons/download.png" alt="" />' + IDS_DOWNLOAD_PAGE + '</button>';
    if DownloadPage = '' then DownloadPage:='-';
    if Site = '' then Site:='-';

    if Trim(DonatePage) <> '' then
      AppInfo.Buttons:=AppInfo.Buttons + '<button class="btn btn-donate" onclick="document.location=''' + DonatePage + '''"><img src="icons/donate.png" alt="" />' + Main.DonateBtn.Caption + '</button>';

    if IsDebug then begin
      AppInfo.Buttons:=AppInfo.Buttons + '<button class="btn" onclick="document.location=''app.html''">Refresh</button>';
      AppInfo.Buttons:=AppInfo.Buttons + '<button class="btn" onclick="document.location=''edit://' + UrlEncode(ExtractFileName(FileName)) + '''">Edit</button>';
      AppInfo.Buttons:=AppInfo.Buttons + '<button class="btn" onclick="document.location=''explorer://' + UrlEncode(ExtractFileName(FileName)) + '''">Explorer</button>';
      AppInfo.Buttons:=AppInfo.Buttons + '<button class="btn" onclick="document.location=''size://' + UrlEncode(ExtractFileName(FileName)) + '''">Sizes & hashes</button>';
    end;

    AppInfo.Screenshots:=BuildScreenshotsHTML(UTF8Decode(UTF8String(Ini.ReadString('App', 'Screenshots', ''))));

    AppInfo.Details:='<div class="detail-header">' + IDS_ADDITIONAL_INFORMATION + '</div><div class="detail"><div class="detail-title">' + IDS_VERSION + '</div><div class="detail-descr">' + GetIniStr(Ini, 'App', 'Version') + '</div></div>';

    // Размер
    AppSize:=FormatFileSize(StrToIntDef(GetIniStr(Ini, 'App', 'SizeBytes.x64'), 0));
    AppSize2:=FormatFileSize(StrToIntDef(GetIniStr(Ini, 'App', 'SizeBytes.x86'), 0));
    AppsSizes:=AppSize + IfThen((AppSize <> '') and (AppSize2 <> ''), ', ') + AppSize2;
    if AppsSizes = '' then AppsSizes:='-';

    AppInfo.Details:=AppInfo.Details + '<div class="detail"><div class="detail-title">' + IDS_SIZE + '</div><div class="detail-descr">' + AppsSizes + '</div></div>';

    AppInfo.Details:=AppInfo.Details+ '<div class="detail"><div class="detail-title">' + IDS_LICENSE + '</div><div class="detail-descr">' + GetIniStr(Ini, 'App', 'License') + '</div></div>';

    AppInfo.Details:=AppInfo.Details + '<div class="detail"><div class="detail-title">' + IDS_CATEGORY + '</div><div class="detail-descr">' + CurCatName + '</div></div>';

    if Site <> '-' then
      AppInfo.Details:=AppInfo.Details + '<div class="detail"><div class="detail-title">' + IDS_SITE + '</div><div class="detail-descr"><a href="' + Site + '" title="' + Site + '">' +  RemoveHttp(Site) + '</a></div></div>'
    else
      AppInfo.Details:=AppInfo.Details + '<div class="detail"><div class="detail-title">' + IDS_SITE + '</div><div class="detail-descr">-</div></div>';

    if DownloadPage <> '-' then
      AppInfo.Details:=AppInfo.Details + '<div class="detail"><div class="detail-title">' + IDS_DOWNLOAD_PAGE + '</div><div class="detail-descr"><a href="' + DownloadPage + '" title="' + DownloadPage + '">' + RemoveHttp(DownloadPage) + '</a></div></div>'
    else
      AppInfo.Details:=AppInfo.Details + '<div class="detail"><div class="detail-title">' + IDS_DOWNLOAD_PAGE + '</div><div class="detail-descr">-</div></div>';

    AppInfo.Details:=AppInfo.Details + '<div class="clear"></div></div>';

    if RequiredComponents <> '' then begin
      AppInfo.RequiredComponents:='<div class="detail-header">' + IDS_REQUIRED_COMPONENTS + '</div><div class="detail-content">';
      AppInfo.RequiredComponents:=AppInfo.RequiredComponents + '&bull; ' + StringReplace(RequiredComponents, ';', '<br>&bull; ', [rfReplaceAll]);
      AppInfo.RequiredComponents:=AppInfo.RequiredComponents + '</div>';
    end;

    if AppNotes <> '' then begin
      AppInfo.Notes:='<div class="detail-header">' + IDS_NOTES + '</div><div class="detail-content">';
      AppInfo.Notes:=AppInfo.Notes + StringReplace(AppNotes, '\n', '<br/>', [rfReplaceAll])  + '</div>';
    end;

    AppInfo.OldVersions:='';
    AddOldVersionBlock(Ini, 'App.Windows10',  'Windows 10', AppInfo);
    AddOldVersionBlock(Ini, 'App.Windows8.1',  'Windows 8.1', AppInfo);
    AddOldVersionBlock(Ini, 'App.Windows8',  'Windows 8', AppInfo);
    AddOldVersionBlock(Ini, 'App.Windows7',  'Windows 7', AppInfo);
    AddOldVersionBlock(Ini, 'App.WindowsVista',  'Windows Vista', AppInfo);
    AddOldVersionBlock(Ini, 'App.WindowsXP', 'Windows XP', AppInfo);

  finally
    Ini.Free;
  end;
end;

// Возможное кол-во ошибок для слова
{function GetWordErrorCount(Str: string): integer;
begin
  Result:=(Length(Str) div 4) + 1;
end;

const cuthalf = 100;
var
  buf: array [0..((cuthalf * 2) - 1)] of integer;
function min3(a, b, c: integer): integer;
begin
  Result:=a;
  if b < Result then
    Result:=b;
  if c < Result then
    Result:=c;
end;

// Расстояние Левенштейна
function LevDist(s, t: string): integer;
var i, j, m, n: integer; 
    cost: integer;
    flip: boolean;
begin 
  s:=Copy(s, 1, cuthalf - 1);
  t:=Copy(t, 1, cuthalf - 1);
  m:=Length(s);
  n:=Length(t);
  if m = 0 then
    Result:=n
  else if n = 0 then
    Result:=m
  else begin
    flip := false;
    for i:=0 to n do buf[i] := i;
    for i:=1 to m do begin
      if flip then buf[0]:=i
      else buf[cuthalf]:=i;
      for j:=1 to n do begin
        if s[i] = t[j] then
          cost:=0
        else
          cost:=1;
        if flip then
          buf[j]:=min3((buf[cuthalf + j] + 1),
                         (buf[j - 1] + 1),
                         (buf[cuthalf + j - 1] + cost))
        else
          buf[cuthalf + j]:=min3((buf[j] + 1), (buf[cuthalf + j - 1] + 1), (buf[j - 1] + cost));
      end;
      flip:=not flip;
    end;
    if flip then
      Result:=buf[cuthalf + n]
    else
      Result:=buf[n];
  end;
end;}

function CompareFilesByName(List: TStringList; Index1, Index2: Integer): Integer;
var
  FileName1, FileName2: string;
begin
  FileName1:=ExtractFileName(Trim(List[Index1]));
  FileName2:=ExtractFileName(Trim(List[Index2]));
  Result:=CompareText(FileName1, FileName2); // нечувствительно к регистру
end;

procedure TMain.WebViewDocumentComplete(Sender: TObject;
  const pDisp: IDispatch; var URL: OleVariant);
var
  sUrl: string;
  HTMLContent: WideString;
  SR: TSearchRec;
  AppInfo: TAppInfo;
  i, TempPos: integer;
  AppName, SearchStr, FoundFileName, SearchFileCatFolder, SearchFileCatName: string;
  RecommendationsList: TStringList;
begin
  if SearchEdt.Text = '' then begin
    SearchEdt.Font.Color:=clGray;
    SearchEdt.Text:=IDS_SEARCH_TITLE;
  end;

  sUrl:=ExtractFileName(StringReplace(URL, '/', '\', [rfReplaceAll]));
  if pDisp = (Sender as TWebBrowser).Application then begin
    if sUrl = 'categories.html' then begin
      SearchEdt.Font.Color:=clGray;
      SearchEdt.Text:=IDS_SEARCH_TITLE;
      CurCatName:='';
      CurAppFile:='';
      CurAppName:='';
      //HTMLContent:='';
      IsSearch:=false;
      IsRecommendations:=false;
      StatusBar.SimpleText:='';

      HTMLContent:='<div class="cat-item" onclick="document.location=''folder://Recommendations|' + IDS_RECOMMENDATIONS + ''';">' +
      '<div class="icon"><img src="' + AppFilePath + HTMLStyleFolder + '/icons/recommendations.png" alt="" /></div>' +
      '<div class="label">' + IDS_RECOMMENDATIONS + '</div>' +
      '<div class="clear"></div></div>';

      AddCat('Internet and Networking', IDS_CAT_INTERNET_NETWORKING, 'internet.png', HTMLContent);
      AddCat('Office and Productivity', IDS_CAT_OFFICE_PRODUCTIVITY, 'office.png', HTMLContent);
      AddCat('Multimedia', IDS_CAT_MULTIMEDIA, 'multimedia.png', HTMLContent);
      AddCat('Games and Utilities', IDS_CAT_GAMES_UTILITIES, 'games.png', HTMLContent);
      AddCat('System Utilities', IDS_CAT_SYSTEM_UTILITIES, 'tools.png', HTMLContent);
      AddCat('Development and Engineering', IDS_CAT_DEVELOPMENT_ENGINEERING, 'development.png', HTMLContent);
      AddCat('Other', IDS_CAT_OTHER, 'other.png', HTMLContent);
      WebView.OleObject.Document.getElementById('categories').innerHTML := HTMLContent;
    end;

    if sUrl = 'category.html' then begin
      HTMLContent:='';

      if IsSearch then begin

        for i:=0 to SearchList.Count - 1 do begin

          AppName:=Copy(SearchList.Strings[i], 1, Pos('|', SearchList.Strings[i]) - 1);
          //if LevDist(AnsiLowerCase(SearchEdt.Text), AppName) < GetWordErrorCount(SearchEdt.Text) then begin
          if Pos(AnsiLowerCase(SearchEdt.Text), AppName) > 0 then begin

            SearchStr:=Copy(SearchList.Strings[i], Pos('|', SearchList.Strings[i]) + 1, MaxInt);

            // FoundFileName
            TempPos:=Pos('|', SearchStr);
            FoundFileName:=Copy(SearchStr, 1, TempPos - 1);
            Delete(SearchStr, 1, TempPos);

            // SearchFileCatFolder
            TempPos:=Pos('|', SearchStr);
            SearchFileCatFolder:=Copy(SearchStr, 1, TempPos - 1);
            Delete(SearchStr, 1, TempPos);

            // SearchFileCatName
            SearchFileCatName:=SearchStr;

            //ShowMessage(FoundFileName);
            //ShowMessage(SearchFileCatFolder);
            //ShowMessage(SearchFileCatName);

            AddItem(FoundFileName, SearchFileCatFolder, SearchFileCatName, HTMLContent);

          end;
        end;

      end else begin

        if CurCatFolder = 'Recommendations' then begin
          IsRecommendations:=true;
          RecommendationsList:=TStringList.Create;
          if FileExists(DBPath + 'Recommendations.txt') then RecommendationsList.LoadFromFile(DBPath + 'Recommendations.txt');

          RecommendationsList.CustomSort(CompareFilesByName);


          for i:=0 to RecommendationsList.Count - 1 do
            if (Trim(RecommendationsList.Strings[i]) <> '') and (FileExists(DBPath + RecommendationsList.Strings[i])) then
              AddItem(DBPath + RecommendationsList.Strings[i], ExtractFilePath(RecommendationsList.Strings[i]), IDS_RECOMMENDATIONS, HTMLContent);
              //SearchFileCatFolder, SearchFileCatName

          RecommendationsList.Free;
        // сканируем папку FCurrentFolder
        end else if FindFirst(DBPath + CurCatFolder + '\*.ini', faAnyFile, SR) = 0 then begin
          repeat
            AddItem(DBPath + CurCatFolder + '\' + SR.Name, '', '', HTMLContent);
          until FindNext(SR) <> 0;
          FindClose(SR);
        end;
      end;

      WebView.OleObject.Document.getElementById('category').innerHTML := HTMLContent;
    end;

    if sUrl = 'app.html' then begin

      GetAppInfo(DBPath + CurCatFolder + '\' + CurAppFile, AppInfo);
      CurAppName:=AppInfo.Name;

      WebView.OleObject.Document.getElementById('app-header').innerHTML:=AppInfo.Header;
      WebView.OleObject.Document.getElementById('app-details').innerHTML:=AppInfo.Details;
      WebView.OleObject.Document.getElementById('screenshots-title').innerHTML:=IDS_SCREENSHOTS;
      if AppInfo.Screenshots <> '' then
        WebView.OleObject.Document.getElementById('screenshots').innerHTML:=AppInfo.Screenshots
      else
        WebView.OleObject.Document.getElementById('app-screenshots').style.display:='none';

      WebView.OleObject.Document.getElementById('old-versions-title').innerHTML:=IDS_OLD_VERSIONS;

      if AppInfo.RequiredComponents <> '' then
        WebView.OleObject.Document.getElementById('app-components').innerHTML:=AppInfo.RequiredComponents
      else
        WebView.OleObject.Document.getElementById('app-components').style.display:='none';

      if AppInfo.Notes <> '' then
        WebView.OleObject.Document.getElementById('app-notes').innerHTML:=AppInfo.Notes
      else
        WebView.OleObject.Document.getElementById('app-notes').style.display:='none';

      if AppInfo.OldVersions <> '' then begin
        WebView.OleObject.Document.getElementById('old-versions').innerHTML:=AppInfo.OldVersions;
        WebView.OleObject.Document.getElementById('old-versions-block').style.display:='block';
      end else
        WebView.OleObject.Document.getElementById('old-versions-block').style.display:='none';

      WebView.OleObject.Document.getElementById('buttons').innerHTML:=AppInfo.Buttons;
    end;

    // Заголовок
    NavBarHTML:='<span class="nav-link" onclick="document.location=''categories.html'';">' + IDS_CATALOG + '</span>';
    if CurCatName <> '' then
      if IsSearch then
        NavBarHTML:=NavBarHTML + ' > <span class="nav-link" onclick="document.location=''folder://' + CurCatFolder + '|' + CurCatName + ''';">' + IDS_SEARCH + '</span>'
      else if IsRecommendations then
        NavBarHTML:=NavBarHTML + ' > <span class="nav-link" onclick="document.location=''folder://Recommendations|' + IDS_RECOMMENDATIONS + ''';">' + IDS_RECOMMENDATIONS + '</span>'
      else
        NavBarHTML:=NavBarHTML + ' > <span class="nav-link" onclick="document.location=''folder://' + CurCatFolder + '|' + CurCatName + ''';">' + CurCatName + '</span>';

    if CurAppName <> '' then
      NavBarHTML:=NavBarHTML + ' > ' + CurAppName;

    WebView.OleObject.Document.getElementById('nav-bar').innerHTML:=NavBarHTML;
  end;
end;

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  Ini: TIniFile;
begin
  SearchList.Free;
  if (Main.WindowState <> wsMaximized) then
    if (OldWidth <> Width) or (OldHeight <> Height) then begin
      Ini:=TIniFile.Create(AppFilePath + 'Config.ini');
      Ini.WriteInteger('App', 'Width', Width);
      Ini.WriteInteger('App', 'Height', Height);
      Ini.Free;
    end;

    if (OldScreenWidth <> ScreenWidth) or (OldScreenHeight <> ScreenHeight) then begin
      Ini:=TIniFile.Create(AppFilePath + 'Config.ini');
      Ini.WriteInteger('App', 'ScreenWidth', ScreenWidth);
      Ini.WriteInteger('App', 'ScreenHeight', ScreenHeight);
      Ini.Free;
    end;

  if Assigned(DownloadThread) then begin
    DownloadThread.Terminate;
    DownloadThread.WaitFor;
    FreeAndNil(DownloadThread);
  end;
end;

procedure TMain.FormActivate(Sender: TObject);
begin
  SaveMessageHandler:=Application.OnMessage;
  Application.OnMessage:=MessageHandler;
  if not RunOnce then begin
    RunOnce:=true;
    CheckUpdates(true)
  end;
end;

procedure TMain.MessageHandler(var Msg: TMsg; var Handled: Boolean);
var
  iOIPAO: IOleInPlaceActiveObject;
  Dispatch: IDispatch;
begin
  if not Assigned(WebView) then begin
    Handled := False;
    Exit;
  end;
  Handled := (IsDialogMessage(WebView.Handle, Msg) = true);
  if (Handled) and (not WebView.Busy) then begin
    if FOleInPlaceActiveObject = nil then begin
      Dispatch := WebView.Application;
      if Dispatch <> nil then begin
        Dispatch.QueryInterface(IOleInPlaceActiveObject, iOIPAO);
        if iOIPAO <> nil then
          FOleInPlaceActiveObject:=iOIPAO;
      end;
    end;
    if FOleInPlaceActiveObject <> nil then
      if ((Msg.message = WM_KEYDOWN) or (Msg.message = WM_KEYUP)) and
        ((Msg.wParam = VK_BACK) or (Msg.wParam = VK_LEFT) or (Msg.wParam = VK_RIGHT)
        or (Msg.wParam = VK_UP) or (Msg.wParam = VK_DOWN)) then exit;
        FOleInPlaceActiveObject.TranslateAccelerator(Msg);
  end;
end;

procedure TMain.FormDeactivate(Sender: TObject);
begin
  Application.OnMessage:=SaveMessageHandler;
end;

procedure TMain.AboutBtnClick(Sender: TObject);
begin
  Application.MessageBox(PChar(Main.Caption + ' 1.0.0' + #13#10 +
    IDS_LAST_UPDATE + ' 06.04.26' + #13#10 +
    'https://r57zone.github.io' + #13#10 +
    'r57zone@gmail.com' + #13#10 + #13#10 +
    'Third-party components:' + #13#10 +
    '7-Zip © Igor Pavlov (LGPL) https://7-zip.org' + #13#10 +
    'Tango Desktop Project Icons (CC BY-SA 3.0)'
    ),
    PChar(Main.Caption), MB_ICONINFORMATION);
end;

procedure TMain.RemoveBtnClick(Sender: TObject);
var
  Res: HINST;
begin
  // Пытаемся открыть современное окно (Win10/11)
  Res:=ShellExecute(0, 'open', 'ms-settings:appsfeatures', nil, nil, SW_SHOWNORMAL);

  // Если ошибка (меньше или равно 32) — открываем классическое
  if Res <= 32 then
    ShellExecute(0, 'open', 'control.exe', 'appwiz.cpl', nil, SW_SHOWNORMAL);
end;

procedure TMain.LocaleNameBtnClick(Sender: TObject);
begin
  Application.MessageBox(PChar(UserLocalCode), PChar(Caption), MB_ICONINFORMATION);
end;

procedure TMain.CopyFileHashBtnClick(Sender: TObject);
begin
  if not OpenDialog.Execute then Exit;
  ClipBoard.AsText:=GetSha1File(OpenDialog.FileName);
  Application.MessageBox('The hash has been copied to the buffer.', PChar(Caption), MB_ICONINFORMATION);
end;

function GetFileSize(const FileName: string): int64;
var
  FoundData: TSearchRec;
begin
  FindFirst(FileName, faAnyFile, FoundData);
  //Result:=(Int64(FoundData.FindData.nFileSizeHigh) * MAXDWORD) + Int64(FoundData.FindData.nFileSizeLow);
  Result:=(int64(FoundData.FindData.nFileSizeHigh) shl 32) or int64(FoundData.FindData.nFileSizeLow);
  FindClose(FoundData);
end;

function HTTPDownloadFile(const URL, Path: string; out DownloadedFileName: string): boolean;
var
  hSession, hFile: HINTERNET;
  Buffer: array[1..8192] of Byte;
  BufferLen: DWORD;
  F: file;
  FileSize, FileExistsCounter: int64;
  CopySize: int64;
  OutError: TDownloadError;
  BaseFileName: string;
begin
  FileSize:=HTTPGetSize(URL, OutError); // Получаем размер файла / Get file size

  hSession:=InternetOpen(UserAgent, INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(hSession) then begin

    hFile:=InternetOpenURL(hSession, PChar(URL), nil, 0, 0, 0);
    if Assigned(hFile) then begin

      try
        DownloadedFileName:=URLDecode(ExtractFileName(StringReplace(URL, '/', '\', [rfReplaceAll])));
        if not FileExists(Path + DownloadedFileName) then
          AssignFile(F, Path + DownloadedFileName)
        else begin
          BaseFileName:=DownloadedFileName;
          FileExistsCounter:=1;
          while true do begin
            DownloadedFileName:=Copy(BaseFileName, 1, Length(BaseFileName) - 4) + '(' + IntToStr(FileExistsCounter) + ')' + ExtractFileExt(BaseFileName);
            if not FileExists(Path + DownloadedFileName) then begin
              AssignFile(F, Path + DownloadedFileName);
              Break;
            end;
            Inc(FileExistsCounter);
          end;
        end;
        ReWrite(F, 1);
        repeat
          if InternetReadFile(hFile, @Buffer, SizeOf(Buffer), BufferLen) then begin
            BlockWrite(F, Buffer, BufferLen);
            CopySize:=CopySize + BufferLen;
            //Main.StatusBar.SimpleText:=' ' + IntToStr(Round( CopySize / (FileSize / 100));
            //if StopDownload then // По запросу останавливаем загрузку / Stop download on request
              //break;
          end else
            Break;
          Application.ProcessMessages;
        until BufferLen = 0;
        CloseFile(F);
      except
      end;

      InternetCloseHandle(hFile);
    end;

    InternetCloseHandle(hSession);
  end;

  // Проверка на целостность файла / Checking file size
  if (FileSize <= 0) or (FileSize = GetFileSize(Path + DownloadedFileName)) then
    Result:=true
  else begin
    // Удаляем неполный файл / Delete the incomplete file
    DeleteFile(Path + DownloadedFileName);
    Result:=false;
  end
end;

procedure TMain.GetHashesCfg(FileName: string);
var
  Ini: TIniFile; DownloadAppPath, DownloadedFile: string;
  List: TStringList;
  i, DonePercent: integer;
  NeedHash: boolean;
  TotalSteps, CurrentStep: Integer;
begin
  Ini:=TIniFile.Create(FileName);
  List:=TStringList.Create;
  List.Add('App');
  List.Add('App.Locale.' + UserLocalCode);
  List.Add('App.Windows10');
  List.Add('App.Windows10.Locale.' + UserLocalCode);
  List.Add('App.Windows8.1');
  List.Add('App.Windows8.1.Locale.' + UserLocalCode);
  List.Add('App.Windows8');
  List.Add('App.Windows8.Locale.' + UserLocalCode);
  List.Add('App.Windows7');
  List.Add('App.Windows7.Locale.' + UserLocalCode);
  List.Add('App.WindowsVista');
  List.Add('App.WindowsVista.Locale.' + UserLocalCode);
  List.Add('App.WindowsXP');
  List.Add('App.WindowsXP.Locale.' + UserLocalCode);

  TotalSteps:=List.Count * 2;
  CurrentStep:=0;

  for i:=0 to List.Count - 1 do begin
    Inc(CurrentStep);
    DonePercent:=Round(CurrentStep * 100 / TotalSteps);
    StatusBar.SimpleText := ' Download and calculating hash, done: ' + IntToStr(DonePercent) + '%';
    DownloadAppPath:=Ini.ReadString(List[i], 'DownloadURL.x86', '');

    NeedHash:=Ini.ReadBool(List[i], 'HashCheck', true);
    if (Trim(DownloadAppPath) <> '') and (HTTPDownloadFile(DownloadAppPath, DownloadsPath, DownloadedFile)) then begin
      if NeedHash then
        Ini.WriteString(List[i], 'SHA1.x86', ' ' + GetSha1File(DownloadsPath + DownloadedFile))
      else
        Ini.WriteString(List[i], 'SHA1.x86', ' 0');

      Ini.WriteString(List[i], 'SizeBytes.x86', ' ' + IntToStr(GetFileSize(DownloadsPath + DownloadedFile)));
      DeleteFile(DownloadsPath + DownloadedFile);
    end;
    Application.ProcessMessages;

    Inc(CurrentStep);
    DonePercent:=Round(CurrentStep * 100 / TotalSteps);
    StatusBar.SimpleText := ' Download and calculating hash, done: ' + IntToStr(DonePercent) + '%';
    DownloadAppPath:=Ini.ReadString(List[i], 'DownloadURL.x64', '');
    if (Trim(DownloadAppPath) <> '') and (HTTPDownloadFile(DownloadAppPath, DownloadsPath, DownloadedFile)) then begin
      if NeedHash then
        Ini.WriteString(List[i], 'SHA1.x64', ' ' + GetSha1File(DownloadsPath + DownloadedFile))
      else
        Ini.WriteString(List[i], 'SHA1.x64', ' 0');
      Ini.WriteString(List[i], 'SizeBytes.x64', ' ' + IntToStr(GetFileSize(DownloadsPath + DownloadedFile)));
      DeleteFile(DownloadsPath + DownloadedFile);
    end;
    Application.ProcessMessages;
    
  end;

  StatusBar.SimpleText:=' Done';
  MessageBox(0, 'Done', PChar(Caption), MB_ICONINFORMATION);

  List.Free;
  Ini.Free;
end;

procedure TMain.GetHashesCfgBtnClick(Sender: TObject);
begin
  if not OpenDialog.Execute then Exit;
  GetHashesCfg(OpenDialog.FileName);
end;

procedure UpdateVerDB(DBVersion: string);
var
  Ini: TIniFile;
begin
  Ini:=TIniFile.Create(AppFilePath + 'Config.ini');
  Ini.WriteString('App', 'DBVersion', DBVersion);
  Ini.Free;
end;

procedure TMain.ExitBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TMain.SettingsBtnClick(Sender: TObject);
begin
  SettingsForm.ShowModal;
end;

procedure TMain.SearchEdtKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if SearchEdt.Text = '' then begin
    SearchEdt.Font.Color:=clGray;
    SearchEdt.Text:=IDS_SEARCH_TITLE;
  end;
  if Length(SearchEdt.Text) > 2 then begin
    IsSearch:=true;
    CurCatName:=IDS_SEARCH_TITLE;
  end else
    IsSearch:=false;
  WebView.Navigate(AppFilePath + HTMLStyleFolder + '/category.html');
end;

procedure TMain.SearchEdtKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // Fixing the bug that hides controls / Убираем баг скрытия контролов
  if Key = VK_MENU then
    Key:=0;

  if SearchEdt.Text = IDS_SEARCH_TITLE then begin
    SearchEdt.Font.Color:=clBlack;
    SearchEdt.Clear;
  end;
end;

procedure TMain.SearchEdtMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if SearchEdt.Text = IDS_SEARCH_TITLE then begin
    SearchEdt.Font.Color:=clBlack;
    SearchEdt.Clear;
  end;
end;

procedure TMain.FormResize(Sender: TObject);
begin
  SearchEdt.Left:=MainPanel.Width - 180;
end;

procedure TMain.DonateBtnClick(Sender: TObject);
var
  DonateURL: string;
begin
  DonateURL:=HTTPGet(AppSite + '/updates/donate.txt');
  if Trim(DonateURL) = '' then
    DonateURL:='https://boosty.to/r57';
  MessageBox(0, PChar(IDS_DONATE_MESSAGE), PChar(Caption), MB_ICONINFORMATION);
  ShellExecute(0, 'open', PChar(DonateURL), nil, nil, SW_NORMAL);
end;

procedure TMain.ProgramsBtnClick(Sender: TObject);
begin
  if not DirectoryExists(ProgramsPath) then CreateDir(ProgramsPath);
  ShellExecute(0, 'open', PChar(ProgramsPath), nil, nil, SW_SHOWNORMAL);
end;

procedure TMain.CatalogBtnClick(Sender: TObject);
begin
  WebView.Navigate(AppFilePath + HTMLStyleFolder + '/categories.html');
end;

procedure TMain.ReportProblemBtnClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'https://github.com/litecatalog/LiteCatalog/issues', nil, nil, SW_NORMAL);
end;

procedure TMain.StatisticsBtnClick(Sender: TObject);
begin
  StatisticsAllApps:=0;
  StatisticsDownloadApps:=0;
  GetStatistics:=true;
  UpdateSearchDB;
  GetStatistics:=false;
  Application.MessageBox(PChar('Apps: ' + IntToStr(StatisticsAllApps) + #13#10 + 'Downloaded apps: ' + IntToStr(StatisticsDownloadApps) + ', ' + IntToStr(Trunc(StatisticsDownloadApps * 100 / StatisticsAllApps)) + '%' ),  PChar(Caption), MB_ICONINFORMATION);
end;

{ TUpdates }

procedure TUpdatesThread.Execute;
begin
  Main.CheckUpdates(FSilent);
end;

procedure TMain.CheckUpdatesBtnClick(Sender: TObject);
begin
  CheckUpdates(false)
end;

procedure TMain.CheckUpdates(Silent: boolean);
var
  RemoteAppVersion, RemoteDBVersion, DownloadAppURL: string; Ini: TIniFile;
  UpdateFound: boolean;
  DownloadParams: TDownloadParams;
  UpdateSearchThread: TUpdateSearchThread;
begin
  //CheckUpdatesBtn.Enabled:=false;
  UpdateFound:=false;
  RemoteDBVersion:=HTTPGet(AppSite + '/updates/db.txt');
  if Trim(RemoteDBVersion) = '' then Exit;

  if RemoteDBVersion <> DBVersion then
    case MessageBox(Main.Handle, PChar(IDS_UPDATE_APP_LIST), PChar(Main.Caption), MB_YESNOCANCEL or MB_ICONQUESTION) of
      IDYES:
        begin
          DownloadParams.Url:='https://github.com/litecatalog/AppsDB/archive/refs/heads/master.zip';
          DownloadParams.Path:=DownloadsPath;
          DownloadParams.Hash:='0';
          DownloadParams.SilentParams:='';
          DownloadParams.NoArchiveNoInstaller:=false;
          DownloadParams.DownloadOnly:=false;
          DownloadParams.ArchiveDesktopShortcuts:='';
          DownloadParams.ArchiveHasInstaller:=false;
          DownloadParams.ArchiveInstallerName:='';

          Main.DownloadFile(DownloadParams, atDownloadDB);
          UpdateVerDB(RemoteDBVersion);
          UpdateSearchDB;
          //UpdateSearchThread:=TUpdateSearchThread.Create(true);
          //UpdateSearchThread.FreeOnTerminate:=true;
          //UpdateSearchThread.Resume;
          UpdateFound:=true;
        end;

      IDNO:
        if MessageBox(Main.Handle, PChar(IDS_SKIP_UPDATE), PChar(Main.Caption), MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES then
          UpdateVerDB(RemoteDBVersion);
    end;

  RemoteAppVersion:=HTTPGet(AppSite + '/updates/version.txt');
  if Trim(RemoteAppVersion) = '' then Exit;

  if RemoteAppVersion <> AppVersion then
    case MessageBox(Main.Handle, PChar(IDS_UPDATE_APP), PChar(Main.Caption), MB_YESNOCANCEL or MB_ICONQUESTION) of
      IDYES:
        begin
          DownloadAppURL:=HTTPGet(AppSite + '/updates/releases.txt');
          if (DownloadAppURL) = '' then DownloadAppURL:='https://github.com/litecatalog/LiteCatalog/releases';
          ShellExecute(0, 'open', PChar(DownloadAppURL), nil, nil, SW_SHOWNORMAL);
          UpdateFound:=true;
        end;

      IDNO:
        if MessageBox(Main.Handle, PChar(IDS_SKIP_UPDATE), PChar(Main.Caption), MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES then begin
          Ini:=TIniFile.Create(AppFilePath + 'Config.ini');
          Ini.WriteString('App', 'Version', RemoteAppVersion);
          Ini.Free;
        end;
    end;
  if (Silent = false) and (UpdateFound = false) then //(RunOnce) and ...
    MessageBox(Main.Handle, PChar(IDS_NO_UPDATES_FOUND), PChar(Main.Caption), MB_ICONINFORMATION);
  //CheckUpdatesBtn.Enabled:=true;
end;

initialization
 OleInitialize(nil);

finalization
 OleUninitialize;

end.
