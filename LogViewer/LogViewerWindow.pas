unit LogViewerWindow;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Forms,
  Controls,

  LogMemoryStorage,
  VCLLogViewPanel,
  GlobalLogManagerUnit,
  DefaultLogEntity,
  ULogTest;

type
  TLogViewerWindow = class(TForm)
  public
    constructor Create(aOwner: TComponent); override;
    procedure Startup;
  protected
    FLogMemoryStorage: TLogMemoryStorage;
    FLogViewPanel: TLogViewPanel;
    procedure CreateThis;
    procedure OnKeyDownHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure GenerateMessages(const aCount: integer);
  public
    property LogMemoryStorage: TLogMemoryStorage read FLogMemoryStorage write FLogMemoryStorage;
  end;


implementation

constructor TLogViewerWindow.Create(aOwner: TComponent);
begin
  inherited CreateNew(aOwner);
end;

procedure TLogViewerWindow.Startup;
begin
  CreateThis;
  OnKeyDown := OnKeyDownHandler;

end;

procedure TLogViewerWindow.CreateThis;
begin
  FLogViewPanel := TLogViewPanel.Create(self);
  FLogViewPanel.Parent := self;
  FLogViewPanel.Align := alClient;
  FLogViewPanel.Storage := FLogMemoryStorage;
end;

procedure TLogViewerWindow.OnKeyDownHandler(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F1 then
    GenerateMessages(1000);
end;

procedure TLogViewerWindow.GenerateMessages(const aCount: integer);
begin
  GenerateLogMessages(GlobalLogManager, 3, 5, aCount, 30);  
end;

end.
