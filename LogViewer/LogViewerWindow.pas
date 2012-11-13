unit LogViewerWindow;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Forms,
  Controls,

  UAdditionalTypes,
  UAdditionalExceptions,

  LogMemoryStorage,
  VCLLogViewPanel,
  GlobalLogManagerUnit,
  EmptyLogEntity,
  DefaultLogEntity,
  ULogTest;

type
  TLogViewerWindow = class(TForm)
  public
    constructor Create(aOwner: TComponent); override;
    procedure Startup;
  protected
    FLog: TEmptyLog;
    FLogMemory: TLogMemoryStorage;
    FLogPanel: TLogViewPanel;
    procedure CreateThis;
    procedure OnKeyDownHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure GenerateMessages(const aCount: integer);
    function DoMouseWheel(aShift: TShiftState; aWheelDelta: Integer; aMousePos: TPoint): boolean;
      override;
  public
    property LogMemory: TLogMemoryStorage read FLogMemory write FLogMemory;
    destructor Destroy; override;
  end;


implementation

constructor TLogViewerWindow.Create(aOwner: TComponent);
begin
  inherited CreateNew(aOwner);
  FLog := TLog.Create(GlobalLogManager, 'LogViewerWindow');
end;

procedure TLogViewerWindow.Startup;
begin
  CreateThis;
end;

procedure TLogViewerWindow.CreateThis;
begin
  FLogPanel := TLogViewPanel.Create(self);
  FLogPanel.Parent := self;
  FLogPanel.Align := alClient;
  FLogPanel.Storage := FLogMemory;
  FLogPanel.Startup;
  
  OnKeyDown := OnKeyDownHandler;
  KeyPreview := true;
end;

procedure TLogViewerWindow.OnKeyDownHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F1 then
    GenerateMessages(1549);
  if Key = VK_F2 then
    GenerateMessages(49);
end;

procedure TLogViewerWindow.GenerateMessages(const aCount: integer);
begin
  GenerateLogMessages(GlobalLogManager, 3, 5, aCount, 30);
end;

destructor TLogViewerWindow.Destroy;
begin
  FreeAndNil(FLog);
  inherited Destroy;
end;

function TLogViewerWindow.DoMouseWheel(aShift: TShiftState; aWheelDelta: Integer;
  aMousePos: TPoint): boolean;
begin
  result := true;
  //inherited DoMouseWheel(aShift, aWheelDelta, aMousePos);
  AssertAssigned(FLogPanel, 'FLogPanel', TVariableType.Field);  
  FLogPanel.ReceiveMouseWheel(aShift, aWheelDelta, aMousePos);
end;

end.
