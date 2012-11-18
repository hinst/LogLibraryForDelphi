unit UCustomLogMessageListFilter;

interface

uses
  ULockThis,

  CustomLogMessage,
  CustomLogMessageFilter,
  CustomLogMessageList;

function CreateFiltered(const aFilter: TCustomLogMessageFilterMethod;
  const aSource: TCustomLogMessageList): TCustomLogMessageList;

procedure AddFiltered(const aDestination: TCustomLogMessageList;
  const aFilter: TCustomLogMessageFilterMethod; const aSource: TCustomLogMessageList);

  
implementation

function CreateFiltered(const aFilter: TCustomLogMessageFilterMethod;
  const aSource: TCustomLogMessageList): TCustomLogMessageList;
begin
  result := TCustomLogMessageList.Create;
  AddFiltered(result, aFilter, aSource);
end;

procedure AddFiltered(const aDestination: TCustomLogMessageList;
  const aFilter: TCustomLogMessageFilterMethod; const aSource: TCustomLogMessageList);
var
  i: integer;
  m: TCustomLogMessage;
begin
  for i := 0 to aSource.Count - 1 do
  begin
    m := aSource[i];
    if aFilter(m) then
      aDestination.Add(m);
  end;
end;

  
end.
