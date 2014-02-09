unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, VirtualizeClass, StdCtrls;

type
  TfrmMain = class(TForm)
    btnTest: TButton;
    eExample1: TEdit;
    eExample2: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
  private
    {Private declarations}
  public
    {Public declarations}
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure ExampleFunction1;
begin
  asm
    db $EB, $06, $FE, $28, $29, $FE, $22, $00
  end;
  Messagebox(frmMain.Handle, 'Example Function 1', 'Example', MB_ICONASTERISK);
  asm
    db $EB, $06, $FE, $28, $29, $FE, $22, $01
  end;
end;

procedure ExampleFunction2;
begin
  asm
    db $EB, $06, $FE, $28, $29, $FE, $22, $00
  end;
  Messagebox(frmMain.Handle, 'Example Function 2', 'Example', MB_ICONASTERISK);
  asm
    db $EB, $06, $FE, $28, $29, $FE, $22, $01
  end;
end;

procedure TfrmMain.btnTestClick(Sender: TObject);
begin
  ExampleFunction1;
  ExampleFunction2;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  VirtualizeInitialize;
  eExample1.Text:=IntToHex(Dword(@ExampleFunction1), 8);
  eExample2.Text:=IntToHex(Dword(@ExampleFunction2), 8);
end;

end.
