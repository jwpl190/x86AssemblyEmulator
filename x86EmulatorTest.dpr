program x86EmulatorTest;

uses
  Forms,
  MainForm in 'MainForm.pas' {frmMain},
  VirtualizeClass in 'VirtualizeClass.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
