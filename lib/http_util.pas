unit http_util;

interface

uses
 ic3k_lib, httpsend, synacode, windows, classes;

type
 TTrackerData = record
   my_username, remote_host, remote_port: string;
 end;

procedure update_tracker(URL, server_name,server_host,server_port,seed: string);
function  get_tracker_data(fAddr: string; output: TStringList): string;

implementation

function get_tracker_data(fAddr: string; output: TStringList): string;
var
 HTTP: THTTPSend;
begin
 try
   HTTP.HTTPMethod('GET', FAddr);
   output.LoadFromStream(HTTP.Document);
 finally
   HTTP.Free;
  end;
 result := '';
end;

procedure update_tracker(URL, server_name,server_host,server_port,seed: string);
var
 Params,Buf: string;
 Response: TMemoryStream;
begin
  dprint('[tracker]: contacting '+URL);
  Response := TMemoryStream.Create;
  Response.Seek(0,soFromBeginning);
  try
    Params := 'servername=' + EncodeURLElement(server_name)+ '&' +
              'serverhost=' + EncodeURLElement(server_host)+ '&' +
              'serverport=' + EncodeURLElement(server_port)+ '&' +
              'seed='       + EncodeURLElement(seed);

    dprint('[tracker]: URL: '+URL+' Params: '+ Params);
    if HttpPostURL(URL, Params, Response) then
     begin
      dprint('[tracker]: retrieved: '+ StreamToString(Response));
      buf := streamtostring(response);
      //Response.SaveToFile('response.txt')
     end;
  finally
    Response.Free;
  end;
end;

end.
