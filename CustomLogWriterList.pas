unit CustomLogWriterList;

interface

uses
  Contnrs,

  CustomLogWriter;

type
  TCustomLogWriterList = class(TObjectList)
  protected
    function GetItem(const aIndex: integer): TCustomLogWriter;
  public
    property Items[const aIndex: integer]: TCustomLogWriter read GetItem; default;
  end;


implementation

function TCustomLogWriterList.GetItem(const aIndex: integer): TCustomLogWriter;
begin
  result := inherited GetItem(aIndex) as TCustomLogWriter;
end;

end.
