object Form1: TForm1
  Left = 126
  Top = 41
  Width = 425
  Height = 179
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  Caption = 'Ping-It!'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Scaled = False
  PixelsPerInch = 96
  TextHeight = 13
  object btnPing: TKOLButton
    Tag = 0
    Left = 344
    Top = 8
    Width = 64
    Height = 22
    HelpContext = 0
    IgnoreDefault = True
    TabOrder = 0
    MinWidth = 0
    MinHeight = 0
    MaxWidth = 0
    MaxHeight = 0
    PlaceDown = False
    PlaceRight = False
    PlaceUnder = False
    Visible = True
    Enabled = True
    DoubleBuffered = False
    Align = caNone
    CenterOnParent = False
    Caption = 'Ping'
    Ctl3D = True
    Color = clBtnFace
    parentColor = False
    Font.Color = clWindowText
    Font.FontStyle = []
    Font.FontHeight = 12
    Font.FontWidth = 0
    Font.FontWeight = 0
    Font.FontName = 'MS Sans Serif'
    Font.FontOrientation = 0
    Font.FontCharset = 1
    Font.FontPitch = fpDefault
    parentFont = False
    OnClick = btnPingClick
    EraseBackground = False
    Localizy = loForm
    TextAlign = taCenter
    VerticalAlign = vaCenter
    TabStop = True
    LikeSpeedButton = False
    autoSize = False
    DefaultBtn = False
    CancelBtn = False
    image.Data = {07544269746D617000000000}
  end
  object lstReplies: TKOLListBox
    Tag = 0
    Left = 8
    Top = 32
    Width = 401
    Height = 105
    HelpContext = 0
    IgnoreDefault = False
    TabOrder = 1
    MinWidth = 0
    MinHeight = 0
    MaxWidth = 0
    MaxHeight = 0
    PlaceDown = False
    PlaceRight = False
    PlaceUnder = False
    Visible = True
    Enabled = True
    DoubleBuffered = False
    Align = caNone
    CenterOnParent = False
    Ctl3D = True
    Color = clWindow
    parentColor = False
    Font.Color = clWindowText
    Font.FontStyle = []
    Font.FontHeight = 12
    Font.FontWidth = 0
    Font.FontWeight = 0
    Font.FontName = 'MS Sans Serif'
    Font.FontOrientation = 0
    Font.FontCharset = 1
    Font.FontPitch = fpDefault
    parentFont = False
    EraseBackground = False
    Localizy = loForm
    Transparent = False
    TabStop = True
    Options = [loNoIntegralHeight]
    CurIndex = 0
    Count = 0
    HasBorder = True
    Brush.Color = clWindow
    Brush.BrushStyle = bsSolid
  end
  object edtHost: TKOLEditBox
    Tag = 0
    Left = 8
    Top = 8
    Width = 329
    Height = 22
    HelpContext = 0
    IgnoreDefault = False
    TabOrder = 2
    MinWidth = 0
    MinHeight = 0
    MaxWidth = 0
    MaxHeight = 0
    PlaceDown = False
    PlaceRight = False
    PlaceUnder = False
    Visible = True
    Enabled = True
    DoubleBuffered = False
    Align = caNone
    CenterOnParent = False
    Ctl3D = True
    Color = clWindow
    parentColor = False
    Font.Color = clWindowText
    Font.FontStyle = []
    Font.FontHeight = 12
    Font.FontWidth = 0
    Font.FontWeight = 0
    Font.FontName = 'MS Sans Serif'
    Font.FontOrientation = 0
    Font.FontCharset = 1
    Font.FontPitch = fpDefault
    parentFont = False
    EraseBackground = False
    Localizy = loForm
    Transparent = False
    Text = '127.0.0.1'
    Options = []
    TabStop = True
    TextAlign = taLeft
    autoSize = False
    HasBorder = True
    EditTabChar = False
    Brush.Color = clWindow
    Brush.BrushStyle = bsSolid
  end
  object KOLProject1: TKOLProject
    Locked = False
    Localizy = False
    projectName = 'Ping'
    projectDest = 'Ping'
    sourcePath = 'E:\Redactor\kolDown\KOLIndy\Ping\'
    outdcuPath = 'E:\Redactor\kolDown\KOLIndy\Ping\'
    dprResource = False
    protectFiles = True
    showReport = False
    isKOLProject = True
    autoBuild = True
    autoBuildDelay = 500
    BUILD = False
    consoleOut = False
    SupportAnsiMnemonics = 0
    PaintType = ptWYSIWIG
    ShowHint = False
    Left = 40
    Top = 112
  end
  object KOLForm1: TKOLForm
    Tag = 0
    ForceIcon16x16 = False
    Caption = 'Ping-It!'
    Visible = True
    AllBtnReturnClick = False
    Tabulate = False
    TabulateEx = False
    Locked = False
    formUnit = 'Unit1'
    formMain = True
    Enabled = True
    defaultSize = False
    defaultPosition = False
    MinWidth = 0
    MinHeight = 0
    MaxWidth = 0
    MaxHeight = 0
    HasBorder = True
    HasCaption = True
    StayOnTop = False
    CanResize = True
    CenterOnScreen = False
    Ctl3D = True
    WindowState = wsNormal
    minimizeIcon = True
    maximizeIcon = True
    closeIcon = True
    helpContextIcon = False
    borderStyle = fbsSingle
    HelpContext = 0
    Color = clBtnFace
    Font.Color = clWindowText
    Font.FontStyle = []
    Font.FontHeight = 0
    Font.FontWidth = 0
    Font.FontWeight = 0
    Font.FontName = 'MS Sans Serif'
    Font.FontOrientation = 0
    Font.FontCharset = 1
    Font.FontPitch = fpDefault
    Brush.Color = clBtnFace
    Brush.BrushStyle = bsSolid
    DoubleBuffered = False
    PreventResizeFlicks = False
    Transparent = False
    AlphaBlend = 255
    Border = 2
    MarginLeft = 0
    MarginRight = 0
    MarginTop = 0
    MarginBottom = 0
    MinimizeNormalAnimated = False
    zOrderChildren = False
    statusSizeGrip = True
    Localizy = False
    ShowHint = False
    OnFormCreate = KOLForm1FormCreate
    EraseBackground = False
    supportMnemonics = False
    Left = 8
    Top = 112
  end
end