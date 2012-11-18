unit VCLLogViewPanel;

interface

uses
  Types,
  SysUtils,
  Classes,
  Graphics,
  Controls,
  ExtCtrls,
  ComCtrls,
  StdCtrls,

  ULockThis,
  UExceptionTracer,
  UAdditionalTypes,
  UAdditionalExceptions,
  UPaintEx,

  CustomLogMessage,
  CustomLogMessageList,
  CustomLogMessageFilter,
  UCustomLogMessageListFilter,
  DefaultLogEntity,
  EmptyLogEntity,
  LogMemoryStorage,
  VCLLogViewPainter,

  GlobalLogManagerUnit;

type
  TLogViewPanel = class(TPanel)
  public
    constructor Create(aOwner: TComponent); override;
  public const
    DefaultUpdateInterval = 1000;
    DefaultPageSize = 100;
    DefaultBottomPanelHeight = 30;
    DefaultLeftGap = 2;
    DefaultRightGap = 8;
    DefaultInnerTextGap = 2;
    DefaultBackgroundColor = clWhite;
    DefaultScrollLineWidth = 3;
    DefaultReverseViewCaption = 'Reverse view';
  protected
    FLog: TEmptyLog;
    FDesiredScrollPosition: single;
    FStorage: TLogMemoryStorage;
    FReverse: boolean;

    {$REGION Visual items}
    FPaintBox: TPaintBox;
    FBottomPanel: TPanel;
    FPageSwitcher: TUpDown;
    FPageBox: TComboBox;
    FReverseSwitch: TCheckBox;
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
    function GetEffectiveHeight: integer;
    procedure CreateThis;
    procedure PanelUpdateCycle(aSender: TObject);
    procedure OnPaintBoxHandler(aSender: TObject);
    procedure PaintBackground; inline;
    procedure PaintMessages; inline;
    procedure UpdatePageControls; inline;
    procedure PaintScrollLine; inline;
    procedure OnPageSwitchHandler(aSender: TObject; var aAllowChange: Boolean; aNewValue: SmallInt;
      aDirection: TUpDownDirection);
    procedure OnPageBoxChange(aSender: TObject);
    procedure OnReverseSwitchChangeHandler(aSender: TObject);
    procedure OnSearchFieldKeyPress(aSender: TObject; var aKey: Char);
    procedure UserChangePage(const aPage: integer);
    procedure UserApplyFilter(const aText: string);
    procedure UpdateAddLogMessages(var aInvalidateRequired: boolean);
    procedure Resize; override;
  public
    property Log: TEmptyLog read FLog;
    property Storage: TLogMemoryStorage read FStorage write FStorage;
    property UserLogMessageList: TCustomLogMessageList read GetUserLogMessageList;
    property PaintBox: TPaintBox read FPaintBox write FPaintBox;
    property Filter: TLogMessageTextFilter read FFilter write FFilter;
    property ScrollPosition: single read GetScrollPosition write SetScrollPosition;
    property ScrollLinePosition: integer read GetScrollLinePosition;
    procedure Startup;
    function ReceiveMouseWheel(aShift: TShiftState; aWheelDelta: Integer; aMousePos: TPoint)
      : boolean;
    destructor Destroy; override;
  end;

implementation

constructor TLogViewPanel.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
end;

function TLogViewPanel.GetUserLogMessageList: TCustomLogMessageList;
begin
  result := nil;
  AssertAssigned(Storage, 'Storage', TVariableType.Prop);
  try
    Storage.Lock;
    AssertAssigned(Storage.List,' Storage.List', TVariableType.Prop);
    result := CreateFiltered(FFilter.Filter, Storage.List);
  finally
    Storage.Unlock;
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

function TLogViewPanel.GetEffectiveHeight: integer;
begin
  result := FPainter.TotalHeight - Height;
  if result = 0 then
    result := 1;
end;

procedure TLogViewPanel.CreateThis;
begin
  DoubleBuffered := true;
  FLog := TLog.Create(GlobalLogManager, 'LogViewPanel');

  FPaintBox := TPaintBox.Create(self);
  FPaintBox.Parent := self;
  FPaintBox.Align := alClient;
  FPaintBox.OnPaint := OnPaintBoxHandler;

  FBottomPanel := TPanel.Create(self);
  FBottomPanel.Parent := self;
  FBottomPanel.Align := alBottom;
  FBottomPanel.Height := DefaultBottomPanelHeight;

  FSearchField := TEdit.Create(FBottomPanel);
  FSearchField.Parent := FBottomPanel;
  FSearchField.Align := alRight;
  FSearchField.AlignWithMargins := true;
  FSearchField.OnKeyPress := OnSearchFieldKeyPress; 

  FReverseSwitch := TCheckBox.Create(FBottomPanel);
  FReverseSwitch.Parent := FBottomPanel;
  FReverseSwitch.Align := alLeft;
  FReverseSwitch.AlignWithMargins := true;
  FReverseSwitch.Margins.Top := (FBottomPanel.ClientHeight - FReverseSwitch.Height) div 2;
  FReverseSwitch.OnClick:= OnReverseSwitchChangeHandler;
  FReverseSwitch.Caption := DefaultReverseViewCaption;

  FPageBox := TComboBox.Create(FBottomPanel);
  FPageBox.Parent := FBottomPanel;
  FPageBox.Align := alLeft;
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

  FExceptionWhileDrawing := false;
end;

procedure TLogViewPanel.PanelUpdateCycle(aSender: TObject);
var
  invalidateRequired: boolean;
  count: integer;
begin
  invalidateRequired := false;
  UpdateAddLogMessages;
  if invalidateRequired then
  begin
    FPaintBox.Invalidate;
    FTimer.Interval := FTimer.Interval;
  end;
end;

procedure TLogViewPanel.OnPaintBoxHandler(aSender: TObject);
begin
  if FExceptionWhileDrawing then
    exit;
  try
    PaintBackground;
    PaintMessages;
    UpdatePageControls;
    PaintScrollLine;
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
  canv.Brush.Color := DefaultBackgroundColor;
  canv.Brush.Style := bsSolid;
  canv.Pen.Style := psClear;
  canv.Rectangle(FPaintBox.ClientRect);
end;

procedure TLogViewPanel.PaintMessages;
begin
  AssertAssigned(Storage, 'Storage', TVariableType.Prop);
  LockPointer(Storage.List);
  AssertAssigned(Storage.List, 'Storage.List', TVariableType.Prop);
  UnlockPointer(Storage.List);
  FPainter.DrawList;
end;

procedure TLogViewPanel.UpdatePageControls;
var
  i, n: integer;
begin
  FPageBox.ItemIndex := FPainter.Page;
  n := FPainter.PageCount;
  if FPageBox.Items.Count < n then
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
  lineLength: integer;
  canv: TCanvas;
begin
  //WriteLN(FloatToStr(ScrollPosition) + '%');
  lineLength := round( ( - 1 + FPaintBox.Height - 1 ) * ScrollPosition );
  canv := FPaintBox.Canvas;
  canv.Pen.Style := psSolid;
  canv.Pen.Color := clBlack;
  canv.Pen.Width := DefaultScrollLineWidth;
  canv.MoveTo(ScrollLinePosition, 1);
  canv.LineTo(ScrollLinePosition, lineLength);
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
  FPainter.Reverse := FReverseSwitch.Checked;
  FPaintBox.Invalidate;
end;

procedure TLogViewPanel.OnSearchFieldKeyPress(aSender: TObject; var aKey: Char);
begin
  if aKey = #13 then
    UserApplyFilter(FSearchField.Text);
end;

procedure TLogViewPanel.UserChangePage(const aPage: integer);
begin
  FPainter.Page := aPage;
  FPaintBox.Invalidate;
end;

procedure TLogViewPanel.UserApplyFilter(const aText: string);
begin
  WriteLN('Applying filter "' + aText + '"');
  Filter.FilterText := aText;
  FPainter.List := UserLogMessageList;
  WriteLN(FPainter.List.Count);
  FPaintBox.Invalidate;
end;

procedure TLogViewPanel.UpdateAddLogMessages(var aInvalidateRequired: boolean);
var
  count: integer;
  i: integer;
  m: TCustomLogMessage;
begin
  AssertAssigned(Storage, 'Storage', TVariableType.Prop);
  count := Storage.Count;
  if FLastTimeMessageCount <> count then
  begin
    aInvalidateRequired := true;
    FLastTimeMessageCount := count;
    Storage.Lock;
    AssertAssigned(Storage.List, 'Storage.List', TVariableType.Prop);
    Storage.Unlock;
  end;
  LockPointer(Storage.List);
  for i := FLastTimeMessageCount - 1 to Storage.List.Count - 1 do
  begin
    m := Storage.List[i];
    if Filter.Filter(m) then
      FPainter.List.Add(m);
  end;
  UnlockPointer(Storage.List);
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
  // Log.Write(IntToStr(aWheelDelta)); // debug
  FPainter.Top := FPainter.Top + aWheelDelta;
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
