program x86Compiler;

uses
  Forms,
  MainForm in 'MainForm.pas' {frmMain},
  Disassembler in 'Disassembler.pas',
  ScanLibrary in 'ScanLibrary.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
