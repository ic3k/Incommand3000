(*
  WRITEEXE.PAS - Unit for writing typed constants to an executable.
  ==================================================================
  Written 21 Feb 1996 by Robert B. Clark <rcl...@iquest.net>
  Donated to the public domain.  Turbo Pascal v7.0 (compat v6.0+).
  Requires DOS v3.0 or later.
  PURPOSE:
  ========
  Update the value of any typed constant variable in an executable so
  that it will be available in subsequent runs of the program.  Useful
  for storing passwords or configuration data inside an executable.
  NOTES:
  ======
  The data to write MUST be a typed constant, declared in your Turbo
  Pascal program as
      CONST <object>: <objectType> = <value>;
  Variables of this type are stored in your executable's data segment.
  They may be located within the executable by taking the segment and
  offset of the variable in memory and offsetting it by the executable
  header size on disk, corrected for by the size of the OS-generated
  program segment prefix (PSP), which is always 256 bytes.
  The executable header size is stored as a two-byte word at offset 8 in
  the .EXE file and represents the number of 16-byte paragraphs in the
  header.  The PSP segment address may be obtained via the PrefixSeg
  variable.
  The offset of the object variable may be expressed in Turbo Pascal by
  the following code:
  objectVarOfs := 16 * (ExeHeaderSize + Seg(objectVar) - PrefixSeg) +
      Ofs(objectVar) - SizeOfPSP;
  Note that on a PC, a segment:offset memory address pair may be
  converted to a flat address by multiplying the segment by 16 and
  adding the offset.
  Once the object variable has been located within the executable, it's
  a simple matter of using BlockWrite to write the new value over the
  existing one.  The object variable will have the new value the next
  time the executable is run.
  This source file uses a unit named Convert if "Debug" is defined at
  compile time.  My Convert unit contains functions to convert decimal
  numbers to hexadecimal bytes, words or doublewords.  These functions
  are used only at the end of the Write2EXE() function, so you may snip
  that section of code out and safely remove Convert from the Uses
  clause if you like.  Or you can just make sure that "Debug" is not
  defined at compilation.
  EXAMPLE USAGE:
  ==============
  Program TestWrite2Exe;
  Uses WriteExe;
  TYPE   objectType = string;
  CONST  password: objectType = 'drowssap';
  BEGIN
      Writeln;
      Writeln('Old password: "',password,'"');
      Write('Enter new password: ');
      Readln(password);
      Writeln;
      Write('Password ');
      If Not Write2Exe(password, SizeOf(password)) then
         Write('NOT ');
      Writeln('updated successfully.');
      Writeln;
      Writeln('The new value (if any) will be initialized the next');
      Writeln('time this executable is run.')
  END.
*)
Unit WriteExe;
{ =================================================================== }
INTERFACE
Uses  windows;
FUNCTION Write2EXE(var objectVar; objectVarSize: word): boolean;
{ Writes the value of 'objectVar' (which must be a typed constant) to
  this executable file.  'objectVarSize' is the size of the variable.
  The executable's filespec is retrieved via ParamStr(0), and so this
  procedure requires DOS v3.x or later.
  Returns true if no errors were encountered; otherwise false. }
{ =================================================================== }
IMPLEMENTATION
procedure ErrMsg(s: string; code: integer);
{ Prints error message to stderr }
VAR stderr: TEXT;
begin
   Assign(stderr,'');
   Rewrite(stderr);             { Writing to stdout }
   //TextRec(stderr).Handle:=2;   { Force handle to stderr }
   //TextRec(stderr).BufSize:=1;  { Needed to correct odd behavior? }
   writeln(stderr,#7,s,' (Error ',code,')')
end; {ErrMsg}
function GetEXEHeader(var f: FILE): word;
{ Returns EXE header length word (in paragraphs) for executable file or
  0 if error.  Executable file should already be opened for read on f;
  the file pointer will be just after the EXE header size field upon
  exit from this function. }
VAR IOError: integer;
    hdrsize: word;
begin
    hdrsize:=0;
    {$I-}
    Seek(f,8);             { EXE header size at offset 8 in file }
    IOError:=IOResult;
    if IOError = 0 then
    begin                  { Read header size (in paragraphs) }
       BlockRead(f, hdrsize, SizeOf(hdrsize));
       IOError := IOResult
    end;
    if IOError <> 0 then hdrsize := 0;    { hdrsize=0 if IOError}
    {$I+}
    GetExeHeader:=hdrsize
end; {GetEXEHeader}
FUNCTION Write2Exe(var objectVar; objectVarSize: word): boolean;
{ Writes new value of 'objectVar' to this executable file.
  Returns true if no errors. }
VAR f: FILE;                { Must be an untyped file }
    programName: string;    { This executable's filespec }
    IOError: integer;       { You should know this one }
    exeHdrSize: word;       { Size of EXE header in paragraphs }
    objectVarOfs: longint;  { Offset of objectVar in EXE file }
CONST SizeOfPSP = 256;      { Size of program segment prefix }
begin
   programName:=ParamStr(0);    { Full filespec of this executable }
   {$I-}
   Assign(f,programName);  { Open this executable file for }
   Reset(f,1);             { read access, blocksize=1 }
   IOError:=IOResult;
   if IOError <> 0 then
      ErrMsg('Could not read executable '+programName,IOError)
   else
   begin
      exeHdrSize:=GetEXEHeader(f);  { Size of EXE hdr in paragraphs }
      if exeHdrSize <> 0 then       { Seek objectVar offset in file }
      begin                         { Calc. file offset of objectVar }
         objectVarOfs := LongInt(16) * (exeHdrSize + Seg(objectVar) -
            PrefixSeg) + Ofs(objectVar) - SizeOfPSP;
         Seek(f, objectVarOfs);
         IOError := IOResult;
         if IOError = 0 then     { Write new objectVar in executable }
         begin
            BlockWrite(f,objectVar,objectVarSize);
            IOError:=IOResult;
            if IOError <> 0 then
               ErrMsg('Could not update executable.',IOError)
         end
         else ErrMsg('Could not find value to change.',IOError);
      end;
      Close(f);
   end;  {if exeHdrSize read successfully}
   {$I+}
   Write2Exe:=IOError=0
{$IFDEF Debug}   { Uses HexWord() and HexDWord() from Convert.TPU }
   ;
   writeln(#10#13'The executable file is       ',programName);
   writeln('Memory address of objectVar: ',HexWord(Seg(objectVar)),
      ':', HexWord(Ofs(objectVar)));
   writeln('objectVarSize:               ',objectVarSize);
   writeln('PSP segment address:         ',HexWord(PrefixSeg));
   writeln('EXE header length word:      ',HexWord(exeHdrSize));
   writeln('File offset of objectVar:    ',HexDWord(objectVarOfs));
   writeln('Write2Exe result code:       ',IOError=0)
{$ENDIF}
end; {Write2Exe}
BEGIN
   if Swap(DOSVersion) < $0300 then   { Req DOS v3+ for ParamStr(0) }
   begin
       ErrMsg('This program requires DOS v3.0 or later.',255);
       Halt(255)
   end;
END.
