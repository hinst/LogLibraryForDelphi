unit CustomLogEntity;

interface

type
  TCustomLog = class
  public
    procedure Write(const aText: string); overload; virtual; abstract;
    procedure Write(const aTag, aText: string); overload; virtual; abstract;
  end;

implementation

end.
