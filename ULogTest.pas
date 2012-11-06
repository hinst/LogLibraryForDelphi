unit ULogTest;

interface

uses
  SysUtils,
  UAdditionalTypes,
  UAdditionalExceptions,

  UMath,
  UTextUtilities,

  CustomLogManager,
  DefaultLogEntity;

procedure GenerateLogMessages(const aLogManager: TCustomLogManager;
  const aLogCount, aTagCount, aCount, aWordsPerMessage: integer);


implementation

procedure GenerateLogMessages(const aLogManager: TCustomLogManager;
  const aLogCount, aTagCount, aCount, aWordsPerMessage: integer);
var
  i: integer;
  logs: array of TLog;
  tags: array of string;
  Text: string;
  currentLog: TLog;
  currentTag: string;
begin
  SetLength(logs, aLogCount);
  for i := 0 to aLogCount - 1 do
    logs[i] := TLog.Create(aLogManager, 'Log' + IntToStr(i));
  for i := 0 to aCount - 1 do
  begin
    currentLog := logs[random(aLogCount)];
    currentTag := tags[random(aTagCount)];
    text := GenerateRandomText(aWordsPerMessage);
    currentLog.Write(currentTag, '');
  end;
end;

end.
