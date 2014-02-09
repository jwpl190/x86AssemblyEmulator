object frmMain: TfrmMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Example'
  ClientHeight = 120
  ClientWidth = 185
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object btnTest: TButton
    Left = 8
    Top = 8
    Width = 169
    Height = 49
    Caption = 'Example Protection'
    TabOrder = 0
    OnClick = btnTestClick
  end
  object eExample1: TEdit
    Left = 8
    Top = 64
    Width = 169
    Height = 21
    TabOrder = 1
  end
  object eExample2: TEdit
    Left = 8
    Top = 91
    Width = 169
    Height = 21
    TabOrder = 2
  end
end
