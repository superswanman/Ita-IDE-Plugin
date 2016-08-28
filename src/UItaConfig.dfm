object ConfigDlg: TConfigDlg
  Left = 192
  Top = 133
  BorderStyle = bsDialog
  Caption = 'Ita IDE Options'
  ClientHeight = 214
  ClientWidth = 594
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  DesignSize = (
    594
    214)
  PixelsPerInch = 96
  TextHeight = 13
  object btnCancel: TButton
    Left = 507
    Top = 181
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 0
  end
  object btnOK: TButton
    Left = 423
    Top = 181
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 1
  end
  object btnPreview: TButton
    Left = 327
    Top = 181
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Test'
    TabOrder = 2
    OnClick = btnPreviewClick
  end
  object gbFileName: TGroupBox
    Left = 8
    Top = 8
    Width = 578
    Height = 53
    Caption = 'FileName'
    TabOrder = 3
    object edImagePath: TEdit
      Left = 12
      Top = 20
      Width = 538
      Height = 21
      TabOrder = 0
      TextHint = '(Default)'
    end
    object btnSelectImage: TButton
      Left = 550
      Top = 20
      Width = 20
      Height = 20
      Caption = '...'
      TabOrder = 1
      OnClick = btnSelectImageClick
    end
  end
  object gbPosition: TGroupBox
    Left = 8
    Top = 67
    Width = 337
    Height = 106
    Caption = 'Position'
    TabOrder = 4
    object lblMarginX: TLabel
      Left = 24
      Top = 67
      Width = 45
      Height = 13
      Alignment = taRightJustify
      Caption = 'Margin X:'
    end
    object lblMarginY: TLabel
      Left = 156
      Top = 67
      Width = 45
      Height = 13
      Alignment = taRightJustify
      Caption = 'Margin Y:'
    end
    object rbLeftTop: TRadioButton
      Left = 12
      Top = 29
      Width = 60
      Height = 17
      Caption = 'LeftTop'
      TabOrder = 0
    end
    object rbLeftBottom: TRadioButton
      Left = 80
      Top = 29
      Width = 80
      Height = 17
      Caption = 'LeftBottom'
      TabOrder = 1
    end
    object rbRightTop: TRadioButton
      Left = 166
      Top = 29
      Width = 70
      Height = 17
      Caption = 'RightTop'
      TabOrder = 2
    end
    object rbRightBottom: TRadioButton
      Left = 242
      Top = 29
      Width = 90
      Height = 17
      Caption = 'RightBottom'
      TabOrder = 3
    end
    object edX: TEdit
      Left = 75
      Top = 63
      Width = 45
      Height = 21
      Alignment = taRightJustify
      NumbersOnly = True
      TabOrder = 4
      Text = '0'
    end
    object edY: TEdit
      Left = 207
      Top = 63
      Width = 45
      Height = 21
      Alignment = taRightJustify
      NumbersOnly = True
      TabOrder = 5
      Text = '0'
    end
    object udX: TUpDown
      Left = 120
      Top = 63
      Width = 16
      Height = 21
      Associate = edX
      Min = -10000
      Max = 10000
      TabOrder = 6
    end
    object udY: TUpDown
      Left = 252
      Top = 63
      Width = 16
      Height = 21
      Associate = edY
      Min = -10000
      Max = 10000
      TabOrder = 7
    end
  end
  object gbAlphaBlend: TGroupBox
    Left = 351
    Top = 123
    Width = 235
    Height = 50
    Caption = 'AlphaBlend'
    TabOrder = 5
    object lblAlpha: TLabel
      Left = 190
      Top = 20
      Width = 18
      Height = 13
      Caption = '255'
    end
    object tbAlpha: TTrackBar
      Left = 11
      Top = 16
      Width = 180
      Height = 25
      Max = 255
      Position = 255
      TabOrder = 0
      TickStyle = tsNone
      OnChange = tbAlphaChange
    end
  end
  object gbScale: TGroupBox
    Left = 351
    Top = 67
    Width = 235
    Height = 50
    Caption = 'Scale'
    TabOrder = 6
    object lblScale: TLabel
      Left = 190
      Top = 20
      Width = 39
      Height = 13
      Caption = '100.0%'
    end
    object tbScale: TTrackBar
      Left = 11
      Top = 16
      Width = 180
      Height = 25
      Max = 1000
      Min = 1
      Position = 1000
      TabOrder = 0
      TickStyle = tsNone
      OnChange = tbScaleChange
    end
  end
  object od: TFileOpenDialog
    ClientGuid = '{180E2DE4-6BAF-463A-ADDE-16323459E594}'
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = 'Image'
        FileMask = '*.png;*.jpg;*.jpeg;*.bmp'
      end
      item
        DisplayName = 'PNG'
        FileMask = '*.png'
      end
      item
        DisplayName = 'JPEG'
        FileMask = '*.jpg;*.jpeg'
      end
      item
        DisplayName = 'Bitmap'
        FileMask = '*.bmp'
      end>
    Options = []
    Left = 316
    Top = 119
  end
end
