unit ConsoleLogWriter;

interface

uses
  CustomLogMessage,
  CustomLogTextFormat,
  PlainLogTextFormat,
  UEnhancedObject,
  CustomLogWriter;

type
  TConsoleLogWriter = class(TCustomLogWriter)
  protected
    FFormat: TCustomLogTextFormat;
    procedure SetFormat(const aFormat: TCustomLogTextFormat);
    procedure ActuallyWrite(const aMessage: TCustomLogMessage);
  public
    property Format: TCustomLogTextFormat read FFormat write SetFormat;
    procedure Write(const aMessage: TCustomLogMessage); override;
    destructor Destroy; override;
  end;
  

implementation

procedure TConsoleLogWriter.SetFormat(const aFormat: TCustomLogTextFormat);
begin
  TEnhancedObject.AssignReference(FFormat, aFormat);
end;

procedure TConsoleLogWriter.ActuallyWrite(const aMessage: TCustomLogMessage);
var
  text: string;
begin
  text := '';
  if Format = nil then
    Format := TPlainLogTextFormat.CreateDefault;
  text := Format.Format(aMessage);
  WriteLN(text);
end;

procedure TConsoleLogWriter.Write(const aMessage: TCustomLogMessage);
begin
  if IsConsole then
    ActuallyWrite(aMessage);
end;

destructor TConsoleLogWriter.Destroy;
begin
  Format := nil;
  inherited Destroy;
end;

end.
