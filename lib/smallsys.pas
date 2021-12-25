unit smallsys;

interface

uses classes;

const
  PathDelim  = {$IFDEF MSWINDOWS} '\'; {$ELSE} '/'; {$ENDIF}
  DriveDelim = {$IFDEF MSWINDOWS} ':'; {$ELSE} '';  {$ENDIF}
  PathSep    = {$IFDEF MSWINDOWS} ';'; {$ELSE} ':'; {$ENDIF}

function StrPos(const Str1, Str2: PAnsiChar): PAnsiChar; overload; deprecated 'Moved to the AnsiStrings unit';
function StrPos(const Str1, Str2: PWideChar): PWideChar; overload;
function StrScan(const Str: PWideChar; Chr: WideChar): PWideChar; overload;
function Explode2(const str: string; const separator: string): TStringList;

implementation

function ExtractFilePath(const FileName: string): string;
var
  I: Integer;
begin
  I := FileName.LastDelimiter([PathDelim {$IFDEF MSWINDOWS}, DriveDelim {$ENDIF}]);
  Result := Copy(FileName, 1, I + 1);
end;

function StrScan(const Str: PWideChar; Chr: WideChar): PWideChar;
begin
  Result := Str;
  while Result^ <> #0 do
  begin
    if Result^ = Chr then
      Exit;
    Inc(Result);
  end;
  if Chr <> #0 then
    Result := nil;
end;



function Explode2(const str: string; const separator: string): TStringList;
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
end.


