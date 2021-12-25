unit tracker_lib;

{$WARNINGS OFF}

interface

uses
 windows, classes, sysutils, ic3k_lib, HTTPSend, Synacode;

type
 TTrackerData = record
   tracker_ok: boolean;
   servername,serverhost,serverport: string;
 end;

function add_client(URL: string; tracker_data: TTrackerData; var output: string): boolean;
function get_client_info(URL: String; var TrackerData:TTrackerData): boolean;

var
 tdata: TTrackerData;

implementation

function get_client_info(URL: String; var TrackerData:TTrackerData): boolean;
var
  Response: TStringList;
  buf: string;
  i: integer;
begin
  Result := False;
  TrackerData.tracker_ok := False;
  buf := '?';
  Response := TStringList.Create;
  try
    if HttpGetText(URL+'tracker.php', Response) then
     begin
      if response.Count=0 then
      begin
        Buf := '';
        Result := False;
      end else
      begin
       buf := '';
       for i := 0 to response.Count -1 do buf := buf + response.Strings[i];
       if pos('@',buf) = 0 then
       begin
        result := false;
       end else
       begin
        //--  servername,serverhost,serverport: string;
        TrackerData.servername := explode2(buf, '@').Strings[0];
        TrackerData.serverhost := explode2(buf, '@').Strings[1];
        TrackerData.serverport := explode2(buf, '@').Strings[2];
        TrackerData.tracker_ok := True;
        Result := True;
        //streamtostring(response);
        //Response.SaveToFile('response.txt')
        end;
       end;
     end;
  finally
    Response.Free;
  end;
  //Result := Buf;
end;

function add_client(URL: string; tracker_data: TTrackerData; var output: string): boolean;
var
 Params,buf: string;
 //Params: AnsiString;
 Response: TMemoryStream;
begin
  Result := False;
  Response := TMemoryStream.Create;
  Response.Seek(0,soFromBeginning);
  try
    Params := 'servername=' + EncodeURLElement(tracker_data.servername)+ '&' +
              'serverip=' + EncodeURLElement(tracker_data.serverhost)+ '&' +
              'serverport=' + EncodeURLElement(tracker_data.serverport);
    if HttpPostURL(URL+'update.php', Params, Response) then
     begin
      buf := streamtostring(response);
      output := buf;
      Result := True;
     end;
  finally
    Response.Free;
  end;
end;

end.
