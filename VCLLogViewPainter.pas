unit VCLLogViewPainter;

interface

uses
  SysUtils,
  Graphics,

  UMath,

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
    function GetMessageListStartIndex(const aList: TCustomLogMessageList): integer;
    function GetMessageListLastIndex(const aList: TCustomLogMessageList): integer;
  public
    property Filter: TCustomLogMessageFilterMethod read GetFilter write FFilter;
    property PageSize: integer read FPageSize write FPageSize;
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

function TLogMessageTextBoxPaint.GetMessageListStartIndex(const aList: TCustomLogMessageList)
  : integer;
begin
  result := Page * PageSize;
  if result < 0 then
    result := 0;
  if result > aList.Count - 1 then // exceeds
    result := aList.Count; // does not exists
end;

function TLogMessageTextBoxPaint.GetMessageListLastIndex(const aList: TCustomLogMessageList)
  : integer;
begin
  result := (Page + 1) * PageSize;
  if result < 0 then
    result := 0;
  if result > aList.Count - 1 then // exceeds
    result := aList.Count - 1; // exists
end;

procedure TLogMessageTextBoxPaint.Draw(const aMessage: TCustomLogMessage);
begin
  CurrentHeight := CurrentHeight + InnerTextGap;
  AppendDraw(
    '#' + IntToStr(aMessage.Number) + ' "' + aMessage.Name + '" [' + aMessage.Tag + ']',
    clBlue
  );
  if AppendDraw(aMessage.Text, clBlack) then
  begin
    FBox.Canvas.Pen.Style := psSolid;
    FBox.Canvas.Pen.Color := clBlack;
    FBox.Canvas.Pen.Width := 1;
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
var
  startIndex, lastIndex: integer;
begin
  FCurrentHeight := 0;
  FTotalHeight := 0;
  startIndex := GetMessageListStartIndex(aList);
  lastIndex := GetMessageListLastIndex(aList);
  WriteLN(startIndex, ' ', lastIndex);
  for i := startIndex to lastIndex do
  begin
    m := aList[i];
    if filter(m) then
      DrawMessage;
  end;
  FTotalHeight := CurrentHeight;
end;

end.
