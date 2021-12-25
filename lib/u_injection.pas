unit u_injection;

interface

uses Windows, ShellAPI;

procedure Inject(ProcessHandle: longword; EntryPoint: pointer);
procedure FindAndInject(ExePath, ClassName, WindowTitle: PChar; EntryPoint : pointer);

implementation

{Inject procedure done by Aphex}
procedure Inject(ProcessHandle: integer; EntryPoint: pointer);
var
  Module, NewModule: Pointer;
  Size, BytesWritten, TID: longword;
begin
  Module := Pointer(GetModuleHandle(nil));
  Size := PImageOptionalHeader32(Pointer(integer(Module) + PImageDosHeader(Module)._lfanew + SizeOf(dword) + SizeOf(TImageFileHeader))).SizeOfImage;
  VirtualFreeEx(ProcessHandle, Module, 0, MEM_RELEASE);
  NewModule := VirtualAllocEx(ProcessHandle, Module, Size, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
  WriteProcessMemory(ProcessHandle, NewModule, Module, Size, BytesWritten);
  CreateRemoteThread(ProcessHandle, nil, 0, EntryPoint, Module, 0, TID);
end;

{This is my procedure}
procedure FindAndInject(ExePath, ClassName, WindowTitle: PChar; EntryPoint : pointer);
var
  ProcessHandle, PID : longword;
  Active : Integer;
begin
  Active := FindWindow(ClassName, WindowTitle);
  if Active = 0 then
  begin
    ShellExecute(0, 'Open', ExePath, nil, nil, 0);
    Sleep(3000);
  end;
  GetWindowThreadProcessId(FindWindow(ClassName, WindowTitle), @PID);
  ProcessHandle := OpenProcess(PROCESS_ALL_ACCESS, False, PID);
  Inject(ProcessHandle, EntryPoint);
  CloseHandle(ProcessHandle);
end;

end.
