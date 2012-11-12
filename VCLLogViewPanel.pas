unit VCLLogViewPanel;

interface

uses
  Types,
  SysUtils,
  Classes,
  Graphics,
  Controls,
  ExtCtrls,

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
    DefaultBottomPanelHeight = 64;
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
    procedure PaintScrollLine;
    procedure PaintPageControl;
  public
    property Log: TEmptyLog read FLog;
    property Storage: TLogMemoryStorage read FStorage write FStorage;
    property ScrollPosition: single read GetScrollPosition write SetScrollPosition;
    property ScrollLinePosition: integer read GetScrollLinePosition;
    function ReceiveMouseWheel(aShift: TShiftState; aWheelDelta: Integer; aMousePos: TPoint)
      : boolean;
    destructor Destroy; override;
  end;

implementation

constructor TLogViewPanel.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  CreateThis;
end;

function TLogViewPanel.GetScrollPosition: single;
var
  effectiveHeight: integer;
begin
  if effectiveheight = 0 then
    effectiveHeight := 1;
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

  FTimer := TTimer.Create(self);
  FTimer.Interval := DefaultUpdateInterval;
  FTimer.OnTimer := UpdateLogMessagesImage;

  FPainter := TLogMessageTextBoxPaint.Create;
  FPainter.LeftGap := DefaultLeftGap;
  FPainter.RightGap := DefaultRightGap;
  FPainter.InnerTextGap := DefaultInnerTextGap;
  FPainter.PaintBox := FPaintBox;
  FPainter.PageSize := DefaultPageSize;

  FExceptionWhileDrawing := false;
end;

procedure TLogViewPanel.UpdateLogMessagesImage(aSender: TObject);
var
  currentMessageCount: integer;
begin
  LockPointer(Storage.List);
  currentMessageCount := Storage.List.Count;
  UnlockPointer(Storage.List);
  if FLastTimeMessageCount <> currentMessageCount then
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
  LockPointer(Storage.List);
  FPainter.DrawList(Storage.List);
  FLastTimeMessageCount := Storage.List.Count;
  UnlockPointer(Storage.List);
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
