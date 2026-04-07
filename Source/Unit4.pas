unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, IniFiles, ShlObj;

type
  TSettingsForm = class(TForm)
    DownloadFolderGB: TGroupBox;
    DownloadsPathEdt: TEdit;
    SelectDownloadPathBtn: TButton;
    DownloadedRunCB: TCheckBox;
    Panel: TPanel;
    OkBtn: TButton;
    CancelBtn: TButton;
    ProgramsFolderGB: TGroupBox;
    ProgramsPathEdt: TEdit;
    SelectProgramsPathBtn: TButton;
    SilentInstallCB: TCheckBox;
    DeleteAfterRunCB: TCheckBox;
    procedure OkBtnClick(Sender: TObject);
    procedure SelectDownloadPathBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure SelectProgramsPathBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SettingsForm: TSettingsForm;
  NewProgramsPath: string = '';
  NewDownloadsPath: string = '';

implementation

uses Unit1;

{$R *.dfm}

function BrowseFolderDialog(Title: PChar): string;
var
  TitleName: string;
  lpItemid: pItemIdList;
  BrowseInfo: TBrowseInfo;
  DisplayName: array[0..MAX_PATH] of Char;
  TempPath: array[0..MAX_PATH] of Char;
begin
  FillChar(BrowseInfo, SizeOf(TBrowseInfo), #0);
  BrowseInfo.hwndOwner:=GetDesktopWindow;
  BrowseInfo.pSzDisplayName:=@DisplayName;
  TitleName:=Title;
  BrowseInfo.lpSzTitle:=PChar(TitleName);
  BrowseInfo.ulFlags:=BIF_NEWDIALOGSTYLE;
  //BrowseInfo.ulFlags:=BIF_RETURNONLYFSDIRS;
  lpItemId:=shBrowseForFolder(BrowseInfo);
  if lpItemId <> nil then begin
    shGetPathFromIdList(lpItemId, TempPath);
    Result:=TempPath;
    GlobalFreePtr(lpItemId);
  end;
end;

procedure TSettingsForm.OkBtnClick(Sender: TObject);
var
  Ini: TIniFile;
begin
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  if NewDownloadsPath <> '' then begin
    DownloadsPath:=NewDownloadsPath;
    Ini.WriteString('Main', 'DownloadPath', DownloadsPath);
    NewDownloadsPath:='';
  end;

  if NewProgramsPath <> '' then begin
    ProgramsPath:=NewProgramsPath;
    Ini.WriteString('Main', 'ProgramsPath', ProgramsPath);
    NewProgramsPath:='';
  end;

  IsDownloadedRun:=DownloadedRunCB.Checked;
  Ini.WriteBool('Main', 'DownloadedRun', DownloadedRunCB.Checked);

  DeleteAfterRun:=DeleteAfterRunCB.Checked;
  Ini.WriteBool('Main', 'DeleteAfterRun', DeleteAfterRunCB.Checked);

  IsSilentInstall:=SilentInstallCB.Checked;
  Ini.WriteBool('Main', 'SilentInstall', SilentInstallCB.Checked);

  Ini.Free;
  Close;
end;

procedure TSettingsForm.SelectDownloadPathBtnClick(Sender: TObject);
var
  TempPath: string;
begin
  TempPath:=BrowseFolderDialog(PChar('Выбор папки'));
  if TempPath = '' then Exit;
  if TempPath[Length(TempPath)] <> '\' then TempPath:=TempPath + '\';
  NewDownloadsPath:=TempPath;
  DownloadsPathEdt.Text:=NewDownloadsPath;
end;

procedure TSettingsForm.CancelBtnClick(Sender: TObject);
begin
  NewDownloadsPath:='';
  DownloadsPathEdt.Text:=DownloadsPath;
  ProgramsPathEdt.Text:=ProgramsPath;
  Close;
end;

procedure TSettingsForm.FormCreate(Sender: TObject);
begin
  Caption:=Main.SettingsBtn.Caption;
  DownloadFolderGB.Caption:=IDS_DOWNLOAD_FOLDER;
  SelectDownloadPathBtn.Caption:=IDS_SELECT;
  ProgramsFolderGB.Caption:=IDS_PROGRAMS_FOLDER;
  SelectProgramsPathBtn.Caption:=IDS_SELECT;
  DownloadedRunCB.Caption:=IDS_DOWNLOAD_FOLDER;
  DeleteAfterRunCB.Caption:=IDS_DELETE_INSTALLER;
  SilentInstallCB.Caption:=IDS_SILENT_INSTALL;
  OkBtn.Caption:=IDS_OK;
  CancelBtn.Caption:=IDS_CANCEL;

  DownloadsPathEdt.Text:=DownloadsPath;
  ProgramsPathEdt.Text:=ProgramsPath;
  DownloadedRunCB.Checked:=IsDownloadedRun;
  DeleteAfterRunCB.Checked:=DeleteAfterRun;
  SilentInstallCB.Checked:=IsSilentInstall;
end;

procedure TSettingsForm.FormActivate(Sender: TObject);
begin
  DownloadsPathEdt.SelLength:=0;
end;

procedure TSettingsForm.SelectProgramsPathBtnClick(Sender: TObject);
var
  TempPath: string;
begin
  TempPath:=BrowseFolderDialog(PChar(IDS_SELECT_FOLDER));
  if TempPath = '' then Exit;
  if TempPath[Length(TempPath)] <> '\' then TempPath:=TempPath + '\';
  NewProgramsPath:=TempPath;
  ProgramsPathEdt.Text:=NewProgramsPath;
end;

end.
