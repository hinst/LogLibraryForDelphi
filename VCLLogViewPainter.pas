unit VCLLogViewPainter;

interface

uses
  SysUtils,
  Graphics,

  CustomLogMessage,
  CustomLogMessageList,
  CustomLogMessageFilter,
  UVCLTextBoxPaint;

type
  TLogMessageTextBoxPaint = class(TTextBoxPainter)
  protected
    FFilter: TCustomLogMessageFilterMethod;
    FPageSize: integer;
    FPage: integer;
    FTotalHeight: integer;
    procedure SetTop(const aTop: integer); override;
    function EmptyFilter(const aMessage: TCustomLogMessage): boolean;
    function GetFilter: TCustomLogMessageFilterMethod;
  public
    property Filter: TCustomLogMessageFilterMethod read GetFilter write FFilter;
    property Page: integer read FPage write FPage;
    property TotalHeight: integer read FTotalHeight;
    procedure Draw(const aMessage: TCustomLogMessage); overload;
    procedure DrawList(const aList: TCustomLogMessageList); overload;
  end;

  TLogMessageTextBoxPaintAdvanced = class(TLogMessageTextBoxPaint)
  public
  end;


implementation

procedure TLogMessageTextBoxPaint.SetTop(const aTop: integer);
begin
  FTop := aTop;
  if FTop < - TotalHeight + FBox.Height then
  begin
    FTop := - TotalHeight + FBox.Height;
  end;
  inherited SetTop(FTop);
end;

function TLogMessageTextBoxPaint.EmptyFilter(const aMessage: TCustomLogMessage): boolean;
begin
  result := true; // all pass, none ignored
end;

function TLogMessageTextBoxPaint.GetFilter: TCustomLogMessageFilterMethod;
begin
  result := FFilter;
  if @result = nil then
    result := EmptyFilter;
end;

procedure TLogMessageTextBoxPaint.Draw(const aMessage: TCustomLogMessage);
begin
  CurrentHeight := CurrentHeight + InnerTextGap;
  AppendDraw(IntToStr(aMessage.Number), clRed);
  AppendDraw(aMessage.Name, clGreen);
  AppendDraw(aMessage.Tag, clBlue);
  if AppendDraw(aMessage.Text, clBlack) then
  begin
    FBox.Canvas.Pen.Style := psSolid;
    FBox.Canvas.Pen.Color := clBlack;
    FBox.Canvas.MoveTo(LeftGap, Top + CurrentHeight);
    FBox.Canvas.LineTo(FBox.Width - RightGap, Top + CurrentHeight );
  end;
end;

procedure TLogMessageTextBoxPaint.DrawList(const aList: TCustomLogMessageList);
var
  i: integer;
  m: TCustomLogMessage;
  {$REGION Local PROCEDURE}
  procedure DrawMessage;
  begin
    Draw(m);
  end;
  {$ENDREGION}
begin
  FCurrentHeight := 0;
  FTotalHeight := 0;
  for i := 0 to aList.Count - 1 do
  begin
    m := aList[i];
    if filter(m) then
      DrawMessage;
  end;
  FTotalHeight := CurrentHeight;
end;

end.
