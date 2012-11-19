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
    procedure SetList(const aList: TCustomLogMessageList); inline;
    function EnsureValidateTop(const aTop: integer): integer; override;
    function EmptyFilter(const aMessage: TCustomLogMessage): boolean;
    function GetFilter: TCustomLogMessageFilterMethod; inline;
    procedure SetPage(const aPage: integer); inline;
    function GetMessageListStartIndex: integer; inline;
    function GetMessageListLastIndex: integer; inline;
    function GetPageCount: integer; inline;
  public
      // owns the list
    property List: TCustomLogMessageList read FList write SetList;
    property Filter: TCustomLogMessageFilterMethod read GetFilter write FFilter;
    property PageSize: integer read FPageSize write FPageSize;
    property Page: integer read FPage write SetPage;
    property MessageListStartIndex: integer read GetMessageListStartIndex;
    property MessageListLastIndex: integer read GetMessageListLastIndex;
    property PageCount: integer read GetPageCount;
    property TotalHeight: integer read FTotalHeight;
    property Reverse: boolean read FReverse write FReverse;
    function CheckPageIndex(const aPage: integer): boolean;
    procedure Draw(const aMessage: TCustomLogMessage; const aDraw: boolean = true);
    procedure DrawList(const aDraw: boolean = true); overload;
    destructor Destroy; override;
  end;


implementation

constructor TLogMessageTextBoxPaint.Create;
begin
  inherited Create;
end;

procedure TLogMessageTextBoxPaint.SetList(const aList: TCustomLogMessageList);
begin
  if FList <> nil then
    FreeAndNil(FList);
  FList := aList;
end;

function TLogMessageTextBoxPaint.EnsureValidateTop(const aTop: integer): integer;
begin
  result := inherited EnsureValidateTop(aTop);
  if result < - TotalHeight + FBox.Height then
    result := - TotalHeight + FBox.Height;
  if TotalHeight < FBox.Height then
    result := 0;
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
var
  oldPage: integer;
begin
  if not CheckPageIndex(aPage) then
    exit;
  oldPage := Page;
  FPage := aPage;
  if aPage > oldPage then
    Top := 0;
  if aPage < oldPage then
  begin
    DrawList(false);
    Top := - TotalHeight + FBox.Height;
  end;
end;

function TLogMessageTextBoxPaint.GetMessageListStartIndex: integer;
begin
  AssertAssigned(List, 'List', TVariableType.Prop);
  LockPointer(List);

  result := Page * PageSize;
  if not Reverse then
  begin
    if result > List.Count - 1 then // exceeds
      result := List.Count; // exceeds
  end
  else
  begin
    result := List.Count - 1 - result;
    if result < 0 then // exceeds
      result := -1; // exceeds
  end;
  
  UnlockPointer(List);
end;

function TLogMessageTextBoxPaint.GetMessageListLastIndex: integer;
begin
  AssertAssigned(List, 'List', TVariableType.Prop);
  LockPointer(List);

  result := (Page + 1) * PageSize;
  if not Reverse then
  begin
    if result > List.Count - 1 then // exceeds
      result := List.Count - 1; // exists
  end
  else
  begin
    result := List.Count - 1 - result;
    if result < 0 then //exceeds
      result := 0; // exists
  end;
  
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

procedure TLogMessageTextBoxPaint.Draw(const aMessage: TCustomLogMessage;
  const aDraw: boolean);
var
  canv: TCanvas;
  bottomestVisible: boolean;
begin
  CurrentHeight := CurrentHeight + InnerTextGap;
  AppendDraw(
    '# ' + IntToStr(aMessage.Number)
    + ' at ' + DateTimeToStr(aMessage.Time)
    + ' [' + aMessage.Tag + ']'
    + ' "' + aMessage.Name + '"',
    clBlue,
    aDraw
  );
  bottomestVisible := AppendDraw(
    aMessage.Text,
    clBlack,
    aDraw
  );
  if bottomestVisible and aDraw then
  begin
    canv := FBox.Canvas;
    canv.Pen.Style := psSolid;
    canv.Pen.Color := clBlack;
    canv.Pen.Width := 1;
    canv.MoveTo(LeftGap, Top + CurrentHeight);
    canv.LineTo(FBox.Width - RightGap, Top + CurrentHeight );
  end;
end;

procedure TLogMessageTextBoxPaint.DrawList(const aDraw: boolean = true);
var
  i: integer;
  m: TCustomLogMessage;
  {$REGION Local PROCEDURE}
  procedure CycleMessage;
  begin
    m := List[i];
    if Filter(m) then
      Draw(m, aDraw);
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
  startIndex := MessageListStartIndex;
  lastIndex := MessageListLastIndex;
  AssertAssigned(List, 'List', TVariableType.Prop);
  if Reverse
  then
    for i := startIndex downto lastIndex do
      CycleMessage
  else
    for i := startIndex to lastIndex do
      CycleMessage;
  FTotalHeight := CurrentHeight;
  {$IFDEF DEBUG_WRITELN_REDRAW_PERFORMANCE}
    WriteLN(FormatFloat(',0.000000', StopCount(stopWatch)));
  {$ENDIF}
end;

destructor TLogMessageTextBoxPaint.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

end.








