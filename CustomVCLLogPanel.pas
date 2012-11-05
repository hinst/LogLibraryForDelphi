unit CustomVCLLogPanel;

interface

uses
  SysUtils,
  Classes,
  ExtCtrls,
  SyncObjs,
  Controls,

  UAdditionalTypes,
  UAdditionalExceptions,

  CustomLogMessage,
  EmptyLogEntity,
  CustomLogWriter;

type
  TCustomLogViewPanel = class(TPanel)
  public
    constructor Create(aOwner: TComponent); override;
  protected
    fLog: TEmptyLog;
    fLock: TCriticalSection;
    procedure SetLog(const aLog: TEmptyLog);
    procedure CreateThis;
    procedure DestroyThis;
  public
    property Log: TEmptyLog read fLog write SetLog;
    property Lock: TCriticalSection read fLock;
    procedure AddMessage(const aMessage: TCustomLogMessage); virtual; abstract;
    destructor Destroy; override;
  end;

implementation

constructor TCustomLogViewPanel.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  CreateThis;
end;

procedure TCustomLogViewPanel.SetLog(const aLog: TEmptyLog);
begin
  ReplaceLog(fLog, aLog);
end;

procedure TCustomLogViewPanel.CreateThis;
begin
  Log := TEmptyLog.Create;
  fLock := TCriticalSection.Create;
end;

procedure TCustomLogViewPanel.DestroyThis;
begin
  FreeAndNil(fLock);
  FreeAndNil(fLog);
end;

destructor TCustomLogViewPanel.Destroy;
begin
  DestroyThis;
  inherited Destroy;
end;

end.
