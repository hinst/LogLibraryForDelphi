unit PlainLogManager;

interface

uses
  SysUtils,
  Contnrs,
  SyncObjs,

  UEnhancedObject,
  ULockThis,

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
    FLog: TCustomLog;
    FMessageNumber: integer;
    FWriters: TCustomLogWriterList;
    FWriteMessageLock: TCriticalSection;
    procedure WriteMessageInternal(const aMessage: TCustomLogMessage);
    procedure WriteMessageThreadSafe(const aMessage: TCustomLogMessage);
  public
    property Log: TCustomLog read FLog;
    property MessageNumber: integer read FMessageNumber;
    property Writers: TCustomLogWriterList read FWriters;
    property WriteMessageLock: TCriticalSection read FWriteMessageLock;
      // TLogManager owns writers.
      // It meas that it releases them on destruction
    function CreateMessage: TCustomLogMessage; override;
      // Releases aMessage after execution
    procedure WriteMessage(const aMessage: TCustomLogMessage); override;
    procedure AddWriter(const aWriter: TCustomLogWriter); override;
    function RemoveWriter(const aWriter: TCustomLogWriter): boolean; override;
    function FindWriter(const aClass: TCustomLogWriterClass): TCustomLogWriter;
    function WriterListToText: string;
    procedure WriteWriterList;
    destructor Destroy; override;
  end;
  

implementation

constructor TPlainLogManager.Create;
begin
  inherited Create;
  FLog := TLog.Create(self, 'LogManager');
  FMessageNumber := 0;
  FWriters := TCustomLogWriterList.Create(true);
  FWriteMessageLock := TCriticalSection.Create;
end;

procedure TPlainLogManager.WriteMessageInternal(const aMessage: TCustomLogMessage);
var
  i: integer;
begin
  LockPointer(@FMessageNumber); // Lock FMessageNumber
    inc(FMessageNumber);
    aMessage.Number := FMessageNumber;
  UnlockPointer(@FMessageNumber); // Unlock FMessageNumber

  LockPointer(Writers); // Lock Writers
    for i := 0 to Writers.Count - 1 do
      Writers[i].Write(aMessage);
  UnlockPointer(Writers); // Unlock Writers
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
  LockPointer(Writers);
  Writers.Add(aWriter);
  UnlockPointer(Writers);
end;

function TPlainLogManager.RemoveWriter(const aWriter: TCustomLogWriter): boolean;
var
  resultIndex: integer;
begin
  LockPointer(Writers);
  resultIndex := Writers.Remove(aWriter);
  UnlockPointer(Writers);
  result := resultIndex >= 0;
end;

function TPlainLogManager.FindWriter(const aClass: TCustomLogWriterClass): TCustomLogWriter;
var
  i: integer;
begin
  result := nil;
  LockPointer(Writers);
  for i := 0 to Writers.Count - 1 do
    if Writers[i] is aClass then
    begin
      result := Writers[i];
      break;
    end;
  UnlockPointer(Writers);
end;

procedure TPlainLogManager.WriteMessage(const aMessage: TCustomLogMessage);
begin
  aMessage.Reference;
  WriteMessageThreadSafe(aMessage);
  aMessage.Dereference;
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
  FreeAndNil(FWriteMessageLock);
  FreeAndNil(FWriters);
  FreeAndNil(FLog);
  inherited Destroy;
end;

end.
