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
  protected
    FList: TCustomLogMessageList;
    function GetLockedCount: integer;
  public
      // lock the list while using|iterating it.
    property List: TCustomLogMessageList read FList;
      // TCustomLogWriter essential method
    procedure Lock;
    procedure Write(const aMessage: TCustomLogMessage); override;
    procedure Unlock;
      // Notes:
      // Count: locked count
      // List.Count: unlocked count
    property Count: integer read GetLockedCount;
    destructor Destroy; override;
  end;


implementation

constructor TLogMemoryStorage.Create;
begin
  FList := TCustomLogMessageList.Create; 
end;

function TLogMemoryStorage.GetLockedCount: integer;
begin
  Lock;
  result := FList.Count;
  Unlock;
end;

procedure TLogMemoryStorage.Lock;
begin
  LockPointer(FList);
end;

procedure TLogMemoryStorage.Write(const aMessage: TCustomLogMessage);
begin
  Lock;
  FList.Add(aMessage);
  Unlock;
end;

procedure TLogMemoryStorage.Unlock;
begin
  UnlockPointer(FList);
end;

destructor TLogMemoryStorage.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

end.
