unit VCLLogPanelItem;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Graphics,
  Contnrs,
  Forms,

  Controls,
  ExtCtrls,
  StdCtrls,

  UAdditionalTypes,
  UAdditionalExceptions,
  UEnhancedObject,
  UCustomThread,

  CustomLogMessage;

type
  TLogPanelItem = class
  public
    constructor Create(const aOwner: TComponent; const aMessage: TCustomLogMessage); reintroduce;
  public const
    NOHEIGHT = -1;
  public type
    TRecalculateHeight = class
    public
      Item: TLogPanelItem;
      Canvas: TCanvas;
      procedure Perform; overload;
      class procedure Perform(
        const aItem: TLogPanelItem;
        const aCanvas: TCanvas;
        const aThread: TCustomThread
      ); overload;
    end;
  protected
    fLogMessage: TCustomLogMessage;
    fTime: string;
    fTimeHeight: integer;
    fCaptionHeight: integer;
    fTextHeight: integer;
    fHeight: integer;
    fParent: TPanel;
    fGap: integer;
    fInnerTextGap: integer;
    fBorderColor: TColor;
    function GetTime: string; inline;
    function GetDefaultTimeFormat: string;
    function GetCaptionText: string;
    procedure CreateThis;
    procedure AssignDefaults;
    function CalculateTextHeight(const aCanvas: TCanvas; const aText: string): integer;
    procedure DestroyThis;
  public
    property LogMessage: TCustomLogMessage read fLogMessage;
    property CaptionText: string read GetCaptionText;
    property Time: string read GetTime;
    property TimeHeight: integer read fTimeHeight;
    property CaptionHeight: integer read fCaptionHeight;
    property TextHeight: integer read fTextHeight;
    property Height: integer read fHeight;
      // external assign required
    property Parent: TPanel read fParent write fParent;
    property Gap: integer read fGap write fGap;
    property InnerTextGap: integer read fInnerTextGap write fInnerTextGap;
    property BorderColor: TColor read fBorderColor write fBorderColor;
    procedure DirectRecalculateHeight(const aCanvas: TCanvas);
    procedure SynchronizedRecalculateHeight(const aCanvas: TCanvas; const aThread: TCustomThread);
    procedure Paint(const aCanvas: TCanvas; const aTop: integer);
    destructor Destroy; override;
  end;

  TLogPanelItemList = class(TObjectList)
  protected
    function GetItem(const aIndex: integer): TLogPanelItem;
  public
    property Items[const aIndex: integer]: TLogPanelItem read GetItem; default;
  end;


implementation

constructor TLogPanelItem.Create(const aOwner: TComponent; const aMessage: TCustomLogMessage);
begin
  inherited Create;
  fLogMessage := aMessage;
  CreateThis;
end;

procedure TLogPanelItem.CreateThis;
begin
  LogMessage.Reference;
  AssignDefaults;
end;

procedure TLogPanelItem.AssignDefaults;
begin
  fHeight := NOHEIGHT;
  Gap := 3;
  BorderColor := clGray;
  InnerTextGap := 3;
end;

function TLogPanelItem.CalculateTextHeight(const aCanvas: TCanvas; const aText: string): integer;
var
  r: TRect;
  text: string;
begin
  text := aText;
  r := Rect(
    Gap + InnerTextGap,
    InnerTextGap,
    Parent.ClientWidth - Gap - InnerTextGap, 0);
  DrawText(aCanvas.Handle,
    PChar(PChar(text)),
    Length(text),
    r,
    DT_LEFT or DT_TOP or DT_WORDBREAK or DT_CALCRECT
  );
  result := r.Bottom - r.Top;
end;

procedure TLogPanelItem.DestroyThis;
begin
  DereferenceAndNil(fLogMessage);
end;

procedure TLogPanelItem.DirectRecalculateHeight(const aCanvas: TCanvas);
begin
  fHeight := 0;
  {$REGION Time}
  fTimeHeight := CalculateTextHeight(aCanvas, Time);
  fHeight := fHeight + InnerTextGap + fTimeHeight;
  {$ENDREGION}
  {$REGION Tag}
  fCaptionHeight := CalculateTextHeight(aCanvas, LogMessage.Name + ': ' + LogMessage.Tag);
  fHeight := Height + InnerTextGap + CaptionHeight;
  {$ENDREGION}
  {$REGION Text}
  fTextHeight := CalculateTextHeight(aCanvas, LogMessage.Text);
  fHeight := Height + InnerTextGap + TextHeight;
  {$ENDREGION}

  fHeight := Height + InnerTextGap;
  //WriteLN('Height recalculated: ' + IntToStr(Height));
end;

function TLogPanelItem.GetCaptionText: string;
begin
  result := LogMessage.Name + ': ' + LogMessage.Tag;
end;

function TLogPanelItem.GetDefaultTimeFormat: string;
begin
  result := 'yyyy.m.d hh:mm:ss.zz';
end;

function TLogPanelItem.GetTime: string;
begin
  AssertAssigned(LogMessage, 'LogMessage', TVariableType.Prop);
  if fTime = '' then
    DateTimeToString(fTime, GetDefaultTimeFormat, LogMessage.Time);
  result := fTime;
end;

procedure TLogPanelItem.SynchronizedRecalculateHeight(const aCanvas: TCanvas;
  const aThread: TCustomThread);
begin
  TRecalculateHeight.Perform(self, aCanvas, aThread);
end;

procedure TLogPanelItem.Paint(const aCanvas: TCanvas; const aTop: integer);
var
  currentOffset: integer;

  function NextRect(const aHeight: integer): TRect;
  begin
    result.Left := Parent.ClientRect.Left + Gap + InnerTextGap;
    result.Top := aTop + currentOffset + InnerTextGap;
    result.Right := Parent.ClientRect.Right - Gap - InnerTextGap;
    result.Bottom := aTop + currentOffset + InnerTextGap + aHeight;
    currentOffset := currentOffset + InnerTextGap + aHeight;
  end;

  procedure NextDraw(const aText: string; const aHeight: integer);
  var
    textRect: TRect;
    text: string;
  begin
    textRect := NextRect(aHeight);
    text := aText;
    aCanvas.TextRect(
      textRect,
      text,
      [tfWordBreak]
    );
    //aCanvas.Rectangle(textRect);
  end;

begin
  aCanvas.Pen.Color := BorderColor;
  aCanvas.Pen.Width := 1;
  aCanvas.Pen.Style := psSolid;
  aCanvas.Rectangle(
    Parent.ClientRect.Left + Gap,
    aTop,
    Parent.ClientRect.Right - Gap * 2,
    aTop + Height
  );

  currentOffset := 0;
  aCanvas.Font.Color := clGreen;
  NextDraw(Time, TimeHeight);
  aCanvas.Font.Color := clBlue;
  NextDraw(CaptionText, CaptionHeight);
  aCanvas.Font.Color := clBlack;
  NextDraw(LogMessage.Text, TextHeight);
end;

destructor TLogPanelItem.Destroy;
begin
  DestroyThis;
  inherited Destroy;
end;


function TLogPanelItemList.GetItem(const aIndex: integer): TLogPanelItem;
begin
  result := inherited GetItem(aIndex) as TLogPanelItem;
end;

procedure TLogPanelItem.TRecalculateHeight.Perform;
begin
  item.DirectRecalculateHeight(Canvas);
end;

class procedure TLogPanelItem.TRecalculateHeight.Perform(const aItem: TLogPanelItem;
  const aCanvas: TCanvas; const aThread: TCustomThread);
var
  me: TRecalculateHeight;
begin
  me := TRecalculateHeight.Create;
  me.Item := aItem;
  me.Canvas := aCanvas;
  aThread.Synchronize(me.Perform);
  me.Free;
end;



end.
