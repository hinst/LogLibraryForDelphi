unit CustomLogMessageFilter;

{ $DEFINE DEBUG_WRITELN_CUSTOM_LOG_MESSAGE_FILTER_APPLY}

interface

uses
  SysUtils,
  Classes,
  StrUtils,

  JclArrayLists,

  UAdditionalTypes,
  UAdditionalExceptions,
  UTextUtilities,

  CustomLogMessage;

type

  TCustomLogMessageFilterMethod = function(const aMessage: TCustomLogMessage): boolean of object;

  TLogMessageTextFilter = class
  public
    constructor Create;
  public const
    NegativeChar = '-';
  protected
    FRequired: TStrings;
    FNegative: TStrings;
    procedure SetFilterText(const aFilterText: string);
    function ContainsRequired(const aText: string): boolean;
    function ContainsNegative(const aText: string): boolean;
    function CheckExtractNegative(var aString: string): boolean;
    procedure ExtractFirstPhaseWords(const aFilterText: string);
    procedure ExtractNegative;
  public
    property FilterText: string write SetFilterText;
    function Filter(const aMessage: TCustomLogMessage): boolean;
    procedure Clear;
    destructor Destroy; override;
  end;


implementation

constructor TLogMessageTextFilter.Create;
begin
  inherited Create;
  FRequired := TStringList.Create;
  FNegative := TStringList.Create;
end;

procedure TLogMessageTextFilter.SetFilterText(const aFilterText: string);
begin
  ExtractFirstPhaseWords(aFilterText);
  ExtractNegative;
end;

function TLogMessageTextFilter.ContainsRequired(const aText: string): boolean;
var
  i: integer;
begin
  result := true;
  // если хотя бы одни не содержит, то ответ отрицательный и прервать цикл
  for i := 0 to FRequired.Count - 1 do
    if not ContainsText(aText, FRequired[i]) then
    begin
      result := false;
      {$IFDEF DEBUG_WRITELN_CUSTOM_LOG_MESSAGE_FILTER_APPLY}
      WriteLN(aText, ', ', FRequired[i], ', ', result);
      {$ENDIF}
      break;
    end;
end;

function TLogMessageTextFilter.ContainsNegative(const aText: string): boolean;
var
  i: integer;
begin
  result := false;
  // если хотя бы один содержит запрещённый, то ответ положительный и прервать цикл
  for i := 0 to FNegative.Count - 1 do
    if ContainsText(aText, FNegative[i]) then
    begin
      result := true;
      break;
    end;
end;

function TLogMessageTextFilter.CheckExtractNegative(var aString: string): boolean;
begin
  result := StartsText(NegativeChar, aString);
  if result then
    Delete(aString, 1, 1);  
end;

procedure TLogMessageTextFilter.ExtractFirstPhaseWords(const aFilterText: string);
begin
  FRequired.Clear;
  FRequired.DelimitedText := aFilterText;
end;

procedure TLogMessageTextFilter.ExtractNegative;
begin
  FreeAndNil(FNegative);
  FNegative := CreateExtractStrings(FRequired, CheckExtractNegative);
end;

function TLogMessageTextFilter.Filter(const aMessage: TCustomLogMessage): boolean;
begin
  result := ContainsRequired(aMessage.Tag);
  result := result and not ContainsNegative(aMessage.Tag);
end;

procedure TLogMessageTextFilter.Clear;
begin
  FRequired.Clear;
  FNegative.Clear;
end;

destructor TLogMessageTextFilter.Destroy;
begin
  FreeAndNil(FRequired);
  FreeAndNil(FNegative);
  inherited Destroy;
end;

end.
