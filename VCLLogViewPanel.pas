unit VCLLogViewPanel;

interface

uses
  SysUtils,
  Classes,
  Graphics,
  Controls,
  ExtCtrls,

  LogMemoryStorage,
  VCLLogViewPainter;

type
  TLogViewPanel = class(TPanel)
  public
    constructor Create(aOwner: TComponent); override;
  public const
    DefaultUpdateInterval = 100;
    DefaultBottomPanelHeight = 64;
    DefaultBackgroundColor = clWhite;
  protected
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
    procedure CreateThis;
    procedure UpdateLogMessagesImage(aSender: TObject);
    procedure OnPaintBoxHandler(aSender: TObject);
    procedure PaintBackground;
  public
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
  FPainter.PaintBox := FPaintBox;
end;

procedure TLogViewPanel.UpdateLogMessagesImage(aSender: TObject);
begin
  FPaintBox.Invalidate;
  FTimer.Interval := FTimer.Interval;
end;

procedure TLogViewPanel.OnPaintBoxHandler(aSender: TObject);
begin
  PaintBackground;
end;

procedure TLogViewPanel.PaintBackground;
begin
  FPaintBox.Canvas.Brush.Color := DefaultBackgroundColor;
  FPaintBox.Canvas.Brush.Style := bsSolid;
  FPaintBox.Canvas.Rectangle(0, 0, FPaintBox.ClientWidth, FPaintBox.ClientHeight);
end;

destructor TLogViewPanel.Destroy;
begin
  FreeAndNil(FPainter);
  inherited Destroy;
end;

end.
