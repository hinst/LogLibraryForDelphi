unit CustomVCLLogPanelAttachable;

interface

uses
  SysUtils,
  Classes,

  UAdditionalTypes,
  UAdditionalExceptions,

  CustomLogManager,
  CustomVCLLogPanel,
  VCLLogPanelWriter;

type
  TCustomLogViewPanelParentClass = TCustomLogViewPanel;

  TCustomLogViewPanel = class(TCustomLogViewPanelParentClass)
  public
    constructor Create(aOwner: TComponent); override;
  public type
    EAlreadyAttached = class(Exception);
    ENotAttached = class(Exception);
  protected
    fWriter: TLogPanelWriter;
    fLogManager: TCustomLogManager;
    procedure CreateThis;
    procedure DestroyThis;
  public
    property Writer: TLogPanelWriter read fWriter;
    property LogManager: TCustomLogManager read fLogManager;
    procedure AttachTo(const aLogManager: TCustomLogManager);
    function DetachFrom(const aLogManager: TCustomLogManager): boolean;
    function Detach: boolean;
    destructor Destroy; override;
  end;


implementation

constructor TCustomLogViewPanel.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  CreateThis;
end;

procedure TCustomLogViewPanel.CreateThis;
begin
  fWriter := TLogPanelWriter.Create(self);
end;

procedure TCustomLogViewPanel.DestroyThis;
var
  detached: boolean;
begin
  if Writer <> nil then
  begin
    detached := Detach;
    if not detached then
      FreeAndNil(fWriter);
  end;
end;

procedure TCustomLogViewPanel.AttachTo(const aLogManager: TCustomLogManager);
begin
  if LogManager <> nil then
    raise EAlreadyAttached.Create('');
  aLogManager.AddWriter(Writer);
  fLogManager := aLogManager;
end;

function TCustomLogViewPanel.DetachFrom(const aLogManager: TCustomLogManager): boolean;
begin
  AssertAssigned(aLogManager, 'aLogManager', TVariableType.Argument);
  result := aLogManager.RemoveWriter(Writer);
  if result then
    fWriter := nil;
end;

function TCustomLogViewPanel.Detach: boolean;
begin
  result := LogManager <> nil;
  if result then
    result := DetachFrom(LogManager);
end;

destructor TCustomLogViewPanel.Destroy;
begin
  DestroyThis;
  inherited Destroy;
end;

end.
