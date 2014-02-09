unit ScanLibrary;

interface

uses Windows, Sysutils, Classes, GeneralFunctions;

function FindAob(szPattern: String; dwStart: Dword = $00400000; dwEnd: Dword = $01400000; dwSkip: Dword = 0): Dword;

implementation

function ScanPattern(bPattern, bBytes: array of Byte; dwStart, dwEnd: Dword): Dword;
var
  i, j: Dword;
  bFound: Boolean;
begin
  for i:=dwStart to dwEnd - Dword( High(bPattern)) do
  begin
    bFound:=True;
    try
      for j:=i to i + Dword( High(bPattern)) do
        if bPattern[j - i] <> 0 then
          if bBytes[j - i] <> pByte(j)^ then
          begin
            bFound:=False;
            break;
          end;
    except
      Continue;
    end;
    if bFound then
    begin
      Result:=i;
      Exit;
    end;
  end;
  Result:=Dword( -1);
end;

function FindAob(szPattern: String; dwStart: Dword; dwEnd: Dword; dwSkip: Dword): Dword;
var
  PatternSplit: TStringArray;
  bPattern: array of Byte;
  bBytes: array of Byte;
  i: Integer;
begin
  PatternSplit:=SplitW(szPattern, ' ');
  SetLength(bPattern, High(PatternSplit) + 1);
  SetLength(bBytes, High(PatternSplit) + 1);
  for i:=0 to High(PatternSplit) do
  begin
    if (PatternSplit[i] = '??') or (PatternSplit[i] = '?') then
      bPattern[i]:=0
    else
    begin
      bPattern[i]:=1;
      bBytes[i]:=HexToDec(PatternSplit[i]);
    end;
  end;
  i:=0;
  while True do
  begin
    Result:=ScanPattern(bPattern, bBytes, dwStart, dwEnd);
    if Result = Dword( -1) then
      Exit;
    if Dword(i) < dwSkip then
      dwStart:=Result + 1
    else
      Exit;
    Inc(i);
  end;
end;

end.
