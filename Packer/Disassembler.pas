unit Disassembler;
{$WARNINGS OFF}
{$HINTS OFF}

interface

uses imagehlp, sysutils, windows;

type
  Tprefix = set of byte;

type
  TMemory = array [0 .. 23] of byte;

function rd(bt: byte): string;
function rd8(bt: byte): string;
function rd16(bt: byte): string;

function r8(bt: byte): string;
function r16(bt: byte): string;
function r32(bt: byte): string;
function mm(bt: byte): string;
function xmm(bt: byte): string;
function sreg(bt: byte): string;
function CR(bt: byte): string;
function DR(bt: byte): string;

function GetBitOf(bt: dword; bit: integer): byte;
function getsegmentoverride(prefix: Tprefix): string;
function getmod(bt: byte): byte;
function getRM(bt: byte): byte;
function getREG(bt: byte): byte;

function SIB(memory: TMemory; sibbyte: integer; var last: dword): string;
function MODRM(memory: TMemory; prefix: Tprefix; modrmbyte: integer; inst: integer; var last: dword): string;

function disassemble(var offset: dword): string; overload;
function disassemble(var offset: dword; var description: string): string; overload;

function previousopcode(address: dword): dword;
function translatestring(disassembled: string; numberofbytes: integer): string;

function inttohexs(address: dword; chars: integer): string;

implementation

function rd(bt: byte): string;
begin
  case bt of
    0:
      result:='eax';
    1:
      result:='ecx';
    2:
      result:='edx';
    3:
      result:='ebx';
    4:
      result:='esp';
    5:
      result:='ebp';
    6:
      result:='esi';
    7:
      result:='edi';
  end;
end;

function rd8(bt: byte): string;
begin
  case bt of
    0:
      result:='al';
    1:
      result:='cl';
    2:
      result:='dl';
    3:
      result:='bl';
    4:
      result:='ah';
    5:
      result:='ch';
    6:
      result:='dh';
    7:
      result:='bh';
  end;
end;

function rd16(bt: byte): string;
begin
  case bt of
    0:
      result:='ax';
    1:
      result:='cx';
    2:
      result:='dx';
    3:
      result:='bx';
    4:
      result:='sp';
    5:
      result:='bp';
    6:
      result:='si';
    7:
      result:='di';
  end;
end;

function r8(bt: byte): string;
begin
  case getREG(bt) of
    0:
      result:='al';
    1:
      result:='cl';
    2:
      result:='dl';
    3:
      result:='bl';
    4:
      result:='ah';
    5:
      result:='ch';
    6:
      result:='dh';
    7:
      result:='bh';
  end;
end;

function r16(bt: byte): string;
begin
  case getREG(bt) of
    0:
      result:='ax';
    1:
      result:='cx';
    2:
      result:='dx';
    3:
      result:='bx';
    4:
      result:='sp';
    5:
      result:='bp';
    6:
      result:='si';
    7:
      result:='di';
  end;
end;

function r32(bt: byte): string;
begin
  case getREG(bt) of
    0:
      result:='eax';
    1:
      result:='ecx';
    2:
      result:='edx';
    3:
      result:='ebx';
    4:
      result:='esp';
    5:
      result:='ebp';
    6:
      result:='esi';
    7:
      result:='edi';
  end;

end;

function xmm(bt: byte): string;
begin
  case getREG(bt) of
    0:
      result:='XMM0';
    1:
      result:='XMM1';
    2:
      result:='XMM2';
    3:
      result:='XMM3';
    4:
      result:='XMM4';
    5:
      result:='XMM5';
    6:
      result:='XMM6';
    7:
      result:='XMM7';
  end;
end;

function mm(bt: byte): string;
begin
  case getREG(bt) of
    0:
      result:='MM0';
    1:
      result:='MM1';
    2:
      result:='MM2';
    3:
      result:='MM3';
    4:
      result:='MM4';
    5:
      result:='MM5';
    6:
      result:='MM6';
    7:
      result:='MM7';
  end;
end;

function sreg(bt: byte): string;
begin
  case getREG(bt) of
    0:
      result:='ES';
    1:
      result:='CS';
    2:
      result:='SS';
    3:
      result:='DS';
    4:
      result:='FS';
    5:
      result:='GS';
    6:
      result:='HS'; //as if...
    7:
      result:='IS';
  end;
end;

function CR(bt: byte): string;
begin
  case getREG(bt) of
    0:
      result:='CR0';
    1:
      result:='CR1';
    2:
      result:='CR2';
    3:
      result:='CR3';
    4:
      result:='CR4';
    5:
      result:='CR5';
    6:
      result:='CR6';
    7:
      result:='CR7';
  end;
end;

function DR(bt: byte): string;
begin
  case getREG(bt) of
    0:
      result:='DR0';
    1:
      result:='DR1';
    2:
      result:='DR2';
    3:
      result:='DR3';
    4:
      result:='DR4';
    5:
      result:='DR5';
    6:
      result:='DR6';
    7:
      result:='DR7';
  end;
end;

function GetBitOf(bt: dword; bit: integer): byte;
begin
  bt:=bt shl (31 - bit);
  result:=bt shr 31;
  //result:=(bt shl (7-bit)) shr 7;  //can someone explain why this isn't working ?
end;

function getsegmentoverride(prefix: Tprefix): string;
begin
  if $2E in prefix then
    result:='CS:'
  else if $26 in prefix then
    result:='ES:'
  else if $36 in prefix then
    result:='SS:'
  else if $3E in prefix then
    result:=''
  else if $64 in prefix then
    result:='FS:'
  else if $65 in prefix then
    result:='GS:';
end;

function getmod(bt: byte): byte;
begin
  result:=(bt shr 6) and 3;
end;

function getRM(bt: byte): byte;
begin
  result:=bt and 7;
end;

function getREG(bt: byte): byte;
begin
  result:=(bt shr 3) and 7;
end;

function MODRM2(memory: TMemory; prefix: Tprefix; modrmbyte: integer; inst: integer; var last: dword): string;
var
  dwordptr: ^dword;
begin

  dwordptr:=@memory[modrmbyte + 1];
  last:=modrmbyte + 1;

  if $67 in prefix then
  begin
    //put some 16-bit stuff in here
    //but since this is a 32-bit debugger only ,forget it...

  end
  else
  begin
    case getmod(memory[modrmbyte]) of
      0:
        case getRM(memory[modrmbyte]) of
          0:
            result:=getsegmentoverride(prefix) + '[EAX],';
          1:
            result:=getsegmentoverride(prefix) + '[ECX],';
          2:
            result:=getsegmentoverride(prefix) + '[EDX],';
          3:
            result:=getsegmentoverride(prefix) + '[EBX],';
          4:
            result:=getsegmentoverride(prefix) + '[' + SIB(memory, modrmbyte + 1, last) + '],';
          5:
            begin
              result:=getsegmentoverride(prefix) + '[' + inttohexs(dwordptr^, 8) + '],';
              last:=last + 4;
            end;
          6:
            result:=getsegmentoverride(prefix) + '[ESI],';
          7:
            result:=getsegmentoverride(prefix) + '[EDI],';
        end;

      1:
        begin
          case getRM(memory[modrmbyte]) of
            0:
              if memory[modrmbyte + 1] <= $7F then
                result:=getsegmentoverride(prefix) + '[EAX+' + inttohexs(memory[modrmbyte + 1], 2) + '],'
              else
                result:=getsegmentoverride(prefix) + '[EAX-' + inttohexs($100 - memory[modrmbyte + 1], 2) + '],';
            1:
              if memory[modrmbyte + 1] <= $7F then
                result:=getsegmentoverride(prefix) + '[ECX+' + inttohexs(memory[modrmbyte + 1], 2) + '],'
              else
                result:=getsegmentoverride(prefix) + '[ECX-' + inttohexs($100 - memory[modrmbyte + 1], 2) + '],';
            2:
              if memory[modrmbyte + 1] <= $7F then
                result:=getsegmentoverride(prefix) + '[EDX+' + inttohexs(memory[modrmbyte + 1], 2) + '],'
              else
                result:=getsegmentoverride(prefix) + '[EDX-' + inttohexs($100 - memory[modrmbyte + 1], 2) + '],';
            3:
              if memory[modrmbyte + 1] <= $7F then
                result:=getsegmentoverride(prefix) + '[EBX+' + inttohexs(memory[modrmbyte + 1], 2) + '],'
              else
                result:=getsegmentoverride(prefix) + '[EBX-' + inttohexs($100 - memory[modrmbyte + 1], 2) + '],';
            4:
              begin
                result:=getsegmentoverride(prefix) + '[' + SIB(memory, modrmbyte + 1, last);
                if memory[last] <= $7F then
                  result:=result + '+' + inttohexs(memory[last], 2) + '],'
                else
                  result:=result + '-' + inttohexs($100 - memory[last], 2) + '],';
              end;
            5:
              if memory[modrmbyte + 1] <= $7F then
                result:=getsegmentoverride(prefix) + '[EBP+' + inttohexs(memory[modrmbyte + 1], 2) + '],'
              else
                result:=getsegmentoverride(prefix) + '[EBP-' + inttohexs($100 - memory[modrmbyte + 1], 2) + '],';
            6:
              if memory[modrmbyte + 1] <= $7F then
                result:=getsegmentoverride(prefix) + '[ESI+' + inttohexs(memory[modrmbyte + 1], 2) + '],'
              else
                result:=getsegmentoverride(prefix) + '[ESI-' + inttohexs($100 - memory[modrmbyte + 1], 2) + '],';
            7:
              if memory[modrmbyte + 1] <= $7F then
                result:=getsegmentoverride(prefix) + '[EDI+' + inttohexs(memory[modrmbyte + 1], 2) + '],'
              else
                result:=getsegmentoverride(prefix) + '[EDI-' + inttohexs($100 - memory[modrmbyte + 1], 2) + '],';
          end;
          inc(last);
        end;

      2:
        begin
          case getRM(memory[modrmbyte]) of
            0:
              if dwordptr^ <= $7FFFFFFF then
                result:=getsegmentoverride(prefix) + '[EAX+' + inttohexs(dwordptr^, 8) + '],'
              else
                result:=getsegmentoverride(prefix) + '[EAX-' + inttohexs($100000000 - dwordptr^, 8) + '],';
            1:
              if dwordptr^ <= $7FFFFFFF then
                result:=getsegmentoverride(prefix) + '[ECX+' + inttohexs(dwordptr^, 8) + '],'
              else
                result:=getsegmentoverride(prefix) + '[ECX-' + inttohexs($100000000 - dwordptr^, 8) + '],';
            2:
              if dwordptr^ <= $7FFFFFFF then
                result:=getsegmentoverride(prefix) + '[EDX+' + inttohexs(dwordptr^, 8) + '],'
              else
                result:=getsegmentoverride(prefix) + '[EDX-' + inttohexs($100000000 - dwordptr^, 8) + '],';
            3:
              if dwordptr^ <= $7FFFFFFF then
                result:=getsegmentoverride(prefix) + '[EBX+' + inttohexs(dwordptr^, 8) + '],'
              else
                result:=getsegmentoverride(prefix) + '[EBX-' + inttohexs($100000000 - dwordptr^, 8) + '],';
            4:
              begin
                result:=getsegmentoverride(prefix) + '[' + SIB(memory, modrmbyte + 1, last);
                dwordptr:=@memory[last];
                if dwordptr^ <= $7FFFFFFF then
                  result:=result + '+' + inttohexs(dwordptr^, 8) + '],'
                else
                  result:=result + '+' + inttohexs($100000000 - dwordptr^, 8) + '],';

              end;
            5:
              if dwordptr^ <= $7FFFFFFF then
                result:=getsegmentoverride(prefix) + '[EBP+' + inttohexs(dwordptr^, 8) + '],'
              else
                result:=getsegmentoverride(prefix) + '[EBP-' + inttohexs($100000000 - dwordptr^, 8) + '],';
            6:
              if dwordptr^ <= $7FFFFFFF then
                result:=getsegmentoverride(prefix) + '[ESI+' + inttohexs(dwordptr^, 8) + '],'
              else
                result:=getsegmentoverride(prefix) + '[ESI-' + inttohexs($100000000 - dwordptr^, 8) + '],';
            7:
              if dwordptr^ <= $7FFFFFFF then
                result:=getsegmentoverride(prefix) + '[EDI+' + inttohexs(dwordptr^, 8) + '],'
              else
                result:=getsegmentoverride(prefix) + '[EDI-' + inttohexs($100000000 - dwordptr^, 8) + '],';
          end;
          inc(last, 4);
        end;

      3:
        begin
          case getRM(memory[modrmbyte]) of
            0:
              case inst of
                0:
                  result:='EAX,';
                1:
                  result:='AX,';
                2:
                  result:='AL,';
                3:
                  result:='MM0,';
                4:
                  result:='XMM0,';
              end;

            1:
              case inst of
                0:
                  result:='ECX,';
                1:
                  result:='CX,';
                2:
                  result:='CL,';
                3:
                  result:='MM1,';
                4:
                  result:='XMM1,';
              end;

            2:
              case inst of
                0:
                  result:='EDX,';
                1:
                  result:='DX,';
                2:
                  result:='DL,';
                3:
                  result:='MM2,';
                4:
                  result:='XMM2,';
              end;

            3:
              case inst of
                0:
                  result:='EBX,';
                1:
                  result:='BX,';
                2:
                  result:='BL,';
                3:
                  result:='MM3,';
                4:
                  result:='XMM3,';
              end;

            4:
              case inst of
                0:
                  result:='ESP,';
                1:
                  result:='SP,';
                2:
                  result:='AH,';
                3:
                  result:='MM4,';
                4:
                  result:='XMM4,';
              end;

            5:
              case inst of
                0:
                  result:='EBP,';
                1:
                  result:='BP,';
                2:
                  result:='CH,';
                3:
                  result:='MM5,';
                4:
                  result:='XMM5,';
              end;

            6:
              case inst of
                0:
                  result:='ESI,';
                1:
                  result:='SI,';
                2:
                  result:='DH,';
                3:
                  result:='MM6,';
                4:
                  result:='XMM6,';
              end;

            7:
              case inst of
                0:
                  result:='EDI,';
                1:
                  result:='DI,';
                2:
                  result:='BH,';
                3:
                  result:='MM7,';
                4:
                  result:='XMM7,';
              end;
          end;
        end;
    end;

  end;

end;

function MODRM(memory: TMemory; prefix: Tprefix; modrmbyte: integer; inst: integer; var last: dword): string; overload;
begin
  result:=MODRM2(memory, prefix, modrmbyte, inst, last);
end;

function MODRM(memory: TMemory; prefix: Tprefix; modrmbyte: integer; inst: integer; var last: dword; opperandsize: integer): string; overload;
begin
  result:=MODRM2(memory, prefix, modrmbyte, inst, last);
  if (length(result) > 0) and (result[1] = '[') then
  begin
    case opperandsize of
      8:
        result:='byte ptr ' + result;
      16:
        result:='word ptr ' + result;
      32:
        result:='dword ptr ' + result;
      64:
        result:='qword ptr ' + result;
      80:
        result:='tword ptr ' + result;
      128:
        result:='dqword ptr ' + result;
    end;
  end;
end;

function SIB(memory: TMemory; sibbyte: integer; var last: dword): string;
var
  dwordptr: ^dword;
begin
  case memory[sibbyte] of
    $00:
      begin
        result:='EAX+EAX';
        last:=sibbyte + 1;
      end;

    $01:
      begin
        result:='ECX+EAX';
        last:=sibbyte + 1;
      end;

    $02:
      begin
        result:='EDX+EAX';
        last:=sibbyte + 1;
      end;

    $03:
      begin
        result:='EBX+EAX';
        last:=sibbyte + 1;
      end;

    $04:
      begin
        result:='ESP+EAX';
        last:=sibbyte + 1;
      end;

    $05:
      begin
        dwordptr:=@memory[sibbyte + 1];
        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EAX+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EAX';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EAX';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $06:
      begin
        result:='ESI+EAX';
        last:=sibbyte + 1;
      end;

    $07:
      begin
        result:='EDI+EAX';
        last:=sibbyte + 1;
      end;
    //--------------
    $08:
      begin
        result:='EAX+ECX';
        last:=sibbyte + 1;
      end;

    $09:
      begin
        result:='ECX+ECX';
        last:=sibbyte + 1;
      end;

    $0A:
      begin
        result:='EDX+ECX';
        last:=sibbyte + 1;
      end;

    $0B:
      begin
        result:='EBX+ECX';
        last:=sibbyte + 1;
      end;

    $0C:
      begin
        result:='ESP+ECX';
        last:=sibbyte + 1;
      end;

    $0D:
      begin
        dwordptr:=@memory[sibbyte + 1];
        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='ECX+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+ECX';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+ECX';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $0E:
      begin
        result:='ESI+ECX';
        last:=sibbyte + 1;
      end;

    $0F:
      begin
        result:='EDI+ECX';
        last:=sibbyte + 1;
      end;

    //10-17
    $10:
      begin
        result:='EAX+EDX';
        last:=sibbyte + 1;
      end;

    $11:
      begin
        result:='ECX+EDX';
        last:=sibbyte + 1;
      end;

    $12:
      begin
        result:='EDX+EDX';
        last:=sibbyte + 1;
      end;

    $13:
      begin
        result:='EBX+EDX';
        last:=sibbyte + 1;
      end;

    $14:
      begin
        result:='ESP+EDX';
        last:=sibbyte + 1;
      end;

    $15:
      begin
        dwordptr:=@memory[sibbyte + 1];
        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EDX+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDX';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDX';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $16:
      begin
        result:='ESI+EDX';
        last:=sibbyte + 1;
      end;

    $17:
      begin
        result:='EDI+EDX';
        last:=sibbyte + 1;
      end;
    //18-1F
    $18:
      begin
        result:='EAX+EBX';
        last:=sibbyte + 1;
      end;

    $19:
      begin
        result:='ECX+EBX';
        last:=sibbyte + 1;
      end;

    $1A:
      begin
        result:='EDX+EBX';
        last:=sibbyte + 1;
      end;

    $1B:
      begin
        result:='EBX+EBX';
        last:=sibbyte + 1;
      end;

    $1C:
      begin
        result:='ESP+EBX';
        last:=sibbyte + 1;
      end;

    $1D:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EBX+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBX';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBX';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $1E:
      begin
        result:='ESI+EBX';
        last:=sibbyte + 1;
      end;

    $1F:
      begin
        result:='EDI+EBX';
        last:=sibbyte + 1;
      end;

    //20-27  []
    $20, $60, $A0, $E0:
      begin
        result:='EAX';
        last:=sibbyte + 1;
      end;

    $21, $61, $A1, $E1:
      begin
        result:='ECX';
        last:=sibbyte + 1;
      end;

    $22, $62, $A2, $E2:
      begin
        result:='EDX';
        last:=sibbyte + 1;
      end;

    $23, $63, $A3, $E3:
      begin
        result:='EBX';
        last:=sibbyte + 1;
      end;

    $24, $64, $A4, $E4:
      begin
        result:='ESP';
        last:=sibbyte + 1;
      end;

    $25, $65, $A5, $E5:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 4;
              result:=inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 5;
              result:='EBP+' + inttohexs(dwordptr^, 8);
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $26, $66, $A6, $E6:
      begin
        result:='ESI';
        last:=sibbyte + 1;
      end;

    $27, $67, $A7, $E7:
      begin
        result:='EDI';
        last:=sibbyte + 1;
      end;
    //28-2F
    $28:
      begin
        result:='EAX+EBP';
        last:=sibbyte + 1;
      end;

    $29:
      begin
        result:='ECX+EBP';
        last:=sibbyte + 1;
      end;

    $2A:
      begin
        result:='EDX+EBP';
        last:=sibbyte + 1;
      end;

    $2B:
      begin
        result:='EBX+EBP';
        last:=sibbyte + 1;
      end;

    $2C:
      begin
        result:='ESP+EBP';
        last:=sibbyte + 1;
      end;

    $2D:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EBP+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBP';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBP';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $2E:
      begin
        result:='ESI+EBP';
        last:=sibbyte + 1;
      end;

    $2F:
      begin
        result:='EDI+EBP';
        last:=sibbyte + 1;
      end;

    $30:
      begin
        result:='EAX+ESI';
        last:=sibbyte + 1;
      end;

    $31:
      begin
        result:='ECX+ESI';
        last:=sibbyte + 1;
      end;

    $32:
      begin
        result:='EDX+ESI';
        last:=sibbyte + 1;
      end;

    $33:
      begin
        result:='EBX+ESI';
        last:=sibbyte + 1;
      end;

    $34:
      begin
        result:='ESP+ESI';
        last:=sibbyte + 1;
      end;

    $35:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='ESI+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+ESI';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+ESI';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $36:
      begin
        result:='ESI+ESI';
        last:=sibbyte + 1;
      end;

    $37:
      begin
        result:='EDI+ESI';
        last:=sibbyte + 1;
      end;
    //38-3F
    $38:
      begin
        result:='EAX+EDI';
        last:=sibbyte + 1;
      end;

    $39:
      begin
        result:='ECX+EDI';
        last:=sibbyte + 1;
      end;

    $3A:
      begin
        result:='EDX+EDI';
        last:=sibbyte + 1;
      end;

    $3B:
      begin
        result:='EBX+EDI';
        last:=sibbyte + 1;
      end;

    $3C:
      begin
        result:='ESP+EDI';
        last:=sibbyte + 1;
      end;

    $3D:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EDI+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDI';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDI';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $3E:
      begin
        result:='ESI+EDI';
        last:=sibbyte + 1;
      end;

    $3F:
      begin
        result:='EDI+EDI';
        last:=sibbyte + 1;
      end;

    // *2
    //40-47
    $40:
      begin
        result:='EAX+EAX*2';
        last:=sibbyte + 1;
      end;

    $41:
      begin
        result:='ECX+EAX*2';
        last:=sibbyte + 1;
      end;

    $42:
      begin
        result:='EDX+EAX*2';
        last:=sibbyte + 1;
      end;

    $43:
      begin
        result:='EBX+EAX*2';
        last:=sibbyte + 1;
      end;

    $44:
      begin
        result:='ESP+EAX*2';
        last:=sibbyte + 1;
      end;

    $45:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EAX*2+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EAX*2';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EAX*2';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $46:
      begin
        result:='ESI+EAX*2';
        last:=sibbyte + 1;
      end;

    $47:
      begin
        result:='EDI+EAX*2';
        last:=sibbyte + 1;
      end;
    //48-4f
    $48:
      begin
        result:='EAX+ECX*2';
        last:=sibbyte + 1;
      end;

    $49:
      begin
        result:='ECX+ECX*2';
        last:=sibbyte + 1;
      end;

    $4A:
      begin
        result:='EDX+ECX*2';
        last:=sibbyte + 1;
      end;

    $4B:
      begin
        result:='EBX+ECX*2';
        last:=sibbyte + 1;
      end;

    $4C:
      begin
        result:='ESP+ECX*2';
        last:=sibbyte + 1;
      end;

    $4D:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='ECX*2+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+ECX*2';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+ECX*2';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $4E:
      begin
        result:='ESI+ECX*2';
        last:=sibbyte + 1;
      end;

    $4F:
      begin
        result:='EDI+ECX*2';
        last:=sibbyte + 1;
      end;

    //50-57
    $50:
      begin
        result:='EAX+EDX*2';
        last:=sibbyte + 1;
      end;

    $51:
      begin
        result:='ECX+EDX*2';
        last:=sibbyte + 1;
      end;

    $52:
      begin
        result:='EDX+EDX*2';
        last:=sibbyte + 1;
      end;

    $53:
      begin
        result:='EBX+EDX*2';
        last:=sibbyte + 1;
      end;

    $54:
      begin
        result:='ESP+EDX*2';
        last:=sibbyte + 1;
      end;

    $55:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EDX*2+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDX*2';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDX*2';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $56:
      begin
        result:='ESI+EDX*2';
        last:=sibbyte + 1;
      end;

    $57:
      begin
        result:='EDI+EDX*2';
        last:=sibbyte + 1;
      end;
    //58-5f
    $58:
      begin
        result:='EAX+EBX*2';
        last:=sibbyte + 1;
      end;

    $59:
      begin
        result:='ECX+EBX*2';
        last:=sibbyte + 1;
      end;

    $5A:
      begin
        result:='EDX+EBX*2';
        last:=sibbyte + 1;
      end;

    $5B:
      begin
        result:='EBX+EBX*2';
        last:=sibbyte + 1;
      end;

    $5C:
      begin
        result:='ESP+EBX*2';
        last:=sibbyte + 1;
      end;

    $5D:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EBX*2+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBX*2';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBX*2';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $5E:
      begin
        result:='ESI+EBX*2';
        last:=sibbyte + 1;
      end;

    $5F:
      begin
        result:='EDI+EBX*2';
        last:=sibbyte + 1;
      end;
    //60-67 see 20-27
    //68-6f
    $68:
      begin
        result:='EAX+EBP*2';
        last:=sibbyte + 1;
      end;

    $69:
      begin
        result:='ECX+EBP*2';
        last:=sibbyte + 1;
      end;

    $6A:
      begin
        result:='EDX+EBP*2';
        last:=sibbyte + 1;
      end;

    $6B:
      begin
        result:='EBX+EBP*2';
        last:=sibbyte + 1;
      end;

    $6C:
      begin
        result:='ESP+EBP*2';
        last:=sibbyte + 1;
      end;

    $6D:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EBP*2+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 2;
              result:='EBP+EBP*2';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBP*2';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $6E:
      begin
        result:='ESI+EBP*2';
        last:=sibbyte + 1;
      end;

    $6F:
      begin
        result:='EDI+EBP*2';
        last:=sibbyte + 1;
      end;

    //70-77
    $70:
      begin
        result:='EAX+ESI*2';
        last:=sibbyte + 1;
      end;

    $71:
      begin
        result:='ECX+ESI*2';
        last:=sibbyte + 1;
      end;

    $72:
      begin
        result:='EDX+ESI*2';
        last:=sibbyte + 1;
      end;

    $73:
      begin
        result:='EBX+ESI*2';
        last:=sibbyte + 1;
      end;

    $74:
      begin
        result:='ESP+ESI*2';
        last:=sibbyte + 1;
      end;

    $75:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='ESI*2+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+ESI*2';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+ESI*2';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $76:
      begin
        result:='ESI+ESI*2';
        last:=sibbyte + 1;
      end;

    $77:
      begin
        result:='EDI+ESI*2';
        last:=sibbyte + 1;
      end;
    //78-7f
    $78:
      begin
        result:='EAX+EDI*2';
        last:=sibbyte + 1;
      end;

    $79:
      begin
        result:='ECX+EDI*2';
        last:=sibbyte + 1;
      end;

    $7A:
      begin
        result:='EDX+EDI*2';
        last:=sibbyte + 1;
      end;

    $7B:
      begin
        result:='EBX+EDI*2';
        last:=sibbyte + 1;
      end;

    $7C:
      begin
        result:='ESP+EDI*2';
        last:=sibbyte + 1;
      end;

    $7D:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EDI*2+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDI*2';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDI*2';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $7E:
      begin
        result:='ESI+EDI*2';
        last:=sibbyte + 1;
      end;

    $7F:
      begin
        result:='EDI+EDI*2';
        last:=sibbyte + 1;
      end;
    //-----------------
    //------*4---------
    //-----------------
    //80-BF  (COPY PASTE FROM 40-7F) but now replace *2 wih *4  (hope it doesn't cause bugs)

    $80:
      begin
        result:='EAX+EAX*4';
        last:=sibbyte + 1;
      end;

    $81:
      begin
        result:='ECX+EAX*4';
        last:=sibbyte + 1;
      end;

    $82:
      begin
        result:='EDX+EAX*4';
        last:=sibbyte + 1;
      end;

    $83:
      begin
        result:='EBX+EAX*4';
        last:=sibbyte + 1;
      end;

    $84:
      begin
        result:='ESP+EAX*4';
        last:=sibbyte + 1;
      end;

    $85:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EAX*4+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EAX*4';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EAX*4';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $86:
      begin
        result:='ESI+EAX*4';
        last:=sibbyte + 1;
      end;

    $87:
      begin
        result:='EDI+EAX*4';
        last:=sibbyte + 1;
      end;
    //88-8f
    $88:
      begin
        result:='EAX+ECX*4';
        last:=sibbyte + 1;
      end;

    $89:
      begin
        result:='ECX+ECX*4';
        last:=sibbyte + 1;
      end;

    $8A:
      begin
        result:='EDX+ECX*4';
        last:=sibbyte + 1;
      end;

    $8B:
      begin
        result:='EBX+ECX*4';
        last:=sibbyte + 1;
      end;

    $8C:
      begin
        result:='ESP+ECX*4';
        last:=sibbyte + 1;
      end;

    $8D:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='ECX*4+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+ECX*4';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+ECX*4';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $8E:
      begin
        result:='ESI+ECX*4';
        last:=sibbyte + 1;
      end;

    $8F:
      begin
        result:='EDI+ECX*4';
        last:=sibbyte + 1;
      end;

    //90-97
    $90:
      begin
        result:='EAX+EDX*4';
        last:=sibbyte + 1;
      end;

    $91:
      begin
        result:='ECX+EDX*4';
        last:=sibbyte + 1;
      end;

    $92:
      begin
        result:='EDX+EDX*4';
        last:=sibbyte + 1;
      end;

    $93:
      begin
        result:='EBX+EDX*4';
        last:=sibbyte + 1;
      end;

    $94:
      begin
        result:='ESP+EDX*4';
        last:=sibbyte + 1;
      end;

    $95:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EDX*4+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDX*4';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDX*4';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $96:
      begin
        result:='ESI+EDX*4';
        last:=sibbyte + 1;
      end;

    $97:
      begin
        result:='EDI+EDX*4';
        last:=sibbyte + 1;
      end;
    //98-9f
    $98:
      begin
        result:='EAX+EBX*4';
        last:=sibbyte + 1;
      end;

    $99:
      begin
        result:='ECX+EBX*4';
        last:=sibbyte + 1;
      end;

    $9A:
      begin
        result:='EDX+EBX*4';
        last:=sibbyte + 1;
      end;

    $9B:
      begin
        result:='EBX+EBX*4';
        last:=sibbyte + 1;
      end;

    $9C:
      begin
        result:='ESP+EBX*4';
        last:=sibbyte + 1;
      end;

    $9D:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EBX*4+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBX*4';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBX*4';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $9E:
      begin
        result:='ESI+EBX*4';
        last:=sibbyte + 1;
      end;

    $9F:
      begin
        result:='EDI+EBX*4';
        last:=sibbyte + 1;
      end;
    //a0-a7 see 20-27
    //a8-af
    $A8:
      begin
        result:='EAX+EBP*4';
        last:=sibbyte + 1;
      end;

    $A9:
      begin
        result:='ECX+EBP*4';
        last:=sibbyte + 1;
      end;

    $AA:
      begin
        result:='EDX+EBP*4';
        last:=sibbyte + 1;
      end;

    $AB:
      begin
        result:='EBX+EBP*4';
        last:=sibbyte + 1;
      end;

    $AC:
      begin
        result:='ESP+EBP*4';
        last:=sibbyte + 1;
      end;

    $AD:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EBP*4+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBP*4';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBP*4';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $AE:
      begin
        result:='ESI+EBP*4';
        last:=sibbyte + 1;
      end;

    $AF:
      begin
        result:='EDI+EBP*4';
        last:=sibbyte + 1;
      end;

    //b0-b7
    $B0:
      begin
        result:='EAX+ESI*4';
        last:=sibbyte + 1;
      end;

    $B1:
      begin
        result:='ECX+ESI*4';
        last:=sibbyte + 1;
      end;

    $B2:
      begin
        result:='EDX+ESI*4';
        last:=sibbyte + 1;
      end;

    $B3:
      begin
        result:='EBX+ESI*4';
        last:=sibbyte + 1;
      end;

    $B4:
      begin
        result:='ESP+ESI*4';
        last:=sibbyte + 1;
      end;

    $B5:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='ESI*4+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+ESI*4';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+ESI*4';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $B6:
      begin
        result:='ESI+ESI*4';
        last:=sibbyte + 1;
      end;

    $B7:
      begin
        result:='EDI+ESI*4';
        last:=sibbyte + 1;
      end;
    //b8-bf
    $B8:
      begin
        result:='EAX+EDI*4';
        last:=sibbyte + 1;
      end;

    $B9:
      begin
        result:='ECX+EDI*4';
        last:=sibbyte + 1;
      end;

    $BA:
      begin
        result:='EDX+EDI*4';
        last:=sibbyte + 1;
      end;

    $BB:
      begin
        result:='EBX+EDI*4';
        last:=sibbyte + 1;
      end;

    $BC:
      begin
        result:='ESP+EDI*4';
        last:=sibbyte + 1;
      end;

    $BD:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EDI*4+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDI*4';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDI*4';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $BE:
      begin
        result:='ESI+EDI*4';
        last:=sibbyte + 1;
      end;

    $BF:
      begin
        result:='EDI+EDI*4';
        last:=sibbyte + 1;
      end;

    //c0-ff same as 80-bf but with 8* instead of 4*
    $C0:
      begin
        result:='EAX+EAX*8';
        last:=sibbyte + 1;
      end;

    $C1:
      begin
        result:='ECX+EAX*8';
        last:=sibbyte + 1;
      end;

    $C2:
      begin
        result:='EDX+EAX*8';
        last:=sibbyte + 1;
      end;

    $C3:
      begin
        result:='EBX+EAX*8';
        last:=sibbyte + 1;
      end;

    $C4:
      begin
        result:='ESP+EAX*8';
        last:=sibbyte + 1;
      end;

    $C5:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EAX*8+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EAX*8';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EAX*8';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $C6:
      begin
        result:='ESI+EAX*8';
        last:=sibbyte + 1;
      end;

    $C7:
      begin
        result:='EDI+EAX*8';
        last:=sibbyte + 1;
      end;
    //88-8f
    $C8:
      begin
        result:='EAX+ECX*8';
        last:=sibbyte + 1;
      end;

    $C9:
      begin
        result:='ECX+ECX*8';
        last:=sibbyte + 1;
      end;

    $CA:
      begin
        result:='EDX+ECX*8';
        last:=sibbyte + 1;
      end;

    $CB:
      begin
        result:='EBX+ECX*8';
        last:=sibbyte + 1;
      end;

    $CC:
      begin
        result:='ESP+ECX*8';
        last:=sibbyte + 1;
      end;

    $CD:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='ECX*8+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+ECX*8';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+ECX*8';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $CE:
      begin
        result:='ESI+ECX*8';
        last:=sibbyte + 1;
      end;

    $CF:
      begin
        result:='EDI+ECX*8';
        last:=sibbyte + 1;
      end;

    //90-97
    $D0:
      begin
        result:='EAX+EDX*8';
        last:=sibbyte + 1;
      end;

    $D1:
      begin
        result:='ECX+EDX*8';
        last:=sibbyte + 1;
      end;

    $D2:
      begin
        result:='EDX+EDX*8';
        last:=sibbyte + 1;
      end;

    $D3:
      begin
        result:='EBX+EDX*8';
        last:=sibbyte + 1;
      end;

    $D4:
      begin
        result:='ESP+EDX*8';
        last:=sibbyte + 1;
      end;

    $D5:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EDX*8+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDX*8';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDX*8';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $D6:
      begin
        result:='ESI+EDX*8';
        last:=sibbyte + 1;
      end;

    $D7:
      begin
        result:='EDI+EDX*8';
        last:=sibbyte + 1;
      end;
    //98-9f
    $D8:
      begin
        result:='EAX+EBX*8';
        last:=sibbyte + 1;
      end;

    $D9:
      begin
        result:='ECX+EBX*8';
        last:=sibbyte + 1;
      end;

    $DA:
      begin
        result:='EDX+EBX*8';
        last:=sibbyte + 1;
      end;

    $DB:
      begin
        result:='EBX+EBX*8';
        last:=sibbyte + 1;
      end;

    $DC:
      begin
        result:='ESP+EBX*8';
        last:=sibbyte + 1;
      end;

    $DD:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EBX*8+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBX*8';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBX*8';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $DE:
      begin
        result:='ESI+EBX*8';
        last:=sibbyte + 1;
      end;

    $DF:
      begin
        result:='EDI+EBX*8';
        last:=sibbyte + 1;
      end;
    //a0-a7 see 20-27
    //a8-af
    $E8:
      begin
        result:='EAX+EBP*8';
        last:=sibbyte + 1;
      end;

    $E9:
      begin
        result:='ECX+EBP*8';
        last:=sibbyte + 1;
      end;

    $EA:
      begin
        result:='EDX+EBP*8';
        last:=sibbyte + 1;
      end;

    $EB:
      begin
        result:='EBX+EBP*8';
        last:=sibbyte + 1;
      end;

    $EC:
      begin
        result:='ESP+EBP*8';
        last:=sibbyte + 1;
      end;

    $ED:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EBP*8+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBP*8';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EBP*8';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $EE:
      begin
        result:='ESI+EBP*8';
        last:=sibbyte + 1;
      end;

    $EF:
      begin
        result:='EDI+EBP*8';
        last:=sibbyte + 1;
      end;

    //b0-b7
    $F0:
      begin
        result:='EAX+ESI*8';
        last:=sibbyte + 1;
      end;

    $F1:
      begin
        result:='ECX+ESI*8';
        last:=sibbyte + 1;
      end;

    $F2:
      begin
        result:='EDX+ESI*8';
        last:=sibbyte + 1;
      end;

    $F3:
      begin
        result:='EBX+ESI*8';
        last:=sibbyte + 1;
      end;

    $F4:
      begin
        result:='ESP+ESI*8';
        last:=sibbyte + 1;
      end;

    $F5:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='ESI*8+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+ESI*8';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+ESI*8';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $F6:
      begin
        result:='ESI+ESI*8';
        last:=sibbyte + 1;
      end;

    $F7:
      begin
        result:='EDI+ESI*8';
        last:=sibbyte + 1;
      end;
    //b8-bf
    $F8:
      begin
        result:='EAX+EDI*8';
        last:=sibbyte + 1;
      end;

    $F9:
      begin
        result:='ECX+EDI*8';
        last:=sibbyte + 1;
      end;

    $FA:
      begin
        result:='EDX+EDI*8';
        last:=sibbyte + 1;
      end;

    $FB:
      begin
        result:='EBX+EDI*8';
        last:=sibbyte + 1;
      end;

    $FC:
      begin
        result:='ESP+EDI*8';
        last:=sibbyte + 1;
      end;

    $FD:
      begin
        dwordptr:=@memory[sibbyte + 1];

        case getmod(memory[sibbyte - 1]) of
          0:
            begin
              last:=sibbyte + 5;
              result:='EDI*8+' + inttohexs(dwordptr^, 8);
            end;

          1:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDI*8';
            end;

          2:
            begin
              last:=sibbyte + 1;
              result:='EBP+EDI*8';
            end;

          3:
            begin
              result:='error';
            end;
        end;
      end;

    $FE:
      begin
        result:='ESI+EDI*8';
        last:=sibbyte + 1;
      end;

    $FF:
      begin
        result:='EDI+EDI*8';
        last:=sibbyte + 1;
      end;

  end;

end;

function disassemble(var offset: dword; var description: string): string; overload;
var
  memory: TMemory;
  actualread: dword;
  startoffset: dword;
  tempresult: string;
  tempst: string;
  wordptr: ^word;
  dwordptr: ^dword;
  dwordptr2: ^dword;
  singleptr: ^single;
  doubleptr: ^double;
  extenedptr: ^extended;
  int64ptr: ^int64;
  i, j: integer;

  prefix: Tprefix;
  prefix2: Tprefix;
  isprefix: boolean;

  last: dword;
  foundit: boolean;
  opz: dword;
begin
  result:='';
  isprefix:=true;
  prefix:=[$F0, $F2, $F3, $2E, $36, $3E, $26, $64, $65, $66, $67];
  prefix2:=[];

  startoffset:=offset;

  //readprocessmemory(processhandle,pointer(offset),addr(memory),24,actualread);
  virtualprotect(pointer(offset), 24, PAGE_EXECUTE_READWRITE, opz);
  if IsBadReadPtr(pointer(offset), 24) then
  begin
    offset:=offset + 1;
    result:='??';
    exit;
  end;
  CopyMemory(@memory, pointer(offset), 24);
  actualread:=24;

  if actualread > 0 then
  begin

    while isprefix do
    begin
      inc(offset);
      if memory[0] in prefix then
      begin
        isprefix:=true;
        inc(startoffset);
        prefix2:=prefix2 + [memory[0]];
        virtualprotect(pointer(offset), 24, PAGE_EXECUTE_READWRITE, opz);
        CopyMemory(@memory, pointer(offset), 24);
      end
      else
        isprefix:=false;
    end;

    if $F0 in prefix2 then
      tempresult:='lock ';
    if $F2 in prefix2 then
      tempresult:=tempresult + 'repne ';
    if $F3 in prefix2 then
      tempresult:=tempresult + 'repe ';

    case memory[0] of //opcode
      $00:
        begin
          description:='Add';
          tempresult:=tempresult + 'add ' + MODRM(memory, prefix2, 1, 2, last) + r8(memory[1]);
          inc(offset, last - 1);
        end;

      $01:
        begin
          description:='Add';
          if $66 in prefix2 then
            tempresult:=tempresult + 'ADD ' + MODRM(memory, prefix2, 1, 1, last) + r16(memory[1])
          else
            tempresult:=tempresult + 'ADD ' + MODRM(memory, prefix2, 1, 0, last) + r32(memory[1]);
          inc(offset, last - 1);

        end;

      $02:
        begin
          description:='Add';
          tempresult:=tempresult + 'ADD ' + r8(memory[1]) + ',' + MODRM(memory, prefix2, 1, 2, last);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $03:
        begin
          description:='Add';
          if $66 in prefix2 then
            tempresult:=tempresult + 'ADD ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last)
          else
            tempresult:=tempresult + 'ADD ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $04:
        begin
          description:='Add x to y';
          tempresult:=tempresult + 'ADD AL,' + inttohexs(memory[1], 2);
          inc(offset);
        end;

      $05:
        begin
          description:='Add x to y';
          wordptr:=@memory[1];
          dwordptr:=@memory[1];
          if $66 in prefix2 then
          begin
            tempresult:=tempresult + 'ADD AX,' + inttohexs(wordptr^, 4);
            inc(offset, 2);
          end
          else
          begin
            tempresult:=tempresult + 'ADD EAX,' + inttohexs(dwordptr^, 8);
            inc(offset, 4);
          end;
        end;

      $06:
        begin
          description:='Place ES on the stack';
          tempresult:=tempresult + 'PUSH ES';
        end;

      $07:
        begin
          description:='Remove ES from the stack';
          tempresult:=tempresult + 'POP ES';
        end;

      $08:
        begin
          description:='Logical Inclusive OR';
          tempresult:=tempresult + 'OR ' + MODRM(memory, prefix2, 1, 2, last) + r8(memory[1]);
          inc(offset, last - 1);
        end;

      $09:
        begin
          description:='Logical Inclusive OR';
          if $66 in prefix2 then
            tempresult:=tempresult + 'OR ' + MODRM(memory, prefix2, 1, 1, last) + r16(memory[1])
          else
            tempresult:=tempresult + 'OR ' + MODRM(memory, prefix2, 1, 0, last) + r32(memory[1]);
          inc(offset, last - 1);

        end;

      $0A:
        begin
          description:='Logical Inclusive OR';
          tempresult:=tempresult + 'OR ' + r8(memory[1]) + ',' + MODRM(memory, prefix2, 1, 2, last);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $0B:
        begin
          description:='Logical Inclusive OR';
          if $66 in prefix2 then
            tempresult:=tempresult + 'OR ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last)
          else
            tempresult:=tempresult + 'OR ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $0C:
        begin
          description:='Logical Inclusive OR';
          tempresult:=tempresult + 'OR AL,' + inttohexs(memory[1], 2);
          inc(offset);
        end;

      $0D:
        begin
          description:='Logical Inclusive OR';
          if $66 in prefix2 then
          begin
            wordptr:=@memory[1];
            tempresult:=tempresult + 'OR AX,' + inttohexs(wordptr^, 4);
            inc(offset, 2);
          end
          else
          begin
            dwordptr:=@memory[1];
            tempresult:=tempresult + 'OR EAX,' + inttohexs(dwordptr^, 8);
            inc(offset, 4);
          end;
        end;

      $0E:
        begin
          description:='Place CS on the stack';
          tempresult:=tempresult + 'PUSH CS';
        end;

      $0F:
        begin //SIMD extensions
          case memory[1] of
            $00:
              begin
                case getREG(memory[2]) of
                  0:
                    begin
                      description:='Store Local Descriptor Table Register';
                      if $66 in prefix2 then
                        tempresult:=tempresult + 'SLDT ' + MODRM(memory, prefix2, 2, 1, last, 16)
                      else
                        tempresult:=tempresult + 'SLDT ' + MODRM(memory, prefix2, 2, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  1:
                    begin
                      description:='Store Task Register';
                      tempresult:=tempresult + 'STR ' + MODRM(memory, prefix2, 2, 1, last, 16);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  2:
                    begin
                      description:='Load Local Descriptor Table Register';
                      tempresult:=tempresult + 'LLDT ' + MODRM(memory, prefix2, 2, 1, last, 16);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  3:
                    begin
                      description:='Load Task Register';
                      tempresult:=tempresult + 'LTR ' + MODRM(memory, prefix2, 2, 1, last, 16);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  4:
                    begin
                      description:='Verify a Segment for Reading';
                      tempresult:=tempresult + 'VERR ' + MODRM(memory, prefix2, 2, 1, last, 16);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  5:
                    begin
                      description:='Verify a Segment for Writing';
                      tempresult:=tempresult + 'VERW ' + MODRM(memory, prefix2, 2, 1, last, 16);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  //the following 2 were made up by me.
                else
                  begin
                    description:='Not specified by the intel documentation';
                    tempresult:=tempresult + 'DB 0F';
                  end;

                end;

              end;

            $01:
              begin
                case getREG(memory[2]) of
                  0:
                    begin
                      description:='Store Global Descriptor Table Register';
                      tempresult:=tempresult + 'SGDT ' + MODRM(memory, prefix2, 2, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  1:
                    begin
                      description:='Store Interrupt Descriptor Table Register';
                      tempresult:=tempresult + 'SIDT ' + MODRM(memory, prefix2, 2, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  2:
                    begin
                      description:='Load Global Descriptor Table Register';
                      tempresult:=tempresult + 'LGDT ' + MODRM(memory, prefix2, 2, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  3:
                    begin
                      description:='Load Interupt Descriptor Table Register';
                      tempresult:=tempresult + 'LIDT ' + MODRM(memory, prefix2, 2, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  4:
                    begin
                      description:='Store Machine Status Word';
                      if $66 in prefix2 then
                        tempresult:=tempresult + 'SMSW ' + MODRM(memory, prefix2, 2, 0, last)
                      else
                        tempresult:=tempresult + 'SMSW ' + MODRM(memory, prefix2, 2, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  6:
                    begin
                      description:='Load Machine Status Word';
                      tempresult:=tempresult + 'LMSW ' + MODRM(memory, prefix2, 2, 1, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  7:
                    begin
                      description:='Invalidate TLB Entry';
                      tempresult:=tempresult + 'INVPLG ' + MODRM(memory, prefix2, 2, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;
                end;
              end;

            $02:
              begin
                description:='Load Access Rights Byte';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'LAR ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'LAR ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 2, last);

                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $03:
              begin
                description:='Load Segment Limit';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'LSL ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'LSL ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 2, last);

                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $06:
              begin
                description:='Clear Task-Switched Flag in CR0';
                tempresult:=tempresult + 'CLTS';
                inc(offset);
              end;

            $08:
              begin
                description:='Invalidate Internal Caches';
                tempresult:=tempresult + 'INCD';
                inc(offset);
              end;

            $09:
              begin
                description:='Write Back and Invalidate Cache';
                tempresult:=tempresult + 'WBINVD';
                inc(offset);
              end;

            $0B:
              begin
                description:='Undefined Instruction(Yes, this one really excists..)';
                tempresult:=tempresult + 'UD2';
                inc(offset);
              end;

            $10:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  description:='Move Scalar Double-FP';
                  tempresult:='MOVSD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  description:='Move Scalar Single-FP';
                  tempresult:='MOVSS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else if $66 in prefix2 then
                begin
                  description:='Move Unaligned Packed Double-FP';
                  tempresult:='MOVUPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Move Unaligned Four Packed Single-FP';
                  tempresult:='MOVUPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $11:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  description:='Move Scalar Double-FP';
                  tempresult:='MOVSD ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  description:='Move Scalar Single-FP';
                  tempresult:='MOVSS ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  inc(offset, last - 1);
                end
                else if $66 in prefix2 then
                begin
                  description:='Move Unaligned Packed Double-FP';
                  tempresult:='MOVUPD ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Move Unaligned Four Packed Single-FP';
                  tempresult:='MOVUPS ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  inc(offset, last - 1);
                end;

              end;

            $12:
              begin
                if $66 in prefix2 then
                begin
                  description:='Move low packed Double-Precision Floating-Point Value';
                  tempresult:=tempresult + 'MOVLPD ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='High to Low Packed Single-FP';
                  tempresult:=tempresult + 'MOVLPS ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  inc(offset, last - 1);
                end;
              end;

            $13:
              begin
                if $66 in prefix2 then
                begin
                  description:='Move Low Packed Double-FP';
                  tempresult:=tempresult + 'MOVLPD ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Move Low Packed Single-FP';
                  tempresult:=tempresult + 'MOVLPS ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  inc(offset, last - 1);
                end;
              end;

            $14:
              begin
                if $66 in prefix2 then
                begin
                  description:='Unpack Low Packed Single-FP';
                  tempresult:=tempresult + 'UNPCKLPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Unpack Low Packed Single-FP';
                  tempresult:=tempresult + 'UNPCKLPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $15:
              begin
                if $66 in prefix2 then
                begin
                  description:='Unpack and Interleave High Packed Double-FP';
                  tempresult:=tempresult + 'UNPCKHPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Unpack High packed Single-FP';
                  tempresult:=tempresult + 'UNPCKHPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $16:
              begin
                if $66 in prefix2 then
                begin
                  description:='Move High Packed Double-Precision Floating-Point Value';
                  tempresult:=tempresult + 'MOVHPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='High to Low Packed Single-FP';
                  tempresult:=tempresult + 'MOVHPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $17:
              begin
                if $66 in prefix2 then
                begin
                  description:='Move High Packed Double-Precision Floating-Point Value';
                  tempresult:=tempresult + 'MOVHPD ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='High to Low Packed Single-FP';
                  tempresult:=tempresult + 'MOVHPS ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  inc(offset, last - 1);
                end;
              end;

            $18:
              begin
                case getREG(memory[2]) of
                  0:
                    begin
                      description:='Prefetch';
                      tempresult:=tempresult + 'PREFETCHNTA ' + MODRM(memory, prefix2, 2, 2, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    end;

                  1:
                    begin
                      description:='Prefetch';
                      tempresult:=tempresult + 'PREFETCHT0 ' + MODRM(memory, prefix2, 2, 2, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    end;

                  2:
                    begin
                      description:='Prefetch';
                      tempresult:=tempresult + 'PREFETCHT1 ' + MODRM(memory, prefix2, 2, 2, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    end;

                  3:
                    begin
                      description:='Prefetch';
                      tempresult:=tempresult + 'PREFETCHT2 ' + MODRM(memory, prefix2, 2, 2, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    end;

                end;
              end;

            $20:
              begin
                description:='Move from Control Register';
                tempresult:=tempresult + 'MOV ' + r32(memory[2]) + ',' + CR(memory[2]);
                inc(offset, 2);
              end;

            $21:
              begin
                description:='Move from Control Register';
                tempresult:=tempresult + 'MOV ' + r32(memory[2]) + ',' + DR(memory[2]);
                inc(offset, 2);
              end;

            $22:
              begin
                description:='Move to Control Register';
                tempresult:=tempresult + 'MOV ' + CR(memory[2]) + ',' + r32(memory[2]);
                inc(offset, 2);
              end;

            $23:
              begin
                description:='Move to Control Register';
                tempresult:=tempresult + 'MOV ' + DR(memory[2]) + ',' + r32(memory[2]);
                inc(offset, 2);
              end;

            $28:
              begin
                if $66 in prefix2 then
                begin
                  description:='Move Aligned Packed Fouble-FP Values';
                  tempresult:=tempresult + 'MOVAPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Move Aligned Four Packed Single-FP';
                  tempresult:=tempresult + 'MOVAPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $29:
              begin
                description:='Move Aligned Four Packed Single-FP';
                tempresult:=tempresult + 'MOVAPS ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                inc(offset, last - 1);
              end;

            $2A:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  description:='Convert Doubleword integer to Scalar DoublePrecision Floating-point value';
                  tempresult:=tempresult + 'CVTSI2SD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  description:='Scalar Signed INT32 to Single-FP Conversion';
                  tempresult:=tempresult + 'CVTSI2SS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  if $66 in prefix2 then
                  begin
                    description:='Convert Packed DWORD''s to Packed DP-FP''s';
                    tempresult:=tempresult + 'CVTPI2PD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    inc(offset, last - 1);
                  end
                  else
                  begin
                    description:='Packed Signed INT32 to Packed Single-FP Conversion';
                    tempresult:=tempresult + 'CVTPI2PS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    inc(offset, last - 1);
                  end;
                end;
              end;

            $2B:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'MOVNTPD ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  description:='Move Packed double-precision floating-point using Non-Temporal hint';
                  inc(offset, last - 1);
                end
                else
                begin
                  tempresult:=tempresult + 'MOVNTPS ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  description:='Move Aligned Four Packed Single-FP Non Temporal';
                  inc(offset, last - 1);
                end;
              end;

            $2C:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  description:='Convert with truncation scalar Double-precision floating point value to Signed doubleword integer';
                  tempresult:=tempresult + 'CVTTSD2SI ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  description:='Scalar Single-FP to Signed INT32 Conversion (Truncate)';
                  tempresult:=tempresult + 'CVTTSS2SI ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  if $66 in prefix2 then
                  begin
                    description:='Packed DoublePrecision-FP to Packed DWORD Conversion (Truncate)';
                    tempresult:=tempresult + 'CVTTPD2PI ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    inc(offset, last - 1);
                  end
                  else
                  begin
                    description:='Packed Single-FP to Packed INT32 Conversion (Truncate)';
                    tempresult:=tempresult + 'CVTTPS2PI ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    inc(offset, last - 1);
                  end;
                end;
              end;

            $2D:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  description:='Convert Scalar Double-Precision Floating-Point Value to Doubleword Integer';
                  tempresult:=tempresult + 'CVTSD2SI ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  description:='Scalar Single-FP to Signed INT32 Conversion';
                  tempresult:=tempresult + 'CVTSS2SI ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  if $66 in prefix2 then
                  begin
                    description:='Convert 2 packed DP-FP''s from param 2 to packed signed dword in param1';
                    tempresult:=tempresult + 'CVTPI2PS ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    inc(offset, last - 1);
                  end
                  else
                  begin
                    description:='Packed Single-FP to Packed INT32 Conversion';
                    tempresult:=tempresult + 'CVTPS2PI ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    inc(offset, last - 1);
                  end;
                end;
              end;

            $2E:
              begin
                if $66 in prefix2 then
                begin
                  description:='Unordered Scalar Double-FP Compare and Set EFLAGS';
                  tempresult:=tempresult + 'UCOMISD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Unordered Scalar Single-FP Compare and Set EFLAGS';
                  tempresult:=tempresult + 'UCOMISS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $2F:
              begin
                if $66 in prefix2 then
                begin
                  description:='Compare scalar ordered double-precision Floating Point Values and set EFLAGS';
                  tempresult:=tempresult + 'COMISD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Scalar Ordered Single-FP Compare and Set EFLAGS';
                  tempresult:=tempresult + 'COMISS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $30:
              begin
                description:='Write to Model Specific Register';
                tempresult:=tempresult + 'WRMSR';
                inc(offset);
              end;

            $31:
              begin
                description:='Read Time-Stamp Counter';
                tempresult:=tempresult + 'RDTSC';
                inc(offset);
              end;

            $32:
              begin
                description:='Read from Model Specific Register';
                tempresult:=tempresult + 'RDMSR';
                inc(offset);
              end;

            $33:
              begin
                description:='Read Performance-Monitoring counters';
                tempresult:=tempresult + 'RDPMC';
                inc(offset);
              end;

            $34:
              begin
                description:='Fast Transistion to System Call Entry Point';
                tempresult:=tempresult + 'SYSENTER';
                inc(offset);
              end;

            $35:
              begin
                description:='Fast Transistion from System Call Entry Point';
                tempresult:=tempresult + 'SYSEXIT';
                inc(offset);
              end;

            $40:
              begin
                description:='Move if overflow';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVO ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVO ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                inc(offset, last - 1);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
              end;

            $41:
              begin
                description:='Move if not overflow';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVNO ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVNO ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);

                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $42:
              begin
                description:='Move if below/ Move if Carry';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVB ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVB ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $43:
              begin
                description:='Move if above or equal/ Move if not carry';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVAE ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVAE ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $44:
              begin
                description:='Move if equal/Move if Zero';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVE ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVE ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $45:
              begin
                description:='Move if not equal/Move if not zero';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVNE ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVNE ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $46:
              begin
                description:='Move if below or equal';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVBE ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVBE ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $47:
              begin
                description:='Move if Above';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVA ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVA ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $48:
              begin
                description:='Move if Sign';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVS ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVS ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $49:
              begin
                description:='Move if not sign';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVNS ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVNS ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $4A:
              begin
                description:='Move if parity Even';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVPE ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVPE ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $4B:
              begin
                description:='Move if not parity/Move if parity odd';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVNP ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVNP ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $4C:
              begin
                description:='Move if less';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVL ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVL ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $4D:
              begin
                description:='Move if greater or equal';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVGE ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVGE ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $4E:
              begin
                description:='Move if less or equal';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVLE ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVLE ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $4F:
              begin
                description:='Move if greater';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMOVG ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'CMOVG ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $50:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'MOVMSKPD ' + MODRM(memory, prefix2, 2, 0, last) + xmm(memory[2]);
                  description:='Extract Packed Double-Precision Floating-Point sign Mask';
                  inc(offset, last - 1);
                end
                else
                begin
                  tempresult:=tempresult + 'MOVMSKPS ' + MODRM(memory, prefix2, 2, 0, last) + xmm(memory[2]);
                  description:='Move Mask To Integer';
                  inc(offset, last - 1);
                end;
              end;

            $51:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  tempresult:=tempresult + 'SQRTSD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  description:='Scalar Double-FP Square Root';
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  tempresult:=tempresult + 'SQRTSS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  description:='Scalar Single-FP Square Root';
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);

                  inc(offset, last - 1);
                end
                else if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'SQRTPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  description:='Packed Double-FP Square Root';
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  tempresult:=tempresult + 'SQRTPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  description:='Packed Single-FP Square Root';
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $52:
              begin
                if $F3 in prefix2 then
                begin
                  tempresult:=tempresult + 'RSQRSS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Packed Single-FP Square Root Reciprocal';
                  inc(offset, last - 1);
                end
                else
                begin
                  tempresult:=tempresult + 'RSQRTPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Scalar Single-FP Square Root Reciprocal';
                  inc(offset, last - 1);
                end;
              end;

            $53:
              begin
                if $F3 in prefix2 then
                begin
                  tempresult:=tempresult + 'RCPSS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Scalar Single-FP Reciprocal';
                  inc(offset, last - 1);
                end
                else
                begin
                  tempresult:=tempresult + 'RCPPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Packed Single-FP Reciprocal';
                  inc(offset, last - 1);
                end;
              end;

            $54:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'ANDPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Bit-wise Logical AND of xmm2/m128 and xmm1';
                  inc(offset, last - 1);
                end
                else
                begin
                  tempresult:=tempresult + 'ANDPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Bit-wise Logical And For Single FP';
                  inc(offset, last - 1);
                end;
              end;

            $55:
              begin
                if $66 in prefix2 then
                begin
                  description:='Bit-wise Logical AND NOT of Packed Double-precision FP Values';
                  tempresult:=tempresult + 'ANDNPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);

                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Bit-wise Logical And Not For Single-FP';
                  tempresult:=tempresult + 'ANDNPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);

                  inc(offset, last - 1);
                end;
              end;

            $56:
              begin
                if $66 in prefix2 then
                begin
                  description:='Bit-wise Logical OR of Double-FP';
                  tempresult:=tempresult + 'ORPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);

                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Bit-wise Logical OR For Single-FP';
                  tempresult:=tempresult + 'ORPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);

                  inc(offset, last - 1);
                end;
              end;

            $57:
              begin
                if $66 in prefix2 then
                begin
                  description:='Bit-wise Logical XOR For Double-FP Data';
                  tempresult:=tempresult + 'XORPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);

                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Bit-wise Logical XOR For Single-FP Data';
                  tempresult:=tempresult + 'XORPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);

                  inc(offset, last - 1);
                end;
              end;

            $58:
              begin
                if $F2 in prefix2 then
                begin
                  //delete the repne from the tempresult
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);

                  tempresult:='ADDSD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Add the lower SP FP number from XMM2/Mem to XMM1.';
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  //delete the repe from the tempresult
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);

                  tempresult:='ADDSS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Add the lower SP FP number from XMM2/Mem to XMM1.';
                  inc(offset, last - 1);
                end
                else
                begin
                  if $66 in prefix2 then
                  begin
                    tempresult:=tempresult + 'ADDPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    description:='Add packed double-precision floating-point values from XMM2/Mem to xmm1';
                    inc(offset, last - 1);
                  end
                  else
                  begin
                    tempresult:=tempresult + 'ADDPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    description:='Add packed SP FP numbers from XMM2/Mem to XMM1';
                    inc(offset, last - 1);
                  end;
                end;
              end;

            $59:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  tempresult:='MULSD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Scalar Double-FP Multiply';
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  tempresult:='MULSS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Scalar Single-FP Multiply';
                  inc(offset, last - 1);
                end
                else if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'MULPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Packed Double-FP Multiply';
                  inc(offset, last - 1);
                end
                else
                begin
                  tempresult:=tempresult + 'MULPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Packed Single-FP Multiply';
                  inc(offset, last - 1);
                end;
              end;

            $5A:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  tempresult:=tempresult + 'CVTSD2SS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Convert Scalar Double-Precision Floating-Point Value to Scalar Single-Precision Floating-Point Value';
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  tempresult:=tempresult + 'CVTSS2SD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Convert Scalar Single-Precision Floating-Point Value to Scalar Double-Precision Floating-Point Value';
                  inc(offset, last - 1);
                end
                else
                begin
                  if $66 in prefix2 then
                  begin
                    tempresult:=tempresult + 'CVTPD2PS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    description:='Convert Packed Double Precision FP Values to Packed Single Precision FP Values';
                    inc(offset, last - 1);
                  end
                  else
                  begin
                    tempresult:=tempresult + 'CVTPS2PD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    description:='Convert Packed Single Precision FP Values to Packed Double Precision FP Values';
                    inc(offset, last - 1);
                  end;
                end;
              end;

            $5B:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'CVTPS2DQ ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Convert PS-Precision FPoint Values to Packed DWORD''s ';
                  inc(offset, last - 1);
                end
                else
                begin
                  tempresult:=tempresult + 'CVTDQ2PS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Convert Packed DWORD''s to PS-Precision FPoint Values';
                  inc(offset, last - 1);
                end;
              end;

            $5C:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=tempresult + 'SUBSD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Scalar Double-FP Subtract';
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=tempresult + 'SUBSS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Scalar Single-FP Subtract';
                  inc(offset, last - 1);
                end
                else if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'SUBPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Packed Double-FP Subtract';
                  inc(offset, last - 1);
                end
                else
                begin
                  tempresult:=tempresult + 'SUBPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Packed Single-FP Subtract';
                  inc(offset, last - 1);
                end;
              end;

            $5D:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  tempresult:=tempresult + 'MINSD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Scalar Single-FP Minimum';
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  tempresult:=tempresult + 'MINSS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Scalar Single-FP Minimum';
                  inc(offset, last - 1);
                end
                else
                begin
                  if $66 in prefix2 then
                  begin
                    tempresult:=tempresult + 'MINPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    description:='Packed Double-FP Minimum';
                    inc(offset, last - 1);
                  end
                  else
                  begin
                    tempresult:=tempresult + 'MINPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    description:='Packed Single-FP Minimum';
                    inc(offset, last - 1);
                  end;
                end;
              end;

            $5E:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  tempresult:=tempresult + 'DIVSD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Scalar Double-Precision-FP Divide';
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  tempresult:=tempresult + 'DIVSS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  description:='Scalar Single-FP Divide';
                  inc(offset, last - 1);
                end
                else
                begin
                  if $66 in prefix2 then
                  begin
                    tempresult:=tempresult + 'DIVPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    description:='Packed Double-Precision FP Divide';
                    inc(offset, last - 1);
                  end
                  else
                  begin
                    tempresult:=tempresult + 'DIVPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    description:='Packed Single-FP Divide';
                    inc(offset, last - 1);
                  end;
                end;
              end;

            $5F:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  description:='Scalar Double-FP Maximum';
                  tempresult:=tempresult + 'MAXSD ' + xmm(memory[1]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  description:='Scalar Single-FP Maximum';
                  tempresult:=tempresult + 'MAXSS ' + xmm(memory[1]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  if $66 in prefix2 then
                  begin
                    description:='Packed Double-FP Maximum';
                    tempresult:=tempresult + 'MAXPD ' + xmm(memory[1]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    inc(offset, last - 1);
                  end
                  else
                  begin
                    description:='Packed Single-FP Maximum';
                    tempresult:=tempresult + 'MAXPS ' + xmm(memory[1]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    inc(offset, last - 1);
                  end;
                end;
              end;

            $60:
              begin
                if $66 in prefix2 then
                begin
                  description:='Unpack Low Packed Data';
                  tempresult:=tempresult + 'PUNPCKLBW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Unpack Low Packed Data';
                  tempresult:=tempresult + 'PUNPCKLBW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $61:
              begin
                if $66 in prefix2 then
                begin
                  description:='Unpack Low Packed Data';
                  tempresult:=tempresult + 'PUNPCKLWD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Unpack Low Packed Data';
                  tempresult:=tempresult + 'PUNPCKLWD ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $62:
              begin
                if $66 in prefix2 then
                begin
                  description:='Unpack Low Packed Data';
                  tempresult:=tempresult + 'PUNPCKLDQ ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Unpack Low Packed Data';
                  tempresult:=tempresult + 'PUNPCKLDQ ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $63:
              begin
                if $66 in prefix2 then
                begin
                  description:='Pack with signed Saturation';
                  tempresult:=tempresult + 'PACKSSWB ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Pack with signed Saturation';
                  tempresult:=tempresult + 'PACKSSWB ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $64:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Compare for Greater Than';
                  tempresult:=tempresult + 'PCMPGTB ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Compare for Greater Than';
                  tempresult:=tempresult + 'PCMPGTB ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $65:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Compare for Greater Than';
                  tempresult:=tempresult + 'PCMPGTW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Compare for Greater Than';
                  tempresult:=tempresult + 'PCMPGTW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $66:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Compare for Greater Than';
                  tempresult:=tempresult + 'PCMPGTD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Compare for Greater Than';
                  tempresult:=tempresult + 'PCMPGTD ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $67:
              begin
                if $66 in prefix2 then
                begin
                  description:='Pack with Unsigned Saturation';
                  tempresult:=tempresult + 'PACKUSWB ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Pack with Unsigned Saturation';
                  tempresult:=tempresult + 'PACKUSWB ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $68:
              begin
                if $66 in prefix2 then
                begin
                  description:='Unpack High Packed Data';
                  tempresult:=tempresult + 'PUNPCKHBW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Unpack High Packed Data';
                  tempresult:=tempresult + 'PUNPCKHBW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $69:
              begin
                if $66 in prefix2 then
                begin
                  description:='Unpack High Packed Data';
                  tempresult:=tempresult + 'PUNPCKHWD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Unpack High Packed Data';
                  tempresult:=tempresult + 'PUNPCKHWD ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $6A:
              begin
                if $66 in prefix2 then
                begin
                  description:='Unpack High Packed Data';
                  tempresult:=tempresult + 'PUNPCKHDQ ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Unpack High Packed Data';
                  tempresult:=tempresult + 'PUNPCKHDQ ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $6B:
              begin
                if $66 in prefix2 then
                begin
                  description:='Pack with signed Saturation';
                  tempresult:=tempresult + 'PACKSSDW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Pack with signed Saturation';
                  tempresult:=tempresult + 'PACKSSDW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $6C:
              begin
                if $66 in prefix2 then
                begin
                  description:='Unpack Low Packed Data';
                  tempresult:=tempresult + 'PUNPCKLQDQ ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
              end;

            $6D:
              begin
                if $66 in prefix2 then
                begin
                  description:='Unpack High Packed Data';
                  tempresult:=tempresult + 'PUNPCKHQDQ ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
              end;

            $6E:
              begin
                if $66 in prefix2 then
                begin
                  description:='Move Doubleword';
                  tempresult:=tempresult + 'MOVD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Move 32 Bits';
                  tempresult:=tempresult + 'MOVD ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $6F:
              begin
                if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  description:='Move UnAligned Double Quadword';
                  tempresult:=tempresult + 'MOVDQU ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else if $66 in prefix2 then
                begin
                  description:='Move Aligned Double Quadword';
                  tempresult:=tempresult + 'MOVDQA ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Move 64 Bits';
                  tempresult:=tempresult + 'MOVDQA ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $70:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  description:='Shuffle Packed Low Words';
                  tempresult:=tempresult + 'PSHUFLW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last) + '' + inttohexs(memory[last], 2);
                  inc(offset, last);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  description:='Shuffle Packed High Words';
                  tempresult:=tempresult + 'PSHUFHW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last) + '' + inttohexs(memory[last], 2);
                  inc(offset, last);
                end
                else if $66 in prefix2 then
                begin
                  description:='Packed Shuffle DoubleWord';
                  tempresult:=tempresult + 'PSHUFD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last) + '' + inttohexs(memory[last], 2);
                  inc(offset, last);
                end
                else
                begin
                  description:='Packed Shuffle Word';
                  tempresult:=tempresult + 'PSHUFW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last) + '' + inttohexs(memory[last], 2);
                  inc(offset, last);
                end;
              end;

            $71:
              begin
                case getREG(memory[2]) of
                  2:
                    begin
                      if $66 in prefix2 then
                      begin
                        description:='Packed Shift Right Logical';
                        tempresult:=tempresult + 'PSRLW ' + xmm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end
                      else
                      begin
                        description:='Packed Shift Right Logical';
                        tempresult:=tempresult + 'PSRLW ' + mm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end;
                    end;

                  4:
                    begin
                      if $66 in prefix2 then
                      begin
                        description:='Packed Shift Right Arithmetic';
                        tempresult:=tempresult + 'PSRAW ' + xmm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end
                      else
                      begin
                        description:='Packed Shift Right Arithmetic';
                        tempresult:=tempresult + 'PSRAW ' + mm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end;
                    end;

                  6:
                    begin
                      if $66 in prefix2 then
                      begin
                        description:='Packed Shift Left Logical';
                        tempresult:=tempresult + 'PSLLW ' + xmm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end
                      else
                      begin
                        description:='Packed Shift Left Logical';
                        tempresult:=tempresult + 'PSLLW ' + mm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end;
                    end;
                end;
              end;

            $72:
              begin
                case getREG(memory[2]) of
                  2:
                    begin
                      if $66 in prefix2 then
                      begin
                        description:='Packed Shift Right Logical';
                        tempresult:=tempresult + 'PSRLD ' + xmm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end
                      else
                      begin
                        description:='Packed Shift Right Logical';
                        tempresult:=tempresult + 'PSRLD ' + mm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end;
                    end;

                  4:
                    begin
                      if $66 in prefix2 then
                      begin
                        description:='Packed Shift Right Arithmetic';
                        tempresult:=tempresult + 'PSRAD ' + xmm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end
                      else
                      begin
                        description:='Packed Shift Right Arithmetic';
                        tempresult:=tempresult + 'PSRAD ' + mm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end;
                    end;

                  6:
                    begin
                      if $66 in prefix2 then
                      begin
                        description:='Packed Shift Left Logical';
                        tempresult:=tempresult + 'PSLLD ' + xmm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end
                      else
                      begin
                        description:='Packed Shift Left Logical';
                        tempresult:=tempresult + 'PSLLD ' + mm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end;
                    end;
                end;
              end;

            $73:
              begin
                case getREG(memory[2]) of
                  2:
                    begin
                      if $66 in prefix2 then
                      begin
                        description:='Packed Shift Right Logical';
                        tempresult:=tempresult + 'PSRLQ ' + xmm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end
                      else
                      begin
                        description:='Packed Shift Right Logical';
                        tempresult:=tempresult + 'PSRLQ ' + mm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end;
                    end;

                  3:
                    begin
                      if $66 in prefix2 then
                      begin
                        description:='Shift double Quadword right Lopgical';
                        tempresult:=tempresult + 'PSRLDQ ' + xmm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end;
                    end;

                  6:
                    begin
                      if $66 in prefix2 then
                      begin
                        description:='Packed Shift Left Logical';
                        tempresult:=tempresult + 'PSLLQ ' + xmm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end
                      else
                      begin
                        description:='Packed Shift Left Logical';
                        tempresult:=tempresult + 'PSLLQ ' + mm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end;
                    end;

                  7:
                    begin
                      if $66 in prefix2 then
                      begin
                        description:='Shift Double Quadword Left Logical';
                        tempresult:=tempresult + 'PSLLDQ ' + xmm(memory[2]) + ',' + inttohexs(memory[3], 2);
                        inc(offset, 3);
                      end;
                    end;
                end;
              end;

            $74:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Compare for Equal';
                  tempresult:=tempresult + 'PCMPEQB ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Compare for Equal';
                  tempresult:=tempresult + 'PCMPEQB ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $75:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Compare for Equal';
                  tempresult:=tempresult + 'PCMPEQW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Compare for Equal';
                  tempresult:=tempresult + 'PCMPEQW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $76:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Compare for Equal';
                  tempresult:=tempresult + 'PCMPEQD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Compare for Equal';
                  tempresult:=tempresult + 'PCMPEQD ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $77:
              begin
                description:='Empty MMX™ State';
                tempresult:=tempresult + 'EMMS';
                inc(offset);
              end;

            $7E:
              begin
                if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  description:='Move quadword';
                  tempresult:=tempresult + 'MOVQ ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else if $66 in prefix2 then
                begin
                  description:='Move 32 Bits';
                  tempresult:=tempresult + 'MOVD ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Move 32 Bits';
                  tempresult:=tempresult + 'MOVD ' + MODRM(memory, prefix2, 2, 3, last) + mm(memory[2]);
                  inc(offset, last - 1);
                end;
              end;

            $7F:
              begin
                if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  description:='Move Unaligned double Quadword';
                  tempresult:=tempresult + 'MOVDQU ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  inc(offset, last - 1);
                end
                else if $66 in prefix2 then
                begin
                  description:='Move aligned double Quadword';
                  tempresult:=tempresult + 'MOVDQA ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Move 64 Bits';
                  tempresult:=tempresult + 'MOVQ ' + MODRM(memory, prefix2, 2, 3, last) + mm(memory[2]);
                  inc(offset, last - 1);
                end;
              end;

            $80:
              begin
                description:='Jump near if overflow';
                tempresult:=tempresult + 'JO ';

                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);
              end;

            $81:
              begin
                description:='Jump near if not overflow';
                tempresult:=tempresult + 'JNO ';
                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(offset + pint(@memory[2])^, 8);

              end;

            $82:
              begin
                description:='Jump near if below/carry';
                dwordptr:=@memory[2];
                tempresult:=tempresult + 'JB ';
                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);

              end;

            $83:
              begin
                description:='Jump near if above or equal';
                tempresult:=tempresult + 'JAE ';
                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);
              end;

            $84:
              begin
                description:='Jump near if equal';
                tempresult:=tempresult + 'JE ';

                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);
              end;

            $85:
              begin
                description:='Jump near if not equal';
                tempresult:=tempresult + 'JNE ';

                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);

              end;

            $86:
              begin
                description:='Jump near if below or equal';
                tempresult:=tempresult + 'JBE ';

                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);
              end;

            $87:
              begin
                description:='Jump near if above';
                tempresult:=tempresult + 'JA ';

                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);
              end;

            $88:
              begin
                description:='Jump near if sign';
                tempresult:=tempresult + 'JS ';

                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);
              end;

            $89:
              begin
                description:='Jump near if less';
                tempresult:=tempresult + 'JL ';

                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);
              end;

            $8A:
              begin
                description:='Jump near if parity';
                tempresult:=tempresult + 'JP ';

                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);
              end;

            $8B:
              begin
                description:='Jump near if not parity';
                tempresult:=tempresult + 'JNP ';

                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);
              end;

            $8C:
              begin
                description:='Jump near if less';
                tempresult:=tempresult + 'JL ';

                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);
              end;

            $8D:
              begin
                description:='Jump near if not less';
                tempresult:=tempresult + 'JNL ';

                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);
              end;

            $8E:
              begin
                description:='Jump near if not greater';
                tempresult:=tempresult + 'JNG ';

                inc(offset, 1 + 4);
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);
              end;

            $8F:
              begin
                description:='Jump near if greater';
                tempresult:=tempresult + 'JG ';
                tempresult:=tempresult + inttohexs(dword(offset + pint(@memory[2])^), 8);
                inc(offset, 1 + 4);
              end;

            $90:
              begin
                description:='Set byte if overflow';
                tempresult:=tempresult + 'SETO ' + MODRM(memory, prefix2, 2, 2, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $91:
              begin
                description:='Set byte if not overfloww';
                tempresult:=tempresult + 'SETNO ' + MODRM(memory, prefix2, 2, 2, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $92:
              begin
                description:='Set byte if below/carry';
                tempresult:=tempresult + 'SETB ' + MODRM(memory, prefix2, 2, 2, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $93:
              begin
                description:='Set byte if above or equal';
                tempresult:=tempresult + 'SETAE ' + MODRM(memory, prefix2, 2, 2, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $94:
              begin
                description:='Set byte if equal';
                tempresult:=tempresult + 'SETE ' + MODRM(memory, prefix2, 2, 2, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $95:
              begin
                description:='Set byte if not carry(not equal)';
                tempresult:=tempresult + 'SETNC ' + MODRM(memory, prefix2, 2, 2, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $96:
              begin
                description:='Set byte if below or equal';
                tempresult:=tempresult + 'SETBE ' + MODRM(memory, prefix2, 2, 2, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $97:
              begin
                description:='Set byte if above';
                tempresult:=tempresult + 'SETA ' + MODRM(memory, prefix2, 2, 2, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $98:
              begin
                description:='Set byte if sign';
                tempresult:=tempresult + 'SETS ' + MODRM(memory, prefix2, 2, 2, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $99:
              begin
                description:='Set byte if not sign';
                tempresult:=tempresult + 'SETNS ' + MODRM(memory, prefix2, 2, 2, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $9A:
              begin
                description:='Set byte if parity';
                tempresult:=tempresult + 'SETP ' + MODRM(memory, prefix2, 2, 2, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $9B:
              begin
                description:='Set byte if not parity';
                tempresult:=tempresult + 'SETNP ' + MODRM(memory, prefix2, 2, 2, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $9C:
              begin
                description:='Set byte if less';
                tempresult:=tempresult + 'SETL ' + MODRM(memory, prefix2, 2, 2, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $9D:
              begin
                description:='Set byte if greater or equal';
                tempresult:=tempresult + 'SETGE ' + MODRM(memory, prefix2, 2, 2, last);
                inc(offset, last - 1);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
              end;

            $9E:
              begin
                description:='Set byte if less or equal';
                tempresult:=tempresult + 'SETLE ' + MODRM(memory, prefix2, 2, 2, last);
                inc(offset, last - 1);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
              end;

            $9F:
              begin
                description:='Set byte if greater';
                tempresult:=tempresult + 'SETG ' + MODRM(memory, prefix2, 2, 2, last);
                inc(offset, last - 1);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);

              end;

            $A0:
              begin
                description:='Push Word or Doubleword Onto the Stack';
                tempresult:=tempresult + 'PUSH FS';
                inc(offset);
              end;

            $A1:
              begin
                description:='Pop a Value from the Stack';
                tempresult:=tempresult + 'POP FS';
                inc(offset);
              end;

            $A2:
              begin
                description:='CPU Identification';
                tempresult:=tempresult + 'CPUID';
                inc(offset);
              end;

            $A3:
              begin
                description:='Bit Test';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'BT ' + MODRM(memory, prefix2, 2, 1, last) + r16(memory[2])
                else
                  tempresult:=tempresult + 'BT ' + MODRM(memory, prefix2, 2, 0, last) + r32(memory[2]);
                inc(offset, last - 1);

              end;

            $A4:
              begin
                description:='Double Precision Shift Left';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'SHLD ' + MODRM(memory, prefix2, 2, 1, last) + r16(memory[2])
                else
                  tempresult:=tempresult + 'SHLD ' + MODRM(memory, prefix2, 2, 0, last) + r32(memory[2]);
                inc(offset, last - 1);

              end;

            $A5:
              begin
                description:='Double Precision Shift Left';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'SHLD ' + MODRM(memory, prefix2, 2, 1, last) + 'CL'
                else
                  tempresult:=tempresult + 'SHLD ' + MODRM(memory, prefix2, 2, 0, last) + 'CL';
                inc(offset, last - 1);

              end;

            $A8:
              begin
                description:='Push Word or Doubleword Onto the Stack';
                tempresult:=tempresult + 'PUSH GS';
                inc(offset);
              end;

            $A9:
              begin
                description:='Pop a Value from the Stack';
                tempresult:=tempresult + 'POP GS';
                inc(offset);
              end;

            $AA:
              begin
                description:='Resume from System Management Mode';
                tempresult:=tempresult + 'RSM';
                inc(offset);
              end;

            $AB:
              begin
                description:='Bit Test and Set';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'BTS ' + MODRM(memory, prefix2, 2, 1, last) + r16(memory[2])
                else
                  tempresult:=tempresult + 'BTS ' + MODRM(memory, prefix2, 2, 0, last) + r32(memory[2]);
                inc(offset, last - 1);

              end;

            $AC:
              begin
                description:='Double Precision Shift Right';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'SHRD ' + MODRM(memory, prefix2, 2, 1, last) + r16(memory[2])
                else
                  tempresult:=tempresult + 'SHRD ' + MODRM(memory, prefix2, 2, 0, last) + r32(memory[2]);
                inc(offset, last - 1);

              end;

            $AD:
              begin
                description:='Double Precision Shift Right';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'SHRD ' + MODRM(memory, prefix2, 2, 1, last) + 'CL'
                else
                  tempresult:=tempresult + 'SHRD ' + MODRM(memory, prefix2, 2, 0, last) + 'CL';
                inc(offset, last - 1);

              end;

            $AE:
              begin
                case getREG(memory[2]) of
                  0:
                    begin
                      description:='Store FP and MMX State and Streaming SIMD Extension State';
                      tempresult:=tempresult + 'FXSAVE ' + MODRM(memory, prefix2, 2, 0, last);
                      inc(offset, last - 1);
                    end;

                  1:
                    begin
                      description:='Restore FP and MMX State and Streaming SIMD Extension State';
                      tempresult:=tempresult + 'FXRSTOR ' + MODRM(memory, prefix2, 2, 0, last);
                      inc(offset, last - 1);
                    end;

                  2:
                    begin
                      description:='Load Streaming SIMD Extension Control/Status';
                      tempresult:='LDMXCSR ' + MODRM(memory, prefix2, 2, 0, last);
                      inc(offset, last - 1);
                    end;

                  3:
                    begin
                      description:='Store Streaming SIMD Extension Control/Status';
                      tempresult:='STMXCSR ' + MODRM(memory, prefix2, 2, 0, last);
                      inc(offset, last - 1);
                    end;

                  7:
                    begin
                      description:='Store Fence';
                      tempresult:='SFENCE ' + MODRM(memory, prefix2, 2, 0, last);
                      inc(offset, last - 1);
                    end;

                END;

              end;

            $AF:
              begin
                description:='Signed Multiply';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'IMUL ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'IMUL ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $B0:
              begin
                description:='Compare and Exchange';
                tempresult:=tempresult + 'CMPXCHG ' + MODRM(memory, prefix2, 2, 2, last) + r8(memory[2]);
                inc(offset, last - 1);
              end;

            $B1:
              begin
                description:='Compare and Exchange';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'CMPXCHG ' + MODRM(memory, prefix2, 2, 1, last) + r16(memory[2])
                else
                  tempresult:=tempresult + 'CMPXCHG ' + MODRM(memory, prefix2, 2, 0, last) + r32(memory[2]);
                inc(offset, last - 1);
              end;

            $B2:
              begin
                description:='Load Far Pointer';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'LSS ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'LSS ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $B3:
              begin
                description:='Bit Test and Reset';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'BTR ' + MODRM(memory, prefix2, 2, 1, last) + r16(memory[2])
                else
                  tempresult:=tempresult + 'BTR ' + MODRM(memory, prefix2, 2, 0, last) + r32(memory[2]);
                inc(offset, last - 1);

              end;

            $B4:
              begin
                description:='Load Far Pointer';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'LFS ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'LFS ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $B5:
              begin
                description:='Load Far Pointer';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'LGS ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'LGS ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $B6:
              begin
                description:='Load Far Pointer';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'MOVZX ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 2, last, 8)
                else
                  tempresult:=tempresult + 'MOVZX ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 2, last, 8);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);

                inc(offset, last - 1);
              end;

            $B7:
              begin
                description:='Load Far Pointer';
                tempresult:=tempresult + 'MOVZX ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last, 16);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);

                inc(offset, last - 1);
              end;

            $BA:
              begin
                case getREG(memory[2]) of
                  4:
                    begin
                      //BT
                      description:='Bit Test';
                      if $66 in prefix2 then
                        tempresult:=tempresult + 'BT ' + MODRM(memory, prefix2, 2, 1, last) + '' + inttohexs(memory[3], 2)
                      else
                        tempresult:=tempresult + 'BT ' + MODRM(memory, prefix2, 2, 0, last) + '' + inttohexs(memory[3], 2); //notice the difference in the modrm 4th parameter

                      inc(offset, last - 1 + 1);
                    end;

                  5:
                    begin
                      //BTS
                      description:='Bit Test and Set';
                      if $66 in prefix2 then
                        tempresult:=tempresult + 'BTS ' + MODRM(memory, prefix2, 2, 1, last) + '' + inttohexs(memory[3], 2)
                      else
                        tempresult:=tempresult + 'BTS ' + MODRM(memory, prefix2, 2, 0, last) + '' + inttohexs(memory[3], 2); //notice the difference in the modrm 4th parameter
                      inc(offset, last - 1 + 1);
                    end;

                  6:
                    begin
                      //BTR
                      description:='Bit Test and Reset';
                      if $66 in prefix2 then
                        tempresult:=tempresult + 'BTR ' + MODRM(memory, prefix2, 2, 1, last) + '' + inttohexs(memory[3], 2)
                      else
                        tempresult:=tempresult + 'BTR ' + MODRM(memory, prefix2, 2, 0, last) + '' + inttohexs(memory[3], 2); //notice the difference in the modrm 4th parameter
                      inc(offset, last - 1 + 1);
                    end;

                  7:
                    begin
                      //BTC
                      description:='Bit Test and Complement';
                      if $66 in prefix2 then
                        tempresult:=tempresult + 'BTC ' + MODRM(memory, prefix2, 2, 1, last) + '' + inttohexs(memory[3], 2)
                      else
                        tempresult:=tempresult + 'BTC ' + MODRM(memory, prefix2, 2, 0, last) + '' + inttohexs(memory[3], 2); //notice the difference in the modrm 4th parameter
                      inc(offset, last - 1 + 1);
                    end;

                end;

              end;

            $BB:
              begin
                description:='Bit Test and Complement';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'BTC ' + MODRM(memory, prefix2, 2, 1, last) + r16(memory[2])
                else
                  tempresult:=tempresult + 'BTC ' + MODRM(memory, prefix2, 2, 0, last) + r32(memory[2]);
                inc(offset, last - 1);

              end;

            $BC:
              begin
                //bsf
                description:='Bit Scan Forward';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'BSF ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'BSF ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);

                inc(offset, last - 1);
              end;

            $BD:
              begin
                //bsf
                description:='Bit Scan Reverse';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'BSR ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last)
                else
                  tempresult:=tempresult + 'BSR ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);

                inc(offset, last - 1);
              end;

            $BE:
              begin
                description:='Move with Sign-Extension';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'MOVSX ' + r16(memory[2]) + ',' + MODRM(memory, prefix2, 2, 2, last, 8)
                else
                  tempresult:=tempresult + 'MOVSX ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 2, last, 8);

                tempresult:=copy(tempresult, 1, length(tempresult) - 1);

                inc(offset, last - 1);
              end;

            $BF:
              begin
                description:='Move with Sign-Extension';
                tempresult:=tempresult + 'MOVSX ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 1, last, 16);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            $C0:
              begin
                description:='Exchange and Add';
                tempresult:=tempresult + 'XADD ' + MODRM(memory, prefix2, 2, 2, last) + r8(memory[2]);
                inc(offset, last - 1);
              end;

            $C1:
              begin
                description:='Exchange and Add';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'XADD ' + MODRM(memory, prefix2, 2, 1, last) + r16(memory[2])
                else
                  tempresult:=tempresult + 'XADD ' + MODRM(memory, prefix2, 2, 0, last) + r32(memory[2]);
                inc(offset, last - 1);
              end;

            $C2:
              begin
                if $F2 in prefix2 then
                begin
                  description:='Compare Scalar Dpuble-Precision Floating-Point Values';
                  tempresult:=tempresult + 'CMPSD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last, 128) + '' + inttohexs(memory[last], 2);
                  inc(offset, last);
                end
                else if $F3 in prefix2 then
                begin
                  description:='Packed Single-FP Compare';
                  tempresult:=tempresult + 'CMPSS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last, 128) + '' + inttohexs(memory[last], 2);
                  inc(offset, last);
                end
                else
                begin
                  if $66 in prefix2 then
                  begin
                    description:='Compare packed double-Precision Floating-Point Values';
                    tempresult:=tempresult + 'CMPPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last, 128) + '' + inttohexs(memory[last], 2);
                    inc(offset, last);
                  end
                  else
                  begin
                    description:='Packed Single-FP Compare';
                    tempresult:=tempresult + 'CMPPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last, 128) + '' + inttohexs(memory[last], 2);
                    inc(offset, last);
                  end;
                end;
              end;

            $C3:
              begin
                description:='Store doubleword using Non-temporal Hint';
                tempresult:=tempresult + 'MOVNTI ' + MODRM(memory, prefix2, 2, 0, last) + r32(memory[2]);
                inc(offset, last);
              end;

            $C4:
              begin
                if $66 in prefix2 then
                begin
                  description:='Insert Word';
                  tempresult:=tempresult + 'PINSRW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last) + inttohexs(memory[last], 2);
                  inc(offset, last);
                end
                else
                begin
                  description:='Insert Word';
                  tempresult:=tempresult + 'PINSRW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 0, last) + inttohexs(memory[last], 2);
                  inc(offset, last);
                end;
              end;

            $C5:
              begin
                if $66 in prefix2 then
                begin
                  description:='Extract Word';
                  tempresult:=tempresult + 'PEXTRW ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last) + ',' + inttohexs(memory[last], 2);
                  inc(offset, 3);
                end
                else
                begin
                  description:='Extract Word';
                  tempresult:=tempresult + 'PEXTRW ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last) + ',' + inttohexs(memory[last], 2);
                  inc(offset, 3);
                end;
              end;

            $C6:
              begin
                if $66 in prefix2 then
                begin
                  description:='Shuffle Double-FP';
                  tempresult:=tempresult + 'SHUFPD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last) + inttohexs(memory[last], 2);
                  inc(offset, last);
                end
                else
                begin
                  description:='Shuffle Single-FP';
                  tempresult:=tempresult + 'SHUFPS ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last) + inttohexs(memory[last], 2);
                  inc(offset, last);
                end;
              end;

            $C7:
              begin
                case getREG(memory[2]) of
                  1:
                    begin
                      description:='Compare and Exchange 8 Bytes';
                      tempresult:=tempresult + 'CMPXCHG8B ' + MODRM(memory, prefix2, 2, 0, last);
                      inc(offset, last - 1);
                    end;
                end;

              end;

            $C8 .. $CF:
              begin
                //BSWAP
                description:='Byte Swap';
                tempresult:=tempresult + 'BSWAP ' + rd(memory[1] - $C8);
                inc(offset);
              end;

            $D1:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Shift Right Logical';
                  tempresult:=tempresult + 'PSRLW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Shift Right Logical';
                  tempresult:=tempresult + 'PSRLW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $D2:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Shift Right Logical';
                  tempresult:=tempresult + 'PSRLD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Shift Right Logical';
                  tempresult:=tempresult + 'PSRLD ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $D3:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Shift Right Logical';
                  tempresult:=tempresult + 'PSRLQ ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Shift Right Logical';
                  tempresult:=tempresult + 'PSRLQ ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $D4:
              begin
                if $66 in prefix2 then
                begin
                  description:='Add Packed Quadwprd Integers';
                  tempresult:=tempresult + 'PADDQ ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Add Packed Quadwprd Integers';
                  tempresult:=tempresult + 'PADDQ ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $D5:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Multiply Low';
                  tempresult:=tempresult + 'PMULLW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Multiply Low';
                  tempresult:=tempresult + 'PMULLW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $D6:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  description:='Move low quadword from xmm to MMX technology register';
                  tempresult:=tempresult + 'MOVDQ2Q ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  description:='Move low quadword from xmm to MMX technology register';
                  tempresult:=tempresult + 'MOVQ2DQ ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else if $66 in prefix2 then
                begin
                  description:='Move low quadword from xmm to MMX technology register';
                  tempresult:=tempresult + 'MOVQ ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Move quadword from MMX technology to xmm register';
                  tempresult:=tempresult + 'MOVQ2Dq ' + MODRM(memory, prefix2, 2, 4, last) + mm(memory[2]);
                  inc(offset, last - 1);
                end;

              end;

            $D7:
              begin
                if $66 in prefix2 then
                begin
                  description:='Move Byte Mask To Integer';
                  tempresult:=tempresult + 'PMOVMSKB ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Move Byte Mask To Integer';
                  tempresult:=tempresult + 'PMOVMSKB ' + r32(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $D8:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Subtract Unsigned with Saturation';
                  tempresult:=tempresult + 'PSUBUSB ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Subtract Unsigned with Saturation';
                  tempresult:=tempresult + 'PSUBUSB ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $D9:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Subtract Unsigned with Saturation';
                  tempresult:=tempresult + 'PSUBUSW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Subtract Unsigned with Saturation';
                  tempresult:=tempresult + 'PSUBUSW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $DA:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Unsigned Integer Byte Minimum';
                  tempresult:=tempresult + 'PMINUB ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Unsigned Integer Byte Minimum';
                  tempresult:=tempresult + 'PMINUB ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $DB:
              begin
                if $66 in prefix2 then
                begin
                  description:='Logical AND';
                  tempresult:=tempresult + 'PAND ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Logical AND';
                  tempresult:=tempresult + 'PAND ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $DC:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Add Unsigned with Saturation';
                  tempresult:=tempresult + 'PADDUSB ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Add Unsigned with Saturation';
                  tempresult:=tempresult + 'PADDUSB ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $DD:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Add Unsigned with Saturation';
                  tempresult:=tempresult + 'PADDUSW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Add Unsigned with Saturation';
                  tempresult:=tempresult + 'PADDUSW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $DE:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Unsigned Integer Byte Maximum';
                  tempresult:=tempresult + 'PMAXUB ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Unsigned Integer Byte Maximum';
                  tempresult:=tempresult + 'PMAXUB ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $DF:
              begin
                if $66 in prefix2 then
                begin
                  description:='Logical AND NOT';
                  tempresult:=tempresult + 'PANDN ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Logical AND NOT';
                  tempresult:=tempresult + 'PANDN ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $E0:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Average';
                  tempresult:=tempresult + 'PAVGB ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Average';
                  tempresult:=tempresult + 'PAVGB ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $E1:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Shift Right Arithmetic';
                  tempresult:=tempresult + 'PSRAW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Shift Right Arithmetic';
                  tempresult:=tempresult + 'PSRAW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $E2:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Shift Left Logical';
                  tempresult:=tempresult + 'PSRAD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Shift Left Logical';
                  tempresult:=tempresult + 'PSRAD ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $E3:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Average';
                  tempresult:=tempresult + 'PAVGW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Average';
                  tempresult:=tempresult + 'PAVGW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $E4:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Multiply High Unsigned';
                  tempresult:=tempresult + 'PMULHUW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Multiply High Unsigned';
                  tempresult:=tempresult + 'PMULHUW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $E5:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Multiply High';
                  tempresult:=tempresult + 'PMULHW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Multiply High';
                  tempresult:=tempresult + 'PMULHW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $E6:
              begin
                if $F2 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 6);
                  description:='Convert two packed signed dwords from param2 to two packed DP-Floating point values in param1';
                  tempresult:=tempresult + 'CVTPD2DQ ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else if $F3 in prefix2 then
                begin
                  tempresult:=copy(tempresult, 1, length(tempresult) - 5);
                  description:='Convert two packed signed dwords from param2 to two packed DP-Floating point values in param1';
                  tempresult:=tempresult + 'CVTDQ2PD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  if $66 in prefix2 then
                  begin
                    description:='Convert with truncation Packed Double-precision Floating-Point Values to Packed Doubleword Integers';
                    tempresult:=tempresult + 'CVTTPD2DQ ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                    tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                    inc(offset, last - 1);
                  end;
                end;
              end;

            $E7:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'MOVNTDQ ' + MODRM(memory, prefix2, 2, 4, last) + xmm(memory[2]);
                  description:='Move Double quadword Using Non-Temporal Hint';
                  inc(offset, last - 1);
                end
                else
                begin
                  tempresult:=tempresult + 'MOVNTQ ' + MODRM(memory, prefix2, 2, 3, last) + mm(memory[2]);
                  description:='Move 64 Bits Non Temporal';
                  inc(offset, last - 1);
                end;
              end;

            $E8:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Subtract with Saturation';
                  tempresult:=tempresult + 'PSUBSB ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Subtract with Saturation';
                  tempresult:=tempresult + 'PSUBSB ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $E9:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Subtract with Saturation';
                  tempresult:=tempresult + 'PSUBSW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Subtract with Saturation';
                  tempresult:=tempresult + 'PSUBSW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $EA:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Signed Integer Word Minimum';
                  tempresult:=tempresult + 'PMINSW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Signed Integer Word Minimum';
                  tempresult:=tempresult + 'PMINSW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $EB:
              begin
                if $66 in prefix2 then
                begin
                  description:='Bitwise Logical OR';
                  tempresult:=tempresult + 'POR ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Bitwise Logical OR';
                  tempresult:=tempresult + 'POR ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $EC:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Add with Saturation';
                  tempresult:=tempresult + 'PADDSB ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Add with Saturation';
                  tempresult:=tempresult + 'PADDSB ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $ED:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Add with Saturation';
                  tempresult:=tempresult + 'PADDSW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Add with Saturation';
                  tempresult:=tempresult + 'PADDSW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $EE:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Signed Integer Word Maximum';
                  tempresult:=tempresult + 'PMAXSW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Signed Integer Word Maximum';
                  tempresult:=tempresult + 'PMAXSW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $EF:
              begin
                if $66 in prefix2 then
                begin
                  description:='Logical Exclusive OR';
                  tempresult:=tempresult + 'PXOR ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Logical Exclusive OR';
                  tempresult:=tempresult + 'PXOR ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $F1:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Shift Left Logical';
                  tempresult:=tempresult + 'PSLLW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Shift Left Logical';
                  tempresult:=tempresult + 'PSLLW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $F2:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Shift Left Logical';
                  tempresult:=tempresult + 'PSLLD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Shift Left Logical';
                  tempresult:=tempresult + 'PSLLD ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $F3:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Shift Left Logical';
                  tempresult:=tempresult + 'PSLLQ ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Shift Left Logical';
                  tempresult:=tempresult + 'PSLLQ ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $F4:
              begin
                if $66 in prefix2 then
                begin
                  description:='Multiply Packed Unsigned Doubleword Integers';
                  tempresult:=tempresult + 'PMULUDQ ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Multiply Packed Unsigned Doubleword Integers';
                  tempresult:=tempresult + 'PMULUDQ ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $F5:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Multiply and Add';
                  tempresult:=tempresult + 'PMADDWD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Multiply and Add';
                  tempresult:=tempresult + 'PMADDWD ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $F6:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Sum of Absolute Differences';
                  tempresult:=tempresult + 'PSADBW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Sum of Absolute Differences';
                  tempresult:=tempresult + 'PSADBW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $F7:
              begin
                if $66 in prefix2 then
                begin
                  description:='Store Selected Bytes of Double Quadword';
                  tempresult:=tempresult + 'MASKMOVDQU ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Byte Mask Write';
                  tempresult:=tempresult + 'MASKMOVQ ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $F8:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Subtract';
                  tempresult:=tempresult + 'PSUBB ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Subtract';
                  tempresult:=tempresult + 'PSUBB ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $F9:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Subtract';
                  tempresult:=tempresult + 'PSUBW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Subtract';
                  tempresult:=tempresult + 'PSUBW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $FA:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Subtract';
                  tempresult:=tempresult + 'PSUBD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Subtract';
                  tempresult:=tempresult + 'PSUBD ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $FB:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Subtract';
                  tempresult:=tempresult + 'PSUBQ ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Subtract';
                  tempresult:=tempresult + 'PSUBQ ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  inc(offset, last - 1);
                end;
              end;

            $FC:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Add';
                  tempresult:=tempresult + 'PADDB ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Add';
                  tempresult:=tempresult + 'PADDB ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $FD:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Add';
                  tempresult:=tempresult + 'PADDW ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Add';
                  tempresult:=tempresult + 'PADDW ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            $FE:
              begin
                if $66 in prefix2 then
                begin
                  description:='Packed Add';
                  tempresult:=tempresult + 'PADDD ' + xmm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 4, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Packed Add';
                  tempresult:=tempresult + 'PADDD ' + mm(memory[2]) + ',' + MODRM(memory, prefix2, 2, 3, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

          end;

        end;

      //

      //

      $10:
        begin
          description:='Add with carry';
          tempresult:=tempresult + 'ADC ' + MODRM(memory, prefix2, 1, 2, last) + r8(memory[1]);
          inc(offset, last - 1);
        end;

      $11:
        begin
          description:='Add with carry';
          if $66 in prefix2 then
            tempresult:=tempresult + 'ADC ' + MODRM(memory, prefix2, 1, 1, last) + r16(memory[1])
          else
            tempresult:=tempresult + 'ADC ' + MODRM(memory, prefix2, 1, 0, last) + r32(memory[1]);
          inc(offset, last - 1);

        end;

      $12:
        begin
          description:='Add with carry';
          tempresult:=tempresult + 'ADC ' + r8(memory[1]) + ',' + MODRM(memory, prefix2, 1, 2, last, 8);
          tempresult:=copy(tempresult, 1, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $13:
        begin
          description:='Add with carry';
          if $66 in prefix2 then
            tempresult:=tempresult + 'ADC ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last)
          else
            tempresult:=tempresult + 'ADC ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);
          tempresult:=copy(tempresult, 1, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $14:
        begin
          description:='Add with carry';
          tempresult:=tempresult + 'ADC AL,' + inttohexs(memory[1], 2);
          inc(offset);
        end;

      $15:
        begin
          description:='Add with carry';
          if $66 in prefix2 then
          begin
            wordptr:=@memory[1];
            tempresult:=tempresult + 'ADC AX,' + inttohexs(wordptr^, 4);
            inc(offset, 2);
          end
          else
          begin
            dwordptr:=@memory[1];
            tempresult:=tempresult + 'ADC EAX,' + inttohexs(dwordptr^, 8);
            inc(offset, 4);
          end;
        end;

      $16:
        begin
          description:='Place SS on the stack';
          tempresult:=tempresult + 'PUSH SS';
        end;

      $17:
        begin
          description:='Remove SS from the stack';
          tempresult:=tempresult + 'POP SS';
        end;

      $18:
        begin
          description:='Integer Subtraction with Borrow';
          tempresult:=tempresult + 'SBB ' + MODRM(memory, prefix2, 1, 2, last) + r8(memory[1]);
          inc(offset, last - 1);
        end;

      $19:
        begin
          description:='Integer Subtraction with Borrow';
          if $66 in prefix2 then
            tempresult:=tempresult + 'SBB ' + MODRM(memory, prefix2, 1, 1, last) + r16(memory[1])
          else
            tempresult:=tempresult + 'SBB ' + MODRM(memory, prefix2, 1, 0, last) + r32(memory[1]);
          inc(offset, last - 1);
        end;

      $1A:
        begin
          description:='Integer Subtraction with Borrow';
          tempresult:=tempresult + 'SBB ' + r8(memory[1]) + ',' + MODRM(memory, prefix2, 1, 2, last, 8);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $1B:
        begin
          description:='Integer subtraction with Borrow';
          if $66 in prefix2 then
            tempresult:=tempresult + 'SBB ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last)
          else
            tempresult:=tempresult + 'SBB ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);

          inc(offset, last - 1);
        end;

      $1C:
        begin
          description:='Integer Subtraction with Borrow';
          tempresult:=tempresult + 'SBB AL,' + inttohexs(memory[1], 2);
          inc(offset);
        end;

      $1D:
        begin
          description:='Integer Subtraction with Borrow';
          if $66 in prefix2 then
          begin
            wordptr:=@memory[1];
            tempresult:=tempresult + 'SBB AX,' + inttohexs(wordptr^, 4);
            inc(offset, 2);
          end
          else
          begin
            dwordptr:=@memory[1];
            tempresult:=tempresult + 'SBB EAX,' + inttohexs(dwordptr^, 8);
            inc(offset, 4);
          end;
        end;

      $1E:
        begin
          description:='Place DS on the stack';
          tempresult:=tempresult + 'PUSH DS';
        end;

      $1F:
        begin
          description:='Remove DS from the stack';
          tempresult:=tempresult + 'POP DS';
        end;

      $20:
        begin
          description:='Logical AND';
          tempresult:=tempresult + 'AND ' + MODRM(memory, prefix2, 1, 2, last) + r8(memory[1]);
          inc(offset, last - 1);
        end;

      $21:
        begin
          description:='Logical AND';
          if $66 in prefix2 then
            tempresult:=tempresult + 'AND ' + MODRM(memory, prefix2, 1, 1, last) + r16(memory[1])
          else
            tempresult:=tempresult + 'AND ' + MODRM(memory, prefix2, 1, 0, last) + r32(memory[1]);
          inc(offset, last - 1);

        end;

      $22:
        begin
          description:='Logical AND';
          tempresult:=tempresult + 'AND ' + r8(memory[1]) + ',' + MODRM(memory, prefix2, 1, 2, last);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $23:
        begin
          description:='Logical AND';
          if $66 in prefix2 then
            tempresult:=tempresult + 'AND ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last)
          else
            tempresult:=tempresult + 'AND ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $24:
        begin
          description:='Logical AND';
          tempresult:=tempresult + 'AND AL,' + inttohexs(memory[1], 2);
          inc(offset);
        end;

      $25:
        begin
          description:='Logical AND';
          if $66 in prefix2 then
          begin
            wordptr:=@memory[1];
            tempresult:=tempresult + 'AND AX,' + inttohexs(wordptr^, 4);
            inc(offset, 2);
          end
          else
          begin
            dwordptr:=@memory[1];
            tempresult:=tempresult + 'AND EAX,' + inttohexs(dwordptr^, 8);
            inc(offset, 4);
          end;
        end;

      $27:
        begin
          description:='Decimal Adjust AL after Addition';
          tempresult:=tempresult + 'DAA';
        end;

      $28:
        begin
          description:='Subtract';
          tempresult:=tempresult + 'SUB ' + MODRM(memory, prefix2, 1, 2, last) + r8(memory[1]);
          inc(offset, last - 1);
        end;

      $29:
        begin
          description:='Subtract';
          if $66 in prefix2 then
            tempresult:=tempresult + 'SUB ' + MODRM(memory, prefix2, 1, 1, last) + r16(memory[1])
          else
            tempresult:=tempresult + 'SUB ' + MODRM(memory, prefix2, 1, 0, last) + r32(memory[1]);
          inc(offset, last - 1);

        end;

      $2A:
        begin
          description:='Subtract';
          tempresult:=tempresult + 'SUB ' + r8(memory[1]) + ',' + MODRM(memory, prefix2, 1, 2, last);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $2B:
        begin
          description:='Subtract';
          if $66 in prefix2 then
            tempresult:=tempresult + 'SUB ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last)
          else
            tempresult:=tempresult + 'SUB ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $2C:
        begin
          description:='Subtract';
          tempresult:=tempresult + 'SUB AL,' + inttohexs(memory[1], 2);
          inc(offset);
        end;

      $2D:
        begin
          description:='Subtract';
          if $66 in prefix2 then
          begin
            wordptr:=@memory[1];
            tempresult:=tempresult + 'SUB AX,' + inttohexs(wordptr^, 4);
            inc(offset, 2);
          end
          else
          begin
            dwordptr:=@memory[1];
            tempresult:=tempresult + 'SUB EAX,' + inttohexs(dwordptr^, 8);
            inc(offset, 4);
          end;
        end;

      $2F:
        begin
          description:='Decimal Adjust AL after Subtraction';
          tempresult:=tempresult + 'DAS';
        end;

      $30:
        begin
          description:='Logical Exclusive OR';
          tempresult:=tempresult + 'XOR ' + MODRM(memory, prefix2, 1, 2, last) + r8(memory[1]);
          inc(offset, last - 1);
        end;

      $31:
        begin
          description:='Logical Exclusive OR';
          if $66 in prefix2 then
            tempresult:=tempresult + 'XOR ' + MODRM(memory, prefix2, 1, 1, last) + r16(memory[1])
          else
            tempresult:=tempresult + 'XOR ' + MODRM(memory, prefix2, 1, 0, last) + r32(memory[1]);
          inc(offset, last - 1);

        end;

      $32:
        begin
          description:='Logical Exclusive OR';
          tempresult:=tempresult + 'XOR ' + r8(memory[1]) + ',' + MODRM(memory, prefix2, 1, 2, last);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $33:
        begin
          description:='Logical Exclusive OR';
          if $66 in prefix2 then
            tempresult:=tempresult + 'XOR ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last)
          else
            tempresult:=tempresult + 'XOR ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);
          tempresult:=copy(tempresult, 1, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $34:
        begin
          description:='Logical Exclusive OR';
          tempresult:=tempresult + 'XOR AL,' + inttohexs(memory[1], 2);
          inc(offset);
        end;

      $35:
        begin
          description:='Logical Exclusive OR';
          if $66 in prefix2 then
          begin
            wordptr:=@memory[1];
            tempresult:=tempresult + 'XOR AX,' + inttohexs(wordptr^, 4);
            inc(offset, 2);
          end
          else
          begin
            dwordptr:=@memory[1];
            tempresult:=tempresult + 'XOR EAX,' + inttohexs(dwordptr^, 8);
            inc(offset, 4);
          end;
        end;

      $37:
        begin //AAA
          tempresult:=tempresult + 'AAA';
          description:='ASCII adjust AL after addition'
        end;

      //---------
      $38:
        begin //CMP
          description:='Compare Two Operands';
          tempresult:=tempresult + 'CMP ' + MODRM(memory, prefix2, 1, 2, last) + r8(memory[1]);
          inc(offset, last - 1);
        end;

      $39:
        begin
          description:='Compare Two Operands';
          if $66 in prefix2 then
            tempresult:=tempresult + 'CMP ' + MODRM(memory, prefix2, 1, 1, last) + r16(memory[1])
          else
            tempresult:=tempresult + 'CMP ' + MODRM(memory, prefix2, 1, 0, last) + r32(memory[1]);
          inc(offset, last - 1);

        end;

      $3A:
        begin
          description:='Compare Two Operands';
          tempresult:=tempresult + 'CMP ' + r8(memory[1]) + ',' + MODRM(memory, prefix2, 1, 2, last);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $3B:
        begin
          description:='Compare Two Operands';
          if $66 in prefix2 then
            tempresult:=tempresult + 'CMP ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last)
          else
            tempresult:=tempresult + 'CMP ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      //---------

      $3C:
        begin
          description:='Compare Two Operands';
          tempresult:=tempresult + 'CMP AL,' + inttohexs(memory[1], 2);
          inc(offset);
        end;

      $3D:
        begin
          description:='Compare Two Operands';
          if $66 in prefix2 then
          begin
            wordptr:=@memory[1];
            tempresult:=tempresult + 'CMP AX,' + inttohexs(wordptr^, 4);
            inc(offset, 2);
          end
          else
          begin
            dwordptr:=@memory[1];
            tempresult:=tempresult + 'CMP EAX,' + inttohexs(dwordptr^, 8);
            inc(offset, 4);
          end;
        end;

      $3F:
        begin //AAS
          tempresult:=tempresult + 'AAS';
          description:='ASCII Adjust AL After Subtraction';
        end;

      $40 .. $47:
        begin
          description:='Increment by 1';
          if $66 in prefix2 then
            tempresult:=tempresult + 'INC ' + rd16(memory[0] - $40)
          else
            tempresult:=tempresult + 'INC ' + rd(memory[0] - $40);
        end;

      $48 .. $4F:
        begin
          description:='Decrement by 1';
          if $66 in prefix2 then
            tempresult:=tempresult + 'DEC ' + rd16(memory[0] - $48)
          else
            tempresult:=tempresult + 'DEC ' + rd(memory[0] - $48);
        end;

      $50 .. $57:
        begin
          description:='Push Word or Doubleword Onto the Stack';
          if $66 in prefix2 then
            tempresult:=tempresult + 'PUSH ' + rd16(memory[0] - $50)
          else
            tempresult:=tempresult + 'PUSH ' + rd(memory[0] - $50);
        end;

      $58 .. $5F:
        begin
          description:='Pop a Value from the Stack';
          if $66 in prefix2 then
            tempresult:=tempresult + 'POP ' + rd16(memory[0] - $58)
          else
            tempresult:=tempresult + 'POP ' + rd(memory[0] - $58);
        end;

      $60:
        begin
          description:='Push All General-Purpose Registers';
          if $66 in prefix2 then
            tempresult:=tempresult + 'PUSHA'
          else
            tempresult:=tempresult + 'PUSHAD';
        end;

      $61:
        begin
          description:='Pop All General-Purpose Registers';
          if $66 in prefix2 then
            tempresult:=tempresult + 'POPA'
          else
            tempresult:=tempresult + 'POPAD';
        end;

      $62:
        begin
          //BOUND
          description:='Check Array Index Against Bounds';
          if $66 in prefix2 then
            tempresult:=tempresult + 'BOUND ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last)
          else
            tempresult:=tempresult + 'BOUND ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);

          tempresult:=copy(tempresult, 0, length(tempresult) - 1);

          inc(offset, last - 1);

        end;

      $63:
        begin
          //ARPL
          tempresult:=tempresult + 'ARPL ' + MODRM(memory, prefix2, 1, 1, last) + r16(memory[1]);
          inc(offset, last - 1);
          description:='Adjust RPL Field of Segment Selector';
        end;

      $68:
        begin
          if $66 in prefix2 then
          begin
            wordptr:=@memory[1];
            tempresult:=tempresult + 'PUSH ' + inttohexs(wordptr^, 4);
            inc(offset, 2);
          end
          else
          begin
            dwordptr:=@memory[1];
            tempresult:=tempresult + 'PUSH ' + inttohexs(dwordptr^, 8);
            inc(offset, 4);
          end;
          description:='Push Word or Doubleword Onto the Stack';
        end;

      $69:
        begin
          description:='Signed Multiply';
          if $66 in prefix2 then
          begin
            tempresult:=tempresult + 'IMUL ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last);
            wordptr:=@memory[last];
            tempresult:=tempresult + inttohexs(wordptr^, 4);
            inc(offset, last - 1 + 2);
          end
          else
          begin
            tempresult:=tempresult + 'IMUL ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);
            dwordptr:=@memory[last];
            tempresult:=tempresult + inttohexs(dwordptr^, 8);
            inc(offset, last - 1 + 4);
          end;
        end;

      $6A:
        begin
          tempresult:=tempresult + 'PUSH ' + inttohexs(memory[1], 2);
          inc(offset);
          description:='Push Byte Onto the Stack';
        end;

      $6B:
        begin

          description:='Signed Multiply';
          if $66 in prefix2 then
            tempresult:=tempresult + 'IMUL ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last) + inttohexs(memory[last], 2)
          else
            tempresult:=tempresult + 'IMUL ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last) + inttohexs(memory[last], 2);
          inc(offset, last - 1 + 1);
        end;

      $6C:
        begin
          //m8, DX
          description:='Input from Port to String';
          tempresult:=tempresult + 'INSB';
        end;

      $6D:
        begin
          //m8, DX
          description:='Input from Port to String';
          if $66 in prefix2 then
            tempresult:=tempresult + 'INSW'
          else
            tempresult:=tempresult + 'INSD';
        end;

      $6E:
        begin
          //m8, DX
          description:='Output String to Port';
          tempresult:=tempresult + 'OUTSB';
        end;

      $6F:
        begin
          //m8, DX
          description:='Output String to Port';
          if $66 in prefix2 then
            tempresult:=tempresult + 'OUTSW'
          else
            tempresult:=tempresult + 'OUTSD';
        end;

      $70:
        begin
          description:='Jump short if overflow';
          tempresult:=tempresult + 'JO ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $71:
        begin
          description:='Jump short if not overflow';
          tempresult:=tempresult + 'JNO ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $72:
        begin
          description:='Jump short if below/carry';
          tempresult:=tempresult + 'JB ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $73:
        begin
          description:='Jump short if above or equal';
          tempresult:=tempresult + 'JAE ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $74:
        begin
          description:='Jump short if equal';
          tempresult:=tempresult + 'JE ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $75:
        begin
          description:='Jump short if not equal';
          tempresult:=tempresult + 'JNE ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $76:
        begin
          description:='Jump short if not Above';
          tempresult:=tempresult + 'JNA ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $77:
        begin
          description:='Jump short if above';
          tempresult:=tempresult + 'JA ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $78:
        begin
          description:='Jump short if sign';
          tempresult:=tempresult + 'JS ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $79:
        begin
          description:='Jump short if not sign';
          tempresult:=tempresult + 'JNS ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $7A:
        begin
          description:='Jump short if parity';
          tempresult:=tempresult + 'JP ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $7B:
        begin
          description:='Jump short if not parity';
          tempresult:=tempresult + 'JNP ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $7C:
        begin
          description:='Jump short if not greater or equal';
          tempresult:=tempresult + 'JNGE ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $7D:
        begin
          description:='Jump short if not less (greater or equal)';
          tempresult:=tempresult + 'JNL ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $7E:
        begin
          description:='Jump short if less or equal';
          tempresult:=tempresult + 'JLE ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $7F:
        begin
          description:='Jump short if greater';
          tempresult:=tempresult + 'JG ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + shortint(memory[1])), 8);
        end;

      $80:
        begin
          case getREG(memory[1]) of
            0:
              begin
                //ADD
                tempresult:=tempresult + 'ADD ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                offset:=offset + last;
                description:='Add x to y';
              end;

            1:
              begin
                //ADC
                tempresult:=tempresult + 'OR ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                offset:=offset + last;
                description:='Logical Inclusive Or';
              end;

            2:
              begin
                //ADC
                tempresult:=tempresult + 'ADC ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                offset:=offset + last;
                description:='Add with Carry';
              end;

            3:
              begin
                //sbb
                tempresult:=tempresult + 'SBB ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                offset:=offset + last;
                description:='Integer Subtraction with Borrow';
              end;

            4:
              begin
                //AND
                tempresult:=tempresult + 'AND ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                offset:=offset + last;
                description:='Logical AND';
              end;

            5:
              begin
                tempresult:=tempresult + 'SUB ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                offset:=offset + last;
                description:='Subtract';
              end;

            6:
              begin
                tempresult:=tempresult + 'XOR ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                offset:=offset + last;
                description:='Logical Exclusive OR';
              end;

            7:
              begin
                //AND
                tempresult:=tempresult + 'CMP ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                offset:=offset + last;
                description:='Compare Two Operands';
              end;

          end;
        end;

      $81:
        begin
          case getREG(memory[1]) of
            0:
              begin
                //ADD
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'ADD ' + MODRM(memory, prefix2, 1, 1, last, 16);
                  wordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(wordptr^, 4);
                  inc(offset, last - 1 + 2);
                end
                else
                begin
                  tempresult:=tempresult + 'ADD ' + MODRM(memory, prefix2, 1, 0, last);
                  dwordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(dwordptr^, 8);
                  inc(offset, last - 1 + 4);
                end;

                //offset:=offset+last;
                description:='Add x to y';
              end;

            1:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'OR ' + MODRM(memory, prefix2, 1, 1, last, 16);
                  wordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(wordptr^, 4);
                  inc(offset, last - 1 + 2);
                end
                else
                begin
                  tempresult:=tempresult + 'OR ' + MODRM(memory, prefix2, 1, 0, last);
                  dwordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(dwordptr^, 8);
                  inc(offset, last - 1 + 4);
                end;

                description:='Logical Inclusive OR';
              end;

            2:
              begin
                //ADC
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'ADC ' + MODRM(memory, prefix2, 1, 1, last, 16);
                  wordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(wordptr^, 4);
                  inc(offset, last - 1 + 2);
                end
                else
                begin
                  tempresult:=tempresult + 'ADC ' + MODRM(memory, prefix2, 1, 0, last);
                  dwordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(dwordptr^, 8);
                  inc(offset, last - 1 + 4);
                end;

                description:='Add with Carry';
              end;

            3:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'SBB ' + MODRM(memory, prefix2, 1, 1, last, 16);
                  wordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(wordptr^, 4);
                  inc(offset, last - 1 + 2);
                end
                else
                begin
                  tempresult:=tempresult + 'SBB ' + MODRM(memory, prefix2, 1, 0, last);
                  dwordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(dwordptr^, 8);
                  inc(offset, last - 1 + 4);
                end;

                description:='Integer Subtraction with Borrow';
              end;

            4:
              begin
                //AND
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'AND ' + MODRM(memory, prefix2, 1, 1, last, 16);
                  wordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(wordptr^, 4);
                  inc(offset, last - 1 + 2);
                end
                else
                begin
                  tempresult:=tempresult + 'AND ' + MODRM(memory, prefix2, 1, 0, last);
                  dwordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(dwordptr^, 8);
                  inc(offset, last - 1 + 4);
                end;

                description:='Logical AND';
              end;

            5:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'SUB ' + MODRM(memory, prefix2, 1, 1, last);
                  wordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(wordptr^, 4);
                  inc(offset, last - 1 + 2);
                end
                else
                begin
                  tempresult:=tempresult + 'SUB ' + MODRM(memory, prefix2, 1, 0, last);
                  dwordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(dwordptr^, 8);
                  inc(offset, last - 1 + 4);
                end;

                description:='Subtract';
              end;

            6:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'XOR ' + MODRM(memory, prefix2, 1, 1, last, 16);
                  wordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(wordptr^, 4);
                  inc(offset, last - 1);
                end
                else
                begin
                  tempresult:=tempresult + 'XOR ' + MODRM(memory, prefix2, 1, 0, last);
                  dwordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(dwordptr^, 8);
                  inc(offset, last - 1 + 2);
                end;

                offset:=offset + last;
                description:='Logical Exclusive OR';
              end;

            7:
              begin
                //CMP
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'CMP ' + MODRM(memory, prefix2, 1, 1, last, 16);
                  wordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(wordptr^, 4);
                  inc(offset, last - 1 + 2);
                end
                else
                begin
                  tempresult:=tempresult + 'CMP ' + MODRM(memory, prefix2, 1, 0, last);
                  dwordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(dwordptr^, 8);
                  inc(offset, last - 1 + 4);
                end;

                description:='Compare Two Operands';
              end;

          end;
        end;

      $83:
        begin
          case getREG(memory[1]) of
            0:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'ADD ' + MODRM(memory, prefix2, 1, 1, last, 16) + inttohexs(memory[last], 2);
                end
                else
                begin
                  tempresult:=tempresult + 'ADD ' + MODRM(memory, prefix2, 1, 0, last, 32) + inttohexs(memory[last], 2);
                end;

                inc(offset, last);
                description:='Add (Sign Extended)';
              end;

            1:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'OR ' + MODRM(memory, prefix2, 1, 1, last, 16) + inttohexs(memory[last], 2);
                end
                else
                begin
                  tempresult:=tempresult + 'OR ' + MODRM(memory, prefix2, 1, 0, last, 32) + inttohexs(memory[last], 2);
                end;

                inc(offset, last);
                description:='Add (Sign Extended)';
              end;

            2:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'ADC ' + MODRM(memory, prefix2, 1, 1, last, 16) + inttohexs(memory[last], 2);
                end
                else
                begin
                  tempresult:=tempresult + 'ADC ' + MODRM(memory, prefix2, 1, 0, last, 32) + inttohexs(memory[last], 2);

                end;

                inc(offset, last);
                description:='Add with Carry (Sign Extended)';
              end;

            3:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'SBB ' + MODRM(memory, prefix2, 1, 1, last, 16) + inttohexs(memory[last], 2);
                end
                else
                begin
                  tempresult:=tempresult + 'SBB ' + MODRM(memory, prefix2, 1, 0, last, 32) + inttohexs(memory[last], 2);

                end;

                inc(offset, last);
                description:='Integer Subtraction with Borrow (Sign Extended)';
              end;

            4:
              begin
                //AND
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'AND ' + MODRM(memory, prefix2, 1, 1, last, 16) + inttohexs(memory[last], 2);
                end
                else
                begin
                  tempresult:=tempresult + 'AND ' + MODRM(memory, prefix2, 1, 0, last, 32) + inttohexs(memory[last], 2);

                end;

                offset:=offset + last;
                description:='Logical AND (Sign Extended)';
              end;

            5:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'SUB ' + MODRM(memory, prefix2, 1, 1, last, 16) + inttohexs(memory[last], 2);
                end
                else
                begin
                  tempresult:=tempresult + 'SUB ' + MODRM(memory, prefix2, 1, 0, last, 32) + inttohexs(memory[last], 2);

                end;

                offset:=offset + last;
                description:='Subtract';
              end;

            6:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'XOR ' + MODRM(memory, prefix2, 1, 1, last, 16) + inttohexs(memory[last], 2);
                end
                else
                begin
                  tempresult:=tempresult + 'XOR ' + MODRM(memory, prefix2, 1, 0, last, 32) + inttohexs(memory[last], 2);

                end;

                offset:=offset + last;
                description:='Logical Exclusive OR';
              end;

            7:
              begin
                //CMP
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'CMP ' + MODRM(memory, prefix2, 1, 1, last, 16) + inttohexs(memory[last], 2);
                end
                else
                begin
                  tempresult:=tempresult + 'CMP ' + MODRM(memory, prefix2, 1, 0, last, 32) + inttohexs(memory[last], 2);

                end;

                offset:=offset + last;
                description:='Compare Two Operands';
              end;

          end;
        end;

      $84:
        begin
          description:='Logical Compare';
          tempresult:=tempresult + 'TEST ' + r8(memory[1]) + ',' + MODRM(memory, prefix2, 1, 2, last);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $85:
        begin
          description:='Logical Compare';
          if $66 in prefix2 then
            tempresult:=tempresult + 'TEST ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last)
          else
            tempresult:=tempresult + 'TEST ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);
          tempresult:=copy(tempresult, 0, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $86:
        begin
          description:='Exchage Memory with Register';
          tempresult:=tempresult + 'XCHG ' + MODRM(memory, prefix2, 1, 2, last) + r8(memory[1]);
          inc(offset, last - 1);
        end;

      $87:
        begin
          description:='Exchage Memory with Register';
          if $66 in prefix2 then
            tempresult:=tempresult + 'XCHG ' + MODRM(memory, prefix2, 1, 1, last) + r16(memory[1])
          else
            tempresult:=tempresult + 'XCHG ' + MODRM(memory, prefix2, 1, 0, last) + r32(memory[1]);
          inc(offset, last - 1);
        end;

      $88:
        begin
          description:='Copy memory';
          tempresult:=tempresult + 'MOV ' + MODRM(memory, prefix2, 1, 2, last) + r8(memory[1]);
          inc(offset, last - 1);
        end;

      $89:
        begin
          description:='Copy memory';
          if $66 in prefix2 then
            tempresult:=tempresult + 'MOV ' + MODRM(memory, prefix2, 1, 1, last) + r32(memory[1])
          else
            tempresult:=tempresult + 'MOV ' + MODRM(memory, prefix2, 1, 0, last) + r32(memory[1]);
          inc(offset, last - 1);
        end;

      $8A:
        begin
          description:='Copy memory';
          tempresult:=tempresult + 'MOV ' + r8(memory[1]) + ',' + MODRM(memory, prefix2, 1, 2, last);
          tempresult:=copy(tempresult, 1, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $8B:
        begin
          description:='Copy memory';
          if $66 in prefix2 then
            tempresult:=tempresult + 'MOV ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last)
          else
            tempresult:=tempresult + 'MOV ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);
          tempresult:=copy(tempresult, 1, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $8C:
        begin
          description:='Copy memory';
          tempresult:=tempresult + 'MOV ' + MODRM(memory, prefix2, 1, 1, last) + sreg(memory[1]);
          inc(offset, last - 1);
        end;

      $8D:
        begin
          description:='Load Effective Address';
          if $66 in prefix2 then
            tempresult:=tempresult + 'LEA ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last)
          else
            tempresult:=tempresult + 'LEA ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);

          tempresult:=copy(tempresult, 1, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $8E:
        begin
          description:='Copy memory';
          tempresult:=tempresult + 'MOV ' + sreg(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last);
          tempresult:=copy(tempresult, 1, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $8F:
        begin
          case getREG(memory[1]) of
            0:
              begin
                description:='Pop a Value from the Stack';
                if $66 in prefix2 then
                  tempresult:='POP ' + MODRM(memory, prefix2, 1, 1, last, 16)
                else
                  tempresult:='POP ' + MODRM(memory, prefix2, 1, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

          else
            begin
              description:='Undefined by the intel specification';
              tempresult:='DB 8F';
            end;
          end;
        end;

      $90:
        begin
          description:='No Operation';
          tempresult:='NOP';
        end;

      $91 .. $97:
        begin
          description:='Exchagne Register with Register';
          if $66 in prefix2 then
            tempresult:=tempresult + 'XCHG AX,' + rd16(memory[0] - $90)
          else
            tempresult:=tempresult + 'XCHG EAX,' + rd(memory[0] - $90);
        end;

      $98:
        begin
          //CBW/CWDE
          if $66 in prefix2 then
          begin
            tempresult:=tempresult + 'CBW';
            description:='Convert Byte to Word';
          end
          else
          begin
            tempresult:=tempresult + 'CWDE';
            description:='Convert Word to Doubleword';
          end;
        end;

      $99:
        begin
          if $66 in prefix2 then
          begin
            description:='Convert Word to Doubleword';
            tempresult:=tempresult + 'CWD';
          end
          else
          begin
            description:='Convert Doubleword to Quadword';
            tempresult:=tempresult + 'CDQ';
          end;
        end;

      $9A:
        begin
          description:='Call Procedure';
          wordptr:=@memory[5];
          tempresult:=tempresult + 'CALL ' + inttohexs(wordptr^, 4) + ':';
          dwordptr:=@memory[1];
          tempresult:=tempresult + inttohexs(dwordptr^, 8);
          inc(offset, 6);
        end;

      $9B:
        begin //ehrm, wait???
          case memory[1] of

            $D9:
              begin
                case getREG(memory[2]) of
                  6:
                    begin
                      description:='Store FPU Environment';
                      tempresult:=tempresult + 'WAIT:FSTENV ' + MODRM(memory, prefix2, 2, 0, last);
                      inc(offset, last - 1);
                    end;

                  7:
                    begin
                      description:='Store Control Word';
                      tempresult:=tempresult + 'WAIT:FSTCW ' + MODRM(memory, prefix2, 2, 0, last);
                      inc(offset, last - 1);
                    end;
                end;
              end;

            $DB:
              begin
                case memory[2] of
                  $E2:
                    begin
                      description:='Clear Exceptions';
                      tempresult:=tempresult + 'WAIT:FCLEX';
                      inc(offset, 2);
                    end;

                  $E3:
                    begin
                      description:='Initialize Floaring-Point Unit';
                      tempresult:=tempresult + 'WAIT:FINIT';
                      inc(offset, 2);
                    end;
                end;
              end;

            $DD:
              begin
                case getREG(memory[2]) of
                  6:
                    begin
                      description:='Store FPU State';
                      tempresult:=tempresult + 'WAIT:FSAVE ' + MODRM(memory, prefix2, 2, 0, last);
                      inc(offset, last - 1);
                    end;

                  7:
                    begin
                      description:='Store Status Word';
                      tempresult:=tempresult + 'WAIT:FSTSW ' + MODRM(memory, prefix2, 2, 0, last);
                      inc(offset, last - 1);
                    end;
                end;
              end;

            $DF:
              begin
                case memory[2] of
                  $E0:
                    begin
                      description:='Store Status Word';
                      tempresult:=tempresult + 'WAIT:FSTSW AX';
                      inc(offset, 2);
                    end;
                end;
              end;

          else
            begin
              description:='Wait';
              tempresult:=tempresult + 'WAIT';
            end;

          end;

        end;

      $9C:
        begin
          description:='Push EFLAGS Register onto the Stack';
          if $66 in prefix2 then
            tempresult:=tempresult + 'PUSHF'
          else
            tempresult:=tempresult + 'PUSHFD';
        end;

      $9D:
        begin
          description:='Pop Stack into EFLAGS Register';
          if $66 in prefix2 then
            tempresult:=tempresult + 'POPF'
          else
            tempresult:=tempresult + 'POPFD';
        end;

      $9E:
        begin
          description:='Store AH into Flags';
          tempresult:=tempresult + 'SAHF';
        end;

      $9F:
        begin
          description:='Load Status Flag into AH Register';
          tempresult:=tempresult + 'LAHF';
        end;

      $A0:
        begin
          description:='Copy memory';
          dwordptr:=@memory[1];
          tempresult:=tempresult + 'MOV AX,' + getsegmentoverride(prefix2) + '[' + inttohexs(dwordptr^, 8) + ']';
          inc(offset, 4);
        end;

      $A1:
        begin
          description:='Copy memory';
          dwordptr:=@memory[1];
          if $66 in prefix2 then
            tempresult:=tempresult + 'MOV AX,' + getsegmentoverride(prefix2) + '[' + inttohexs(dwordptr^, 8) + ']'
          else
            tempresult:=tempresult + 'MOV EAX,' + getsegmentoverride(prefix2) + '[' + inttohexs(dwordptr^, 8) + ']';
          inc(offset, 4);
        end;

      $A2:
        begin
          description:='Copy memory';
          dwordptr:=@memory[1];
          tempresult:=tempresult + 'MOV byte ptr ' + getsegmentoverride(prefix2) + '[' + inttohexs(dwordptr^, 8) + '],AL';
          inc(offset, 4);
        end;

      $A3:
        begin
          description:='Copy memory';
          dwordptr:=@memory[1];
          tempresult:=tempresult + 'MOV ' + getsegmentoverride(prefix2) + '[' + inttohexs(dwordptr^, 8) + '],';
          if $66 in prefix2 then
            tempresult:=tempresult + 'AX'
          else
            tempresult:=tempresult + 'EAX';
          inc(offset, 4);
        end;

      $A4:
        begin
          description:='Move Data from String to String';
          tempresult:=tempresult + 'MOVSB';
        end;

      $A5:
        begin
          description:='Move Data from String to String';
          if $66 in prefix2 then
            tempresult:=tempresult + 'MOVSW'
          else
            tempresult:=tempresult + 'MOVSD';
        end;

      $A6:
        begin
          description:='Compare String Operands';
          tempresult:=tempresult + 'CMPSB';
        end;

      $A7:
        begin
          description:='Compare String Operands';
          if $66 in prefix2 then
            tempresult:=tempresult + 'CMPSW'
          else
            tempresult:=tempresult + 'CMPSD';
        end;

      $A8:
        begin
          description:='Logical Compare';
          tempresult:=tempresult + 'TEST AL,' + inttohexs(memory[1], 2);
          inc(offset);
        end;

      $A9:
        begin
          description:='Logical Compare';
          if $66 in prefix2 then
          begin
            wordptr:=@memory[1];
            tempresult:=tempresult + 'TEST AX,' + inttohexs(wordptr^, 4);
            inc(offset, 2);
          end
          else
          begin
            dwordptr:=@memory[1];
            tempresult:=tempresult + 'TEST EAX,' + inttohexs(dwordptr^, 8);
            inc(offset, 4);
          end;
        end;

      $AA:
        begin
          description:='Store String';
          tempresult:=tempresult + 'STOSB';
        end;

      $AB:
        begin
          description:='Store String';
          if $66 in prefix2 then
            tempresult:=tempresult + 'STOSW'
          else
            tempresult:=tempresult + 'STOSD';
        end;

      $AC:
        begin
          description:='Compare String Operands';
          tempresult:=tempresult + 'LODSB';
        end;

      $AD:
        begin
          description:='Compare String Operands';
          if $66 in prefix2 then
            tempresult:=tempresult + 'LODSW'
          else
            tempresult:=tempresult + 'LODSD';
        end;

      $AE:
        begin
          description:='Compare AL with byte at ES:EDI and set status flag';
          tempresult:=tempresult + 'SCASB';
        end;

      $AF:
        begin
          description:='Scan String';
          if $66 in prefix2 then
            tempresult:=tempresult + 'SCASW'
          else
            tempresult:=tempresult + 'SCASD';
        end;

      $B0 .. $B7:
        begin
          description:='Copy Memory';
          tempresult:=tempresult + 'MOV ' + rd8(memory[0] - $B0) + ',' + inttohexs(memory[1], 2);
          inc(offset);
        end;

      $B8 .. $BF:
        begin
          description:='Copy Memory';
          if $66 in prefix2 then
          begin
            wordptr:=@memory[1];
            tempresult:=tempresult + 'MOV ' + rd16(memory[0] - $B8) + ',' + inttohexs(wordptr^, 4);
            inc(offset, 2);
          end
          else
          begin
            dwordptr:=@memory[1];
            tempresult:=tempresult + 'MOV ' + rd(memory[0] - $B8) + ',' + inttohexs(dwordptr^, 8);
            inc(offset, 4);
          end;
        end;

      $C0:
        begin
          case getREG(memory[1]) of
            0:
              begin
                tempresult:=tempresult + 'ROL ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                description:='Rotate eight bits left ' + inttostr(memory[last]) + ' times';
                inc(offset, last);
              end;

            1:
              begin
                tempresult:=tempresult + 'ROR ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                description:='Rotate eight bits right ' + inttostr(memory[last]) + ' times';
                inc(offset, last);
              end;

            2:
              begin
                tempresult:=tempresult + 'RCL ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                description:='Rotate nine bits left ' + inttostr(memory[last]) + ' times';
                inc(offset, last);
              end;

            3:
              begin
                tempresult:=tempresult + 'RCR ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                description:='Rotate nine bits right ' + inttostr(memory[last]) + ' times';
                inc(offset, last);
              end;

            4:
              begin
                tempresult:=tempresult + 'SHL ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                description:='Multiply by 2, ' + inttostr(memory[last]) + ' times';
                inc(offset, last);
              end;

            5:
              begin
                tempresult:=tempresult + 'SHR ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                description:='Unsigned divide by 2, ' + inttostr(memory[last]) + ' times';
                inc(offset, last);
              end;

            {Not in intel spec}
            6:
              begin
                tempresult:=tempresult + 'ROL ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                description:='Rotate eight bits left ' + inttostr(memory[last]) + ' times';
                inc(offset, last);
              end;
            {^^^^^^^^^^^^^^^^^^}

            7:
              begin
                tempresult:=tempresult + 'SAR ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                description:='Signed divide by 2, ' + inttostr(memory[last]) + ' times';
                inc(offset, last);
              end;

          end;
        end;

      $C1:
        begin
          case getREG(memory[1]) of
            0:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'ROL ' + MODRM(memory, prefix2, 1, 1, last, 16) + inttohexs(memory[last], 2);
                  description:='Rotate 16 bits left ' + inttostr(memory[last]) + ' times';
                  inc(offset, last);
                end
                else
                begin
                  tempresult:=tempresult + 'ROL ' + MODRM(memory, prefix2, 1, 0, last) + inttohexs(memory[last], 2);
                  description:='Rotate 32 bits left ' + inttostr(memory[last]) + ' times';
                  inc(offset, last);
                end;
              end;

            1:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'ROR ' + MODRM(memory, prefix2, 1, 1, last, 16) + inttohexs(memory[last], 2);
                  description:='Rotate 16 bits right ' + inttostr(memory[last]) + ' times';
                  inc(offset, last);
                end
                else
                begin
                  tempresult:=tempresult + 'ROR ' + MODRM(memory, prefix2, 1, 0, last) + inttohexs(memory[last], 2);
                  description:='Rotate 32 bits right ' + inttostr(memory[last]) + ' times';
                  inc(offset, last);
                end;
              end;

            2:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'RCL ' + MODRM(memory, prefix2, 1, 1, last, 16) + inttohexs(memory[last], 2);
                  description:='Rotate 17 bits left ' + inttostr(memory[last]) + ' times';
                  inc(offset, last);
                end
                else
                begin
                  tempresult:=tempresult + 'RCL ' + MODRM(memory, prefix2, 1, 0, last) + inttohexs(memory[last], 2);
                  description:='Rotate 33 bits left ' + inttostr(memory[last]) + ' times';
                  inc(offset, last);
                end;
              end;

            3:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'RCR ' + MODRM(memory, prefix2, 1, 1, last, 16) + inttohexs(memory[last], 2);
                  description:='Rotate 17 bits right ' + inttostr(memory[last]) + ' times';
                  inc(offset, last);
                end
                else
                begin
                  tempresult:=tempresult + 'RCR ' + MODRM(memory, prefix2, 1, 0, last) + inttohexs(memory[last], 2);
                  description:='Rotate 33 bits right ' + inttostr(memory[last]) + ' times';
                  inc(offset, last);
                end;
              end;

            4:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'SHL ' + MODRM(memory, prefix2, 1, 1, last, 16) + inttohexs(memory[last], 2);
                  description:='Multiply by 2 ' + inttostr(memory[last]) + ' times';
                  inc(offset, last);
                end
                else
                begin
                  tempresult:=tempresult + 'SHL ' + MODRM(memory, prefix2, 1, 0, last) + inttohexs(memory[last], 2);
                  description:='Multiply by 2 ' + inttostr(memory[last]) + ' times';
                  inc(offset, last);
                end;
              end;

            5:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'SHR ' + MODRM(memory, prefix2, 1, 1, last, 16) + inttohexs(memory[last], 2);
                  description:='Unsigned divide by 2 ' + inttostr(memory[last]) + ' times';
                  inc(offset, last);
                end
                else
                begin
                  tempresult:=tempresult + 'SHR ' + MODRM(memory, prefix2, 1, 0, last) + inttohexs(memory[last], 2);
                  description:='Unsigned divide by 2 ' + inttostr(memory[last]) + ' times';
                  inc(offset, last);
                end;
              end;

            7:
              begin
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'SAR ' + MODRM(memory, prefix2, 1, 2, last, 16) + inttohexs(memory[last], 2);
                  description:='Signed divide by 2 ' + inttostr(memory[last]) + ' times';
                  inc(offset, last);
                end
                else
                begin
                  tempresult:=tempresult + 'SAR ' + MODRM(memory, prefix2, 1, 2, last) + inttohexs(memory[last], 2);
                  description:='Signed divide by 2 ' + inttostr(memory[last]) + ' times';
                  inc(offset, last);
                end;
              end;

          end;
        end;

      $C2:
        begin
          description:='Near return to calling procedure and pop 2 bytes from stack';
          wordptr:=@memory[1];
          tempresult:=tempresult + 'RET ' + inttohexs(wordptr^, 4);
          inc(offset, 2);
        end;

      $C3:
        begin
          description:='Near return to calling procedure';
          tempresult:=tempresult + 'RET';
        end;

      $C4:
        begin
          description:='Load Far Pointer';
          if $66 in prefix2 then
            tempresult:=tempresult + 'LES ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last)
          else
            tempresult:=tempresult + 'LES ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);

          tempresult:=copy(tempresult, 1, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $C5:
        begin
          description:='Load Far Pointer';
          if $66 in prefix2 then
            tempresult:=tempresult + 'LDS ' + r16(memory[1]) + ',' + MODRM(memory, prefix2, 1, 1, last)
          else
            tempresult:=tempresult + 'LDS ' + r32(memory[1]) + ',' + MODRM(memory, prefix2, 1, 0, last);

          tempresult:=copy(tempresult, 1, length(tempresult) - 1);
          inc(offset, last - 1);
        end;

      $C6:
        begin
          case getREG(memory[1]) of
            0:
              begin
                description:='Copy Memory';
                tempresult:=tempresult + 'MOV ' + MODRM(memory, prefix2, 1, 2, last, 8) + '' + inttohexs(memory[last], 2);
                inc(offset, last);
              end;

          else
            begin
              description:='Not defined by the intel documentation';
              tempresult:=tempresult + 'DB C6';
            end;
          end;
        end;

      $C7:
        begin
          case getREG(memory[1]) of
            0:
              begin
                description:='Copy Memory';
                if $66 in prefix2 then
                begin
                  wordptr:=@memory[1];
                  tempresult:=tempresult + 'MOV ' + MODRM(memory, prefix2, 1, 1, last, 16);

                  wordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(wordptr^, 4);
                  inc(offset, last + 1);
                end
                else
                begin
                  dwordptr:=@memory[1];
                  tempresult:=tempresult + 'MOV ' + MODRM(memory, prefix2, 1, 0, last);

                  dwordptr:=@memory[last];
                  tempresult:=tempresult + inttohexs(dwordptr^, 8);
                  inc(offset, last + 3);
                end;
              end;

          else
            begin
              description:='Not defined by the intel documentation';
              tempresult:=tempresult + 'DB C7';
            end;

          end;
        end;

      $C8:
        begin
          description:='Make Stack Frame for Procedure Parameters';
          wordptr:=@memory[1];
          tempresult:=tempresult + 'ENTER ' + inttohexs(wordptr^, 4) + ',' + inttohexs(memory[3], 2);
          inc(offset, 3);
        end;

      $C9:
        begin
          description:='High Level Procedure Exit';
          tempresult:=tempresult + 'LEAVE';
        end;

      $CA:
        begin
          description:='Far return to calling procedure and pop 2 bytes from stack';
          wordptr:=@memory[1];
          tempresult:=tempresult + 'RET ' + inttohexs(wordptr^, 4);
          inc(offset, 2);
        end;

      $CB:
        begin
          description:='Far return to calling procedure';
          tempresult:=tempresult + 'RET';
        end;

      $CC:
        begin
          //should not be shown if its being debugged using int 3'
          description:='Call to Interrupt Procedure-3:Trap to debugger';
          tempresult:=tempresult + 'INT 3';
        end;

      $CD:
        begin
          description:='Call to Interrupt Procedure';
          tempresult:=tempresult + 'INT ' + inttohexs(memory[1], 2);
          inc(offset);
        end;

      $CE:
        begin
          description:='Call to Interrupt Procedure-4:If overflow flag=1';
          tempresult:=tempresult + 'INTO';
        end;

      $CF:
        begin
          description:='Interrupt Return';
          if $66 in prefix2 then
            tempresult:=tempresult + 'IRET'
          else
            tempresult:=tempresult + 'IRETD';
        end;

      $D0:
        begin
          case getREG(memory[1]) of
            0:
              begin
                description:='Rotate eight bits left once';
                tempresult:=tempresult + 'ROL ' + MODRM(memory, prefix2, 1, 2, last, 8) + '1';
                inc(offset, last - 1);
              end;

            1:
              begin
                description:='Rotate eight bits right once';
                tempresult:=tempresult + 'ROR ' + MODRM(memory, prefix2, 1, 2, last, 8) + '1';
                inc(offset, last - 1);
              end;

            2:
              begin
                description:='Rotate nine bits left once';
                tempresult:=tempresult + 'RCL ' + MODRM(memory, prefix2, 1, 2, last, 8) + '1';
                inc(offset, last - 1);
              end;

            3:
              begin
                description:='Rotate nine bits right once';
                tempresult:=tempresult + 'RCR ' + MODRM(memory, prefix2, 1, 2, last, 8) + '1';
                inc(offset, last - 1);
              end;

            4:
              begin
                description:='Multiply by 2, once';
                tempresult:=tempresult + 'SHL ' + MODRM(memory, prefix2, 1, 2, last, 8) + '1';
                inc(offset, last - 1);
              end;

            5:
              begin
                description:='Unsigned devide by 2, once';
                tempresult:=tempresult + 'SHR ' + MODRM(memory, prefix2, 1, 2, last, 8) + '1';
                inc(offset, last - 1);
              end;

            6:
              begin
                description:='Not defined by the intel documentation';
                tempresult:='DB D0' + inttohexs(memory[1], 2);
              end;

            7:
              begin
                description:='Signed devide by 2, once';
                tempresult:=tempresult + 'SAR ' + MODRM(memory, prefix2, 1, 2, last, 8) + '1';
                inc(offset, last - 1);
              end;

          end;
        end;

      $D1:
        begin
          case getREG(memory[1]) of
            0:
              begin
                if $66 in prefix2 then
                begin
                  description:='Rotate 16 bits left once';
                  tempresult:=tempresult + 'ROL ' + MODRM(memory, prefix2, 1, 1, last, 16) + '1';
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Rotate 32 bits left once';
                  tempresult:=tempresult + 'ROL ' + MODRM(memory, prefix2, 1, 0, last) + '1';
                  inc(offset, last - 1);
                end;
              end;

            1:
              begin
                if $66 in prefix2 then
                begin
                  description:='Rotate 16 bits right once';
                  tempresult:=tempresult + 'ROR ' + MODRM(memory, prefix2, 1, 1, last, 16) + '1';
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Rotate 32 bits right once';
                  tempresult:=tempresult + 'ROR ' + MODRM(memory, prefix2, 1, 0, last) + '1';
                  inc(offset, last - 1);
                end;
              end;

            2:
              begin
                if $66 in prefix2 then
                begin
                  description:='Rotate 17 bits left once';
                  tempresult:=tempresult + 'RCL ' + MODRM(memory, prefix2, 1, 1, last, 16) + '1';
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Rotate 33 bits left once';
                  tempresult:=tempresult + 'RCL ' + MODRM(memory, prefix2, 1, 0, last) + '1';
                  inc(offset, last - 1);
                end;
              end;

            3:
              begin
                if $66 in prefix2 then
                begin
                  description:='Rotate 17 bits right once';
                  tempresult:=tempresult + 'RCR ' + MODRM(memory, prefix2, 1, 1, last, 16) + '1';
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Rotate 33 bits right once';
                  tempresult:=tempresult + 'RCR ' + MODRM(memory, prefix2, 1, 0, last) + '1';
                  inc(offset, last - 1);
                end;
              end;

            4:
              begin
                if $66 in prefix2 then
                begin
                  description:='Multiply by 2, Once';
                  tempresult:=tempresult + 'SHL ' + MODRM(memory, prefix2, 1, 1, last, 16) + '1';
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Multiply by 2, once';
                  tempresult:=tempresult + 'SHL ' + MODRM(memory, prefix2, 1, 0, last) + '1';
                  inc(offset, last - 1);
                end;
              end;

            5:
              begin
                if $66 in prefix2 then
                begin
                  description:='Unsigned divide by 2, Once';
                  tempresult:=tempresult + 'SHR ' + MODRM(memory, prefix2, 1, 1, last, 16) + '1';
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Unsigned divide by 2, once';
                  tempresult:=tempresult + 'SHR ' + MODRM(memory, prefix2, 1, 0, last) + '1';
                  inc(offset, last - 1);
                end;
              end;

            6:
              begin
                description:='Undefined by the intel documentation';
                tempresult:='DB D1';
              end;

            7:
              begin
                if $66 in prefix2 then
                begin
                  description:='Signed divide by 2, Once';
                  tempresult:=tempresult + 'SAR ' + MODRM(memory, prefix2, 1, 1, last, 16) + '1';
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Signed divide by 2, once';
                  tempresult:=tempresult + 'SAR ' + MODRM(memory, prefix2, 1, 0, last) + '1';
                  inc(offset, last - 1);
                end;
              end;

          end;
        end;

      $D2:
        begin
          case getREG(memory[1]) of
            0:
              begin
                description:='Rotate eight bits left CL times';
                tempresult:=tempresult + 'ROL ' + MODRM(memory, prefix2, 1, 2, last, 8) + 'CL';
                inc(offset, last - 1);
              end;

            1:
              begin
                description:='Rotate eight bits right CL times';
                tempresult:=tempresult + 'ROR ' + MODRM(memory, prefix2, 1, 2, last, 8) + 'CL';
                inc(offset, last - 1);
              end;

            2:
              begin
                description:='Rotate nine bits left CL times';
                tempresult:=tempresult + 'RCL ' + MODRM(memory, prefix2, 1, 2, last, 8) + 'CL';
                inc(offset, last - 1);
              end;

            3:
              begin
                description:='Rotate nine bits right CL times';
                tempresult:=tempresult + 'RCR ' + MODRM(memory, prefix2, 1, 2, last, 8) + 'CL';
                inc(offset, last - 1);
              end;

            4:
              begin
                description:='Multiply by 2, CL times';
                tempresult:=tempresult + 'SHL ' + MODRM(memory, prefix2, 1, 2, last, 8) + 'CL';
                inc(offset, last - 1);
              end;

            5:
              begin
                description:='Unsigned devide by 2, CL times';
                tempresult:=tempresult + 'SHR ' + MODRM(memory, prefix2, 1, 2, last, 8) + 'CL';
                inc(offset, last - 1);
              end;

            6:
              begin
                description:='Multiply by 2, CL times';
                tempresult:=tempresult + 'SHL ' + MODRM(memory, prefix2, 1, 2, last, 8) + 'CL';
                inc(offset, last - 1);
              end;

            7:
              begin
                description:='Signed devide by 2, CL times';
                tempresult:=tempresult + 'SAR ' + MODRM(memory, prefix2, 1, 2, last, 8) + 'CL';
                inc(offset, last - 1);
              end;

          end;
        end;

      $D3:
        begin
          case getREG(memory[1]) of
            0:
              begin
                if $66 in prefix2 then
                begin
                  description:='Rotate 16 bits left CL times';
                  tempresult:=tempresult + 'ROL ' + MODRM(memory, prefix2, 1, 1, last, 16) + 'CL';
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Rotate 32 bits left CL times';
                  tempresult:=tempresult + 'ROL ' + MODRM(memory, prefix2, 1, 0, last) + 'CL';
                  inc(offset, last - 1);
                end;
              end;

            1:
              begin
                if $66 in prefix2 then
                begin
                  description:='Rotate 16 bits right CL times';
                  tempresult:=tempresult + 'ROR ' + MODRM(memory, prefix2, 1, 1, last, 16) + 'CL';
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Rotate 32 bits right CL times';
                  tempresult:=tempresult + 'ROR ' + MODRM(memory, prefix2, 1, 0, last) + 'CL';
                  inc(offset, last - 1);
                end;
              end;

            2:
              begin
                if $66 in prefix2 then
                begin
                  description:='Rotate 17 bits left CL times';
                  tempresult:=tempresult + 'RCL ' + MODRM(memory, prefix2, 1, 1, last, 16) + 'CL';
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Rotate 33 bits left CL times';
                  tempresult:=tempresult + 'RCL ' + MODRM(memory, prefix2, 1, 0, last) + 'CL';
                  inc(offset, last - 1);
                end;
              end;

            3:
              begin
                if $66 in prefix2 then
                begin
                  description:='Rotate 17 bits right CL times';
                  tempresult:=tempresult + 'RCR ' + MODRM(memory, prefix2, 1, 1, last, 16) + 'CL';
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Rotate 33 bits right CL times';
                  tempresult:=tempresult + 'RCR ' + MODRM(memory, prefix2, 1, 0, last) + 'CL';
                  inc(offset, last - 1);
                end;
              end;

            4:
              begin
                if $66 in prefix2 then
                begin
                  description:='Multiply by 2, CL times';
                  tempresult:=tempresult + 'SHL ' + MODRM(memory, prefix2, 1, 1, last, 16) + 'CL';
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Multiply by 2, CL times';
                  tempresult:=tempresult + 'SHL ' + MODRM(memory, prefix2, 1, 0, last) + 'CL';
                  inc(offset, last - 1);
                end;
              end;

            5:
              begin
                if $66 in prefix2 then
                begin
                  description:='Unsigned divide by 2, CL times';
                  tempresult:=tempresult + 'SHR ' + MODRM(memory, prefix2, 1, 1, last, 16) + 'CL';
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Unsigned divide by 2, CL times';
                  tempresult:=tempresult + 'SHR ' + MODRM(memory, prefix2, 1, 0, last) + 'CL';
                  inc(offset, last - 1);
                end;
              end;

            7:
              begin
                if $66 in prefix2 then
                begin
                  description:='Signed divide by 2, CL times';
                  tempresult:=tempresult + 'SAR ' + MODRM(memory, prefix2, 1, 1, last, 16) + 'CL';
                  inc(offset, last - 1);
                end
                else
                begin
                  description:='Signed divide by 2, CL times';
                  tempresult:=tempresult + 'SAR ' + MODRM(memory, prefix2, 1, 0, last) + 'CL';
                  inc(offset, last - 1);
                end;
              end;

          end;
        end;

      $D4:
        begin //AAM
          inc(offset);
          tempresult:=tempresult + 'AAM';
          description:='ASCII Adjust AX After Multiply';
          if memory[1] <> $0A then
            tempresult:=tempresult + ' ' + inttohexs(memory[1], 2);
        end;

      $D5:
        begin //AAD
          inc(offset);
          tempresult:=tempresult + 'AAD';
          description:='ASCII adjust AX before division';
          if memory[1] <> $0A then
            tempresult:=tempresult + ' ' + inttohexs(memory[1], 2);
        end;

      $D7:
        begin
          description:='Table Look-up Translation';
          tempresult:=tempresult + 'XLATB';
        end;

      $D8:
        begin
          case getREG(memory[1]) of
            0:
              begin
                //fadd
                description:='Add';
                last:=2;
                if memory[1] >= $C0 then
                  tempresult:=tempresult + 'FADD ST(' + inttostr(memory[1] - $C0) + ')'
                else
                begin
                  tempresult:=tempresult + 'FADD ' + MODRM(memory, prefix2, 1, 0, last, 32);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

            1:
              begin
                description:='Multiply';
                last:=2;
                if memory[1] >= $C8 then
                  tempresult:=tempresult + 'FMUL ST(' + inttostr(memory[1] - $C8) + ')'
                else
                begin
                  tempresult:=tempresult + 'FMUL ' + MODRM(memory, prefix2, 1, 0, last, 32);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

            2:
              begin
                description:='Compare Real';
                last:=2;
                if memory[1] >= $D0 then
                  tempresult:=tempresult + 'FCOM ST(' + inttostr(memory[1] - $D0) + ')'
                else
                begin
                  tempresult:=tempresult + 'FCOM ' + MODRM(memory, prefix2, 1, 0, last, 32);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

            3:
              begin
                description:='Compare Real and pop register stack';
                last:=2;
                if memory[1] >= $D8 then
                  tempresult:=tempresult + 'FCOMP ST(' + inttostr(memory[1] - $D8) + ')'
                else
                begin
                  tempresult:=tempresult + 'FCOMP ' + MODRM(memory, prefix2, 1, 0, last, 32);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

            4:
              begin
                description:='Substract';
                last:=2;
                if memory[1] >= $E0 then
                  tempresult:=tempresult + 'FSUB ST(' + inttostr(memory[1] - $E0) + ')'
                else
                begin
                  tempresult:=tempresult + 'FSUB ' + MODRM(memory, prefix2, 1, 0, last, 32);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

            5:
              begin
                description:='Reverse Substract';
                last:=2;
                if memory[1] >= $E0 then
                  tempresult:=tempresult + 'FSUBR ST(' + inttostr(memory[1] - $E0) + ')'
                else
                begin
                  tempresult:=tempresult + 'FSUBR ' + MODRM(memory, prefix2, 1, 0, last, 32);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

            6:
              begin
                description:='Divide';
                last:=2;
                if memory[1] >= $F0 then
                  tempresult:=tempresult + 'FDIV ST(' + inttostr(memory[1] - $D8) + ')'
                else
                begin
                  tempresult:=tempresult + 'FDIV ' + MODRM(memory, prefix2, 1, 0, last, 32);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

            7:
              begin
                description:='Reverse Divide';
                last:=2;
                if memory[1] >= $F8 then
                  tempresult:=tempresult + 'FDIVR ST(' + inttostr(memory[1] - $D8) + ')'
                else
                begin
                  tempresult:=tempresult + 'FDIVR ' + MODRM(memory, prefix2, 1, 0, last, 32);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;
          end;

        end;

      $D9:
        begin
          case memory[1] of
            $00 .. $BF:
              begin
                case getREG(memory[1]) of
                  0:
                    begin
                      description:='Load Floating Point Value';
                      tempresult:=tempresult + 'FLD ' + MODRM(memory, prefix2, 1, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  2:
                    begin
                      description:='Store Real';
                      tempresult:=tempresult + 'FST ' + MODRM(memory, prefix2, 1, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  3:
                    begin
                      description:='Store Real';
                      tempresult:=tempresult + 'FSTP ' + MODRM(memory, prefix2, 1, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  4:
                    begin
                      description:='Load FPU Environment';
                      tempresult:=tempresult + 'FLDENV ' + MODRM(memory, prefix2, 1, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  5:
                    begin
                      description:='Load Control Word';
                      tempresult:=tempresult + 'FLDCW ' + MODRM(memory, prefix2, 1, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  6:
                    begin
                      description:='Store FPU Environment';
                      tempresult:=tempresult + 'FNSTENV ' + MODRM(memory, prefix2, 1, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  7:
                    begin
                      description:='Store Control Word';
                      tempresult:=tempresult + 'FNSTCW ' + MODRM(memory, prefix2, 1, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                end;
              end;

            $C0 .. $C7:
              begin
                description:='Push ST(i) onto the FPU register stack';
                tempresult:=tempresult + 'FLD ST(' + inttostr(memory[1] - $C0) + ')';
                inc(offset);
              end;

            $C8 .. $CF:
              begin
                description:='Exchange Register Contents';
                tempresult:=tempresult + 'FLD ST(' + inttostr(memory[1] - $C8) + ')';
                inc(offset);
              end;

            $D9 .. $DF:
              begin
                description:='Exchagne Register contents';
                tempresult:=tempresult + 'FXCH ST(' + inttostr(memory[1] - $D9) + ')';
                inc(offset);
              end;

            $D0:
              begin
                description:='No Operation';
                tempresult:=tempresult + 'FNOP';
                inc(offset);
              end;

            $E0:
              begin
                description:='Change Sign';
                tempresult:=tempresult + 'FCHS';
                inc(offset);
              end;

            $E1:
              begin
                description:='Absolute Value';
                tempresult:=tempresult + 'FABS';
                inc(offset);
              end;

            $E4:
              begin
                description:='TEST';
                tempresult:=tempresult + 'FTST';
                inc(offset);
              end;

            $E5:
              begin
                description:='Examine';
                tempresult:=tempresult + 'FXAM';
                inc(offset);
              end;

            $E8:
              begin
                description:='Load constant';
                tempresult:=tempresult + 'FLD1';
                inc(offset);
              end;

            $E9:
              begin
                description:='Load constant';
                tempresult:=tempresult + 'FLDL2T';
                inc(offset);
              end;

            $EA:
              begin
                description:='Load constant';
                tempresult:=tempresult + 'FLD2E';
                inc(offset);
              end;

            $EB:
              begin
                description:='Load constant';
                tempresult:=tempresult + 'FLDPI';
                inc(offset);
              end;

            $EC:
              begin
                description:='Load constant';
                tempresult:=tempresult + 'FLDLG2';
                inc(offset);
              end;

            $ED:
              begin
                description:='Load constant';
                tempresult:=tempresult + 'FLDLN2';
                inc(offset);
              end;

            $EE:
              begin
                description:='Load constant';
                tempresult:=tempresult + 'FLDZ';
                inc(offset);
              end;

            $F0:
              begin
                description:='Compute 2^x–1';
                tempresult:=tempresult + 'F2XM1';
                inc(offset);
              end;

            $F1:
              begin
                description:='Compute y*log(2)x';
                tempresult:=tempresult + 'FYL2X';
                inc(offset);
              end;

            $F2:
              begin
                description:='Partial Tangent';
                tempresult:=tempresult + 'FPTAN';
                inc(offset);
              end;

            $F3:
              begin
                description:='Partial Arctangent';
                tempresult:=tempresult + 'FPATAN';
                inc(offset);
              end;

            $F4:
              begin
                description:='Extract Exponent and Significand';
                tempresult:=tempresult + 'FXTRACT';
                inc(offset);
              end;

            $F5:
              begin
                description:='Partial Remainder';
                tempresult:=tempresult + 'FPREM1';
                inc(offset);
              end;

            $F6:
              begin
                description:='Decrement Stack-Top Pointer';
                tempresult:='FDECSTP';
                inc(offset);
              end;

            $F7:
              begin
                description:='Increment Stack-Top Pointer';
                tempresult:='FINCSTP';
                inc(offset);
              end;

            $F8:
              begin
                description:='Partial Remainder';
                tempresult:=tempresult + 'FPREM';
                inc(offset);
              end;

            $F9:
              begin
                description:='Compute y*log(2)(x+1)';
                tempresult:=tempresult + 'FYL2XP1';
                inc(offset);
              end;

            $FA:
              begin
                description:='Square Root';
                tempresult:=tempresult + 'FSQRT';
                inc(offset);
              end;

            $FB:
              begin
                description:='Sine and Cosine';
                tempresult:=tempresult + 'FSINCOS';
                inc(offset);
              end;

            $FC:
              begin
                description:='Round to Integer';
                tempresult:=tempresult + 'FRNDINT';
                inc(offset);
              end;

            $FD:
              begin
                description:='Scale';
                tempresult:=tempresult + 'FSCALE';
                inc(offset);
              end;

            $FE:
              begin
                description:='Sine';
                tempresult:=tempresult + 'FSIN';
                inc(offset);
              end;

            $FF:
              begin
                description:='Cosine';
                tempresult:=tempresult + 'FCOS';
                inc(offset);
              end;
          end;
        end;

      $DA:
        begin
          if memory[1] < $BF then
          begin
            case getREG(memory[1]) of
              0:
                begin
                  description:='Add';
                  tempresult:=tempresult + 'FIADD ' + MODRM(memory, prefix2, 1, 0, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;

              1:
                begin
                  description:='Multiply';
                  tempresult:=tempresult + 'FIMUL ' + MODRM(memory, prefix2, 1, 0, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;

              2:
                begin
                  description:='Compare Integer';
                  tempresult:=tempresult + 'FICOM ' + MODRM(memory, prefix2, 1, 0, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;

              3:
                begin
                  description:='Compare Integer';
                  tempresult:=tempresult + 'FICOMP ' + MODRM(memory, prefix2, 1, 0, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;

              4:
                begin
                  description:='Subtract';
                  tempresult:=tempresult + 'FISUB ' + MODRM(memory, prefix2, 1, 0, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;

              5:
                begin
                  description:='Reverse Subtract';
                  tempresult:=tempresult + 'FISUBR ' + MODRM(memory, prefix2, 1, 0, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;

              6:
                begin
                  description:='Devide';
                  tempresult:=tempresult + 'FIDIV ' + MODRM(memory, prefix2, 1, 0, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;

              7:
                begin
                  description:='Reverse Devide';
                  tempresult:=tempresult + 'FIDIVR ' + MODRM(memory, prefix2, 1, 0, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
            end;
          end
          else
          begin
            case getREG(memory[1]) of
              0:
                begin
                  description:='Floating-Point: Move if below';
                  tempresult:='FCMOVB ST(' + inttostr(memory[1] - $C0) + ')';
                  inc(offset);
                end;

              1:
                begin
                  description:='Floating-Point: Move if equal';
                  tempresult:='FCMOVE ST(' + inttostr(memory[1] - $C8) + ')';
                  inc(offset);
                end;

              2:
                begin
                  description:='Floating-Point: Move if below or equal';
                  tempresult:='FCMOVBE ST(' + inttostr(memory[1] - $D0) + ')';
                  inc(offset);
                end;

              3:
                begin
                  description:='Floating-Point: Move if unordered';
                  tempresult:='FCMOVU ST(' + inttostr(memory[1] - $D8) + ')';
                  inc(offset);
                end;

              5:
                begin
                  case memory[1] of
                    $E9:
                      begin
                        description:='Unordered Compare Real';
                        tempresult:=tempresult + 'FUCOMPP';
                        inc(offset);
                      end;
                  end;
                end;
            end;
          end;
        end;

      $DB:
        begin
          case memory[1] of
            $0 .. $BF:
              begin
                case getREG(memory[1]) of
                  0:
                    begin
                      description:='Load Integer';
                      tempresult:=tempresult + 'FILD ' + MODRM(memory, prefix2, 1, 0, last, 32);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  2:
                    begin
                      description:='Store Integer';
                      tempresult:=tempresult + 'FIST ' + MODRM(memory, prefix2, 1, 0, last, 32);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  3:
                    begin
                      description:='Store Integer';
                      tempresult:=tempresult + 'FISTP ' + MODRM(memory, prefix2, 1, 0, last, 32);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  5:
                    begin
                      description:='Load Floating Point Value';
                      tempresult:=tempresult + 'FLD ' + MODRM(memory, prefix2, 1, 0, last, 64);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  7:
                    begin
                      description:='Store Real';
                      tempresult:=tempresult + 'FSTP ' + MODRM(memory, prefix2, 1, 0, last, 80);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                end;
              end;

            $C0 .. $C7:
              begin
                description:='Floating-Point: Move if not below';
                tempresult:='FCMOVNB ST(' + inttostr(memory[1] - $C0) + ')';
                inc(offset);
              end;

            $C8 .. $CF:
              begin
                description:='Floating-Point: Move if not equal';
                tempresult:='FCMOVNE ST(' + inttostr(memory[1] - $C8) + ')';
                inc(offset);
              end;

            $D0 .. $D7:
              begin
                description:='Floating-Point: Move if not below or equal';
                tempresult:='FCMOVNBE ST(' + inttostr(memory[1] - $D0) + ')';
                inc(offset);
              end;

            $D8 .. $DF:
              begin
                description:='Floating-Point: Move if not unordered';
                tempresult:='FCMOVNU ST(' + inttostr(memory[1] - $D8) + ')';
                inc(offset);
              end;

            $E2:
              begin
                description:='Clear Exceptions';
                tempresult:=tempresult + 'FNCLEX';
                inc(offset);
              end;

            $E3:
              begin
                description:='Initialize floating-Point Unit';
                tempresult:=tempresult + 'FNINIT';
                inc(offset);
              end;

            $E8 .. $EF:
              begin
                description:='Floating-Point: Compare Real and Set EFLAGS';
                tempresult:='FUCOMI ST(' + inttostr(memory[1] - $E8) + ')';
                inc(offset);
              end;

            $F0 .. $F7:
              begin
                description:='Floating-Point: Compare Real and Set EFLAGS';
                tempresult:='FCOMI ST(' + inttostr(memory[1] - $F0) + ')';
                inc(offset);
              end;
          end;

        end;

      $DC:
        begin
          case getREG(memory[1]) of
            0:
              begin
                //fadd
                description:='Add';
                last:=2;
                if memory[1] >= $C0 then
                  tempresult:=tempresult + 'FADD ST(' + inttostr(memory[1] - $C0) + ')'
                else
                begin
                  tempresult:=tempresult + 'FADD ' + MODRM(memory, prefix2, 1, 0, last, 64);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

            1:
              begin
                description:='Multiply';
                last:=2;
                if memory[1] >= $C8 then
                  tempresult:=tempresult + 'FMUL ST(' + inttostr(memory[1] - $C8) + ')'
                else
                begin
                  tempresult:=tempresult + 'FMUL ' + MODRM(memory, prefix2, 1, 0, last, 64);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

            2:
              begin
                description:='Compare Real';
                last:=2;
                tempresult:=tempresult + 'FCOM ' + MODRM(memory, prefix2, 1, 0, last, 64);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            3:
              begin
                description:='Compare Real';
                last:=2;
                tempresult:=tempresult + 'FCOMP ' + MODRM(memory, prefix2, 1, 0, last, 64);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            4:
              begin
                description:='Subtract';
                last:=2;
                if memory[1] >= $E0 then
                  tempresult:=tempresult + 'FSUB ST(' + inttostr(memory[1] - $E0) + ')'
                else
                begin
                  tempresult:=tempresult + 'FSUB ' + MODRM(memory, prefix2, 1, 0, last, 64);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

            5:
              begin
                description:='Reverse Subtract';
                last:=2;
                if memory[1] >= $E8 then
                  tempresult:=tempresult + 'FSUBR ST(' + inttostr(memory[1] - $E8) + ')'
                else
                begin
                  tempresult:=tempresult + 'FSUBR ' + MODRM(memory, prefix2, 1, 0, last, 64);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;

                inc(offset, last - 1);
              end;

            6:
              begin
                description:='Divide';
                last:=2;
                if memory[1] >= $F0 then
                  tempresult:=tempresult + 'FDIV ST(' + inttostr(memory[1] - $F0) + '),ST(0)'
                else
                begin
                  tempresult:=tempresult + 'FDIV ' + MODRM(memory, prefix2, 1, 0, last, 64);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

            7:
              begin
                description:='Reverse Divide';
                last:=2;
                if memory[1] >= $F0 then
                  tempresult:=tempresult + 'FDIVR ST(' + inttostr(memory[1] - $F8) + '),ST(0)'
                else
                begin
                  tempresult:=tempresult + 'FDIVR ' + MODRM(memory, prefix2, 1, 0, last, 64);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;
          end;
        end;

      $DD:
        begin
          case memory[1] of
            $0 .. $BF:
              begin
                case getREG(memory[1]) of
                  0:
                    begin
                      description:='Load floating point value';
                      tempresult:=tempresult + 'FLD ' + MODRM(memory, prefix2, 1, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  2:
                    begin
                      description:='Store Real';
                      tempresult:=tempresult + 'FST ' + MODRM(memory, prefix2, 1, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  3:
                    begin
                      description:='Store Real';
                      tempresult:=tempresult + 'FSTP ' + MODRM(memory, prefix2, 1, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  4:
                    begin
                      description:='Restore FPU State';
                      tempresult:=tempresult + 'FRSTOR ' + MODRM(memory, prefix2, 1, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  6:
                    begin
                      description:='Store FPU State';
                      tempresult:=tempresult + 'FSAVE ' + MODRM(memory, prefix2, 1, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                  7:
                    begin
                      description:='Store Status Word';
                      tempresult:=tempresult + 'FNSTSW ' + MODRM(memory, prefix2, 1, 0, last);
                      tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                      inc(offset, last - 1);
                    end;

                end;

              end;

            $C0 .. $C7:
              begin
                description:='Free Floating-Point Register';
                tempresult:=tempresult + 'FFREE ST(' + inttostr(memory[1] - $C0) + ')';
                inc(offset);
              end;

            $D0 .. $D7:
              begin
                description:='Store Real';
                tempresult:=tempresult + 'FST ST(' + inttostr(memory[1] - $D0) + ')';
                inc(offset);
              end;

            $D8 .. $DF:
              begin
                description:='Store Real';
                tempresult:=tempresult + 'FSTP ST(' + inttostr(memory[1] - $D8) + ')';
                inc(offset);
              end;

            $E0 .. $E7:
              begin
                description:='Unordered Compare Real';
                tempresult:=tempresult + 'FUCOM ST(' + inttostr(memory[1] - $E0) + ')';
                inc(offset);
              end;

            $E8 .. $EF:
              begin
                description:='Unordered Compare Real';
                tempresult:=tempresult + 'FUCOMP ST(' + inttostr(memory[1] - $E0) + ')';
                inc(offset);
              end;
          else
            tempresult:=tempresult + 'DB ' + inttohexs(memory[0], 2);

          end;
        end;

      $DE:
        begin
          case getREG(memory[1]) of
            0:
              begin
                //faddp
                description:='Add and pop';
                last:=2;
                if (memory[1] = $C1) then
                  tempresult:=tempresult + 'FADDP'
                else if memory[1] > $C0 then
                  tempresult:=tempresult + 'FADDP ST(' + inttostr(memory[1] - $C0) + ')'
                else
                begin
                  description:='Add';
                  tempresult:=tempresult + 'FIADD ' + MODRM(memory, prefix2, 1, 0, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

            1:
              begin
                description:='Multiply';
                last:=2;
                if memory[1] >= $C8 then
                  tempresult:=tempresult + 'FMULP ST(' + inttostr(memory[1] - $C0) + '),ST(0)'
                else
                begin
                  tempresult:=tempresult + 'FIMUL ' + MODRM(memory, prefix2, 1, 0, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;

                inc(offset, last - 1);
              end;

            2:
              begin
                description:='Compare Integer';
                last:=2;
                tempresult:=tempresult + 'FICOM' + MODRM(memory, prefix2, 1, 0, last);
                inc(offset, last - 1);
              end;

            3:
              begin
                if memory[1] < $C0 then
                begin
                  description:='Compare Integer';
                  tempresult:=tempresult + 'FICOMP ' + MODRM(memory, prefix2, 1, 0, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;

                if memory[1] = $D9 then
                begin
                  description:='Compare Real and pop register stack twice';
                  tempresult:=tempresult + 'FCOMPP';
                  inc(offset);
                end;
              end;

            4:
              begin
                description:='Subtract';
                last:=2;
                if memory[1] >= $E0 then
                  tempresult:=tempresult + 'FSUBRP ST(' + inttostr(memory[1] - $C0) + '),ST(0)'
                else
                begin
                  tempresult:=tempresult + 'FISUB ' + MODRM(memory, prefix2, 1, 0, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

            5:
              begin
                description:='Reverse Devide';
                last:=2;
                if memory[1] >= $E8 then
                  tempresult:=tempresult + 'FSUB ST(' + inttostr(memory[1] - $E8) + ')';
                begin
                  tempresult:=tempresult + 'FISUBR ' + MODRM(memory, prefix2, 1, 0, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;

                inc(offset, last - 1);
              end;

            6:
              begin
                description:='Reverse Devide';
                last:=2;
                if memory[1] >= $F0 then
                begin
                  tempresult:=tempresult + 'FDIVRP ST(' + inttostr(memory[1] - $F0) + ')';
                  inc(offset, last - 1);
                end
                else
                  tempresult:='DB DE'
              end;

            7:
              begin
                description:='Devide';
                last:=2;
                if memory[1] >= $F8 then
                  tempresult:=tempresult + 'FDIVP ST(' + inttostr(memory[1] - $F8) + ')'
                else
                begin
                  tempresult:=tempresult + 'FDIVR ' + MODRM(memory, prefix2, 1, 0, last);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

          end;
        end;

      $DF:
        begin
          case getREG(memory[1]) of
            0:
              begin
                description:='Load Integer';
                tempresult:='FILD ' + MODRM(memory, prefix2, 1, 0, last, 16);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            2:
              begin
                description:='Store Integer';
                tempresult:='FIST ' + MODRM(memory, prefix2, 1, 0, last, 16);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            3:
              begin
                description:='Store Integer';
                tempresult:='FISTP ' + MODRM(memory, prefix2, 1, 0, last, 16);
                inc(offset, last - 1);
              end;

            4:
              begin
                description:='Load Binary Coded Decimal';
                last:=2;
                if memory[1] >= $E0 then
                  tempresult:=tempresult + 'FNSTSW AX'
                else
                begin
                  tempresult:='FBLD ' + MODRM(memory, prefix2, 1, 0, last, 80);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                end;
                inc(offset, last - 1);
              end;

            5:
              begin
                if memory[1] < $C0 then
                begin
                  description:='Load Integer';
                  tempresult:='FILD ' + MODRM(memory, prefix2, 1, 0, last, 128);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;

                if memory[1] >= $E8 then
                begin
                  description:='Compare Real and Set EFLAGS';
                  tempresult:='FUCOMIP ST,(' + inttostr(memory[1] - $E8) + ')';
                  inc(offset);
                end;
              end;

            6:
              begin
                if memory[1] >= $F0 then
                begin
                  description:='Compare Real and Set EFLAGS';
                  tempresult:='FCOMI ST,(' + inttostr(memory[1] - $F0) + ')';
                end
                else
                begin
                  description:='Store BCD Integer and Pop';
                  tempresult:='FBSTP ' + MODRM(memory, prefix2, 1, 0, last, 80);
                  tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                  inc(offset, last - 1);
                end;
              end;

            7:
              begin
                description:='Store Integer';
                tempresult:='FISTP ' + MODRM(memory, prefix2, 1, 0, last, 64);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;
          else
            tempresult:=tempresult + 'DB ' + inttohexs(memory[0], 2);
          end;

        end;

      $E0:
        begin
          description:='Loop According to ECX counter';
          if $66 in prefix2 then
          begin
            tempresult:=tempresult + 'LOOPNE ';
            inc(offset);
            tempresult:=tempresult + inttohexs(dword(offset + pshortint(@memory[1])^), 8);
          end
          else
          begin
            tempresult:=tempresult + 'LOOPNZ ';
            inc(offset);
            tempresult:=tempresult + inttohexs(dword(offset + pshortint(@memory[1])^), 8);
          end;
        end;

      $E1:
        begin
          description:='Loop According to ECX counter';
          if $66 in prefix2 then
          begin
            tempresult:=tempresult + 'LOOPE ';
          end
          else
          begin
            tempresult:=tempresult + 'LOOPZ ';
          end;
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + pshortint(@memory[1])^), 0);
        end;

      $E2:
        begin
          description:='Loop According to ECX counting';
          tempresult:=tempresult + 'LOOP ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + pshortint(@memory[1])^), 0);
        end;

      $E3:
        begin
          description:='Jump short if CX=0';
          if $66 in prefix2 then
            tempresult:=tempresult + 'JCXZ '
          else
            tempresult:=tempresult + 'JECXZ ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + pshortint(@memory[1])^), 8);
        end;

      $E4:
        begin
          description:='Input from Port';
          tempresult:='IN AL,' + inttohexs(memory[1], 2);
          inc(offset);
        end;

      $E5:
        begin
          description:='Input from Port';
          if $66 in prefix2 then
            tempresult:=tempresult + 'IN AX,' + inttohexs(memory[1], 2)
          else
            tempresult:=tempresult + 'IN EAX,' + inttohexs(memory[1], 2);
          inc(offset);

        end;

      $E6:
        begin
          description:='Output to Port';
          tempresult:='OUT ' + inttohexs(memory[1], 2) + ',AL';
          inc(offset);
        end;

      $E7:
        begin
          description:='Output to Port';
          if $66 in prefix2 then
            tempresult:=tempresult + 'OUT ' + inttohexs(memory[1], 2) + ',AX'
          else
            tempresult:=tempresult + 'OUT ' + inttohexs(memory[1], 2) + ',EAX';
          inc(offset);

        end;

      $E8:
        begin
          //call
          //this time no $66 prefix because it will only run in win32
          description:='Call Procedure';
          tempresult:=tempresult + 'CALL ';
          inc(offset, 4);

          tempresult:=tempresult + inttohexs(offset + pint(@memory[1])^, 8);
        end;

      $E9:
        begin
          description:='Jump near';
          if $66 in prefix2 then
          begin
            tempresult:=tempresult + 'JMP ';
            inc(offset, 2);
            tempresult:=tempresult + inttohexs(dword(offset + psmallint(@memory[1])^), 8);
          end
          else
          begin
            tempresult:=tempresult + 'JMP ';
            inc(offset, 4);
            tempresult:=tempresult + inttohexs(dword(offset + pInteger(@memory[1])^), 8);
          end;

        end;

      $EA:
        begin
          description:='Jump far';
          wordptr:=@memory[5];
          tempresult:=tempresult + 'JMP ' + inttohexs(wordptr^, 4) + ':';
          dwordptr:=@memory[1];
          tempresult:=tempresult + inttohexs(dwordptr^, 8);
          inc(offset, 6);
        end;

      $EB:
        begin
          description:='Jump short';
          tempresult:=tempresult + 'JMP ';
          inc(offset);
          tempresult:=tempresult + inttohexs(dword(offset + pshortint(@memory[1])^), 8);
        end;

      $EC:
        begin
          description:='Input from Port';
          tempresult:=tempresult + 'IN AL,DX';
        end;

      $ED:
        begin
          description:='Input from Port';
          if $66 in prefix2 then
            tempresult:=tempresult + 'IN AX,DX'
          else
            tempresult:=tempresult + 'IN EAX,DX';
        end;

      $EE:
        begin
          description:='Input from Port';
          tempresult:=tempresult + 'OUT DX,AL';
        end;

      $EF:
        begin
          description:='Input from Port';
          if $66 in prefix2 then
            tempresult:=tempresult + 'OUT DX,AX'
          else
            tempresult:=tempresult + 'OUT DX,EAX';
        end;

      $F4:
        begin
          description:='Halt';
          tempresult:=tempresult + 'HLT';
        end;

      $F5:
        begin
          description:='Complement Carry Flag';
          tempresult:=tempresult + 'CMC';
        end;

      $F6:
        begin
          case getREG(memory[1]) of
            0:
              begin
                description:='Logical Compare';
                tempresult:=tempresult + 'TEST ' + MODRM(memory, prefix2, 1, 2, last, 8) + inttohexs(memory[last], 2);
                inc(offset, last);
              end;

            2:
              begin
                description:='One''s Complement Negation';
                tempresult:=tempresult + 'NOT ' + MODRM(memory, prefix2, 1, 2, last, 8);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            3:
              begin
                description:='Two''s Complement Negation';
                tempresult:=tempresult + 'NEG ' + MODRM(memory, prefix2, 1, 2, last, 8);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            4:
              begin
                description:='Unsigned Multiply';
                tempresult:=tempresult + 'MUL ' + MODRM(memory, prefix2, 1, 2, last, 8);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            5:
              begin
                description:='Signed Multiply';
                tempresult:=tempresult + 'IMUL ' + MODRM(memory, prefix2, 1, 2, last, 8);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            6:
              begin
                description:='Unsigned Divide';
                tempresult:=tempresult + 'DIV ' + MODRM(memory, prefix2, 1, 2, last, 8);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            7:
              begin
                description:='Signed Divide';
                tempresult:=tempresult + 'IDIV ' + MODRM(memory, prefix2, 1, 2, last, 8);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;
          else
            tempresult:=tempresult + 'DB ' + inttohexs(memory[0], 2);

          end;
        end;

      $F7:
        begin
          case getREG(memory[1]) of
            0:
              begin
                description:='Logical Compare';
                if $66 in prefix2 then
                begin
                  tempresult:=tempresult + 'NOT ' + MODRM(memory, prefix2, 1, 1, last, 16);
                  wordptr:=@memory[last];
                  tempresult:=tempresult + '' + inttohexs(wordptr^, 4);
                  inc(offset, last + 1);
                end
                else
                begin
                  tempresult:=tempresult + 'NOT ' + MODRM(memory, prefix2, 1, 0, last);
                  dwordptr:=@memory[last];
                  tempresult:=tempresult + '' + inttohexs(dwordptr^, 4);
                  inc(offset, last + 3);
                end;
              end;

            2:
              begin
                description:='One''s Complement Negation';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'NOT ' + MODRM(memory, prefix2, 1, 1, last, 16)
                else
                  tempresult:=tempresult + 'NOT ' + MODRM(memory, prefix2, 1, 0, last);

                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            3:
              begin
                description:='Two''s Complement Negation';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'NEG ' + MODRM(memory, prefix2, 1, 1, last, 16)
                else
                  tempresult:=tempresult + 'NEG ' + MODRM(memory, prefix2, 1, 0, last);

                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            4:
              begin
                description:='Unsigned Multiply';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'MUL ' + MODRM(memory, prefix2, 1, 1, last, 16)
                else
                  tempresult:=tempresult + 'MUL ' + MODRM(memory, prefix2, 1, 0, last);

                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            5:
              begin
                description:='Signed Multiply';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'IMUL ' + MODRM(memory, prefix2, 1, 1, last, 16)
                else
                  tempresult:=tempresult + 'IMUL ' + MODRM(memory, prefix2, 1, 0, last);

                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            6:
              begin
                description:='Unsigned Divide';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'DIV ' + MODRM(memory, prefix2, 1, 1, last, 16)
                else
                  tempresult:=tempresult + 'DIV ' + MODRM(memory, prefix2, 1, 0, last);

                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            7:
              begin
                description:='Signed Divide';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'IDIV ' + MODRM(memory, prefix2, 1, 1, last, 16)
                else
                  tempresult:=tempresult + 'IDIV ' + MODRM(memory, prefix2, 1, 0, last);

                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

          else
            tempresult:=tempresult + 'DB ' + inttohexs(memory[0], 2);
          end;
        end;

      $F8:
        begin
          description:='Clear Carry Flag';
          tempresult:=tempresult + 'CLC';
        end;

      $F9:
        begin
          description:='Set Carry Flag';
          tempresult:=tempresult + 'STC';
        end;

      $FA:
        begin
          description:='Clear Interrupt Flag';
          tempresult:=tempresult + 'CLI';
        end;

      $FB:
        begin
          description:='Set Interrupt Flag';
          tempresult:=tempresult + 'STI';
        end;

      $FC:
        begin
          description:='Clear Direction Flag';
          tempresult:=tempresult + 'CLD';
        end;

      $FD:
        begin
          description:='Set Direction Flag';
          tempresult:=tempresult + 'STD';
        end;

      $FE:
        begin
          case getREG(memory[1]) of
            0:
              begin
                description:='Increment by 1';
                tempresult:=tempresult + 'INC ' + MODRM(memory, prefix2, 1, 2, last, 8);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            1:
              begin
                description:='Decrement by 1';
                tempresult:=tempresult + 'DEC ' + MODRM(memory, prefix2, 1, 2, last, 7);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

          else
            tempresult:=tempresult + 'DB ' + inttohexs(memory[0], 2);
          end;
        end;

      $FF:
        begin
          case getREG(memory[1]) of
            0:
              begin
                description:='Increment by 1';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'INC ' + MODRM(memory, prefix2, 1, 1, last, 16)
                else
                  tempresult:=tempresult + 'INC ' + MODRM(memory, prefix2, 1, 0, last);

                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            1:
              begin
                description:='Decrement by 1';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'DEC ' + MODRM(memory, prefix2, 1, 1, last, 16)
                else
                  tempresult:=tempresult + 'DEC ' + MODRM(memory, prefix2, 1, 0, last);

                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            2:
              begin
                //call
                description:='Call Procedure';
                if memory[1] >= $C0 then
                  tempresult:='CALL ' + MODRM(memory, prefix2, 1, 0, last)
                else
                  tempresult:='CALL ' + MODRM(memory, prefix2, 1, 0, last, 32);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            3:
              begin
                //call
                description:='Call Procedure';
                tempresult:='CALL ' + MODRM(memory, prefix2, 1, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            4:
              begin
                //call
                description:='Jump near';
                if memory[1] >= $C0 then
                  tempresult:='JMP ' + MODRM(memory, prefix2, 1, 0, last)
                else
                  tempresult:='JMP ' + MODRM(memory, prefix2, 1, 0, last, 32);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            5:
              begin
                //call
                description:='Jump far';
                tempresult:='JMP ' + MODRM(memory, prefix2, 1, 0, last);
                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;

            6:
              begin
                description:='Push Word or Doubleword Onto the Stack';
                if $66 in prefix2 then
                  tempresult:=tempresult + 'PUSH ' + MODRM(memory, prefix2, 1, 1, last)
                else
                  tempresult:=tempresult + 'PUSH ' + MODRM(memory, prefix2, 1, 0, last);

                tempresult:=copy(tempresult, 1, length(tempresult) - 1);
                inc(offset, last - 1);
              end;
          else
            tempresult:=tempresult + 'DB ' + inttohexs(memory[0], 2);

          end;

        end;

    else
      begin
        tempresult:='DB ' + inttohex(memory[0], 2);
      end;
    end;
    result:=tempresult;
  end
  else
  begin
    result:='??';
    inc(offset);
  end;

  result:=lowercase(result);
end;

function disassemble(var offset: dword): string; overload;
var
  ignore: string;
begin
  result:=disassemble(offset, ignore);
end;

function previousopcode(address: dword): dword;
var
  x, y: dword;
  s: string;
  i: integer;
begin
  y:=address - 40;

  while y < address do
  begin
    x:=y;
    disassemble(y, s);
  end;

  i:=address - 20;
  while (i < address) and (y <> address) do
  begin
    y:=i;
    while y < address do
    begin
      x:=y;
      disassemble(y, s);
    end;
    inc(i);
  end;

  if i = address then
    result:=address - 1
  else
    result:=x;

  //if x<>address then result:=address-1 else result:=y;
end;

function translatestring(disassembled: string; numberofbytes: integer): string;
var
  offset: dword;
  e: integer;
  i, j, k: integer;
  ts: string;
begin
  ts:=disassembled;
  val('$' + disassembled, offset, e);

  result:=inttohex(offset, 8) + ' - ';

  i:=pos('-', disassembled);
  if i = 0 then
    exit;

  ts[i]:=' ';
  inc(i, 2);
  j:=pos('-', ts);
  if j = 0 then
  begin
    result:=result + '??';
    exit;
  end;

  dec(j, 2);

  if (j - i) > 2 * numberofbytes then
  begin
    result:=result + copy(disassembled, i, (2 * (numberofbytes) - 1));
    result:=result + '...';
  end
  else
  begin
    ts:=copy(disassembled, i, j - i);

    k:=2 * (numberofbytes);

    while length(ts) < k + 2 do
      ts:=ts + ' ';

    result:=result + ts;
  end;

  result:=result + copy(disassembled, j + 1, length(disassembled) - j);
end;

function inttohexs(address: dword; chars: integer): string;
begin
  result:=sysutils.inttohex(address, chars);
end;

end.
