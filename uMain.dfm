object fMain: TfMain
  Left = 0
  Top = 0
  Caption = 'fMain'
  ClientHeight = 601
  ClientWidth = 919
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object pnbMain: TPaintBox
    Left = 257
    Top = 0
    Width = 662
    Height = 601
    Align = alClient
    OnPaint = pnbMainPaint
    ExplicitLeft = 251
    ExplicitWidth = 337
    ExplicitHeight = 456
  end
  object trvMain: TTreeView
    Left = 0
    Top = 0
    Width = 257
    Height = 601
    Align = alLeft
    Indent = 19
    TabOrder = 0
    OnChange = trvMainChange
  end
  object MainMenu1: TMainMenu
    Left = 472
    Top = 32
    object mmiNextPage: TMenuItem
      Caption = 'Next page'
      OnClick = mmiNextPageClick
    end
  end
end
