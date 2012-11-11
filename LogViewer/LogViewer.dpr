program LogViewer;

{$APPTYPE CONSOLE}

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  SysUtils,
  CustomLogMessageList,
  LogViewerTestApplication in 'LogViewerTestApplication.pas',
  GlobalLogManagerUnit in 'GlobalLogManagerUnit.pas',
  LogViewerWindow in 'LogViewerWindow.pas';

procedure GlobalRun;
var
  a: TLVTApplication;
begin
  a := TLVTApplication.Create;
  a.Run;
  a.Free;
end;

procedure WriteLN(const s: string);
begin
  System.WriteLN(s);
end;

begin
  WriteLN('GLOBAL EXECUTION START');
  GlobalRun;
  WriteLN('GLOBAL EXECUTION END');
end.
