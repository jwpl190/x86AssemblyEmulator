object frmMain: TfrmMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'x86 Assembly Emulator Compiler'
  ClientHeight = 41
  ClientWidth = 321
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object btnBuild: TButton
    Left = 8
    Top = 8
    Width = 306
    Height = 25
    Caption = 'Build'
    TabOrder = 0
    OnClick = btnBuildClick
  end
  object OpenDialog1: TOpenDialog
    Left = 8
    Top = 8
  end
end
