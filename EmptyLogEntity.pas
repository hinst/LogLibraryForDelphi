unit EmptyLogEntity;

interface

uses
  SysUtils,
  CustomLogEntity;

type
  TEmptyLog = class(TCustomLog)
  public
    procedure Write(const aText: string); overload; override;
    procedure Write(const aTag, aText: string); overload; override;
    function CreateAnother(const aName: string = ''): TEmptyLog; virtual;
  end;

procedure ReplaceLog(var aLog: TEmptyLog; const aNewLog: TEmptyLog);


implementation

procedure TEmptyLog.Write(const aText: string);
begin
end;

procedure TEmptyLog.Write(const aTag, aText: string);
begin
end;

function TEmptyLog.CreateAnother(const aName: string): TEmptyLog;
begin
  result := TEmptyLog.Create;
end;

procedure ReplaceLog(var aLog: TEmptyLog; const aNewLog: TEmptyLog);
begin
  if aLog <> nil then
    FreeAndNil(aLog);
  if aNewLog  <> nil then
    aLog := aNewLog
  else
    aLog := TEmptyLog.Create;
end;

end.


















