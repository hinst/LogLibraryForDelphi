unit CustomLogMessageList;

interface

uses
  Classes,
  Contnrs,

  UAdditionalTypes,
  UAdditionalExceptions,

  CustomLogMessage;

type
  TCustomLogMessageList = class(TObjectList)
  public
    constructor Create; reintroduce;
  protected
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
    function GetItem(const aIndex: integer): TCustomLogMessage;
  public
    function Add(const aItem: TCustomLogMessage): integer; reintroduce;
    property Items[const i: integer]: TCustomLogMessage read GetItem; default;
  end;

implementation

constructor TCustomLogMessageList.Create;
begin
  inherited Create(false);
end;

function TCustomLogMessageList.Add(const aItem: TCustomLogMessage): integer;
begin
  aItem.Reference;
  result := inherited Add(aItem);
end;

function TCustomLogMessageList.GetItem(const aIndex: integer): TCustomLogMessage;
begin
  result := inherited GetItem(aIndex) as TCustomLogMessage;
end;

procedure TCustomLogMessageList.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if Action = lnDeleted then
     TCustomLogMessage(Ptr).Dereference;
  inherited Notify(Ptr, Action);
end;

end.
