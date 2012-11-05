unit CustomLogManager;

interface

uses
  CustomLogMessage,
  CustomLogWriter;

type
  TCustomLogManager = class
  public
    function CreateMessage: TCustomLogMessage; virtual; abstract;
    procedure WriteMessage(const aMessage: TCustomLogMessage); virtual; abstract;
    procedure AddWriter(const aWriter: TCustomLogWriter); virtual; abstract;
    function RemoveWriter(const aWriter: TCustomLogWriter): boolean; virtual; abstract;
  end;

implementation

end.
