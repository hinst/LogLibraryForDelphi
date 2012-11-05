unit VCLLogPanel;

interface

uses
  Types,
  SysUtils,
  Classes,
  SyncObjs,

  Graphics,
  Controls,
  ExtCtrls,

  UAdditionalTypes,
  UAdditionalExceptions,
  UCustomThread,
  UMath,
  ULockThis,

  CustomLogMessage,
  CustomLogMessageList,
  VCLLogPanelItem,
  CustomVCLLogPanelAttachable;

type
  TLogViewPanel = class(TCustomLogViewPanel)
  public
    constructor Create(aOwner: TComponent); override;
  private
    const DefaultUpdateInterval = 30;
    const DefaultScrollSpeed = 300; //< pixels per second
    const DefaultGap = 3; // pixels
    const DefaultUserScrollSpeed = 30;
  protected
    fLogMessages: TLogPanelItemList;
    fScrollTop: single;
    fDesiredScrollTop: single;
    fScrollSpeed: integer;
    fGap: integer;
    fLastMouseY: integer;
    fUpdateTimer: TTimer;
    fNewMessageArrived: boolean;
    fTotalHeight: int64;
    fAutoScroll: boolean;
    procedure SetDesiredScrollTop(const aDesiredScrollTop: single);
    procedure CreateThis;
    procedure Paint; override;
    procedure PaintMessages;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure ScrollThis(const aDeltaY: integer);
    procedure DirectRecalculateHeights;
    procedure NewMessageUpdate;
    procedure ReleaseLogMessages;
    procedure UpdateRoutine(aSender: TObject);
    procedure DestroyThis;
  public
    property LogMessages: TLogPanelItemList read fLogMessages;
    property ScrollTop: single read fScrollTop;
    property DesiredScrollTop: single read fDesiredScrollTop write SetDesiredScrollTop;
    property ScrollSpeed: integer read fScrollSpeed;
    property Gap: integer read fGap write fGap;
    property LastMouseY: integer read fLastMouseY;
    property UpdateTimer: TTimer read fUpdateTimer;
    property NewMessageArrived: boolean read fNewMessageArrived;
    property TotalHeight: int64 read fTotalHeight;
    property AutoScroll: boolean read fAutoScroll write fAutoScroll;
    procedure AddMessage(const aMessage: TCustomLogMessage); override;
    procedure ScrollToBottom;
    procedure UserScroll(const aDelta: integer);
    destructor Destroy; override;
  end;


implementation

constructor TLogViewPanel.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  CreateThis;
end;

procedure TLogViewPanel.SetDesiredScrollTop(const aDesiredScrollTop: single);
begin
  fDesiredScrollTop := aDesiredScrollTop;
  if DesiredScrollTop < 0 then
    DesiredScrollTop := 0;
end;

procedure TLogViewPanel.CreateThis;
begin
  DoubleBuffered := true;

  fLogMessages := TLogPanelItemList.Create(true);
  fScrollTop := 0;
  DesiredScrollTop := 0;
  fScrollSpeed := DefaultScrollSpeed;
  Gap := DefaultGap;
  fTotalHeight := 0;
  fAutoScroll := true; // default
  
  fUpdateTimer := TTimer.Create(self);
  UpdateTimer.Interval := DefaultUpdateInterval;
  UpdateTimer.OnTimer := UpdateRoutine;
  UpdateTimer.Enabled := true;
end;

procedure TLogViewPanel.AddMessage(const aMessage: TCustomLogMessage);
var
  item: TLogPanelItem;
begin
  {$REGION Assertions}
  AssertAssigned(self, 'self', TVariableType.Argument);
  AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
  LockPointer(LogMessages);
  AssertAssigned(LogMessages, 'LogMessages', TVariableType.Prop);
  UnlockPointer(LogMessages);
  {$ENDREGION}
  {$REGION Create Item}
  item := TLogPanelItem.Create(self, aMessage);
  item.Parent := self;
  {$ENDREGION}
  LockPointer(LogMessages);
  LogMessages.Add(item);
  fNewMessageArrived := true;
  UnlockPointer(LogMessages);
end;

procedure TLogViewPanel.ReleaseLogMessages;
begin
  LockPointer(LogMessages);
  LogMessages.Free;
  UnlockPointer(LogMessages);
  fLogMessages := nil;
end;

procedure TLogViewPanel.Paint;
begin
  inherited Paint;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clWhite;
  Canvas.Pen.Style := psClear;
  Canvas.Rectangle(ClientRect);
  PaintMessages;
end;

procedure TLogViewPanel.PaintMessages;
var
  i: integer;
  ActualY: int64;
  DrawY: integer;
  item: TLogPanelItem;
begin
  LockPointer(LogMessages);
  ActualY := Gap;
  for i := 0 to LogMessages.Count - 1 do
  begin
    item := LogMessages[i];
    if item.Height = item.NOHEIGHT then
    begin
      item.DirectRecalculateHeight(Canvas);
      fTotalHeight := fTotalHeight + item.Height + Gap;
    end;
    AssertAssigned(item, 'item', TVariableType.Local);
    DrawY := ActualY - round(ScrollTop);
    if (0 < DrawY + item.Height) and (DrawY < ClientHeight) then
      item.Paint(Canvas, DrawY);
    ActualY := ActualY + item.Height + Gap;
  end;
  UnlockPointer(LogMessages);
end;

procedure TLogViewPanel.Resize;
begin
  inherited Resize;
  if DesiredScrollTop <> ScrollTop then
    DesiredScrollTop := ScrollTop; // no time to wait for this
  DirectRecalculateHeights;
end;

procedure TLogViewPanel.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  fLastMouseY := Y;
end;

procedure TLogViewPanel.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, y);
  if ssLeft in Shift then
  begin
    ScrollThis( - (Y - LastMouseY));
    fLastMouseY := Y;
  end;
end;

procedure TLogViewPanel.NewMessageUpdate;
begin
  if AutoScroll then
    ScrollToBottom;
end;

procedure TLogViewPanel.ScrollThis(const aDeltaY: integer);
begin
  fScrollTop := ScrollTop + aDeltaY;
  if ScrollTop < 0 then
    fScrollTop := 0;
  DesiredScrollTop := fScrollTop;
  Invalidate;
end;

procedure TLogViewPanel.DirectRecalculateHeights;
var
  i: integer;
  item: TLogPanelItem;
begin
  LockPointer(LogMessages);
  fTotalHeight := Gap;
  for i := 0 to LogMessages.Count - 1 do
  begin
    item := LogMessages[i];
    item.DirectRecalculateHeight(Canvas);
    fTotalHeight := fTotalHeight + item.Height + Gap;
  end;
  UnlockPointer(LogMessages);
end;

procedure TLogViewPanel.UpdateRoutine(aSender: TObject);
var
  invalidationRequired: boolean;
  scrollDPA: boolean; // scroll destination position approached
begin
  LockPointer(LogMessages); // LOCK
  if NewMessageArrived then
    NewMessageUpdate;
  scrollDPA :=
    ApproachSingle(
      fScrollTop,
      DesiredScrollTop,
      ScrollSpeed / 1000 * UpdateTimer.Interval
        * Exp(Abs(ScrollTop - DesiredScrollTop)/ScrollSpeed));
  {
  if not scrollDPA then
    WriteLN(FormatFloat('0.0', ScrollTop) + ' -> ' + FormatFloat('0.0', DesiredScrollTop));
  }
  invalidationRequired := not scrollDPA or NewMessageArrived;
  if NewMessageArrived then
    fNewMessageArrived := false;
  UnlockPointer(LogMessages); //UNLOCK
  if invalidationRequired then
    Invalidate;
  UpdateTimer.Interval := UpdateTimer.Interval; // reset timer hack
end;

procedure TLogViewPanel.DestroyThis;
begin
  Detach;
  UpdateTimer.Enabled := false;
  FreeAndNil(fUpdateTimer);
  ReleaseLogMessages;
end;

procedure TLogViewPanel.ScrollToBottom;
begin
  DesiredScrollTop := TotalHeight - ClientHeight - 1;
end;

procedure TLogViewPanel.UserScroll(const aDelta: integer);
begin
  DesiredScrollTop := DesiredScrollTop - aDelta;
end;

destructor TLogViewPanel.Destroy;
begin
  DestroyThis;
  inherited Destroy;
end;

end.
