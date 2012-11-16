unit CustomLogMessageFilter;

interface

uses
  SysUtils,
  Classes,
  StrUtils,

  UAdditionalTypes,
  UAdditionalExceptions,

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
  Clear;
  FRequired.DelimitedText := aFilterText;
  ExtractNegative;
end;

function TLogMessageTextFilter.ContainsRequired(const aText: string): boolean;
var
  i: integer;
begin
  result := true;
  for i := 0 to FRequired.Count - 1 do
    if Pos(FRequired[i], aText) <= 0 then
    begin
      result := false;
      break;
    end;
end;

function TLogMessageTextFilter.ContainsNegative(const aText: string): boolean;
var
  i: integer;
begin
  result := false;
  for i := 0 to FNegative.Count - 1 do
    if Pos(FNegative[i], aText) > 0 then
    begin
      result := true;
      break;
    end;
end;

procedure TLogMessageTextFilter.ExtractNegative;
var
  i: integer;
begin
  for i := 0 to FRequired.Count - 1 do
    if StartsText(NegativeChar, FRequired[i]) then
    begin
      FNegative.Add(FRequired[i]);
      FRequired.Delete(i);
    end;
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
