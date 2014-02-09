unit VirtualizeClass;

interface

uses Windows, Sysutils, Classes, Dialogs;

const
  C_LINK: array [0 .. 23] of Byte = ($FE, $23, $A4, $28, $2F, $E3, $9C, $64, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00);

type
  TAddVectoredExceptionHandler = procedure(dwFirst: Dword; Filter: Pointer); stdcall;

  TRegisters = record
    Temp: Dword;
    Eax, Ebx, Ecx, Edx, Esi, Edi, Ebp, Esp, Eip, EFlags: Dword;
  end;

  TVirtualize = class(TObject)
  private
    FDatabase: Dword;
    FDataOffset, FDataSize, FPointerOffset, FPointerSize: Dword;

    procedure LoadDatabase;
    procedure ParseOneInstruction(var vAddress: Dword; var Registers: TRegisters);
  public
    constructor Create;

    function GetStructureFromAddress(Address: Dword): Dword;

    procedure ProcessInstruction(Address: Dword; var Registers: TRegisters);
  end;

function VirtualizeInitialize: Boolean;

var
  Virtualize: TVirtualize;

implementation

var
  AddVectoredExceptionHandler: TAddVectoredExceptionHandler;

function VirtualizeHandleException(var IPointer: EXCEPTION_POINTERS): Integer; stdcall;
var
  a: String;
  r: TRegisters;
begin
  Result:=0;
  if IPointer.ExceptionRecord.ExceptionCode = $40010006 then
    Exit;
  if IPointer.ExceptionRecord.ExceptionCode = EXCEPTION_PRIV_INSTRUCTION then
  begin
    {* Load Vm Context *}
    r.Eax:=IPointer.ContextRecord.Eax;
    r.Ebx:=IPointer.ContextRecord.Ebx;
    r.Ecx:=IPointer.ContextRecord.Ecx;
    r.Edx:=IPointer.ContextRecord.Edx;
    r.Esi:=IPointer.ContextRecord.Esi;
    r.Edi:=IPointer.ContextRecord.Edi;
    r.Ebp:=IPointer.ContextRecord.Ebp;
    r.Esp:=IPointer.ContextRecord.Esp;
    r.Eip:=IPointer.ContextRecord.Eip;
    r.EFlags:=IPointer.ContextRecord.EFlags;
    Virtualize.ProcessInstruction(IPointer.ContextRecord.Eip, r);
    IPointer.ContextRecord.Eax:=r.Eax;
    IPointer.ContextRecord.Ebx:=r.Ebx;
    IPointer.ContextRecord.Ecx:=r.Ecx;
    IPointer.ContextRecord.Edx:=r.Edx;
    IPointer.ContextRecord.Esi:=r.Esi;
    IPointer.ContextRecord.Edi:=r.Edi;
    IPointer.ContextRecord.Ebp:=r.Ebp;
    IPointer.ContextRecord.Esp:=r.Esp;
    IPointer.ContextRecord.Eip:=r.Eip;
    IPointer.ContextRecord.EFlags:=r.EFlags;
    Result:= -1;
  end;
end;

function VirtualizeInitialize: Boolean;
begin
  Virtualize:=TVirtualize.Create;
  Result:=True;
end;

constructor TVirtualize.Create;
begin
  {* Obtain Variable Data *}
  FDataOffset:=pDword(Dword(@C_LINK[0]) + 8)^;
  FDataSize:=pDword(Dword(@C_LINK[0]) + 12)^;
  FPointerOffset:=pDword(Dword(@C_LINK[0]) + 16)^;
  FPointerSize:=pDword(Dword(@C_LINK[0]) + 20)^;
  if FDataOffset <> 0 then
  begin
    {* Initialize Exception Handlers *}
    @AddVectoredExceptionHandler:=GetProcAddress(LoadLibrary(kernel32), 'AddVectoredExceptionHandler');
    AddVectoredExceptionHandler(1, @VirtualizeHandleException);
    LoadDatabase;
  end;
end;

function TVirtualize.GetStructureFromAddress(Address: Dword): Dword;
var
  i: Integer;
  a: Dword;
begin
  Result:=0;
  {* Find Instruction Structure from Address *}
  a:=FDatabase + FPointerOffset - FDataOffset;
  for i:=0 to FPointerSize - 1 do
  begin
    if pDword(a)^ + hInstance = Address then
    begin
      Result:=FDatabase + pDword(a + 4)^;
      Exit;
    end;
    inc(a, 8);
  end;
end;

procedure TVirtualize.LoadDatabase;
var
  m: Pointer;
  i: Dword;
  pFilePath: PChar;
  msFile: TMemoryStream;
begin
  {* Load Executable *}
  GetMem(pFilePath, 1024);
  GetModuleFileName(hInstance, pFilePath, 512);
  msFile:=TMemoryStream.Create;
  msFile.LoadFromFile(pFilePath);
  FreeMem(pFilePath);
  {* Copy to Memory *}
  GetMem(m, FDataSize);
  FDatabase:=Dword(m);
  for i:=0 to FDataSize - 1 do
    pByte(FDatabase + i)^:=pByte(Dword(msFile.Memory) + FDataOffset + i)^;
  msFile.Free;
end;

function ReadByte(var WriteLocation: Dword): Byte;
begin
  Result:=pByte(WriteLocation)^;
  inc(WriteLocation);
end;

function ReadDword(var WriteLocation: Dword): Dword;
begin
  Result:=pDword(WriteLocation)^;
  inc(WriteLocation, 4);
end;

procedure TVirtualize.ParseOneInstruction(var vAddress: Dword; var Registers: TRegisters);
var
  b: Byte;
  regRead, regWrite: Dword;
begin
  b:=ReadByte(vAddress);
  case b of
    $00:
      begin
        b:=ReadByte(vAddress);
        case b of
          $00:
            begin
              regRead:=Dword(@Registers.Eax) + ReadByte(vAddress) * 4;
              Registers.Temp:=pDword(regRead)^;
            end;
          $01:
            begin
              regRead:=Dword(@Registers.Eax) + ReadByte(vAddress) * 4;
              Registers.Temp:=ReadDword(vAddress) + pDword(regRead)^;
            end;
          $02:
            begin
              regRead:=Dword(@Registers.Eax) + ReadByte(vAddress) * 4;
              Registers.Temp:=pDword(ReadDword(vAddress) + pDword(regRead)^)^;
            end;
          $03:
            begin
              Registers.Temp:=ReadDword(vAddress);
            end;
          $04:
            begin
              Registers.Temp:=pDword(ReadDword(vAddress))^;
            end;
          $05:
            begin
              regWrite:=Dword(@Registers.Eax) + ReadByte(vAddress) * 4;
              pDword(regWrite)^:=Registers.Temp;
            end;
          $06:
            begin
              regWrite:=Dword(@Registers.Eax) + ReadByte(vAddress) * 4;
              pDword(regWrite + ReadDword(vAddress))^:=Registers.Temp;
            end;
          $07:
            begin
              pDword(ReadDword(vAddress))^:=Registers.Temp;
            end;
        end;
      end;
    $01:
      begin
        dec(Registers.Esp, 4);
        pDword(Registers.Esp)^:=Registers.Temp;
        inc(vAddress);
      end;
    $02:
      begin
        dec(Registers.Esp, 4);
        pDword(Registers.Esp)^:=Registers.Eip;
        Registers.Eip:=Registers.Temp;
        inc(vAddress);
      end;
  end;
end;

procedure TVirtualize.ProcessInstruction(Address: Dword; var Registers: TRegisters);
var
  iList: Dword;
  i, iCounter: Integer;
begin
  iList:=GetStructureFromAddress(Address);
  iCounter:=pByte(iList)^;
  inc(iList);
  Registers.Eip:=Registers.Eip + pByte(iList)^;
  inc(iList);
  for i:=1 to iCounter do
    ParseOneInstruction(iList, Registers);
end;

end.
