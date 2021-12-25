unit mycrypt;
 {$HINTS OFF}
 {$W-}
interface
uses Windows, Sysutils;

//function Decrypt(const S: AnsiString; Key: Word): AnsiString;
//function Encrypt(const S: AnsiString; Key: Word): AnsiString;
function  my_encrypt(const S: String; Key: Word): String;
function  my_decrypt(const S: String; Key: Word): String;
function  myencrypt_file(infile, outfile: string; const Key: TGUID): boolean;
procedure XorCrypt( var Data; datasize: Integer; const Key: TGUID );

implementation

const
  C1 = 52845;
  C2 = 22719;

function myencrypt_file(infile, outfile: string; const Key: TGUID): boolean;
var
 FromF, ToF: file;
 NumRead, NumWritten: integer;
 Buf: array[1..1024] of Char;
begin
 result := false;
 if not fileexists(infile) then
  begin
    result := false;
    exit;
  end;
  AssignFile(FromF, infile);
  Reset(FromF, 1);              { Record size = 1 }
  AssignFile(ToF, outfile);     { Open output file }
  Rewrite(ToF, 1);              { Record size = 1 }
  repeat
    BlockRead(FromF, Buf, SizeOf(Buf), NumRead);
    xorcrypt(buf,sizeof(buf),key);
    BlockWrite(ToF, Buf, NumRead, NumWritten);
  until (NumRead = 0) or (NumWritten <> NumRead);
  System.CloseFile(FromF);
  System.CloseFile(ToF);
  result := true;
end;

procedure XorCrypt( var Data; datasize: Integer; const Key: TGUID );
type
  TKeybytes= array [0..sizeof(TGUID)-1] of Byte;
  PKeybytes= ^TKeybytes;
var
  pData: PByte;
  Keybytes: PKeybytes;
  i: Integer;
begin
  pData := @Data;
  KeyBytes := @Key;
  for i:= 0 to datasize-1 do begin
    pData^:= pData^ xor Keybytes^[ i mod datasize ];
    Inc(pData);
  end;
end;

function my_encrypt(const S: String; Key: Word): String;
var
  I: byte;
begin
  //Result[0] := S[0];
  Result := S;
  for I := 1 to Length(S) do begin
    Result[I] := char(byte(S[I]) xor (Key shr 8));
    Key := (byte(Result[I]) + Key) * C1 + C2;
  end;
end;

function my_decrypt(const S: String; Key: Word): String;
var
  I: byte;
begin
  //Result[0] := S[0];
  Result := S;
  for I := 1 to Length(S) do begin
    Result[I] := char(byte(S[I]) xor (Key shr 8));
    Key := (byte(S[I]) + Key) * C1 + C2;
  end;
end;

(*
// Decrypts the text in hEdit with the text in hPW
function my_decrypt(Text,PW: PChar): PChar;
var
x,i,                // count variables
sText,sPW: Integer; // size of Text, PW
//Text,PW:   PChar;   // buffer for Text, PW
begin
  sText:=SizeOf(Text)+1;
  sPW:=SizeOf(PW)+1;
  //GetMem(Text,sText);
  //GetMem(PW,sPW);
  //GetWindowText(hEdit,Text,sText);
  //GetWindowText(hPW,PW,sPW);
  x:=0; // initialize count
  for i:=0 to sText-2 do
  begin
    Text[i]:=Chr(Ord(Text[i])-Ord(PW[x]));
    Inc(x);
    if x=(sPW-1)then x:=0;
  end;
  //SetWindowText(hEdit,Text);
  Result := Text;
  //FreeMem(Text);
  //FreeMem(PW);
end;

// Encrypts the text in hEdit with the text in hPW
function my_encrypt(Text,PW: PChar): PChar;
var
x,i,                // count variables
sText,sPW: Integer; // size of Text, PW
aText,aPW:   PChar;   // buffer for Text, PW
begin
  sText:=Length(Text)+1;
  sPW:=Length(PW)+1;
  aText:=Text;
  aPW:=PW;
  writeln('Text: '+Text+' PW: '+PW);
  writeln('Length Text: '+inttostr(sText)+' Length PW: '+inttostr(sPW));

  //GetMem(Text,sText);
  //GetMem(PW,sPW);
  //GetWindowText(hEdit,Text,sText);
  //GetWindowText(hPW,PW,sPW);
  x:=0; // initialize count
  for i:=0 to sText-2 do
  begin
    aText[i]:=Chr(Ord(aText[i])+Ord(aPW[x]));
    Inc(x);
    if x=(sPW-1)then x:=0;
  end;
  //SetWindowText(hEdit,Text);
  Result := aText;
  //FreeMem(Text);
  //FreeMem(PW);
end;
*)
(*
const
  C1 = 52845;
  C2 = 22719;

function Decode(const S: AnsiString): AnsiString;
const
  Map: array[Char] of Byte = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 62, 0, 0, 0, 63, 52, 53,
    54, 55, 56, 57, 58, 59, 60, 61, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2,
    3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
    20, 21, 22, 23, 24, 25, 0, 0, 0, 0, 0, 0, 26, 27, 28, 29, 30,
    31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45,
    46, 47, 48, 49, 50, 51, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0
  );
var
  I: LongInt;
begin
  case Length(S) of
    2:
    begin
      I := Map[S[1]] + (Map[S[2]] shl 6);
      SetLength(Result, 1);
      Move(I, Result[1], Length(Result))
    end;
    3:
    begin
      I := Map[S[1]] + (Map[S[2]] shl 6) + (Map[S[3]] shl 12);
      SetLength(Result, 2);
      Move(I, Result[1], Length(Result))
    end;
    4:
    begin
      I := Map[S[1]] + (Map[S[2]] shl 6) + (Map[S[3]] shl 12) +
        (Map[S[4]] shl 18);
      SetLength(Result, 3);
      Move(I, Result[1], Length(Result))
    end;
  end;
end;

function PreProcess(const S: AnsiString): AnsiString;
var
  SS: AnsiString;
begin
  SS := S;
  Result := '';
  while SS <> '' do
  begin
    Result := Result + Decode(Copy(SS, 1, 4));
    Delete(SS, 1, 4)
  end;
end;

function InternalDecrypt(const S: AnsiString; Key: Word): AnsiString;
var
  I: Word;
  Seed: Word;
begin
  Result := S;
  Seed := Key;
  for I := 1 to Length(Result) do
  begin
    Result[I] := Char(Byte(Result[I]) xor (Seed shr 8));
    Seed := (Byte(S[I]) + Seed) * Word(C1) + Word(C2)
  end;
end;

function Decrypt(const S: AnsiString; Key: Word): AnsiString;
begin
  Result := InternalDecrypt(PreProcess(S), Key)
end;

function Encode(const S: AnsiString): AnsiString;
const
  Map: array[0..63] of Char = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
    'abcdefghijklmnopqrstuvwxyz0123456789+/';
var
  I: LongInt;
begin
  I := 0;
  Move(S[1], I, Length(S));
  case Length(S) of
    1:
      Result := Map[I mod 64] + Map[(I shr 6) mod 64];
    2:
      Result := Map[I mod 64] + Map[(I shr 6) mod 64] +
        Map[(I shr 12) mod 64];
    3:
      Result := Map[I mod 64] + Map[(I shr 6) mod 64] +
        Map[(I shr 12) mod 64] + Map[(I shr 18) mod 64]
  end;
end;

function PostProcess(const S: AnsiString): AnsiString;
var
  SS: AnsiString;
begin
  SS := S;
  Result := '';
  while SS <> '' do
  begin
    Result := Result + Encode(Copy(SS, 1, 3));
    Delete(SS, 1, 3)
  end;
end;

function InternalEncrypt(const S: AnsiString; Key: Word): AnsiString;
var
  I: Word;
  Seed: Word;
begin
  Result := S;
  Seed := Key;
  for I := 1 to Length(Result) do
  begin
    Result[I] := Char(Byte(Result[I]) xor (Seed shr 8));
    Seed := (Byte(Result[I]) + Seed) * Word(C1) + Word(C2)
  end;
end;

function Encrypt(const S: AnsiString; Key: Word): AnsiString;
begin
  Result := PostProcess(InternalEncrypt(S, Key))
end;
*)
end.
