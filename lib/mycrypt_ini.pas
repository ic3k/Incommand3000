unit mycrypt_ini;

interface

uses
 Windows, Sysutils, INIFiles;


type
  CryptingProc = Function(const InString: String; Key: Word): String;

  TCryptingIni = Class(TInifile)
    function ReadString(const Section, Ident, Default: string): string; override;
    procedure WriteString(const Section, Ident, Value: String); override;
  private
    FEncryptProc: CryptingProc;
    FDecryptProc: CryptingProc;
    FKey: Word;
  public
    Procedure SetCryptingData(aEncryptProc, aDecryptProc: CryptingProc; aKey: Word);
    Procedure UseInternalVersion(aKey: Word);
  End;


implementation

const
  c1 = 43876; // jimbo 52845;
  c2 = 53427; // jimbo 22719;

Type
  TByteArray = Array [0 .. 0] of byte;

{ CryptingINI Begin }
Function AsHexString(p: Pointer; cnt: Integer): String;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to cnt do
    Result := Result + '$' + IntToHex(TByteArray(p^)[i], 2);
end;

Procedure MoveHexString2Dest(Dest: Pointer; Const HS: String);
var
  i: Integer;
begin
  i := 1;
  while i < Length(HS) do
  begin
    TByteArray(Dest^)[i div 3] := StrToInt(Copy(HS, i, 3));
    i := i + 3;
  end;
end;

function EncryptV1(const s: string; Key: Word): string;
var
  i: smallint;
  ResultStr: string;
  UCS: WIDEString;
begin
  Result := s;
  if Length(s) > 0 then
  begin
    for i := 1 to (Length(s)) do
    begin
      Result[i] := Char(byte(s[i]) xor (Key shr 8));
      Key := (smallint(Result[i]) + Key) * c1 + c2
    end;
    UCS := Result;
    Result := AsHexString(@UCS[1], Length(UCS) * 2 - 1)
  end;
end;

function DecryptV1(const s: string; Key: Word): string;
var
  i: smallint;
  sb: String;
  UCS: WIDEString;
begin
  if Length(s) > 0 then
  begin
    SetLength(UCS, Length(s) div 3 div 2);
    MoveHexString2Dest(@UCS[1], s);
    sb := UCS;
    SetLength(Result, Length(sb));
    for i := 1 to (Length(sb)) do
    begin
      Result[i] := Char(byte(sb[i]) xor (Key shr 8));
      Key := (smallint(sb[i]) + Key) * c1 + c2
    end;
  end
  else
    Result := s;
end;

{ TCryptingIni }

function TCryptingIni.ReadString(const Section, Ident, Default: string): string;
begin
  if Assigned(FEncryptProc) then
    Result := inherited ReadString(Section, Ident, FEncryptProc(Default, FKey))
  else
    Result := inherited ReadString(Section, Ident, Default);
  if Assigned(FDecryptProc) then
    Result := FDecryptProc(Result, FKey);
end;

procedure TCryptingIni.SetCryptingData(aEncryptProc, aDecryptProc: CryptingProc; aKey: Word);
begin
  FEncryptProc := aEncryptProc;
  FDecryptProc := aDecryptProc;
  FKey := aKey;
end;

procedure TCryptingIni.UseInternalVersion(aKey: Word);
begin
  FKey := aKey;
  FEncryptProc := EncryptV1;
  FDecryptProc := DecryptV1;
end;

procedure TCryptingIni.WriteString(const Section, Ident, Value: String);
var
  s: String;
begin
  if Assigned(FEncryptProc) then
    s := FEncryptProc(Value, FKey)
  else
    s := Value;
  inherited WriteString(Section, Ident, s);
end;
{ CryptingINI End }



end.
