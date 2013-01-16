unit CustomLogEntity;

interface

type
  TCustomLog = class
  public
    procedure Write(const aText: string); overload; virtual; abstract;
    procedure Write(const aTag, aText: string); overload; virtual; abstract;
  public type
    StandardTag = class
      class function Error: string;
      class function Warning: string;
    end;
  end;

implementation

class function TCustomLog.StandardTag.Error: string;
begin
  result := 'ERROR';
end;

class function TCustomLog.StandardTag.Warning: string;
begin
  result := 'WARNING';
end;

end.
