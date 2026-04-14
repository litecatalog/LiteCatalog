unit SevenZipWrapper;

(*
  SevenZipWrapper — обёртка над 7z.dll для распаковки архивов.
  Совместима с Delphi 7. Поддерживает: zip, 7z, rar, tar, gz, bz2, xz.
*)

interface

uses
  Windows, SysUtils, Classes, ActiveX;

type
  // Callback прогресса: Done и Total в байтах. Total = 0, если неизвестен.
  T7zProgressEvent = procedure(Done, Total: Int64);

  T7zSDK = class
  private
    FHandle:     HMODULE;
    FCreateObj:  Pointer;
    FOnProgress: T7zProgressEvent;
    procedure CheckLoaded;
  public
    destructor Destroy; override;

    // Загрузить 7z.dll. Вызвать один раз при старте приложения.
    // Если Path пуст — ищет рядом с exe.
    procedure Load(const Path: string = '');
    procedure Unload;
    function Loaded: Boolean;

    // Распаковать архив ArchivePath в папку DestPath.
    // Возвращает true при успехе.
    function Extract(const ArchivePath, DestPath: string): Boolean;

    // Опциональный callback прогресса.
    property OnProgress: T7zProgressEvent read FOnProgress write FOnProgress;
  end;

var
  // Глобальный экземпляр. Создаётся автоматически при старте.
  SevenZip: T7zSDK;

implementation

procedure SysPropVariantClear(pv: Pointer); stdcall; external 'ole32.dll' name 'PropVariantClear';

{ ===== Константы ===== }

const
  kpidPath  = 3;
  kpidIsDir = 6;
  kExtract  = 0;

  CLSID_ZIP:  TGUID = '{23170F69-40C1-278A-1000-000110010000}';
  CLSID_BZ2:  TGUID = '{23170F69-40C1-278A-1000-000110020000}';
  CLSID_RAR:  TGUID = '{23170F69-40C1-278A-1000-000110030000}';
  CLSID_7Z:   TGUID = '{23170F69-40C1-278A-1000-000110070000}';
  CLSID_XZ:   TGUID = '{23170F69-40C1-278A-1000-0001100C0000}';
  CLSID_TAR:  TGUID = '{23170F69-40C1-278A-1000-000110EE0000}';
  CLSID_GZ:   TGUID = '{23170F69-40C1-278A-1000-000110EF0000}';

  IID_IInArchive: TGUID = '{23170F69-40C1-278A-0000-000600600000}';

{ ===== Типы ===== }

type
  PInt64   = ^Int64;
  PVarType = ^TVarType;
  PBSTR    = ^WideString;

  TCreateObjectFunc = function(const clsid, iid: TGUID;
    out obj): HRESULT; stdcall;

{ ===== Интерфейсы 7z ===== }

type
  ISequentialInStream = interface(IUnknown)
  ['{23170F69-40C1-278A-0000-000300010000}']
    function Read(data: Pointer; size: Cardinal;
      processedSize: PCardinal): HRESULT; stdcall;
  end;

  IInStream = interface(ISequentialInStream)
  ['{23170F69-40C1-278A-0000-000300030000}']
    function Seek(offset: Int64; seekOrigin: Cardinal;
      newPosition: PInt64): HRESULT; stdcall;
  end;

  ISequentialOutStream = interface(IUnknown)
  ['{23170F69-40C1-278A-0000-000300020000}']
    function Write(data: Pointer; size: Cardinal;
      processedSize: PCardinal): HRESULT; stdcall;
  end;

  IOutStream = interface(ISequentialOutStream)
  ['{23170F69-40C1-278A-0000-000300040000}']
    function Seek(offset: Int64; seekOrigin: Cardinal;
      newPosition: PInt64): HRESULT; stdcall;
    function SetSize(newSize: Int64): HRESULT; stdcall;
  end;

  IArchiveOpenCallback = interface(IUnknown)
  ['{23170F69-40C1-278A-0000-000600100000}']
    function SetTotal(files, bytes: PInt64): HRESULT; stdcall;
    function SetCompleted(files, bytes: PInt64): HRESULT; stdcall;
  end;

  IArchiveExtractCallback = interface(IUnknown)
  ['{23170F69-40C1-278A-0000-000600200000}']
    function SetTotal(total: Int64): HRESULT; stdcall;
    function SetCompleted(completeValue: PInt64): HRESULT; stdcall;
    function GetStream(index: Cardinal; var outStream: ISequentialOutStream;
      askExtractMode: Integer): HRESULT; stdcall;
    function PrepareOperation(askExtractMode: Integer): HRESULT; stdcall;
    function SetOperationResult(opRes: Integer): HRESULT; stdcall;
  end;

  IInArchive = interface(IUnknown)
  ['{23170F69-40C1-278A-0000-000600600000}']
    function Open(stream: IInStream; const maxCheckStartPosition: PInt64;
      openCallback: IArchiveOpenCallback): HRESULT; stdcall;
    function Close: HRESULT; stdcall;
    function GetNumberOfItems(var numItems: Cardinal): HRESULT; stdcall;
    function GetProperty(index: Cardinal; propID: Cardinal;
      var value: TPropVariant): HRESULT; stdcall;
    function Extract(indices: PCardinal; numItems: Cardinal; testMode: Integer;
      extractCallback: IArchiveExtractCallback): HRESULT; stdcall;
    function GetArchiveProperty(propID: Cardinal;
      var value: TPropVariant): HRESULT; stdcall;
    function GetNumberOfProperties(numProperties: PCardinal): HRESULT; stdcall;
    function GetPropertyInfo(index: Cardinal; name: PBSTR;
      propID: PCardinal; varType: PVarType): HRESULT; stdcall;
    function GetNumberOfArchiveProperties(
      numProperties: PCardinal): HRESULT; stdcall;
    function GetArchivePropertyInfo(index: Cardinal; name: PBSTR;
      propID: PCardinal; varType: PVarType): HRESULT; stdcall;
  end;

{ ===== T7zInFileStream ===== }

type
  T7zInFileStream = class(TInterfacedObject, ISequentialInStream, IInStream)
  private
    FHandle: THandle;
  public
    constructor Create(const FileName: string);
    destructor Destroy; override;
    function Read(data: Pointer; size: Cardinal;
      processedSize: PCardinal): HRESULT; stdcall;
    function Seek(offset: Int64; seekOrigin: Cardinal;
      newPosition: PInt64): HRESULT; stdcall;
  end;

constructor T7zInFileStream.Create(const FileName: string);
begin
  inherited Create;
  FHandle := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ,
    nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if FHandle = INVALID_HANDLE_VALUE then
    raise Exception.CreateFmt('Cannot open: %s', [FileName]);
end;

destructor T7zInFileStream.Destroy;
begin
  if FHandle <> INVALID_HANDLE_VALUE then CloseHandle(FHandle);
  inherited;
end;

function HRESULT_FROM_WIN32(x: DWORD): HRESULT;
begin
  if x <= 0 then
    Result := HRESULT(x)
  else
    Result := HRESULT((x and $0000FFFF) or (FACILITY_WIN32 shl 16) or $80000000);
end;

function T7zInFileStream.Read(data: Pointer; size: Cardinal;
  processedSize: PCardinal): HRESULT;
var
  read: Cardinal;
begin
  if ReadFile(FHandle, data^, size, read, nil) then
  begin
    if processedSize <> nil then processedSize^ := read;
    Result := S_OK;
  end else
    Result := HRESULT_FROM_WIN32(GetLastError);
end;

function T7zInFileStream.Seek(offset: Int64; seekOrigin: Cardinal;
  newPosition: PInt64): HRESULT;
var
  lowPart: DWORD;
  highPart: Longint;
  lastError: DWORD;
const
  INVALID_SET_FILE_POINTER = DWORD($FFFFFFFF);
begin
  lowPart := DWORD(offset and $FFFFFFFF);
  highPart := Longint(offset shr 32);
  
  lowPart := SetFilePointer(FHandle, Longint(lowPart), @highPart, seekOrigin);
  
  if lowPart = INVALID_SET_FILE_POINTER then
  begin
    lastError := GetLastError;
    if lastError <> NO_ERROR then
    begin
      Result := HRESULT_FROM_WIN32(lastError);
      Exit;
    end;
  end;

  if newPosition <> nil then
    newPosition^ := Int64(highPart) shl 32 or Int64(lowPart);
    
  Result := S_OK;
end;

{ ===== T7zOutFileStream ===== }

type
  T7zOutFileStream = class(TInterfacedObject, ISequentialOutStream, IOutStream)
  private
    FHandle: THandle;
  public
    constructor Create(const FileName: string);
    destructor Destroy; override;
    function Write(data: Pointer; size: Cardinal;
      processedSize: PCardinal): HRESULT; stdcall;
    function Seek(offset: Int64; seekOrigin: Cardinal;
      newPosition: PInt64): HRESULT; stdcall;
    function SetSize(newSize: Int64): HRESULT; stdcall;
  end;

constructor T7zOutFileStream.Create(const FileName: string);
begin
  inherited Create;
  ForceDirectories(ExtractFilePath(FileName));
  FHandle := CreateFile(PChar(FileName), GENERIC_WRITE, 0, nil,
    CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if FHandle = INVALID_HANDLE_VALUE then
    raise Exception.CreateFmt('Cannot create: %s', [FileName]);
end;

destructor T7zOutFileStream.Destroy;
begin
  if FHandle <> INVALID_HANDLE_VALUE then CloseHandle(FHandle);
  inherited;
end;

function T7zOutFileStream.Write(data: Pointer; size: Cardinal;
  processedSize: PCardinal): HRESULT;
var
  written: Cardinal;
begin
  if WriteFile(FHandle, data^, size, written, nil) then
  begin
    if processedSize <> nil then processedSize^ := written;
    Result := S_OK;
  end else
    Result := HRESULT_FROM_WIN32(GetLastError);
end;

function T7zOutFileStream.Seek(offset: Int64; seekOrigin: Cardinal;
  newPosition: PInt64): HRESULT;
var
  lo, hi: Cardinal;
  lastErr: DWORD;
const
  INVALID_SET_FILE_POINTER = DWORD($FFFFFFFF);
begin
  lo := Cardinal(Int64Rec(offset).Lo);
  hi := Cardinal(Int64Rec(offset).Hi);
  lo := SetFilePointer(FHandle, Integer(lo), @hi, seekOrigin);
  if lo = INVALID_SET_FILE_POINTER then
  begin
    lastErr := GetLastError;
    if lastErr <> NO_ERROR then
    begin
      Result := HRESULT_FROM_WIN32(lastErr);
      Exit;
    end;
  end;
  if newPosition <> nil then
    newPosition^ := Int64(hi) shl 32 or Int64(lo);
  Result := S_OK;
end;

function T7zOutFileStream.SetSize(newSize: Int64): HRESULT;
var
  lo, hi: Cardinal;
  lastErr: DWORD;
const
  INVALID_SET_FILE_POINTER = DWORD($FFFFFFFF);
begin
  lo := Cardinal(Int64Rec(newSize).Lo);
  hi := Cardinal(Int64Rec(newSize).Hi);
  lo := SetFilePointer(FHandle, Integer(lo), @hi, FILE_BEGIN);
  if lo = INVALID_SET_FILE_POINTER then
  begin
    lastErr := GetLastError;
    if lastErr <> NO_ERROR then
    begin
      Result := HRESULT_FROM_WIN32(lastErr);
      Exit;
    end;
  end;
  if not SetEndOfFile(FHandle) then
    Result := HRESULT_FROM_WIN32(GetLastError)
  else
    Result := S_OK;
end;

{ ===== T7zExtractCallback ===== }

type
  T7zExtractCallback = class(TInterfacedObject,
    IArchiveOpenCallback, IArchiveExtractCallback)
  private
    FArchive:    IInArchive;
    FDestPath:   string;
    FOnProgress: T7zProgressEvent;
    FTotal:      Int64;
  public
    constructor Create(const Archive: IInArchive; const DestPath: string;
      const OnProgress: T7zProgressEvent);

    // IArchiveOpenCallback - используем разрешение методов
    function IArchiveOpenCallback.SetTotal = SetTotalOpen;
    function IArchiveOpenCallback.SetCompleted = SetCompletedOpen;
    function SetTotalOpen(files, bytes: PInt64): HRESULT; stdcall;
    function SetCompletedOpen(files, bytes: PInt64): HRESULT; stdcall;

    // IArchiveExtractCallback
    function SetTotal(total: Int64): HRESULT; stdcall;
    function SetCompleted(completeValue: PInt64): HRESULT; stdcall;
    function GetStream(index: Cardinal; var outStream: ISequentialOutStream;
      askExtractMode: Integer): HRESULT; stdcall;
    function PrepareOperation(askExtractMode: Integer): HRESULT; stdcall;
    function SetOperationResult(opRes: Integer): HRESULT; stdcall;
  end;

constructor T7zExtractCallback.Create(const Archive: IInArchive;
  const DestPath: string; const OnProgress: T7zProgressEvent);
begin
  inherited Create;
  FArchive    := Archive;
  FDestPath   := IncludeTrailingPathDelimiter(DestPath);
  FOnProgress := OnProgress;
  FTotal      := 0;
end;

function T7zExtractCallback.SetTotalOpen(files, bytes: PInt64): HRESULT;
begin
  Result := S_OK;
end;

function T7zExtractCallback.SetCompletedOpen(files, bytes: PInt64): HRESULT;
begin
  Result := S_OK;
end;

function T7zExtractCallback.SetTotal(total: Int64): HRESULT;
begin
  FTotal := total;
  Result := S_OK;
end;

function T7zExtractCallback.SetCompleted(completeValue: PInt64): HRESULT;
begin
  if Assigned(FOnProgress) and (completeValue <> nil) then
    FOnProgress(completeValue^, FTotal);
  Result := S_OK;
end;

{ ===== Вспомогательные функции ===== }

procedure PropVariantInit(var pv: TPropVariant);
begin
  FillChar(pv, SizeOf(pv), 0);
end;

function T7zExtractCallback.GetStream(index: Cardinal;
  var outStream: ISequentialOutStream; askExtractMode: Integer): HRESULT;
var
  prop: TPropVariant;
  path: string;
  isDir: Boolean;
begin
  outStream := nil;
  Result    := S_OK;
  if askExtractMode <> kExtract then Exit;

  // Получаем путь файла
  PropVariantInit(prop);
  try
    if FArchive.GetProperty(index, kpidPath, prop) = S_OK then
    begin
      if prop.vt = VT_BSTR then 
        path := prop.bstrVal 
      else 
        path := '';
    end else
      path := '';
  finally
    SysPropVariantClear(@prop);
  end;

  // Проверяем директорию
  PropVariantInit(prop);
  try
    if FArchive.GetProperty(index, kpidIsDir, prop) = S_OK then
    begin
      if prop.vt = VT_BOOL then
        isDir := Boolean(prop.boolVal)
      else
        isDir := False;
    end else
      isDir := False;
  finally
    SysPropVariantClear(@prop);
  end;

  if isDir then
  begin
    ForceDirectories(FDestPath + path);
    Exit;
  end;

  try
    outStream := T7zOutFileStream.Create(FDestPath + path);
  except
    Result := E_FAIL;
  end;
end;

function T7zExtractCallback.PrepareOperation(askExtractMode: Integer): HRESULT;
begin
  Result := S_OK;
end;

function T7zExtractCallback.SetOperationResult(opRes: Integer): HRESULT;
begin
  Result := S_OK;
end;

{ ===== T7zSDK ===== }

procedure T7zSDK.CheckLoaded;
begin
  if not Loaded then
    raise Exception.Create('7z.dll not loaded. Call SevenZip.Load first.');
end;

destructor T7zSDK.Destroy;
begin
  Unload;
  inherited;
end;

function T7zSDK.Loaded: Boolean;
begin
  Result := FHandle <> 0;
end;

procedure T7zSDK.Load(const Path: string);
var
  dllPath: string;
begin
  if Loaded then Exit;

  dllPath := Path;

  if (dllPath = '') or not FileExists(dllPath) then
    dllPath := ExtractFilePath(ParamStr(0)) + '7z.dll';

  if not FileExists(dllPath) then
    raise Exception.Create('7z.dll not found');

  FHandle := LoadLibrary(PChar(dllPath));
  if FHandle = 0 then
    raise Exception.CreateFmt('Cannot load: %s', [dllPath]);

  FCreateObj := GetProcAddress(FHandle, 'CreateObject');
  if FCreateObj = nil then
  begin
    FreeLibrary(FHandle);
    FHandle := 0;
    raise Exception.Create('CreateObject not found in 7z.dll');
  end;
end;

procedure T7zSDK.Unload;
begin
  if FHandle <> 0 then
  begin
    FreeLibrary(FHandle);
    FHandle    := 0;
    FCreateObj := nil;
  end;
end;

function T7zSDK.Extract(const ArchivePath, DestPath: string): Boolean;
var
  clsid:    TGUID;
  obj:      IUnknown;
  archive:  IInArchive;
  inStream: IInStream;
  callbackIntf: IArchiveExtractCallback;
  maxPos:   Int64;
  ext:      string;
begin

  Result := False;
  CheckLoaded;

  ext := LowerCase(ExtractFileExt(ArchivePath));
  if      ext = '.zip' then clsid := CLSID_ZIP
  else if ext = '.7z'  then clsid := CLSID_7Z
  else if ext = '.rar' then clsid := CLSID_RAR
  else if ext = '.tar' then clsid := CLSID_TAR
  else if ext = '.gz'  then clsid := CLSID_GZ
  else if ext = '.tgz' then clsid := CLSID_GZ
  else if ext = '.bz2' then clsid := CLSID_BZ2
  else if ext = '.xz'  then clsid := CLSID_XZ
  else clsid := CLSID_ZIP;

  if TCreateObjectFunc(FCreateObj)(clsid, IID_IInArchive, obj) <> S_OK then
    raise Exception.Create('Cannot create archive handler');

  archive  := obj as IInArchive;
  inStream := T7zInFileStream.Create(ArchivePath);
  callbackIntf := T7zExtractCallback.Create(archive, DestPath, FOnProgress);

  maxPos := $7FFFFFFFFFFFFFFF;  // максимальный Int64
  try
    if archive.Open(inStream, @maxPos,
      callbackIntf as IArchiveOpenCallback) <> S_OK then
      raise Exception.Create('Cannot open archive: ' + ArchivePath);


    Result := archive.Extract(nil, $FFFFFFFF, 0, callbackIntf) = S_OK;
  finally
    archive.Close;
  end;
end;

initialization
  SevenZip := T7zSDK.Create;

finalization
  SevenZip.Free;

end.
