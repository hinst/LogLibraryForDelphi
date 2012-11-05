program LLTestApplication;

{$APPTYPE CONSOLE}

uses
  CustomLogEntity,
  CustomLogManager,
  CustomLogWriter,
  ConsoleLogWriter,
  PlainLogManager,
  DefaultLogEntity;

var
  LogMan: TCustomLogManager;
  ConsoleLW: TCustomLogWriter;
  log: TCustomLogEntity;


begin
  LogMan := TPlainLogManager.Create;
  ConsoleLW := TConsoleLogWriter.Create;
  LogMan.AddWriter(ConsoleLW);
  log := TLog.Create(LogMan, 'GLOBAL');
  log.Write('START', 'The the log is functioning now...');
  log.Write('Some debug message');
  log.Write('END', 'Releasing log...');
  log.Free;
  LogMan.Free;
end.
