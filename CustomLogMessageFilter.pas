unit CustomLogMessageFilter;

interface

uses
  CustomLogMessage;

type
  TCustomLogMessageFilterMethod = function(const aMessage: TCustomLogMessage): boolean of object;

implementation

end.
