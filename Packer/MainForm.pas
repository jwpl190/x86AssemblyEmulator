unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Disassembler, ScanLibrary, StdCtrls;

type
  TStringArray = Array of String;

  TfrmMain = class(TForm)
    btnBuild: TButton;
    OpenDialog1: TOpenDialog;
    procedure btnBuildClick(Sender: TObject);
  private
    {Private declarations}
  public
    {Public declarations}
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

function Occurs(const str, separator: String): integer;
var
  i, nSep: integer;
begin
  nSep:=0;
  for i:=1 to Length(str) do
    if str[i] = separator then
      inc(nSep);
  Result:=nSep;
end;

function Split(const str: String; const separator: String; count: integer = -1): TStringArray;
var
  i, n: integer;
  p, q, s: PChar;
begin
  SetLength(Result, Occurs(str, separator) + 1);
  p:=PChar(str);
  s:=PChar(separator);
  n:=Length(separator);
  i:=0;
  repeat
    q:=StrPos(p, s);
    if q = nil then
      q:=StrScan(p, #0);
    begin
      if (i) = (count - 1) then
        SetString(Result[i], p, StrLen(p))
      else
        SetString(Result[i], p, q - p);
    end;
    p:=q + n;
    inc(i);
    if i = count then
    begin
      SetLength(Result, i);
      exit;
    end;
  until q^ = #0;
end;

function HexToDec(s: String): Int64;
var
  p: Int64;
  c, i: integer;
begin
  p:=0;
  c:=0;
  for i:=1 to Length(s) do
  begin
    case s[i] of
      '0' .. '9':
        c:=Ord(s[i]) - Ord('0');
      'A' .. 'F':
        c:=Ord(s[i]) - Ord('A') + 10;
      'a' .. 'f':
        c:=Ord(s[i]) - Ord('a') + 10;
    else
      begin
        Result:= -1;
        exit
      end;
    end;
    p:=p * 16 + c;
  end;
  Result:=p;
end;

function GetImageNTHeaders(hInstanceBase: Dword): PImageNtHeaders;
var
  NtHeaderOffset: pWord;
begin
  NtHeaderOffset:=Pointer(hInstanceBase + $3C);
  Result:=Pointer(NtHeaderOffset^ + hInstanceBase);
  if pDword(Result)^ <> IMAGE_NT_SIGNATURE then
    Result:=nil;
end;

function GetSection(NtHeader: PImageNtHeaders; Section: Word): PImageSectionHeader;
var
  Adr: Dword;
begin
  Adr:=integer(NtHeader) + SizeOf(IMAGE_NT_HEADERS) + (Section - 1) * SizeOf(IMAGE_SECTION_HEADER);
  Result:=Pointer(Adr);
end;

function FileOffsetToRva(Base, Offset: Dword): Dword;
var
  Section: PImageSectionHeader;
  Headers: PImageNtHeaders;
  i: Dword;
begin
  Result:=0;
  Headers:=GetImageNTHeaders(Base);
  For i:=1 to Headers.FileHeader.NumberOfSections do
  begin
    Section:=GetSection(Headers, i);
    if (Offset > Section.PointerToRawData) and (Offset < Section.SizeOfRawData) then
    begin
      Result:=Offset - Section.PointerToRawData + Section.VirtualAddress;
      exit;
    end;
  end;
end;

procedure SaveFile(m: Pointer; Size: Dword; Filename: String);
var
  hFile: THandle;
  BRead, Position: Dword;
  Buffer: array [1 .. 8192] of byte;
begin
  hFile:=FileCreate(Filename);
  Position:=0;
  while Position < Size do
  begin
    BRead:=Size - Position;
    if BRead > SizeOf(Buffer) then
      BRead:=SizeOf(Buffer);
    CopyMemory(@Buffer, Ptr(Dword(m) + Position), BRead);
    inc(Position, BRead);
    FileWrite(hFile, Buffer, BRead);
  end;
  FileClose(hFile);
end;

procedure WriteByte(var WriteLocation: Dword; Data: byte);
begin
  pByte(WriteLocation)^:=Data;
  inc(WriteLocation);
end;

procedure WriteDword(var WriteLocation: Dword; Data: Dword);
begin
  pDword(WriteLocation)^:=Data;
  inc(WriteLocation, 4);
end;

procedure WriteHex(var WriteLocation: Dword; HexData: String);
var
  s: TStringArray;
  i: integer;
begin
  s:=Split(HexData, ' ');
  for i:=0 to High(s) do
    WriteByte(WriteLocation, HexToDec(s[i]));
end;

procedure AssembleInstruction(var WriteLocation: Dword; InstructionLocation: Dword; FakeBase, RealBase: Dword);
begin
  {* [Byte: Number of Virtualized Instructions] [Byte: x86 Instruction Size] [Hex: Virtualized Instructions] *}
  case pByte(InstructionLocation)^ of
    $6A:
      begin
        {* Push Byte *}
        WriteByte(WriteLocation, 2);
        WriteByte(WriteLocation, 2);

        WriteHex(WriteLocation, '00 03');
        WriteDword(WriteLocation, pByte(InstructionLocation + 1)^);

        WriteHex(WriteLocation, '01');
      end;
    $68:
      begin
        {* Push Dword *}
        WriteByte(WriteLocation, 2);
        WriteByte(WriteLocation, 5);

        WriteHex(WriteLocation, '00 03');
        WriteDword(WriteLocation, pDword(InstructionLocation + 1)^);

        WriteHex(WriteLocation, '01');
      end;
    $A1:
      begin
        {* Mov Eax, [Address] *}
        WriteByte(WriteLocation, 2);
        WriteByte(WriteLocation, 5);

        WriteHex(WriteLocation, '00 04');
        WriteDword(WriteLocation, pDword(InstructionLocation + 1)^);

        WriteHex(WriteLocation, '00 05 00');
      end;
    $E8:
      begin
        {* Call Relative Address *}
        WriteByte(WriteLocation, 2);
        WriteByte(WriteLocation, 5);

        WriteHex(WriteLocation, '00 03');

        WriteDword(WriteLocation, FileOffsetToRva(FakeBase, pDword(InstructionLocation + 1)^ + InstructionLocation + 5 - FakeBase) + RealBase);

        WriteHex(WriteLocation, '02');
      end;
    $50:
      begin
        {* Push Eax *}
        WriteByte(WriteLocation, 2);
        WriteByte(WriteLocation, 1);

        WriteHex(WriteLocation, '00 00 00');

        WriteHex(WriteLocation, '01');
      end;
  else
    Messagebox(0, 'Unsupported Instruction Detected!', 'x86 Assembly Emulator Compiler', mb_iconhand);
  end;
end;

function VirtualizeInstructions(p, Size: Dword; var PointerSize: Dword; var NumberofEntries: Dword): Dword;
var
  i, j, k, l, InstructionCurrent, InstructionCounter: Dword;
  FinalArray, InstructionArray: Pointer;
  n: integer;
begin
  {* Obtain Instruction Size *}
  i:=p;
  InstructionCounter:=0;
  while true do
  begin
    {* Find Section Tags *}
    i:=FindAob('EB 06 FE 28 29 FE 22 00', i, p + Size);
    if i = Dword( -1) then
      Break;
    j:=FindAob('EB 06 FE 28 29 FE 22 01', i, p + Size);
    if j = Dword( -1) then
      Break;
    {* Count Instructions *}
    k:=i + 8;
    while k < j do
    begin
      Disassemble(k);
      inc(InstructionCounter);
    end;
    i:=j;
  end;
  NumberofEntries:=InstructionCounter;
  PointerSize:=InstructionCounter * 8;
  {* Allocate Alot of Memory *}
  GetMem(FinalArray, PointerSize + $10000);
  InstructionArray:=Pointer(Dword(FinalArray) + PointerSize);
  {* Assemble Each Instruction *}
  i:=p;
  InstructionCounter:=0;
  InstructionCurrent:=Dword(InstructionArray);
  while true do
  begin
    i:=FindAob('EB 06 FE 28 29 FE 22 00', i, p + Size);
    if i = Dword( -1) then
      Break;
    j:=FindAob('EB 06 FE 28 29 FE 22 01', i, p + Size);
    if j = Dword( -1) then
      Break;
    {* Count Instructions *}
    k:=i + 8;
    while k < j do
    begin
      {* Write Data *}
      pDword(Dword(FinalArray) + InstructionCounter * 8)^:=FileOffsetToRva(p, k - p);
      pDword(Dword(FinalArray) + InstructionCounter * 8 + 4)^:=InstructionCurrent - Dword(FinalArray);
      {* Parse Instruction *}
      AssembleInstruction(InstructionCurrent, k, p, $00400000); {* Assume Base 00400000 *}
      {* Next Instruction *}
      l:=k;
      Disassemble(k);
      {* Write Halt Instruction *}
      pByte(l)^:=$F4;
      {* Randomize the Rest *}
      for n:=1 to k - l - 1 do
        pByte(l + n)^:=Random($FF);
      inc(InstructionCounter);
    end;
    i:=j;
  end;
  Result:=Dword(FinalArray);
  PointerSize:=PointerSize + InstructionCurrent - Dword(InstructionArray);
end;

function PackFile(FileInput, FileOutput: String): Boolean;
var
  hSrcFile, hSrcFileSize, hSrcFileSizeFixed: Dword;
  hSrcView: Dword;
  pSrcView: Pointer;
  i, hVmSection, NumberofInstructions: Dword;
  hSavePtr: Pointer;
  BaseWrite: Dword;
begin
  Result:=False;
  {* Make Sure File Exists *}
  If Not FileExists(FileInput) Then
    exit;
  {* Open Src File *}
  hSrcFile:=Windows.CreateFile(PChar(FileInput), GENERIC_WRITE or GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, 0);
  if (hSrcFile = INVALID_HANDLE_VALUE) then
    exit;
  hSrcView:=CreateFileMapping(hSrcFile, nil, PAGE_READWRITE or SEC_COMMIT, 0, 0, nil);
  pSrcView:=MapViewOfFile(hSrcView, FILE_MAP_WRITE or FILE_MAP_READ, 0, 0, 0);
  hSrcFileSize:=GetFileSize(hSrcFile, nil);

  GetMem(hSavePtr, hSrcFileSize);
  {* Copy Src File to Memory *}
  for i:=0 to hSrcFileSize - 1 do
    pByte(Dword(hSavePtr) + i)^:=pByte(Dword(pSrcView) + i)^;

  UnMapViewOfFile(pSrcView);
  CloseHandle(hSrcView);
  CloseHandle(hSrcFile);

  hVmSection:=VirtualizeInstructions(Dword(hSavePtr), hSrcFileSize, hSrcFileSizeFixed, NumberofInstructions);

  BaseWrite:=FindAob('FE 23 A4 28 2F E3 9C 64', Dword(hSavePtr), Dword(hSavePtr) + hSrcFileSize) + 8;
  pDword(BaseWrite)^:=hSrcFileSize;
  pDword(BaseWrite + 4)^:=hSrcFileSizeFixed;
  pDword(BaseWrite + 8)^:=hSrcFileSize;
  pDword(BaseWrite + 12)^:=NumberofInstructions;

  for i:=hSrcFileSize to hSrcFileSize + hSrcFileSizeFixed - 1 do
    pByte(Dword(hSavePtr) + i)^:=pByte(hVmSection + i - hSrcFileSize)^;

  DeleteFile(FileOutput);
  SaveFile(hSavePtr, hSrcFileSize + hSrcFileSizeFixed, FileOutput);
  FreeMem(hSavePtr);
end;

procedure TfrmMain.btnBuildClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    PackFile(OpenDialog1.Filename, OpenDialog1.Filename);
    Messagebox(Handle, 'Success!', 'x86 Assembly Emulator Compiler', MB_ICONASTERISK);
  end;
end;

end.
