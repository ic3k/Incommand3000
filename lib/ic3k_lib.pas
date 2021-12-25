unit ic3k_lib;
{$WARNINGS OFF}
{$HINTS OFF}
interface
{$DEFINE DBG}
uses
 system.IOUtils, winapi.TlHelp32, SHFolder, windows, classes, sysutils;

const
 SERVERNAME          = 'ic3k';
 SERVERVERSION       = '1.0';
 SALT                = 1234;
 xKEY: TGUID         = '{90D04A74-5CA8-4BD6-A500-EBF4E5D1F6A8}';
 //CSIDL_STARTUP       = $0007;
 CSIDL_PERSONAL      = $0005;
 //CSIDL_MYDOCUMENTS   = $000c;
 //CSIDL_LOCAL_APPDATA = $001c;

type
 TFileCopyUpdateEvent = procedure(const SrcFile, DestFile: string;
                                  CurrentPos, MaxSize: Integer) of object;

function  GetWinDir: String;
function  Explode2(const str: string; const separator: string): TStringList;
function  MyFileCopy(SrcFile, DestFile: TFilename; OnUpdate: TFileCopyUpdateEvent = nil): boolean;
function  processexists(exeFileName: string): Boolean;
function  setfileattribs(fname: string; ro,hidden,sys,arch,comp,offln: boolean): boolean;
function  getappdatadir: string;
function  GetSpecialFolderPath(CSIDLFolder: Integer): string;
function  CreateTempFileName(aPrefix: string): string;
function  String2Hex(const Buffer: AnsiString): string;
function  Hex2String(const Buffer: string): AnsiString;
function  blockwritef(fn:string; buffer: array of char; xoffset, len: integer): boolean;
function  blockreadf(fn:string; var buffer: array of char; xoffset, len: integer): boolean;
function  fgetfilesize(const aFilename: String): Int64;
function  StreamToString(aStream: TStream): string;
procedure explodeX(const str: string; const separator: string; var List: TStringList);
procedure dread(var s: string);
procedure dprint(txt: string);
procedure dprint2(txt: string);
procedure addspace(fname: string; data: char; len: integer);

implementation
function StreamToString(aStream: TStream): string;
var
  SS: TStringStream;
begin
  if aStream <> nil then
  begin
    SS := TStringStream.Create('');
    try
      SS.Clear;
      SS.CopyFrom(aStream, 0);  // No need to position at 0 nor provide size
      Result := SS.DataString;
    finally
      SS.Free;
    end;
  end else
  begin
    Result := '';
  end;
end;

function fgetfilesize(const aFilename: String): Int64;
var
 info: TWin32FileAttributeData;
begin
 result := -1;
  if NOT GetFileAttributesEx(PWideChar(aFileName), GetFileExInfoStandard, @info) then
      EXIT;
   result := Int64(info.nFileSizeLow) or Int64(info.nFileSizeHigh shl 32);
end;

function blockwritef(fn:string; buffer: array of char; xoffset, len: integer): boolean;
var
  f : file;
  i : Integer;
begin
  AssignFile(f,fn);
  {$I-}
  reset(f,1);
  {$I+}
  if IOResult <> 0 then
  begin
    dprint('[err]: FileNotFound '+fn);
    exit;
  end;

  Seek(f, xoffset);
  for i := 0 to len-1 do
   begin
    //BlockWrite(f, buffer, sizeof(buffer));
    BlockWrite(f, buffer[i],1);
   end;
  closefile(f);
end;

function blockreadf(fn:string; var buffer: array of char; xoffset, len: integer): boolean;
var
  f : file;
  i : Integer;
  //buf : array[0..9] of Byte;
begin
  result := false;
  AssignFile(f,fn);
  {$I-}
  reset(f,1);
  {$I+}
  if IOResult <> 0 then
  begin
    dprint('[err]: FileNotFound '+fn);
    exit;
  end;

  Seek(f, xoffset-len);
  //dprint('[info]: seek to '+inttostr(xoffset));
  //BlockRead(f, buffer,sizeof(buffer));
  for i := 0 to len-1 do
   begin
    BlockRead(f, buffer[i],1);
   end;
  closefile(f);
end;

function String2Hex(const Buffer: AnsiString): string;
begin
  SetLength(Result, Length(Buffer) * 2);
  BinToHex(PAnsiChar(Buffer), PChar(Result), Length(Buffer));
end;

function Hex2String(const Buffer: string): AnsiString;
begin
  SetLength(Result, Length(Buffer) div 2);
  HexToBin(PChar(Buffer), PAnsiChar(Result), Length(Result));
end;

procedure addspace(fname: string; data: char; len: integer);
var
 f: file;
 i: integer;
begin
 {$I-}
 dprint('[addsize]: adding '+inttostr(len)+' to '+fname);
 assign(f,fname);
 reset(f,1);
 seek(f,filesize(f));
 for i:=0 to len do
 begin
  dprint2('.');
  blockwrite(f,data,1);
 end;
 close(f);
 {$I+}
end;


(*
function get_str_from_exe(fn: TFileName; offset: integer): string;
var
  fs: TFileStream;
  b: byte;
  bf: array[0..3] of word;
  buffer: string;
  ReadResult: integer;
begin
  buffer := '';
  fs := TFileStream.Create(fn, fmOpenRead or fmShareDenyWrite);
  try

    fs.Seek(offset, soFromBeginning);    // move to offset $28 in the file
    fs.ReadBuffer(bf, 10);                // read 4 x 2 bytes into buffer (bf)
    )                                     // fs.Position is at this point at $30
    fs.ReadBuffer(b, 1);                 // read one byte (at offset $30) into the buffer (b)
  finally
    fs.free;
  end;
  result := buffer;
end;
*)

function CreateTempFileName(aPrefix: string): string;
var
  Buf: array[0..MAX_PATH] of Char;
  Temp: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, Buf);
  if GetTempFilename(Buf, PChar(aPrefix), 0, Temp) = 0 then
  begin
    dprint('[error]: CreateTempFileName error getting tmpfilename');
    Result := aPrefix;
    exit;
    //raise Exception.CreateFmt(sWin32Error, [GetLastError, SysErrorMessage(GetLastError)]);
  end;
  Result := string(Temp);
end;

function GetSpecialFolderPath(CSIDLFolder: Integer): string;
var
   FilePath: array [0..MAX_PATH] of char;
begin
  SHGetFolderPath(0, CSIDLFolder, 0, 0, FilePath);
  Result := IncludeTrailingPathDelimiter(FilePath);
end;

procedure dprint(txt: string);
begin
  {$IFDEF DBG}
   writeln(txt);
  {$ENDIF}
end;

procedure dprint2(txt: string);
begin
  {$IFDEF DBG}
   write(txt);
  {$ENDIF}
end;

procedure dread(var s: string);
begin
  {$IFDEF DBG}
   readln(s);
  {$ENDIF}
end;

function getappdatadir: string;
var
  Path: string;
begin
  // GetHomePath() uses SHGetFolderPath(CSIDL_APPDATA) internally...
  Path := SysUtils.GetHomePath;
  if Path <> '' then
    Result := IncludeTrailingPathDelimiter(Path)
  else
    Result := '';
end;

function setfileattribs(fname: string; ro,hidden,sys,arch,comp,offln: boolean): boolean;
var
  LFileAttributes: TFileAttributes;
begin
 Result := False;
 if FileExists(fname) then
 begin
  if ro then
     Include(LFileAttributes, TFileAttribute.faReadOnly);
  if hidden then
     Include(LFileAttributes, TFileAttribute.faHidden);
  if sys then
     Include(LFileAttributes, TFileAttribute.faSystem);
  if arch then
     Include(LFileAttributes, TFileAttribute.faArchive);
  if comp then
     Include(LFileAttributes, TFileAttribute.faCompressed);
  if offln then
     Include(LFileAttributes, TFileAttribute.faOffline);
  TFile.SetAttributes(fname, LFileAttributes);
  Result := True;
 end;
end;

function processexists(exeFileName: string): Boolean;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  FSnapshotHandle        := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop           := Process32First(FSnapshotHandle, FProcessEntry32);
  Result := False;

  while Integer(ContinueLoop) <> 0 do
  begin

    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
    begin
      Result := True;
    end;

    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function explode2(const str: string; const separator: string): TStringList;
var     n: integer;
        p, q, s: PChar;
        item: string;
begin
Result := TStringList.Create;
try
        p := PChar(str);
        s := PChar(separator);
        n := Length(separator);
        repeat
                q := StrPos(p, s);
                if q = nil then q := StrScan(p, #0);
                SetString(item, p, q - p);
                Result.Add(item);
                p := q + n;
        until q^ = #0;
except
        item := '';
        Result.Free;
        raise;
        end;
end;

procedure explodeX(const str: string; const separator: string; var List: TStringList);
var     n: integer;
        p, q, s: PChar;
        item: string;
begin
try
        p := PChar(str);
        s := PChar(separator);
        n := Length(separator);
        repeat
                q := StrPos(p, s);
                if q = nil then q := StrScan(p, #0);
                SetString(item, p, q - p);
                List.Add(item);
                p := q + n;
        until q^ = #0;
except
        item := '';
        raise;
        end;
end;

function GetWinDir: String;
var
dir : array [0..max_path] of char;
begin
 GetWindowsDirectory(dir, max_path);
 result:=StrPas(dir)+'\';
end;

function Min(Val1, Val2: Integer): Integer;
begin
  Result := Val1;
  if Val2 < Val1 then
    Result := Val2;
end;

function MyFileCopy(SrcFile, DestFile: TFilename; OnUpdate: TFileCopyUpdateEvent = nil): boolean;
const
  StreamBuf = 4096;
var
  Src, Dst: TFileStream;
  BufCount: Integer;
begin
  Result := False;
  Src := nil;
  Dst := nil; {prevents .Free problems on exception}
  {allow everyone else any access}
  Src := TFileStream.Create(SrcFile, fmOpenRead or fmShareDenyNone);
  if src.Size=0 then dprint('[myfilecopy]: src size 0');

  if FileExists(DestFile) then
    {this could cause an error if a user has the file open}
    Dst := TFileStream.Create(DestFile, fmOpenWrite or fmShareExclusive)
  else
    Dst := TFileStream.Create(DestFile, fmCreate or fmShareExclusive);
    dprint('[myfilecopy]: stream created');
    Result := True;
  try
    while Dst.Position < Dst.Size do
    begin
      BufCount := Min(StreamBuf, Dst.Size - Dst.Position);
      Src.CopyFrom(Dst, BufCount);
      dprint('[myfilecopy]: progress '+inttostr(bufcount));
      if Assigned(OnUpdate) then {report progress every 4k}
        OnUpdate(SrcFile, DestFile, Dst.Position, Dst.Size);
    end;
  finally
    Src.Free;
    Dst.Free;
  end;
end;
end.
