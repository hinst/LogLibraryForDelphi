unit CustomLogTextFormat;

interface

uses
  UEnhancedObject,

  CustomLogMessage;

type
  TCustomLogTextFormat = class(TEnhancedObject)
  public
    function Format(const aMessage: TCustomLogMessage): string; virtual; abstract;
  end;

implementation

end.
