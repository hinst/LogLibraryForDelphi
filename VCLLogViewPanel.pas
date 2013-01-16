unit VCLLogViewPanel;

{ $DEFINE DEBUG_WRITELN_FILTER}
{ $DEFINE DEBUG_WRITELN_REPAINT_STAGES}

interface

uses
  Types,
  SysUtils,
  Classes,
  Math,
  Graphics,
  Forms,
  Controls,
  ExtCtrls,
  ComCtrls,
  StdCtrls,
  Buttons,

  ULockThis,
  UExceptionTracer,
  UAdditionalTypes,
  UAdditionalExceptions,
  UPaintEx,
  UVCL,

  CustomLogMessage,
  CustomLogMessageList,
  CustomLogMessageFilter,
  UCustomLogMessageListFilter,
  DefaultLogEntity,
  EmptyLogEntity,
  LogMemoryStorage,
  VCLLogViewPainter;

type
  TLogViewPanel = class(TPanel)
  public
    constructor Create(aOwner: TComponent); override;
  public const
    DefaultUpdateInterval = 35;
    DefaultPageSize = 100;
    DefaultBottomPanelHeight = 32;
    DefaultLeftGap = 2;
    DefaultRightGap = 24;
    DefaultInnerTextGap = 2;
    DefaultBackgroundColor = clWhite;
    DefaultScrollLineWidth = 5;
    DefaultPageBoxWidth = 100;
    DefaultReverseViewCaption = 'Reverse view';
    DefaultLogFont: array[0..2] of String = ('Consolas', 'Courier', 'Courier New');
    DefaultLogFontSize: array[0..2] of Integer = (10, 10, 10);
  protected
    FLog: TEmptyLog;
    FDesiredScrollPosition: single;
    FStorage: TLogMemoryStorage;
    FReverse: boolean;
    {$REGION Visual items}
    FPaintPanel: TPanel;
    FPaintBox: TPaintBox;
    FBottomPanel: TPanel;
    FPageSwitcher: TUpDown;
    FPageBox: TComboBox;
    FReverseSwitch: TSpeedButton;
    FSearchField: TEdit;
    {$ENDREGION}
    FTimer: TTimer;
    FPainter: TLogMessageTextBoxPaint;
    FExceptionWhileDrawing: boolean;
    FLastTimeMessageCount: integer;
    FFilter: TLogMessageTextFilter;
    function GetUserLogMessageList: TCustomLogMessageList;
    function GetScrollPosition: single;
    procedure SetScrollPosition(const aValue: single);
    function GetScrollLinePosition: integer;
    function GetScrollLineYTop: integer;
    function GetScrollLineYMiddle: integer;
    function GetScrollLineYBottom: integer;
    function GetEffectiveHeight: integer;
    procedure CreateThis;
    procedure SetDefaultLogFont;
    procedure PanelUpdateCycle(aSender: TObject);
    procedure OnPaintBoxHandler(aSender: TObject);
    procedure PaintBackground; inline;
    procedure PaintMessages; inline;
    procedure UpdatePageBox; inline;
    procedure PaintScrollLine; inline;
    procedure PaintMessageNumbers; inline;
    procedure OnPageSwitchHandler(aSender: TObject; var aAllowChange: Boolean; aNewValue: SmallInt;
      aDirection: TUpDownDirection);
    procedure OnPageBoxChange(aSender: TObject);
    procedure OnReverseSwitchChangeHandler(aSender: TObject);
    procedure OnSearchFieldKeyPress(aSender: TObject; var aKey: Char);
    procedure UserChangePage(const aPage: integer);
    procedure UserApplyFilter(const aText: string);
    procedure UpdateIfNewMessages(var aInvalidateRequired: boolean);
    procedure Resize; override;
  public
    property Log: TEmptyLog read FLog;
    property LogMemory: TLogMemoryStorage read FStorage write FStorage;
    property UserLogMessageList: TCustomLogMessageList read GetUserLogMessageList;
    property PaintBox: TPaintBox read FPaintBox write FPaintBox;
    property Filter: TLogMessageTextFilter read FFilter write FFilter;
    property ScrollPosition: single read GetScrollPosition write SetScrollPosition;
    property ScrollLineX: integer read GetScrollLinePosition;
    property ScrollLineYTop: integer read GetScrollLineYTop;
    property ScrollLineYMiddle: integer read GetScrollLineYMiddle;
    property ScrollLineYBottom: integer read GetScrollLineYBottom;
    procedure Startup;
    function ReceiveMouseWheel(aShift: TShiftState; aWheelDelta: Integer; aMousePos: TPoint)
      : boolean;
    destructor Destroy; override;
  end;

implementation

{$R log-view-panel.RES}

constructor TLogViewPanel.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
end;

function TLogViewPanel.GetUserLogMessageList: TCustomLogMessageList;
var
  count: integer;
begin
  result := nil;
  AssertAssigned(LogMemory, 'Storage', TVariableType.Prop);
  try
    AssertAssigned(LogMemory.List,' Storage.List', TVariableType.Prop);
    LogMemory.Lock;
    count := LogMemory.List.Count;
    LogMemory.Unlock;
    result := CreateFiltered(FFilter.Filter, LogMemory.List, count);
  finally
  end;
end;

function TLogViewPanel.GetScrollPosition: single;
begin
  result := abs(FPainter.Top) / GetEffectiveHeight;
  if result < 0 then
    result := 0;
  if result > 1 then
    result := 1;
end;

procedure TLogViewPanel.SetScrollPosition(const aValue: single);
var
  value: single;
begin
  value := aValue;
  if value < 0 then
    value := 0;
  if value > 1 then
    value := 1;
  // not implemented
end;

function TLogViewPanel.GetScrollLinePosition: integer;
begin
  result := Width - FPainter.RightGap div 2 - DefaultScrollLineWidth div 2;
end;

function TLogViewPanel.GetScrollLineYTop: integer;
begin
  result := DefaultScrollLineWidth;
end;

function TLogViewPanel.GetScrollLineYMiddle: integer;
var
  lineLength: integer;
begin
  lineLength := round(
    ( - DefaultScrollLineWidth + FPaintBox.Height - DefaultScrollLineWidth ) * ScrollPosition
  );
  result := DefaultScrollLineWidth + lineLength;
end;

function TLogViewPanel.GetScrollLineYBottom: integer;
begin
  result := FPaintBox.Height - DefaultScrollLineWidth;
end;

function TLogViewPanel.GetEffectiveHeight: integer;
begin
  result := FPainter.TotalHeight - Height;
  if result = 0 then
    result := 1;
end;

function CreateReverseSwitchGlyph: TBitmap;
const
  NAME = 'LOGVIEWPANELGOTOPGLYPH';
var
  stream: TResourceStream;
begin
  result:= TBitmap.Create;
  stream := TResourceStream.Create(HInstance, NAME, RT_RCDATA);
  result.LoadFromStream(stream);
  result.Transparent := true;
  result.TransparentColor := clWhite;
  stream.Free;
end;

procedure TLogViewPanel.CreateThis;
var
  reverseSwitchGlyph: TBitmap;
begin
  DoubleBuffered := true;
  ShowHint := true;
  FLog := TEmptyLog.Create;

  FPaintPanel := TPanel.Create(self);
  FPaintPanel.Parent := self;
  FPaintPanel.DoubleBuffered := true;
  FPaintPanel.Align := alClient;

  FPaintBox := TPaintBox.Create(FPaintBox);
  FPaintBox.Parent := FPaintPanel;
  FPaintBox.Align := alClient;
  FPaintBox.OnPaint := OnPaintBoxHandler;
  SetDefaultLogFont;

  FBottomPanel := TPanel.Create(self);
  FBottomPanel.Parent := self;
  FBottomPanel.Align := alBottom;
  FBottomPanel.Height := DefaultBottomPanelHeight;
  FBottomPanel.AlignWithMargins := true;
  FBottomPanel.Margins.Left := 2;
  FBottomPanel.Margins.Top := 2;
  FBottomPanel.Margins.Right := 2;
  FBottomPanel.Margins.Bottom := 2;

  FSearchField := TEdit.Create(FBottomPanel);
  FSearchField.Parent := FBottomPanel;
  FSearchField.Align := alRight;
  FSearchField.AlignWithMargins := true;
  FSearchField.Margins.Left := 3;
  FSearchField.Margins.Top := (FBottomPanel.ClientHeight - FSearchField.Height) div 2;
  FSearchField.Margins.Right := FSearchField.Margins.Left;
  FSearchField.Margins.Bottom := FSearchField.Margins.Top;
  FSearchField.Anchors := [akLeft, akRight];
  FSearchField.OnKeyPress := OnSearchFieldKeyPress; 

  FReverseSwitch := TSpeedButton.Create(FBottomPanel);
  FReverseSwitch.Parent := FBottomPanel;
  FReverseSwitch.Align := alLeft;
  FReverseSwitch.AlignWithMargins := true;
  FReverseSwitch.OnClick := OnReverseSwitchChangeHandler;
  FReverseSwitch.Hint := DefaultReverseViewCaption;
  reverseSwitchGlyph := CreateReverseSwitchGlyph;
  FReverseSwitch.Glyph:= reverseSwitchGlyph;
  FReverseSwitch.ClientHeight := reverseSwitchGlyph.Height + 2;
  FreeAndNil(reverseSwitchGlyph);
  FReverseSwitch.Margins.Left := 2;
  FReverseSwitch.Margins.Top := 2;
  FReverseSwitch.Margins.Right := FReverseSwitch.Margins.Left;
  FReverseSwitch.Margins.Bottom := FReverseSwitch.Margins.Top;
  FReverseSwitch.Width := FReverseSwitch.Height;
  //FReverseSwitch.Flat := true;
  FReverseSwitch.GroupIndex := 1;
  FReverseSwitch.AllowAllUp := true;

  FPageBox := TComboBox.Create(FBottomPanel);
  FPageBox.Parent := FBottomPanel;
  FPageBox.Align := alLeft;
  FPageBox.Width := DefaultPageBoxWidth;
  FPageBox.Style := csDropDown;
  FPageBox.AlignWithMargins := true;
  FPageBox.Margins.Top := (FBottomPanel.ClientHeight - FPageBox.Height) div 2;
  FPageBox.OnChange := OnPageBoxChange;

  FPageSwitcher := TUpDown.Create(FBottomPanel);
  FPageSwitcher.Parent := FBottomPanel;
  FPageSwitcher.Align := alLeft;
  FPageSwitcher.AlignWithMargins := true;
  FPageSwitcher.OnChangingEx := OnPageSwitchHandler;

  FSearchField.Width :=
    FBottomPanel.ClientWidth
    - FSearchField.Margins.Left - FSearchField.Margins.Right
    - FReverseSwitch.Left - FReverseSwitch.Width;

  FTimer := TTimer.Create(self);
  FTimer.Interval := DefaultUpdateInterval;
  FTimer.OnTimer := PanelUpdateCycle;

  FFilter := TLogMessageTextFilter.Create;
  FPainter := TLogMessageTextBoxPaint.Create;
  FPainter.List := UserLogMessageList;
  FPainter.LeftGap := DefaultLeftGap;
  FPainter.RightGap := DefaultRightGap;
  FPainter.InnerTextGap := DefaultInnerTextGap;
  FPainter.PaintBox := FPaintBox;
  FPainter.PageSize := DefaultPageSize;
  FLastTimeMessageCount := FPainter.List.Count;

  FExceptionWhileDrawing := false;
end;

procedure TLogViewPanel.SetDefaultLogFont;
var
  i: integer;
  currentFontName: string;
begin
  for i := 0 to length(DefaultLogFont) - 1 do
  begin
    currentFontName := DefaultLogFont[i];
    if Screen.Fonts.IndexOf(currentFontName) >= 0 then
    begin
      FPaintBox.Font.Name := currentFontName;
      FPaintBox.Font.Size := DefaultLogFontSize[i];
      break;
    end;
  end;
end;

procedure TLogViewPanel.PanelUpdateCycle(aSender: TObject);
var
  invalidateRequired: boolean;
begin
  if FExceptionWhileDrawing then
    exit;
  invalidateRequired := false;
  try
    UpdateIfNewMessages(invalidateRequired);
  except
    on e: Exception do
    begin
      FExceptionWhileDrawing := true;
      Log.Write('ERROR', 'Exception while updating' + sLineBreak + GetExceptionInfo(e));
    end;
  end;
  invalidateRequired := invalidateRequired or
    FPainter.Update(FTimer.Interval);
  if invalidateRequired then
    FPaintBox.Invalidate;
  FTimer.Interval := FTimer.Interval;
end;

procedure TLogViewPanel.OnPaintBoxHandler(aSender: TObject);
  procedure WriteLNRepaintStage(const s: string);
    inline;
  begin
    {$IFDEF DEBUG_WRITELN_REPAINT_STAGES}
    WriteLN(s);
    {$ENDIF}
  end;

begin
  if FExceptionWhileDrawing then
    exit;
  try
    WriteLNRepaintStage('PaintBackground...');
    PaintBackground;
    WriteLNRepaintStage('PaintMessages...');
    PaintMessages;
    WriteLNRepaintStage('UpdatePageBox...');
    UpdatePageBox;
    WriteLNRepaintStage('PaintScrollLine...');
    PaintScrollLine;
    WriteLNRepaintStage('PaintMessageNumbers...');
    PaintMessageNumbers;
    WriteLNRepaintStage('Repaint stages complete.');
  except
    on e: Exception do
    begin
      Log.Write('ERROR', 'An error occured while executing OnPainBoxHandler: ' + sLineBreak +
        GetExceptionInfo(e));
      FExceptionWhileDrawing := true;
    end;
  end;
end;

procedure TLogViewPanel.PaintBackground;
var
  canv: TCanvas;
begin
  canv := FPaintBox.Canvas;
  canv.Brush.Color := clWhite;
  canv.Brush.Style := bsSolid;
  canv.Pen.Style := psClear;
  canv.Rectangle(FPaintBox.ClientRect);
end;

procedure TLogViewPanel.PaintMessages;
begin
  FPainter.DrawList;
end;

procedure TLogViewPanel.UpdatePageBox;
var
  i, n: integer;
begin
  FPageBox.ItemIndex := FPainter.Page;
  n := FPainter.PageCount;
  if FPageBox.Items.Count <> n then
  begin
    FPageBox.Items.BeginUpdate;
    FPageBox.Items.Clear;
    for i := 0 to n - 1 do
      FPageBox.Items.Add(IntToStr(i));
    FPageBox.Items.EndUpdate;
    FPageBox.ItemIndex := FPainter.Page;
  end;
end;

procedure TLogViewPanel.PaintScrollLine;
var
  canv: TCanvas;
begin
  //WriteLN(FloatToStr(ScrollPosition) + '%');
  canv := FPaintBox.Canvas;
  canv.Pen.Style := psSolid;
  canv.Pen.Color := clBlack;
  canv.Pen.Width := 1;
  canv.Pen.Style := psDot;
  canv.MoveTo(ScrollLineX, ScrollLineYTop);
  canv.LineTo(ScrollLineX, ScrollLineYBottom);
  canv.Pen.Width := DefaultScrollLineWidth;
  canv.Pen.Style := psSolid;
  canv.MoveTo(ScrollLineX, ScrollLineYTop);
  canv.LineTo(ScrollLineX, ScrollLineYMiddle);
end;

procedure TLogViewPanel.PaintMessageNumbers;
var
  text: string;
  canvas: TCanvas;
  x, y: integer;
begin
  text := 
    ' ' + IntToStr(FPainter.MessageListStartIndex + 1)
    + '..' + IntToStr(FPainter.MessageListLastIndex + 1)
    + ' / ' + IntToStr(FPainter.List.Count);
  canvas := FPaintBox.Canvas;
  canvas.Font.Color := clBlack;
  x := ScrollLineX;
  y := ScrollLineYMiddle;
  x := x + canvas.TextHeight(text) div 2 + DefaultScrollLineWidth div 2;
  if ScrollPosition <= 0.5 then
    y := y + DefaultScrollLineWidth
  else
    y := y - canvas.TextWidth(text) - DefaultScrollLineWidth;
  canvas.Font.Orientation := (90 + 180) * 10;
  canvas.Brush.Color := clSilver;
  canvas.TextOut(x, y, text);
  canvas.Font.Orientation := 0;
end;

procedure TLogViewPanel.OnPageSwitchHandler(aSender: TObject; var aAllowChange: Boolean;
  aNewValue: SmallInt; aDirection: TUpDownDirection);
begin
  aAllowChange := FPainter.CheckPageIndex(aNewValue);
  if aAllowChange then
  begin
    FPageBox.ItemIndex := aNewValue;
    UserChangePage(aNewValue);
  end;
end;

procedure TLogViewPanel.OnPageBoxChange(aSender: TObject);
begin
  FPageSwitcher.Position := FPageBox.ItemIndex;
end;

procedure TLogViewPanel.OnReverseSwitchChangeHandler(aSender: TObject);
begin
  //FReverseSwitch.Down := not FReverseSwitch.Down;
  FPainter.Reverse := FReverseSwitch.Down;
  FPaintBox.Invalidate;
end;

procedure TLogViewPanel.OnSearchFieldKeyPress(aSender: TObject; var aKey: Char);
begin
  if aKey = #13 then
    UserApplyFilter(FSearchField.Text);
end;

procedure TLogViewPanel.UserChangePage(const aPage: integer);
begin
  PaintBackground;
  FPainter.Page := aPage;
  FPaintBox.Invalidate;
end;

procedure TLogViewPanel.UserApplyFilter(const aText: string);
begin
  {$IFDEF DEBUG_WRITELN_FILTER}
  WriteLN('Applying filter "' + aText + '"');
  {$ENDIF}
  Filter.FilterText := aText;
  FPainter.List := UserLogMessageList;
  FPainter.Page := 0;
  FPainter.Top := 0;
  FPageSwitcher.Position := FPainter.Page;
  UpdatePageBox;
  {$IFDEF DEBUG_WRITELN_FILTER}
  WriteLN('Filter passed: ' + IntToStr(FPainter.List.Count));
  {$ENDIF}
  FPaintBox.Invalidate;
end;

procedure TLogViewPanel.UpdateIfNewMessages(var aInvalidateRequired: boolean);
var
  count: integer;
  i: integer;
  m: TCustomLogMessage;
begin
  AssertAssigned(LogMemory, 'Storage', TVariableType.Prop);
  LogMemory.Lock;
  count := LogMemory.Count;
  LogMemory.Unlock;
  if FLastTimeMessageCount <> count then
  begin
    aInvalidateRequired := true;
    LogMemory.Lock;
    AssertAssigned(LogMemory.List, 'Storage.List', TVariableType.Prop);
    for i := FLastTimeMessageCount to count - 1 do
    begin
      m := LogMemory.List[i];
      if Filter.Filter(m) then
        FPainter.List.Add(m);
    end;
    LogMemory.Unlock;
    FLastTimeMessageCount := count;
  end;
end;

procedure TLogViewPanel.Resize;
begin
  inherited Resize;
  if Assigned(FPainter) then
    FPainter.Cache.Clear;
end;

procedure TLogViewPanel.Startup;
begin
  CreateThis;
end;

function TLogViewPanel.ReceiveMouseWheel(aShift: TShiftState; aWheelDelta: Integer;
 aMousePos: TPoint): boolean;
begin
  result := true;
  // inherited DoMouseWheel(aShift, aWheelDelta, aMousePos);
  // WriteLN(IntToStr(aWheelDelta)); // debug
  FPainter.DesiredTop := FPainter.DesiredTop + aWheelDelta;
  FPaintBox.Invalidate;
end;

destructor TLogViewPanel.Destroy;
begin
  FreeAndNil(FFilter);
  FreeAndNil(FPainter);
  FreeAndNil(FLog);
  inherited Destroy;
end;


end.
