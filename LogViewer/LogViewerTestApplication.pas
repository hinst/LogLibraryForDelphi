unit LogViewerTestApplication;

interface

uses
  SysUtils,
  Forms,

  UVCL,

  PlainLogManager,
  ULogFileModels,
  ConsoleLogWriter,
  DefaultLogEntity,
  PlainLogTextFormat,
  EmptyLogEntity,
  LogMemoryStorage,

  GlobalLogManagerUnit,
  LogViewerWindow;

type
  TLVTApplication = class
  public const
    LogSubFolder = 'Log';
    LogFileCount = 10;
  protected
    FLog: TEmptyLog;
    FLogMemory: TLogMemoryStorage;
    FMainWindow: TLogViewerWindow;
    procedure StartupLog;
    procedure StartupConsoleLog;
    procedure StartupFileLog;
    procedure StartupLogMemoryStorage;
    procedure StartupVCLApplication;
    function GetLogDirectory: string;
    procedure ShutdownLog;
  public
    property Log: TEmptyLog read FLog;
    procedure Run;
  end;


implementation

procedure TLVTApplication.StartupLog;
begin
  GlobalLogManager := TPlainLogManager.Create;
  StartupConsoleLog;
  FLog := TLog.Create(GlobalLogManager, 'Application');
  StartupLogMemoryStorage;
  StartupFileLog;
end;

procedure TLVTApplication.StartupConsoleLog;
var
  w: TConsoleLogWriter;
begin
  w := TConsoleLogWriter.Create;
  w.Format := TPlainLogTextFormat.CreateShort;
  GlobalLogManager.AddWriter(w);
end;

procedure TLVTApplication.StartupFileLog;
begin
  TLogFileModels.ApplyLocal10Model(GlobalLogManager);
end;

procedure TLVTApplication.StartupLogMemoryStorage;
var
  w: TLogMemoryStorage;
begin
  if Assigned(Log) then
    Log.Write('Now starting log memory storage...');
  w := TLogMemoryStorage.Create;
  GlobalLogManager.AddWriter(w);
  FLogMemory := w;
end;

procedure TLVTApplication.StartupVCLApplication;
begin
  Application.CreateForm(TLogViewerWindow, FMainWindow);
  PlaceFormDesktopPart(FMainWindow, 0.7);
  FMainWindow.LogMemory := FLogMemory;
  FMainWindow.Startup;
  Application.Run;
end;

function TLVTApplication.GetLogDirectory: string;
begin
  result := ExtractFilePath(Application.ExeName) + LogSubFolder;
end;

procedure TLVTApplication.ShutdownLog;
begin
  Log.Write('END', 'Shutdown log.');
  FreeAndNil(FLog);
  FreeAndNil(GlobalLogManager);
end;

procedure TLVTApplication.Run;
begin
  StartupLog;
  StartupVCLApplication;
  ShutdownLog;
end;

end.
