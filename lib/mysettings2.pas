unit mysettings2;
{$WARNINGS OFF}
{$HINTS OFF}
interface

uses
 windows, classes, sysutils, ic3k_lib, file_lib, mycrypt;

//  mPort, hPort, sPasswd, sCFG, tracker_url, installed, start_chat, host_addr, use_tracker
//  9400@8080@passwd@ic3k.cfg@http://kj6ywd.net/ic3k/tracker.php@1@1@192.168.1.164@1
type
 TSettings = record
   mPort, hPort, sPasswd, sCFG, tracker_url, installed, start_chat, host_addr, use_tracker: string;
end;

function loadsettings(infile: string; var fSettings: TSettings): boolean;
function savesettings(outfile, buff: string): boolean;

implementation

function loadsettings(infile: string; var fSettings: TSettings): boolean;
var
 strm: TMemoryStream;
 buff: string;
 lst: TStringList;
 i: integer;
begin
 strm := TMemoryStream.Create;
 result := loadfromfile(infile,strm);
 if result then
 begin
  buff := my_decrypt(readstreamstr(strm), SALT);
  strm.free;
  lst := TSTringList.Create;
  lst.Assign(explode2(buff,'@'));
  //  mPort, hPort, sPasswd, sCFG, tracker_url, installed, start_chat, host_addr, use_tracker
  //  9400@8080@passwd@ic3k.cfg@http://kj6ywd.net/ic3k/tracker.php@1@1@192.168.1.164@1
  fSettings.mPort       := lst.strings[0];
  fSettings.hPort       := lst.strings[1];
  fSettings.sPasswd     := lst.strings[2];
  fSettings.sCFG        := lst.strings[3];
  fSettings.tracker_url := lst.strings[4];
  fSettings.installed   := lst.strings[5];
  fSettings.start_chat  := lst.strings[6];
  fSettings.host_addr   := lst.strings[7];
  fSettings.use_tracker := lst.Strings[8];
  lst.free;
 end;
end;

function savesettings(outfile, buff: string): boolean;
var
 strm: TMemoryStream;
begin
 strm := TMemoryStream.Create;
 buff := my_encrypt(buff,SALT);
 writestreamstr(strm,buff);
 result := AttachToFile(outfile,strm);
 strm.free;
end;

end.
