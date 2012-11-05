unit ULogFileModels;

interface

uses
  SysUtils,

  UEnvironment,
  UFileNameCycler,

  CustomLogManager,
  DefaultLogEntity,
  FileLogWriter;

type
  TLogFileModels = class
  public
    class procedure ApplyLocal10Model(const aLogManager: TCustomLogManager);
  end;


implementation

class procedure TLogFileModels.ApplyLocal10Model(const aLogManager: TCustomLogManager);
const
  LogSubDirectory = 'Log';
  LogFileCount = 10;
var
  w: TFileLogWriter;
  logDirectory: string;
  log: TLog;
begin
  w := TFileLogWriter.Create;
  logDirectory := GetExecutableFolderPath + LogSubDirectory;
  if not DirectoryExists(logDirectory) then
    ForceDirectories(logDirectory);
  w.FilePath := CycleFileName(IncludeTrailingPathDelimiter(logDirectory) + 'logFile',
    LogFileCount, '.text');
  log := TLog.Create(aLogManager, self.ClassName);
  log.Write('Using log file: "' + w.FilePath + '"');
  aLogManager.AddWriter(w);
  FreeAndNil(log);
end;

end.
