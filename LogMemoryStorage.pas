unit LogMemoryStorage;

interface

uses
  SysUtils,

  ULockThis,

  CustomLogMessage,
  CustomLogWriter,
  CustomLogMessageList;

type
  TLogMemoryStorage = class(TCustomLogWriter)
  public
    constructor Create;
  private
    FList: TCustomLogMessageList;
  public
      // lock the list while using|iterating it.
    property List: TCustomLogMessageList read FList;
    procedure Write(const aMessage: TCustomLogMessage); override;
    destructor Destroy; override;
  end;


implementation

constructor TLogMemoryStorage.Create;
begin
  FList := TCustomLogMessageList.Create; 
end;

destructor TLogMemoryStorage.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TLogMemoryStorage.Write(const aMessage: TCustomLogMessage);
begin
  LockPointer(FList);
  FList.Add(aMessage);
  UnlockPointer(FList);
end;

end.
