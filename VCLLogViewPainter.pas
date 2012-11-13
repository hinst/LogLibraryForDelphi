unit VCLLogViewPainter;

interface

uses
  SysUtils,
  Graphics,

  UMath,
  ULockThis,
  UAdditionalTypes,
  UAdditionalExceptions,

  CustomLogMessage,
  CustomLogMessageList,
  CustomLogMessageFilter,
  UVCLTextBoxPaint;

type
  TLogMessageTextBoxPaint = class(TTextBoxPainter)
  protected
    FList: TCustomLogMessageList;
    FFilter: TCustomLogMessageFilterMethod;
    FPageSize: integer;
    FPage: integer;
    FTotalHeight: integer;
    FMessageCount: integer;
    procedure SetTop(const aTop: integer); override;
    function EmptyFilter(const aMessage: TCustomLogMessage): boolean;
    function GetFilter: TCustomLogMessageFilterMethod;
    procedure SetPage(const aPage: integer);
    function GetMessageListStartIndex: integer;
    function GetMessageListLastIndex: integer;
    function GetPageCount: integer;
  public
    property List: TCustomLogMessageList read FList write FList;
    property Filter: TCustomLogMessageFilterMethod read GetFilter write FFilter;
    property PageSize: integer read FPageSize write FPageSize;
    property Page: integer read FPage write SetPage;
    property PageCount: integer read GetPageCount;
    property TotalHeight: integer read FTotalHeight;
    procedure Draw(const aMessage: TCustomLogMessage); overload;
    procedure DrawList; overload;
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

procedure TLogMessageTextBoxPaint.SetPage(const aPage: integer);
begin
  if aPage > Page then
    Top := 0;
  if aPage < Page then
    Top := - TotalHeight + FBox.Height;
end;

function TLogMessageTextBoxPaint.GetMessageListStartIndex: integer;
begin
  result := Page * PageSize;
  if result < 0 then
    result := 0;
  AssertAssigned(List, 'List', TVariableType.Prop);
  LockPointer(List);
  if result > List.Count - 1 then // exceeds
    result := List.Count; // does not exists
  UnlockPointer(List);
end;

function TLogMessageTextBoxPaint.GetMessageListLastIndex: integer;
begin
  result := (Page + 1) * PageSize;
  if result < 0 then
    result := 0;
  AssertAssigned(List, 'List', TVariableType.Prop);
  LockPointer(List);
  if result > List.Count - 1 then // exceeds
    result := List.Count - 1; // exists
  UnlockPointer(List);
end;

function TLogMessageTextBoxPaint.GetPageCount: integer;
begin
  if PageSize = 0 then
    result := 0
  else
    result := FMessageCount div PageSize + 1;
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

procedure TLogMessageTextBoxPaint.DrawList;
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
  FMessageCount := 0;
  startIndex := GetMessageListStartIndex;
  lastIndex := GetMessageListLastIndex;
  AssertAssigned(List, 'List', TVariableType.Prop);
  LockPointer(List);
  for i := startIndex to lastIndex do
  begin
    m := List[i];
    if filter(m) then
    begin
      DrawMessage;
      FMessageCount := FMessageCount + 1;
    end;
  end;
  UnlockPointer(List);
  FTotalHeight := CurrentHeight;
end;

end.
