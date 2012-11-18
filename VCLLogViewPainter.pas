unit VCLLogViewPainter;

{ $DEFINE DEBUG_WRITELN_REDRAW_PERFORMANCE}

interface

uses
  Windows,
  Types,
  SysUtils,
  Graphics,
  Controls,
  ExtCtrls,

  JCLCounter,
  JCLSortedMaps,

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
  public
    constructor Create;
  protected
    FList: TCustomLogMessageList;
    FFilter: TCustomLogMessageFilterMethod;
    FPageSize: integer;
    FPage: integer;
    FTotalHeight: integer;
    FReverse: boolean;
    FMessageHeightCache: TJclPtrPtrSortedMap;
    procedure SetList(const aList: TCustomLogMessageList);
    procedure SetTop(const aTop: integer); override;
    function EmptyFilter(const aMessage: TCustomLogMessage): boolean;
    function GetFilter: TCustomLogMessageFilterMethod;
    procedure SetPage(const aPage: integer);
    function GetMessageListStartIndex: integer;
    function GetMessageListLastIndex: integer;
    function GetPageCount: integer;
  public
      // owns the list
    property List: TCustomLogMessageList read FList write SetList;
    property Filter: TCustomLogMessageFilterMethod read GetFilter write FFilter;
    property PageSize: integer read FPageSize write FPageSize;
    property Page: integer read FPage write SetPage;
    property PageCount: integer read GetPageCount;
    property TotalHeight: integer read FTotalHeight;
    property Reverse: boolean read FReverse write FReverse;
    function CheckPageIndex(const aPage: integer): boolean;
    procedure Draw(const aMessage: TCustomLogMessage); overload;
    procedure DrawList; overload;
    destructor Destroy; override;
  end;


implementation

constructor TLogMessageTextBoxPaint.Create;
begin
  inherited Create;
  FMessageHeightCache := TJclPtrPtrSortedMap.Create(0);
end;

procedure TLogMessageTextBoxPaint.SetList(const aList: TCustomLogMessageList);
begin
  if FList <> nil then
    FreeAndNil(FList);
  FList := aList;
  Page := 0;
end;

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
  if not CheckPageIndex(aPage) then
    exit;
  if aPage > Page then
    Top := 0;
  if aPage < Page then
    Top := - TotalHeight + FBox.Height;
  FPage := aPage;
end;

function TLogMessageTextBoxPaint.GetMessageListStartIndex: integer;
begin
  result := Page * PageSize;
  if Reverse then
    result := List.Count - 1 - result;
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
  if Reverse then
    result := List.Count - 1 - result;  
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
    result := List.Count div PageSize + 1;
end;

function TLogMessageTextBoxPaint.CheckPageIndex(const aPage: integer): boolean;
begin
  result := (0 <= aPage) and (aPage < PageCount);
end;

procedure TLogMessageTextBoxPaint.Draw(const aMessage: TCustomLogMessage);
var
  canv: TCanvas;
begin
  CurrentHeight := CurrentHeight + InnerTextGap;
  AppendDraw(
    '#' + IntToStr(aMessage.Number) + ' "' + aMessage.Name + '" [' + aMessage.Tag + ']',
    clBlue
  );
  if AppendDraw(aMessage.Text, clBlack) then
  begin
    canv := FBox.Canvas;
    canv.Pen.Style := psSolid;
    canv.Pen.Color := clBlack;
    canv.Pen.Width := 1;
    canv.MoveTo(LeftGap, Top + CurrentHeight);
    canv.LineTo(FBox.Width - RightGap, Top + CurrentHeight );
  end;
end;

procedure TLogMessageTextBoxPaint.DrawList;
var
  i: integer;
  m: TCustomLogMessage;
  {$REGION Local PROCEDURE}
  procedure CycleMessage;
  begin
    m := List[i];
    if Filter(m) then
      Draw(m);
  end;
  {$ENDREGION}
var
  startIndex, lastIndex: integer;
  {$IFDEF DEBUG_WRITELN_REDRAW_PERFORMANCE}
    stopWatch: TJclCounter;
  {$ENDIF}
begin
  {$IFDEF DEBUG_WRITELN_REDRAW_PERFORMANCE}
    StartCount(stopWatch);
  {$ENDIF}
  FCurrentHeight := 0;
  FTotalHeight := 0;
  startIndex := GetMessageListStartIndex;
  lastIndex := GetMessageListLastIndex;
  AssertAssigned(List, 'List', TVariableType.Prop);
  LockPointer(List);
  if Reverse
  then
    for i := startIndex downto lastIndex do
      CycleMessage
  else
    for i := startIndex to lastIndex do
      CycleMessage;
  UnlockPointer(List);
  FTotalHeight := CurrentHeight;
  {$IFDEF DEBUG_WRITELN_REDRAW_PERFORMANCE}
    WriteLN(FormatFloat(',0.000000', StopCount(stopWatch)));
  {$ENDIF}
end;

destructor TLogMessageTextBoxPaint.Destroy;
begin
  FreeAndNil(FList);
  FreeAndNil(FMessageHeightCache);
  inherited Destroy;
end;

end.








