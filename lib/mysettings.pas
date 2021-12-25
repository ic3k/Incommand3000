unit mysettings;
{$WARNINGS OFF}
{$HINTS OFF}
interface

uses
 windows, classes, sysutils, ic3k_lib;

type
 TSettings = record
   sPort, sPasswd, sCFG, sInstAs: string[100];
   installed, start_chat: boolean;
end;

function  load_default_settings(infile: string; var sSettings: TSettings): boolean;
function  loadsettings(infile: string; var sSettings: TSettings): boolean;
function  savesettings(outfile: string; sSettings: TSettings): boolean;
//function  AttachToFile(const AFileName: string; MemoryStream: TMemoryStream; sOffset: integer): Boolean;
//function  LoadFromFile(const AFileName: string; MemoryStream: TMemoryStream; sOffset: integer): Boolean;
function  ReadStreamStr(Stream : TStream) : string;
procedure WriteStreamStr(Stream : TStream; Str : string);

implementation

function ReadStreamInt(Stream : TStream) : integer;
begin
 Stream.ReadBuffer(Result, SizeOf(Integer));
end;

function ReadStreamStr(Stream : TStream) : string;
var
 StrLen : integer;
 TempStr : string;
begin
 TempStr := '';
 StrLen := ReadStreamInt(Stream);
 if StrLen > -1 then
  begin
   SetLength(TempStr, StrLen);
   //Here you should also check the character size
   //Reading Bytes!
   Stream.ReadBuffer(Pointer(TempStr)^, StrLen * SizeOf(Char));
   result := TempStr;
  end
else Result := '';
end;

procedure WriteStreamInt(Stream : TStream; Num : integer);
begin
 Stream.WriteBuffer(Num, SizeOf(Integer));
end;

procedure WriteStreamStr(Stream : TStream; Str : string);
var
 StrLen : integer;
begin
 StrLen := Length(Str); //All Delphi versions compatible
 WriteStreamInt(Stream, StrLen);
 Stream.WriteBuffer(Pointer(Str)^, StrLen * SizeOf(Char)); //All Delphi versions compatible
end;

function load_default_settings(infile: string; var sSettings: TSettings): boolean;
var
 tmp, tmp2: string;
 strm1: TMemorystream;
 lst: TStringList;
 i: integer;
begin
  dprint('[settings]: load_default_settings from '+infile);
  result := false;
  if not fileexists(infile) then
   begin
     dprint('[error] load_default_settings, filenotfound '+infile);
     result := false;
     exit;
   end;

  strm1 := TMemoryStream.Create;
  if loadfromfile(infile,strm1) then
  tmp := readstreamstr(strm1);
  tmp2 := my_decrypt(tmp,SALT);
  strm1.Free;
  lst := TStringList.Create;
  lst.Assign(explode2(tmp2,'@'));
  // 9400@passwd@ic3k.exe@mycfg.cfg@start_chat@installed
  sSettings.sPort := lst.strings[0];
  sSettings.sPasswd := lst.strings[1];
  sSettings.sInstAs := lst.strings[2];
  sSettings.sCFG := lst.strings[3];
  if lst.strings[4]='true' then sSettings.start_chat := true;
  if lst.strings[5]='true' then sSettings.installed := true;
  lst.Free;
  result := true;
end;

function loadsettings(infile: string; var sSettings: TSettings): boolean;
var
 strm1: TFileStream;
 tmp1,tmp2: string;
 lst: TStringList;
begin
  result := false;
  if fileexists(infile) then
   begin
    dprint('[loadsettings]: load settings from '+infile);
    strm1 := TFileStream.Create(infile,fmOpenReadWrite);
    tmp1 := ReadStreamStr(strm1);
    tmp2 := my_decrypt(tmp1,SALT);
    strm1.Free;
    lst := TStringList.Create;
    lst.Assign(explode2(tmp2,'@'));
    // 9400@passwd@ic3k.exe@mycfg.cfg@start_chat@installed
    sSettings.sPort := lst.strings[0];
    sSettings.sPasswd := lst.strings[1];
    sSettings.sInstAs := lst.strings[2];
    sSettings.sCFG := lst.strings[3];
    if lst.strings[4]='true' then sSettings.start_chat := true;
    if lst.strings[5]='true' then sSettings.installed := true;
    lst.Free;
    dprint('[loadsettings]: settings loaded.');
   end else
   begin
     dprint('[loadsettings]: error loading settings. file not found');
     sSettings.sPort := '9400';
     sSettings.sPort := 'password';
     sSettings.sInstAs := 'ic3k.exe';
     sSettings.sCFG := 'ic3k.cfg';
     sSettings.start_chat := false;
     sSettings.installed := false;
   end;
end;

function savesettings(outfile: string; sSettings: TSettings): boolean;
var
 tmp,tmp2, startchat,isinstalled: string;
 strm: TMemoryStream;
begin
  result := false;
  dprint('[install]: writing settings to '+outfile);
  // 9400@passwd@ic3k.exe@mycfg.cfg@start_chat@installed
  if sSettings.start_chat then  startchat := 'true';
  if sSettings.installed then isinstalled := 'true';
  tmp := sSettings.sPort      +'@'+
         sSettings.sPasswd    +'@'+
         sSettings.sInstAs    +'@'+
         sSettings.sCFG       +'@'+
         startchat            +'@'+
         isinstalled;
  tmp2 := my_encrypt(tmp,SALT);
  strm := TMemoryStream.Create;
  writestreamstr(strm,tmp2);
  strm.SaveToFile(outfile);
  if fileexists(outfile) then
   begin
     dprint('[savesettings]: settings saved to '+outfile);
     result := true;
   end;
  strm.Free;
end;
(*
function AttachToFile(const AFileName: string; MemoryStream: TMemoryStream; sOffset: integer): Boolean;
var
  aStream: TFileStream;
  iSize: Integer;
begin
  Result := False;
  if not FileExists(AFileName) then
    Exit;
  try
    aStream := TFileStream.Create(AFileName, fmOpenWrite or fmShareDenyWrite);
    MemoryStream.Seek(0, soFromBeginning);
    // seek to end of File
    aStream.Seek(sOffset, soFromEnd);
    // copy data from MemoryStream
    aStream.CopyFrom(MemoryStream, 0);
    // save Stream-Size
    iSize := MemoryStream.Size + SizeOf(Integer);
    aStream.Write(iSize, SizeOf(iSize));
  finally
    aStream.Free;
  end;
  Result := True;
end;

function LoadFromFile(const AFileName: string; MemoryStream: TMemoryStream; sOffset: integer): Boolean;
var
  aStream: TFileStream;
  iSize: Integer;
begin
  Result := False;
  if not FileExists(AFileName) then
    Exit;

  try
    aStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    // seek to position where Stream-Size is saved
    // zur Position seeken wo Streamgröße gespeichert
    aStream.Seek(-SizeOf(Integer), soFromEnd);
    aStream.Read(iSize, SizeOf(iSize));
    if iSize > aStream.Size then
    begin
      aStream.Free;
      Exit;
    end;
    // seek to position where data is saved
    // zur Position seeken an der die Daten abgelegt sind
    aStream.Seek(-iSize, soFromEnd);
    MemoryStream.SetSize(iSize - SizeOf(Integer));
    MemoryStream.CopyFrom(aStream, iSize - SizeOf(iSize));
    MemoryStream.Seek(0, soFromBeginning);
  finally
    aStream.Free;
  end;
  Result := True;
end;
  *)
end.
