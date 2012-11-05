unit PlainLogManager;

interface

uses
  SysUtils,
  Contnrs,
  SyncObjs,

  UEnhancedObject,

  CustomLogMessage,
  CustomLogMessageList,
  CustomLogEntity,
  DefaultLogEntity,
  DefaultLogMessage,
  CustomLogManager,
  CustomLogWriter,
  CustomLogWriterList;

type

  TPlainLogManager = class(TCustomLogManager)
  public
    constructor Create;
  protected
    fLog: TCustomLog;
    fMessageNumber: integer;
    fWriters: TCustomLogWriterList;
    fWriteMessageLock: TCriticalSection;
    procedure WriteMessageInternal(const aMessage: TCustomLogMessage);
    procedure WriteMessageThreadSafe(const aMessage: TCustomLogMessage);
  public
    property Log: TCustomLog read fLog;
    property MessageNumber: integer read fMessageNumber;
    property Writers: TCustomLogWriterList read fWriters;
    property WriteMessageLock: TCriticalSection read fWriteMessageLock;
      // TLogManager owns writers.
      // It meas that it releases them on destruction
    function CreateMessage: TCustomLogMessage; override;
      // Releases aMessage after execution
    procedure WriteMessage(const aMessage: TCustomLogMessage); override;
    procedure AddWriter(const aWriter: TCustomLogWriter); override;
    function RemoveWriter(const aWriter: TCustomLogWriter): boolean; override;
    function WriterListToText: string;
    procedure WriteWriterList;
    destructor Destroy; override;
  end;
  

implementation

constructor TPlainLogManager.Create;
begin
  inherited Create;
  fLog := TLog.Create(self, 'LogManager');
  fMessageNumber := 0;
  fWriters := TCustomLogWriterList.Create(true);
  fWriteMessageLock := TCriticalSection.Create;
end;

procedure TPlainLogManager.WriteMessageInternal(const aMessage: TCustomLogMessage);
var
  i: integer;
begin
  inc(fMessageNumber);
  aMessage.Number := MessageNumber;
  for i := 0 to Writers.Count - 1 do
    Writers[i].Write(aMessage);
  aMessage.Dereference;
end;

procedure TPlainLogManager.WriteMessageThreadSafe(const aMessage: TCustomLogMessage);
begin
  WriteMessageLock.Enter;
  WriteMessageInternal(aMessage);
  WriteMessageLock.Leave;
end;

function TPlainLogManager.CreateMessage: TCustomLogMessage;
begin
  result := TDefaultLogMessage.Create(MessageNumber);
  result.Time := Now;
end;

procedure TPlainLogManager.AddWriter(const aWriter: TCustomLogWriter);
begin
  Writers.Add(aWriter);
end;

function TPlainLogManager.RemoveWriter(const aWriter: TCustomLogWriter): boolean;
var
  resultIndex: integer;
begin
  resultIndex := Writers.Remove(aWriter);
  result := resultIndex >= 0;
end;

procedure TPlainLogManager.WriteMessage(const aMessage: TCustomLogMessage);
begin
  aMessage.Reference;
  WriteMessageThreadSafe(aMessage);
end;

function TPlainLogManager.WriterListToText: string;
var
  i: integer;
begin
  result := 'Writers: ';
  result := result + '(' + IntToStr(Writers.Count) + ')';
  for i := 0 to Writers.Count - 1 do
    result := result + sLineBreak + Writers[i].ClassName;
end;

procedure TPlainLogManager.WriteWriterList;
begin
  Log.Write(WriterListToText);
end;

destructor TPlainLogManager.Destroy;
begin
  FreeAndNil(fWriteMessageLock);
  FreeAndNil(fWriters);
  FreeAndNil(fLog);
  inherited Destroy;
end;

end.
