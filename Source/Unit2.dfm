object DownloadForm: TDownloadForm
  Left = 192
  Top = 125
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #1047#1072#1075#1088#1091#1079#1082#1072
  ClientHeight = 130
  ClientWidth = 250
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object AppTitleLbl: TLabel
    Left = 8
    Top = 16
    Width = 233
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 'App'
  end
  object PercentDownloadLbl: TLabel
    Left = 8
    Top = 64
    Width = 233
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = '0%'
  end
  object ProgressBar: TProgressBar
    Left = 8
    Top = 32
    Width = 233
    Height = 25
    Smooth = True
    TabOrder = 0
  end
  object CancelBtn: TButton
    Left = 88
    Top = 96
    Width = 75
    Height = 25
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 1
    OnClick = CancelBtnClick
  end
end
