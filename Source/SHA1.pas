unit SHA1;

interface

uses
  SysUtils, Classes, Math;

{$R-}
{$Q-}

type
  TSHA1Digest = array[0..4] of Cardinal;

  TSHA1Context = record
    State: TSHA1Digest;
    MsgLen: Int64;
    Buffer: array[0..63] of Byte;
    BufLen: Integer;
  end;

procedure SHA1Init(var Context: TSHA1Context);
procedure SHA1Update(var Context: TSHA1Context; Data: Pointer; DataLen: Integer);
procedure SHA1Final(var Context: TSHA1Context; var Digest: TSHA1Digest);
function  SHA1DigestToHex(const Digest: TSHA1Digest): string;

function GetSha1(Buffer: Pointer; Size: Integer): string;
function GetSha1String(const Text: string): string;
function GetSha1File(const FileName: string): string;

implementation

function RotateLeft(Value: Cardinal; Bits: Integer): Cardinal;
begin
  Result := (Value shl Bits) or (Value shr (32 - Bits));
end;

procedure SHA1Transform(var State: TSHA1Digest; Block: Pointer);
const
  K: array[0..3] of Cardinal = ($5A827999, $6ED9EBA1, $8F1BBCDC, $CA62C1D6);
var
  W: array[0..79] of Cardinal;
  A, B, C, D, E, Temp: Cardinal;
  t, i: Integer;
  P: PByteArray;
begin
  P := PByteArray(Block);

  for t := 0 to 15 do
  begin
    i := t * 4;
    W[t] := (Cardinal(P[i    ]) shl 24) or
            (Cardinal(P[i + 1]) shl 16) or
            (Cardinal(P[i + 2]) shl  8) or
             Cardinal(P[i + 3]);
  end;

  for t := 16 to 79 do
    W[t] := RotateLeft(W[t-3] xor W[t-8] xor W[t-14] xor W[t-16], 1);

  A := State[0]; B := State[1]; C := State[2];
  D := State[3]; E := State[4];

  for t := 0 to 19 do
  begin
    Temp := RotateLeft(A,5) + ((B and C) or ((not B) and D)) + E + W[t] + K[0];
    E := D; D := C; C := RotateLeft(B,30); B := A; A := Temp;
  end;
  for t := 20 to 39 do
  begin
    Temp := RotateLeft(A,5) + (B xor C xor D) + E + W[t] + K[1];
    E := D; D := C; C := RotateLeft(B,30); B := A; A := Temp;
  end;
  for t := 40 to 59 do
  begin
    Temp := RotateLeft(A,5) + ((B and C) or (B and D) or (C and D)) + E + W[t] + K[2];
    E := D; D := C; C := RotateLeft(B,30); B := A; A := Temp;
  end;
  for t := 60 to 79 do
  begin
    Temp := RotateLeft(A,5) + (B xor C xor D) + E + W[t] + K[3];
    E := D; D := C; C := RotateLeft(B,30); B := A; A := Temp;
  end;

  Inc(State[0], A); Inc(State[1], B); Inc(State[2], C);
  Inc(State[3], D); Inc(State[4], E);
end;

procedure SHA1Init(var Context: TSHA1Context);
begin
  Context.State[0] := $67452301;
  Context.State[1] := $EFCDAB89;
  Context.State[2] := $98BADCFE;
  Context.State[3] := $10325476;
  Context.State[4] := $C3D2E1F0;
  Context.MsgLen   := 0;
  Context.BufLen   := 0;
  FillChar(Context.Buffer, SizeOf(Context.Buffer), 0);
end;

procedure SHA1Update(var Context: TSHA1Context; Data: Pointer; DataLen: Integer);
var
  P: PByte;
  CopyLen: Integer;
begin
  if (Data = nil) or (DataLen <= 0) then
    Exit;

  P := PByte(Data);
  Inc(Context.MsgLen, DataLen);

  if Context.BufLen > 0 then
  begin
    CopyLen := 64 - Context.BufLen;
    if CopyLen > DataLen then
      CopyLen := DataLen;
    Move(P^, Context.Buffer[Context.BufLen], CopyLen);
    Inc(Context.BufLen, CopyLen);
    Inc(P, CopyLen);
    Dec(DataLen, CopyLen);
    if Context.BufLen = 64 then
    begin
      SHA1Transform(Context.State, @Context.Buffer);
      Context.BufLen := 0;
    end;
  end;

  while DataLen >= 64 do
  begin
    SHA1Transform(Context.State, P);
    Inc(P, 64);
    Dec(DataLen, 64);
  end;

  if DataLen > 0 then
  begin
    Move(P^, Context.Buffer[0], DataLen);
    Context.BufLen := DataLen;
  end;
end;

procedure SHA1Final(var Context: TSHA1Context; var Digest: TSHA1Digest);
var
  BitLenHi, BitLenLo: Cardinal;
  PadLen: Integer;
  Padding: array[0..71] of Byte;
begin
  BitLenHi := Cardinal(Context.MsgLen shr 29);
  BitLenLo := Cardinal(Context.MsgLen) shl 3;

  if Context.BufLen < 56 then
    PadLen := 56 - Context.BufLen
  else
    PadLen := 120 - Context.BufLen;

  FillChar(Padding, SizeOf(Padding), 0);
  Padding[0] := $80;
  SHA1Update(Context, @Padding, PadLen);

  Padding[0] := Byte(BitLenHi shr 24);
  Padding[1] := Byte(BitLenHi shr 16);
  Padding[2] := Byte(BitLenHi shr  8);
  Padding[3] := Byte(BitLenHi);
  Padding[4] := Byte(BitLenLo shr 24);
  Padding[5] := Byte(BitLenLo shr 16);
  Padding[6] := Byte(BitLenLo shr  8);
  Padding[7] := Byte(BitLenLo);
  SHA1Update(Context, @Padding, 8);

  Digest := Context.State;
  FillChar(Context, SizeOf(Context), 0);
end;

function SHA1DigestToHex(const Digest: TSHA1Digest): string;
begin
  Result := LowerCase(
    IntToHex(Digest[0], 8) +
    IntToHex(Digest[1], 8) +
    IntToHex(Digest[2], 8) +
    IntToHex(Digest[3], 8) +
    IntToHex(Digest[4], 8));
end;

function GetSha1(Buffer: Pointer; Size: Integer): string;
var
  Context: TSHA1Context;
  Digest: TSHA1Digest;
begin
  SHA1Init(Context);
  SHA1Update(Context, Buffer, Size);
  SHA1Final(Context, Digest);
  Result := SHA1DigestToHex(Digest);
end;

function GetSha1String(const Text: string): string;
var
  UTF8: UTF8String;
begin
  if Text = '' then
    Result := GetSha1(nil, 0)
  else
  begin
    UTF8 := UTF8Encode(Text);
    Result := GetSha1(PAnsiChar(UTF8), Length(UTF8));
  end;
end;

function GetSha1File(const FileName: string): string;
const
  BufSize = 64 * 1024;
var
  Stream: TFileStream;
  FileBuf: array[0..BufSize - 1] of Byte;
  BytesRead: Integer;
  Context: TSHA1Context;
  Digest: TSHA1Digest;
begin
  SHA1Init(Context);
  Stream:=TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    repeat
      BytesRead := Stream.Read(FileBuf, BufSize);
      if BytesRead > 0 then
        SHA1Update(Context, @FileBuf[0], BytesRead);
    until BytesRead = 0;
  finally
    Stream.Free;
  end;
  SHA1Final(Context, Digest);
  Result := SHA1DigestToHex(Digest);
end;

end.

