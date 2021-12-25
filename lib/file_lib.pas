unit file_lib;
 {$WARNINGS OFF}
interface

uses
 windows, classes, sysutils;

function  AttachToFile(const AFileName: string; MemoryStream: TMemoryStream): Boolean;
function  LoadFromFile(const AFileName: string; MemoryStream: TMemoryStream): Boolean;
function  ReadStreamStr(Stream : TStream) : string;
function  bind_files(Files: TStrings; const DestFile: string): boolean;
procedure WriteStreamStr(Stream : TStream; Str : string);

implementation

function bind_files(Files: TStrings; const DestFile: string): boolean;
begin
 result := false;
end;

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

function AttachToFile(const AFileName: string; MemoryStream: TMemoryStream): Boolean;
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
    aStream.Seek(0, soFromEnd);
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

function LoadFromFile(const AFileName: string; MemoryStream: TMemoryStream): Boolean;
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
    aStream.Seek(-SizeOf(Integer), soFromEnd);
    aStream.Read(iSize, SizeOf(iSize));
    if iSize > aStream.Size then
    begin
      aStream.Free;
      Exit;
    end;
    // seek to position where data is saved
    aStream.Seek(-iSize, soFromEnd);
    MemoryStream.SetSize(iSize - SizeOf(Integer));
    MemoryStream.CopyFrom(aStream, iSize - SizeOf(iSize));
    MemoryStream.Seek(0, soFromBeginning);
  finally
    aStream.Free;
  end;
  Result := True;
end;

end.
