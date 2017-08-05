object frmValidarXML: TfrmValidarXML
  Left = 335
  Top = 265
  Width = 643
  Height = 415
  BorderWidth = 5
  Caption = 'Validador estrutural de XML'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object mmoLog: TMemo
    Left = 0
    Top = 139
    Width = 617
    Height = 148
    Align = alClient
    Ctl3D = False
    ParentCtl3D = False
    TabOrder = 0
  end
  object pbBarraProgresso: TProgressBar
    Left = 0
    Top = 287
    Width = 617
    Height = 17
    Align = alBottom
    TabOrder = 1
  end
  object Panel1: TPanel
    Left = 0
    Top = 340
    Width = 617
    Height = 27
    Align = alBottom
    BevelOuter = bvNone
    Ctl3D = False
    ParentCtl3D = False
    TabOrder = 2
    DesignSize = (
      617
      27)
    object btnValidar: TButton
      Left = 540
      Top = 1
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '&Validar'
      TabOrder = 0
      OnClick = btnValidarClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 304
    Width = 617
    Height = 36
    Align = alBottom
    BevelOuter = bvNone
    Ctl3D = False
    ParentCtl3D = False
    TabOrder = 3
    object lblArquivo: TLabel
      Left = 8
      Top = 4
      Width = 3
      Height = 13
    end
    object lblPercentual: TLabel
      Left = 8
      Top = 20
      Width = 3
      Height = 13
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 0
    Width = 617
    Height = 139
    Align = alTop
    BevelOuter = bvNone
    Ctl3D = False
    ParentCtl3D = False
    TabOrder = 4
    DesignSize = (
      617
      139)
    object lblXML: TLabel
      Left = 2
      Top = 7
      Width = 64
      Height = 13
      Caption = 'Arquivo XML:'
    end
    object lblXSD: TLabel
      Left = 3
      Top = 52
      Width = 149
      Height = 13
      Caption = 'Diret'#243'rio raiz dos arquivos XSD:'
    end
    object edtXML: TEdit
      Left = 1
      Top = 25
      Width = 591
      Height = 19
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
    object edtXSD: TEdit
      Left = 1
      Top = 71
      Width = 591
      Height = 19
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
    end
    object btnLocalizarXSD: TButton
      Left = 595
      Top = 70
      Width = 20
      Height = 20
      Anchors = [akTop, akRight]
      Caption = '...'
      TabOrder = 2
      OnClick = btnLocalizarXSDClick
    end
    object btnLocalizarXML: TButton
      Left = 595
      Top = 24
      Width = 20
      Height = 20
      Anchors = [akTop, akRight]
      Caption = '...'
      TabOrder = 3
      OnClick = btnLocalizarXMLClick
    end
    object rgTipoXML: TRadioGroup
      Left = 0
      Top = 96
      Width = 185
      Height = 33
      Caption = 'Tipo do XML: '
      Columns = 2
      Ctl3D = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemIndex = 0
      Items.Strings = (
        'NF-e'
        'MDF-e')
      ParentCtl3D = False
      ParentFont = False
      TabOrder = 4
    end
  end
  object dlgOpen: TOpenDialog
    Left = 554
    Top = 308
  end
  object abcDirectoryDialog: TabcDirectoryDialog
    Left = 585
    Top = 308
  end
end
