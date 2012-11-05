unit LogViewerWindow;

interface

uses
  Classes,
  Forms,
  Controls, 

  LogMemoryStorage,
  VCLLogViewPanel;

type
  TLogViewerWindow = class(TForm)
  public
    constructor Create(aOwner: TComponent); override;
    procedure Startup;
  protected
    FLogMemoryStorage: TLogMemoryStorage;
    FLogViewPanel: TLogViewPanel;
    procedure CreateThis;
  public
    property LogMemoryStorage: TLogMemoryStorage write FLogMemoryStorage;
  end;


implementation

constructor TLogViewerWindow.Create(aOwner: TComponent);
begin
  inherited CreateNew(aOwner);
end;

procedure TLogViewerWindow.Startup;
begin
  CreateThis;
end;

procedure TLogViewerWindow.CreateThis;
begin
  FLogViewPanel := TLogViewPanel.Create(self);
  FLogViewPanel.Parent := self;
  FLogViewPanel.Align := alClient;
  FLogViewPanel.Storage := FLogMemoryStorage;
end;

end.
