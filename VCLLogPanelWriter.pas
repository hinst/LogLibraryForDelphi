unit VCLLogPanelWriter;

interface

uses
  SysUtils,

  UExceptionTracer, 

  CustomLogMessage,
  CustomLogWriter,
  CustomLogEntity,
  EmptyLogEntity,
  CustomVCLLogPanel;

type
  TLogPanelWriter = class(TCustomLogWriter)
  public
    constructor Create(const aDisplayGrid: TCustomLogViewPanel); reintroduce;
  protected
    fLog: TEmptyLog;
    fLogDisplayGrid: TCustomLogViewPanel;
    procedure SetLog(const aLog: TEmptyLog);
  public
    property Log: TEmptyLog read fLog write SetLog;
    property LogDisplayGrid: TCustomLogViewPanel read fLogDisplayGrid;
    procedure Write(const aMessage: TCustomLogMessage); override;
    destructor Destroy; override;
  end;

implementation

constructor TLogPanelWriter.Create(const aDisplayGrid: TCustomLogViewPanel);
begin
  inherited Create;
  Log := TEmptyLog.Create;
  fLogDisplayGrid := aDisplayGrid;
end;

procedure TLogPanelWriter.SetLog(const aLog: TEmptyLog);
begin
  ReplaceLog(fLog, aLog);
end;

procedure TLogPanelWriter.Write(const aMessage: TCustomLogMessage);
begin
  LogDisplayGrid.AddMessage(aMessage);
end;

destructor TLogPanelWriter.Destroy;
begin
  FreeAndNil(fLog);
  inherited Destroy;
end;

end.













