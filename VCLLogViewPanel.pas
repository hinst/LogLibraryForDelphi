unit VCLLogViewPanel;

interface

uses
  SysUtils,
  Classes,
  Graphics,
  Controls,
  ExtCtrls,

  ULockThis,
  UExceptionTracer,
  UAdditionalTypes,
  UAdditionalExceptions,

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
    DefaultUpdateInterval = 100;
    DefaultPageSize = 500;
    DefaultBottomPanelHeight = 64;
    DefaultLeftGap = 2;
    DefaultRightGap = 4;
    DefaultInnerTextGap = 2;
    DefaultBackgroundColor = clWhite;
  protected
    FLog: TEmptyLog;
    FScrollPosition: single; // 0..1
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
    procedure CreateThis;
    procedure UpdateLogMessagesImage(aSender: TObject);
    procedure OnPaintBoxHandler(aSender: TObject);
    procedure PaintBackground;
    procedure PaintMessages;
  public
    property Log: TEmptyLog read FLog;
    property Storage: TLogMemoryStorage read FStorage write FStorage;
    destructor Destroy; override;
  end;

implementation

constructor TLogViewPanel.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  CreateThis;
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

  FExceptionWhileDrawing := false;
end;

procedure TLogViewPanel.UpdateLogMessagesImage(aSender: TObject);
begin
  FPaintBox.Invalidate;
  FTimer.Interval := FTimer.Interval;
end;

procedure TLogViewPanel.OnPaintBoxHandler(aSender: TObject);
begin
  if FExceptionWhileDrawing then
    exit;
  try
    PaintBackground;
    PaintMessages;
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
var
  i: integer;
  currentMessage: TCustomLogMessage;
begin
  AssertAssigned(Storage, 'Storage', TVariableType.Prop);
  AssertAssigned(Storage.List, 'Storage.List', TVariableType.Prop);
  LockPointer(Storage.List);
  FPainter.Top := 0;
  FPainter.TotalHeight := 0;
  for i := 0 to Storage.List.Count - 1 do
  begin
    if (FPainter.Top + FPainter.TotalHeight < ClientHeight) then
    begin
      currentMessage := Storage.List[i];
      FPainter.Draw(currentMessage);
    end;
    if FPainter.IsBottomOfPaintBoxReached then
      break;
  end;
  UnlockPointer(Storage.List);
end;

destructor TLogViewPanel.Destroy;
begin
  FreeAndNil(FPainter);
  FreeAndNil(FLog);
  inherited Destroy;
end;

end.
