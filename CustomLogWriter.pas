unit CustomLogWriter;

interface

uses
  Classes,
  CustomLogMessage;

type
  TCustomLogWriter = class
  public
    procedure Write(const aMessage: TCustomLogMessage); virtual; abstract;
  end;

  TCustomLogWriterClass = class of TCustomLogWriter;

implementation

end.
