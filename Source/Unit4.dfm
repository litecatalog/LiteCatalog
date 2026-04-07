object SettingsForm: TSettingsForm
  Left = 192
  Top = 125
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080
  ClientHeight = 249
  ClientWidth = 361
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object DownloadFolderGB: TGroupBox
    Left = 8
    Top = 8
    Width = 345
    Height = 57
    Caption = #1055#1072#1087#1082#1072' '#1076#1083#1103' '#1079#1072#1075#1088#1091#1079#1086#1082
    TabOrder = 1
    object DownloadsPathEdt: TEdit
      Left = 10
      Top = 24
      Width = 240
      Height = 21
      ReadOnly = True
      TabOrder = 0
    end
    object SelectDownloadPathBtn: TButton
      Left = 261
      Top = 22
      Width = 75
      Height = 25
      Caption = #1042#1099#1073#1088#1072#1090#1100
      TabOrder = 1
      OnClick = SelectDownloadPathBtnClick
    end
  end
  object DownloadedRunCB: TCheckBox
    Left = 8
    Top = 136
    Width = 345
    Height = 17
    Caption = #1047#1072#1087#1091#1089#1082#1072#1090#1100' '#1087#1086#1089#1083#1077' '#1079#1072#1075#1088#1091#1079#1082#1080
    TabOrder = 2
  end
  object Panel: TPanel
    Left = 0
    Top = 208
    Width = 361
    Height = 41
    Align = alBottom
    TabOrder = 0
    object OkBtn: TButton
      Left = 8
      Top = 8
      Width = 75
      Height = 25
      Caption = #1054#1050
      TabOrder = 0
      OnClick = OkBtnClick
    end
    object CancelBtn: TButton
      Left = 88
      Top = 8
      Width = 75
      Height = 25
      Caption = #1054#1090#1084#1077#1085#1072
      TabOrder = 1
      OnClick = CancelBtnClick
    end
  end
  object ProgramsFolderGB: TGroupBox
    Left = 8
    Top = 72
    Width = 345
    Height = 57
    Caption = #1055#1072#1087#1082#1072' '#1076#1083#1103' '#1087#1088#1086#1075#1088#1072#1084#1084' ('#1090#1080#1093#1072#1103' '#1091#1089#1090#1072#1085#1086#1074#1082#1072')'
    TabOrder = 4
    object ProgramsPathEdt: TEdit
      Left = 10
      Top = 24
      Width = 240
      Height = 21
      TabOrder = 0
    end
    object SelectProgramsPathBtn: TButton
      Left = 261
      Top = 21
      Width = 75
      Height = 25
      Caption = #1042#1099#1073#1088#1072#1090#1100
      TabOrder = 1
      OnClick = SelectProgramsPathBtnClick
    end
  end
  object SilentInstallCB: TCheckBox
    Left = 8
    Top = 184
    Width = 345
    Height = 17
    Caption = #1059#1089#1090#1072#1085#1086#1074#1082#1072' '#1074' '#1090#1080#1093#1086#1084' '#1088#1077#1078#1080#1084#1077' ('#1077#1089#1083#1080' '#1087#1086#1076#1076#1077#1088#1078#1080#1074#1072#1077#1090#1089#1103')'
    TabOrder = 5
  end
  object DeleteAfterRunCB: TCheckBox
    Left = 8
    Top = 160
    Width = 345
    Height = 17
    Caption = #1059#1076#1072#1083#1103#1090#1100' '#1091#1089#1090#1072#1085#1086#1074#1097#1080#1082' '#1087#1086#1089#1083#1077' '#1079#1072#1082#1088#1099#1090#1080#1103
    TabOrder = 3
  end
end
