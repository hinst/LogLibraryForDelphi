unit FileLogWriter;

interface

uses
  Windows,
  Types,
  SysUtils,
  Classes,
  StrUtils,

  UEnhancedObject,
  UAdditionalTypes,
  UAdditionalExceptions,
  UTextUtilities,
  UWindowsTempFile,

  CustomLogMessage,
  CustomLogTextFormat,
  PlainLogTextFormat,
  CustomLogWriter;

type
  TFileLogWriter = class(TCustomLogWriter)
  protected
    FFilePath: string;
    FFormat: TCustomLogTextFormat;
    FStream: TFileStream;
    procedure SetFormat(const aFormat: TCustomLogTextFormat);
    function GetDefaultFilePath: string;
    procedure ActuallyWrite(const aMessage: TCustomLogMessage);
  public
    property FilePath: string read FFilePath write FFilePath;
    property Format: TCustomLogTextFormat read FFormat write SetFormat;
    property Stream: TFileStream read FStream;
    procedure SetDefaultFilePath;
    procedure Write(const aMessage: TCustomLogMessage); override;
    destructor Destroy; override;
  end;
  

implementation

procedure TFileLogWriter.SetFormat(const aFormat: TCustomLogTextFormat);
begin
  TEnhancedObject.AssignReference(FFormat, aFormat);
end;

function TFileLogWriter.GetDefaultFilePath: string;
begin
  result := GetTempFilePath('LOG');
end;

procedure TFileLogWriter.ActuallyWrite(const aMessage: TCustomLogMessage);
var
  text: string;
begin
  AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
  text := Format.Format(aMessage);
  if not AnsiEndsStr(text, sLineBreak) then
    text := text + sLineBreak;
  Stream.Write(PAnsiChar(text)^, length(text));
end;

procedure TFileLogWriter.SetDefaultFilePath;
begin
  FilePath := GetDefaultFilePath;
end;

procedure TFileLogWriter.Write(const aMessage: TCustomLogMessage);
begin
  if FilePath = '' then
    FilePath := GetDefaultFilePath;
  if FFormat = nil then
    Format := TPlainLogTextFormat.CreateDefault;
  if FStream = nil then
    FStream := TFileStream.Create(FFilePath, fmCreate or fmOpenWrite, fmShareDenyWrite);
  ActuallyWrite(aMessage);
end;

destructor TFileLogWriter.Destroy;
begin
  FreeAndNil(fStream);
  Format := nil;
  inherited Destroy;
end;

end.
