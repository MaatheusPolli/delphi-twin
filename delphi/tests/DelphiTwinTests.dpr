program DelphiTwinTests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  Tributos.Decimal in '..\src\Tributos.Decimal.pas',
  Tributos.Types in '..\src\Tributos.Types.pas',
  Tributos.Icms in '..\src\Tributos.Icms.pas',
  Tributos.IcmsST in '..\src\Tributos.IcmsST.pas',
  Tributos.Ipi in '..\src\Tributos.Ipi.pas',
  Tributos.PisCofins in '..\src\Tributos.PisCofins.pas',
  Tributos.Difal in '..\src\Tributos.Difal.pas',
  Tributos.Motor in '..\src\Tributos.Motor.pas',
  Tributos.SpecLoader in '..\src\Tributos.SpecLoader.pas',
  Tests.Helpers in 'Tests.Helpers.pas',
  Tests.Decimal in 'Tests.Decimal.pas',
  Tests.Icms in 'Tests.Icms.pas',
  Tests.IcmsST in 'Tests.IcmsST.pas',
  Tests.Ipi in 'Tests.Ipi.pas',
  Tests.PisCofins in 'Tests.PisCofins.pas',
  Tests.Difal in 'Tests.Difal.pas',
  Tests.Spec in 'Tests.Spec.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
  NunitLogger: ITestLogger;

begin
  try
    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;

    Logger := TDUnitXConsoleLogger.Create(True);
    Runner.AddLogger(Logger);

    NunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    Runner.AddLogger(NunitLogger);

    Runner.FailsOnNoAsserts := False;

    Results := Runner.Execute;

    if not Results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    if System.IsConsole then
    begin
      System.Write('Pressione <Enter> para sair...');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
