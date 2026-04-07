unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OleCtrls, SHDocVw;

type
  TScreenForm = class(TForm)
    WebView: TWebBrowser;
    procedure WebViewDocumentComplete(Sender: TObject;
      const pDisp: IDispatch; var URL: OleVariant);
    procedure WebViewBeforeNavigate2(Sender: TObject;
      const pDisp: IDispatch; var URL, Flags, TargetFrameName, PostData,
      Headers: OleVariant; var Cancel: WordBool);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ScreenForm: TScreenForm;
  RunOnce: boolean = false;

implementation

uses Unit1;

{$R *.dfm}

procedure TScreenForm.WebViewDocumentComplete(Sender: TObject;
  const pDisp: IDispatch; var URL: OleVariant);
var
  Doc: Variant;
begin
  // Проверяем, что это именно about:blank
  if URL = 'about:blank' then begin
    Doc:=WebView.OleObject.Document;
    Doc.open;
    Doc.write(
      '<html>' +
      '<head><style>' +
      '  * { margin:0; padding:0; }' +
      '  html, body { width:100%; height:100%; background:#f0f0f0; overflow:hidden; }' +
      '  table { width:100%; height:100%; border-collapse:collapse; }' +
      '  td { text-align:center; vertical-align:middle; }' +
      '  img { cursor:pointer; display:block; margin:0 auto; }' +
      '</style>' +
      '<script type="text/javascript">' +
      '  function fitImage() {' +
      '    var img = document.getElementById("scr");' +
      '    var maxW = document.body.clientWidth;' +
      '    var maxH = document.body.clientHeight;' +
      '    img.style.maxWidth  = maxW + "px";' +
      '    img.style.maxHeight = maxH + "px";' +
      '  }' +
      '  window.onresize = fitImage;' +
      '  window.onload   = fitImage;' +
      '</script>' +
      '</head>' +
      '<body>' +
      '<table><tr><td>' +
      '<img id="scr" src="' + ViewImageLink + '" onclick="document.location=''close://''" />' +
      '</td></tr></table>' +
      '</body></html>'
    );
    Doc.close;
  end;
end;

procedure TScreenForm.WebViewBeforeNavigate2(Sender: TObject;
  const pDisp: IDispatch; var URL, Flags, TargetFrameName, PostData,
  Headers: OleVariant; var Cancel: WordBool);
begin
  if Copy(URL, 1, 8) = 'close://' then begin
    Cancel:=true;
    Close;
  end;
end;

procedure TScreenForm.FormCreate(Sender: TObject);
begin
  Caption:=IDS_SCREENSHOT;
end;

procedure TScreenForm.FormResize(Sender: TObject);
begin
  if (Main.WindowState <> wsMaximized) and (RunOnce) then begin
    Main.ScreenWidth:=Width;
    Main.ScreenHeight:=Height;
  end;
end;

procedure TScreenForm.FormShow(Sender: TObject);
begin
  if RunOnce = false then begin
    Width:=Main.ScreenWidth;
    Height:=Main.ScreenHeight;
    RunOnce:=true;
  end;
end;

end.
