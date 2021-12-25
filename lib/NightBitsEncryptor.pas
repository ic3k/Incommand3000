  unit NightBitsEncryptor;

   //TODO: Update the hex to String and the String to Hex to work with delphi 2009 or later

  interface

  type

   TNightBitsEncryptor = Class

     private

     function convertStringToHex(const value: AnsiString) : AnsiString;
     function convertHexToString(const value: AnsiString) : AnsiString;
     function generateHashKey(const key: WideString) : Integer;

     function encryptData(const key, source: AnsiString) : AnsiString;

     published
       constructor create();
       function encrypt(const key, data: AnsiString) : AnsiString;
       function decrypt(const key, data: AnsiString) : AnsiString;
   end;

 implementation

uses
  SysUtils,
  Classes;

// Create the constructor
constructor TNightBitsEncryptor.Create();
begin
  // Do nothing
end;

function TNightBitsEncryptor.convertStringToHex(const value: AnsiString) : AnsiString;
var
  i:integer;
begin
  result := '';
  for i := 1 to length(value) do
    result := result + inttohex(Ord(value[i]),1);
end;

function TNightBitsEncryptor.convertHexToString(const value: AnsiString) : AnsiString;
var
  i:integer;
begin
  result := '';
  for i := 1 to (length(value) div 2) do
    result := result + char( strtoint('$'+ copy(value,(i*2)-1,2)) );
  end;

  function TNightBitsEncryptor.generateHashKey(const key: WideString) : Integer;
  var
  Index: Integer;
  begin
    Result := 0;
    for Index := 1 to Length(key) * 2 do
      Result := ((Result shl 11) or (Result shr 21)) + Ord(key[Index]);
  end;


function TNightBitsEncryptor.encryptData(const key, source: AnsiString) : AnsiString;
const
  oneIntegerBuffer = SizeOf(Integer);  // Integer = 4 bytes
  oneByteBuffer = SizeOf(Byte); // Byte = 1 byte
var
  byteBuffer,
  buffer,
  index,
  specialKey: Integer;
  StreamOut,
  StreamIn: TStringStream;
begin
  // Generate a hashKey
  specialKey := generateHashKey(key);
  StreamIn := TStringStream.Create(source);
  StreamOut := TStringStream.Create('');

  // Reset the Stream positions
  StreamIn.Position := 0;
  StreamOut.Position := 0;

  while (StreamIn.Position < StreamIn.Size) and
    ((StreamIn.Size -StreamIn.Position) >= oneIntegerBuffer)
    do begin
    // Read 4 bytes into the integer variable
    StreamIn.ReadBuffer(buffer, oneIntegerBuffer);

    // Create the xor encryption
    buffer := buffer xor specialKey;
    buffer := buffer xor $E0F;

    // Write the buffer to the outputStream
    StreamOut.WriteBuffer(buffer, oneIntegerBuffer);
  end;

  // Check if we still have bytes left
  if (StreamIn.Size -StreamIn.Position) >= 1 then

  // Write the bytes (one at a time) into the buffer
    for index := StreamIn.Position to StreamIn.Size -1 do begin
      StreamIn.ReadBuffer(byteBuffer, oneByteBuffer);

      // Create the xor encryption
      byteBuffer := byteBuffer xor $F;

      // Write the buffer to the outputStream
      StreamOut.WriteBuffer(byteBuffer, oneByteBuffer);
    end;

  // Reset the outputStream position
  StreamOut.Position := 0;

  // Read the data from the outputStream into the result (so we can return it)
  Result := StreamOut.ReadString(StreamOut.Size);

  // Free the used allocated memory
  FreeAndNil(StreamIn);
  FreeAndNil(StreamOut);
end;

function TNightBitsEncryptor.encrypt(const key, data: AnsiString): AnsiString;
begin
  Result := encryptData(key, data);

  //TODO: Modify the string to hex so it works with delphi 2009 and later
  //Result := convertStringToHex(Result);
end;

function TNightBitsEncryptor.decrypt(const key, data: AnsiString): AnsiString;
begin
 //TODO: Modify the hex to string so it works with delphi 2009 and later
  //Result := convertHexToString(data);
  Result := encryptData(key, Result);
end;

 end.
