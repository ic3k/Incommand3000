{ uExecFromMem
  Author: steve10120
  Description: Run an executable from another's memory.
  Credits: Tan Chew Keong: Dynamic Forking of Win32 EXE; Author of BTMemoryModule: PerformBaseRelocation().
  Reference: http://www.security.org.sg/code/loadexe.html
  Release Date: 26th August 2009
  Website: http://ic0de.org
  History: First try
  Additions by testest 15th July 2010:
    - Parameter support
    - Win7 x64 support
}
unit uExecFromMem;

interface

uses Windows;

function ExecuteFromMem(szFilePath, szParams: string; pFile: Pointer):DWORD;
implementation
function NtUnmapViewOfSection(ProcessHandle:DWORD; BaseAddress:Pointer):DWORD; stdcall; external 'ntdll';
type
  PImageBaseRelocation = ^TImageBaseRelocation;
  TImageBaseRelocation = packed record
     VirtualAddress: DWORD;
     SizeOfBlock: DWORD;
  end;
procedure PerformBaseRelocation(f_module: Pointer; INH:PImageNtHeaders; f_delta: Cardinal); stdcall;
var
  l_i: Cardinal;
  l_codebase: Pointer;
  l_relocation: PImageBaseRelocation;
  l_dest: Pointer;
  l_relInfo: ^Word;
  l_patchAddrHL: ^DWord;
  l_type, l_offset: integer;
begin
  l_codebase := f_module;
  if INH^.OptionalHeader.DataDirectory[5].Size > 0 then
  begin
    l_relocation := PImageBaseRelocation(Cardinal(l_codebase) + INH^.OptionalHeader.DataDirectory[5].VirtualAddress);
    while l_relocation.VirtualAddress > 0 do
    begin
      l_dest := Pointer((Cardinal(l_codebase) + l_relocation.VirtualAddress));
      l_relInfo := Pointer(Cardinal(l_relocation) + 8);
      for l_i := 0 to (trunc(((l_relocation.SizeOfBlock - 8) / 2)) - 1) do
      begin
        l_type := (l_relInfo^ shr 12);
        l_offset := l_relInfo^ and $FFF;
        if l_type = 3 then
        begin
          l_patchAddrHL := Pointer(Cardinal(l_dest) + Cardinal(l_offset));
          l_patchAddrHL^ := l_patchAddrHL^ + f_delta;
        end;
        inc(l_relInfo);
      end;
      l_relocation := Pointer(cardinal(l_relocation) + l_relocation.SizeOfBlock);
    end;
  end;
end;
function AlignImage(pImage:Pointer):Pointer;
var
  IDH:          PImageDosHeader;
  INH:          PImageNtHeaders;
  ISH:          PImageSectionHeader;
  i:            WORD;
begin
  IDH := pImage;
  INH := Pointer(Integer(pImage) + IDH^._lfanew);
  GetMem(Result, INH^.OptionalHeader.SizeOfImage);
  ZeroMemory(Result, INH^.OptionalHeader.SizeOfImage);
  CopyMemory(Result, pImage, INH^.OptionalHeader.SizeOfHeaders);
  for i := 0 to INH^.FileHeader.NumberOfSections - 1 do
  begin
    ISH := Pointer(Integer(pImage) + IDH^._lfanew + 248 + i * 40);
    CopyMemory(Pointer(DWORD(Result) + ISH^.VirtualAddress), Pointer(DWORD(pImage) + ISH^.PointerToRawData), ISH^.SizeOfRawData);
  end;
end;
function Get4ByteAlignedContext(var Base: PContext): PContext;
begin
  Base := VirtualAlloc(nil, SizeOf(TContext) + 4, MEM_COMMIT, PAGE_READWRITE);
  Result := Base;
  if Base <> nil then
    while ((DWORD(Result) mod 4) <> 0) do
      Result := Pointer(DWORD(Result) + 1);
end;
function ExecuteFromMem(szFilePath, szParams:string; pFile:Pointer):DWORD;
var
  PI:           TProcessInformation;
  SI:           TStartupInfo;
  CT:           PContext;
  CTBase:       PContext;
  IDH:          PImageDosHeader;
  INH:          PImageNtHeaders;
  dwImageBase:  DWORD;
  pModule:      Pointer;
  dwNull:       NativeUint; //DWORD;
begin
  if szParams <> '' then szParams := '"'+szFilePath+'" '+szParams;
  Result := 0;
  IDH := pFile;
  if IDH^.e_magic = IMAGE_DOS_SIGNATURE then
  begin
    INH := Pointer(Integer(pFile) + IDH^._lfanew);
    if INH^.Signature = IMAGE_NT_SIGNATURE then
    begin
      FillChar(SI, SizeOf(TStartupInfo), #0);
      FillChar(PI, SizeOf(TProcessInformation), #0);
      SI.cb := SizeOf(TStartupInfo);
      if CreateProcess(PChar(szFilePath), PChar(szParams), nil, nil, FALSE, CREATE_SUSPENDED, nil, nil, SI, PI) then
      begin
        CT := Get4ByteAlignedContext(CTBase);
        if CT <> nil then
        begin
          CT.ContextFlags := CONTEXT_FULL;
          if GetThreadContext(PI.hThread, CT^) then
          begin
            ReadProcessMemory(PI.hProcess, Pointer(CT.Ebx + 8), @dwImageBase, 4, dwNull);
            if dwImageBase = INH^.OptionalHeader.ImageBase then
            begin
              if NtUnmapViewOfSection(PI.hProcess, Pointer(INH^.OptionalHeader.ImageBase)) = 0 then
                pModule := VirtualAllocEx(PI.hProcess, Pointer(INH^.OptionalHeader.ImageBase), INH^.OptionalHeader.SizeOfImage, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE)
              else
                pModule := VirtualAllocEx(PI.hProcess, nil, INH^.OptionalHeader.SizeOfImage, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
            end
            else
              pModule := VirtualAllocEx(PI.hProcess, Pointer(INH^.OptionalHeader.ImageBase), INH^.OptionalHeader.SizeOfImage, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
            if pModule <> nil then
            begin
              pFile := AlignImage(pFile);
              if DWORD(pModule) <> INH^.OptionalHeader.ImageBase then
              begin
                PerformBaseRelocation(pFile, INH, (DWORD(pModule) - INH^.OptionalHeader.ImageBase));
                INH^.OptionalHeader.ImageBase := DWORD(pModule);
                CopyMemory(Pointer(Integer(pFile) + IDH^._lfanew), INH, 248);
              end;
              WriteProcessMemory(PI.hProcess, pModule, pFile, INH.OptionalHeader.SizeOfImage, dwNull);
              WriteProcessMemory(PI.hProcess, Pointer(CT.Ebx + 8), @pModule, 4, dwNull);
              CT.Eax := DWORD(pModule) + INH^.OptionalHeader.AddressOfEntryPoint;
              SetThreadContext(PI.hThread, CT^);
              ResumeThread(PI.hThread);
              Result := PI.hThread;
            end;
          end;
          VirtualFree(CTBase, 0, MEM_RELEASE);
        end;
        if Result = 0 then
          TerminateProcess(PI.hProcess, 0);
      end;
    end;
  end;
end;
end.



(*
var
eu:array of byte;
FS:TFileStream;
CONT:TContext;
imgbase,btsIO:DWORD;
IDH:PImageDosHeader;
INH:PImageNtHeaders;
ISH:PImageSectionHeader;
i:Integer;
PInfo:TProcessInformation;
SInfo:TStartupInfo;
begin
if OpenDialog1.Execute then
  begin
    FS:=TFileStream.Create(OpenDialog1.FileName,fmOpenRead or fmShareDenyNone);
    SetLength(eu,FS.Size);
    FS.Read(eu[0],FS.Size);
    FS.Free;
    Sinfo.cb:=Sizeof(TStartupInfo);
    CreateProcess(nil,Pchar(paramstr(0)),nil,nil,FALSE,CREATE_SUSPENDED,nil,nil,SInfo,PInfo);
    IDH:=@eu[0];
    INH:=@eu[IDH^._lfanew];
    imgbase:=DWORD(VirtualAllocEx(PInfo.hProcess,Ptr(INH^.OptionalHeader.ImageBase),INH^.OptionalHeader.SizeOfImage,MEM_COMMIT or MEM_RESERVE,PAGE_EXECUTE_READWRITE));
    ShowMessage(IntToHex(imgbase,8));
    WriteProcessMemory(PInfo.hProcess,Ptr(imgbase),@eu[0],INH^.OptionalHeader.SizeOfHeaders,btsIO);
    for i:=0 to INH^.FileHeader.NumberOfSections - 1 do
      begin
          ISH:=@eu[IDH^._lfanew + Sizeof(TImageNtHeaders) + i * Sizeof(TImageSectionHeader)];
          WriteProcessMemory(PInfo.hProcess,Ptr(imgbase + ISH^.VirtualAddress),@eu[ISH^.PointerToRawData],ISH^.SizeOfRawData,btsIO);
      end;
    CONT.ContextFlags:=CONTEXT_FULL;
    GetThreadContext(PInfo.hThread,CONT);
    CONT.Eax:=imgbase + INH^.OptionalHeader.AddressOfEntryPoint;
    WriteProcessMemory(PInfo.hProcess,Ptr(CONT.Ebx+8),@imgbase,4,btsIO);
    ShowMessage('Press ok on ENTER');
    SetThreadContext(PInfo.hThread,CONT);
    ResumeThread(PInfo.hThread);
    CloseHandle(Pinfo.hThread);
    CloseHandle(PInfo.hProcess);
  end;
end;


 3

To get opc0de's answer working on both 32bit and 64bit platforms change the context setting as follows,

   GetThreadContext(PInfo.hThread,CONT);
   {$IFDEF WIN64}
      CONT.P6Home:=imgbase + INH^.OptionalHeader.AddressOfEntryPoint;
      WriteProcessMemory(PInfo.hProcess,Ptr(CONT.P3Home+8),@imgbase,4,btsIO);
   {$ELSE}
      CONT.Eax:=imgbase + INH^.OptionalHeader.AddressOfEntryPoint;
      WriteProcessMemory(PInfo.hProcess,Ptr(CONT.Ebx+8),@imgbase,4,btsIO);
   {$ENDIF}
   ShowMessage('Press ok on ENTER');
   SetThreadContext(PInfo.hThread,CONT);

*)
