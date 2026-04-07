program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Main},
  Unit2 in 'Unit2.pas' {DownloadForm},
  Unit3 in 'Unit3.pas' {ScreenForm},
  Unit4 in 'Unit4.pas' {SettingsForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  Application.CreateForm(TDownloadForm, DownloadForm);
  Application.CreateForm(TScreenForm, ScreenForm);
  Application.CreateForm(TSettingsForm, SettingsForm);
  Application.Run;
end.
