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
    DefaultUpdateInterval = 50;
    DefaultPageSize = 100;
    DefaultBottomPanelHeight = 30;
    DefaultLeftGap = 2;
    DefaultRightGap = 8;
    DefaultInnerTextGap = 2;
    DefaultBackgroundColor = clWhite;
    DefaultScrollLineWidth = 3;
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
    {$ENDREGION}
    FTimer: TTimer;
    FPainter: TLogMessageTextBoxPaint;
    FExceptionWhileDrawing: boolean;
    FLastTimeMessageCount: integer;
    function GetScrollPosition: single;
    procedure SetScrollPosition(const aValue: single);
    function GetScrollLinePosition: integer;
    function GetEffectiveHeight: integer;
    procedure CreateThis;
    procedure UpdateLogMessagesImage(aSender: TObject);
    procedure OnPaintBoxHandler(aSender: TObject);
    procedure PaintBackground;
    procedure PaintMessages;
    procedure UpdatePageControls;
    procedure PaintScrollLine;
    procedure PaintPageControl;
    procedure OnPageSwitchHandler(aSender: TObject; var aAllowChange: Boolean; aNewValue: SmallInt;
      aDirection: TUpDownDirection);
    procedure UserChangePage(const aPage: integer);
  public
    property Log: TEmptyLog read FLog;
    property Storage: TLogMemoryStorage read FStorage write FStorage;
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

  FPageBox := TComboBox.Create(FBottomPanel);
  FPageBox.Parent := FBottomPanel;
  FPageBox.Align := alLeft;
  FPageBox.Style := csDropDown;
  FPageBox.AlignWithMargins := true;
  FPageBox.Margins.Top := (FBottomPanel.ClientHeight - FPageBox.ClientHeight) div 2;

  FPageSwitcher := TUpDown.Create(FBottomPanel);
  FPageSwitcher.Parent := FBottomPanel;
  FPageSwitcher.Align := alLeft;
  FPageSwitcher.OnChangingEx := OnPageSwitchHandler;

  FTimer := TTimer.Create(self);
  FTimer.Interval := DefaultUpdateInterval;
  FTimer.OnTimer := UpdateLogMessagesImage;

  FPainter := TLogMessageTextBoxPaint.Create;
  FPainter.List := Storage.List;
  FPainter.LeftGap := DefaultLeftGap;
  FPainter.RightGap := DefaultRightGap;
  FPainter.InnerTextGap := DefaultInnerTextGap;
  FPainter.PaintBox := FPaintBox;
  FPainter.PageSize := DefaultPageSize;

  FExceptionWhileDrawing := false;
end;

procedure TLogViewPanel.UpdateLogMessagesImage(aSender: TObject);
var
  invalidateRequired: boolean;
begin
  LockPointer(Storage.List);
  invalidateRequired := FLastTimeMessageCount <> Storage.List.Count;
  UnlockPointer(Storage.List);
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
begin
  FPaintBox.Canvas.Brush.Color := DefaultBackgroundColor;
  FPaintBox.Canvas.Brush.Style := bsSolid;
  FPaintBox.Canvas.Pen.Style := psClear;
  FPaintBox.Canvas.Rectangle(FPaintBox.ClientRect);
end;

procedure TLogViewPanel.PaintMessages;
begin
  AssertAssigned(Storage, 'Storage', TVariableType.Prop);
  AssertAssigned(Storage.List, 'Storage.List', TVariableType.Prop);
  FPainter.DrawList;
  FLastTimeMessageCount := Storage.List.Count;
  UpdatePageControls;
end;

procedure TLogViewPanel.UpdatePageControls;
var
  i, n: integer;
begin
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
  
  FPageSwitcher.Min := 0;
  FPageSwitcher.Max := n;
end;

procedure TLogViewPanel.PaintScrollLine;
var
  lineLength: integer;
begin
  //WriteLN(FloatToStr(ScrollPosition) + '%');
  lineLength := round( ( - 1 + FPaintBox.Height - 1 ) * ScrollPosition );
  FPaintBox.Canvas.Pen.Style := psSolid;
  FPaintBox.Canvas.Pen.Color := clBlack;
  FPaintBox.Canvas.Pen.Width := DefaultScrollLineWidth;
  FPaintBox.Canvas.MoveTo(ScrollLinePosition, 1);
  FPaintBox.Canvas.LineTo(ScrollLinePosition, lineLength);
end;

procedure TLogViewPanel.PaintPageControl;
begin

end;

procedure TLogViewPanel.OnPageSwitchHandler(aSender: TObject; var aAllowChange: Boolean;
  aNewValue: SmallInt; aDirection: TUpDownDirection);
begin
  aAllowChange := (0 <= aNewValue) and (aNewValue <= FPageBox.Items.Count);
  if aAllowChange then
    FPageBox.ItemIndex := aNewValue;
end;

procedure TLogViewPanel.UserChangePage(const aPage: integer);
begin
  FPainter.Page := aPage;
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
  FreeAndNil(FPainter);
  FreeAndNil(FLog);
  inherited Destroy;
end;


end.
