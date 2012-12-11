unit CustomLogEntity;

interface

type
  TCustomLog = class
  public
    procedure Write(const aText: string); overload; virtual; abstract;
    procedure Write(const aTag, aText: string); overload; virtual; abstract;
  public type
    StandardTag = object
    public const
      Error = 'ERROR';
      Warning = 'WARNING';
    end;
  end;

implementation

end.
