unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls;

type
  TDownloadForm = class(TForm)
    ProgressBar: TProgressBar;
    AppTitleLbl: TLabel;
    PercentDownloadLbl: TLabel;
    CancelBtn: TButton;
    procedure CancelBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DownloadForm: TDownloadForm;

implementation

uses Unit1;

{$R *.dfm}

procedure TDownloadForm.CancelBtnClick(Sender: TObject);
begin
  DownloadAborted:=true;
  Main.DownloadThread.Terminate;
  DownloadForm.Close;
end;

procedure TDownloadForm.FormCreate(Sender: TObject);
begin
  CancelBtn.Caption:=IDS_CANCEL;
end;

end.
