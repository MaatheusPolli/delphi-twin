program DelphiTwin;

{$APPTYPE CONSOLE}

{
  Executor da spec: le cada spec/cases/*.json, calcula o TResultadoTributos
  via TMotorTributario e grava o resultado em results/delphi/<id>.json.
  E o lado "legado" do par comparado por tools/compare.ts (RF08/RF09).
}

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  Tributos.Types in 'src\Tributos.Types.pas',
  Tributos.Decimal in 'src\Tributos.Decimal.pas',
  Tributos.Icms in 'src\Tributos.Icms.pas',
  Tributos.IcmsST in 'src\Tributos.IcmsST.pas',
  Tributos.Ipi in 'src\Tributos.Ipi.pas',
  Tributos.PisCofins in 'src\Tributos.PisCofins.pas',
  Tributos.Difal in 'src\Tributos.Difal.pas',
  Tributos.Motor in 'src\Tributos.Motor.pas',
  Tributos.SpecLoader in 'src\Tributos.SpecLoader.pas';

function LocalizarRaizDoRepo: string;
var
  Atual, Candidata: string;
  Nivel: Integer;
begin
  Atual := TDirectory.GetCurrentDirectory;
  for Nivel := 0 to 6 do
  begin
    Candidata := TPath.Combine(Atual, 'spec');
    if TDirectory.Exists(Candidata) then
      Exit(Atual);
    Atual := TDirectory.GetParent(Atual);
    if Atual = '' then
      Break;
  end;
  Result := '';
end;

var
  RaizRepo, PastaCases, PastaResultados, Arquivo, Json: string;
  Caso: TCasoDeTeste;
  Motor: IMotorTributario;
  Resultado: TResultadoTributos;
  ResultadoJson: TJSONObject;
  Total: Integer;
begin
  try
    RaizRepo := LocalizarRaizDoRepo;
    if RaizRepo = '' then
    begin
      Writeln('Nao foi possivel localizar a pasta spec/ a partir de ', TDirectory.GetCurrentDirectory);
      ExitCode := 1;
      Exit;
    end;

    PastaCases := TPath.Combine(TPath.Combine(RaizRepo, 'spec'), 'cases');
    PastaResultados := TPath.Combine(TPath.Combine(RaizRepo, 'results'), 'delphi');
    TDirectory.CreateDirectory(PastaResultados);

    Motor := TMotorTributario.CreatePadrao;
    Total := 0;
    for Arquivo in ListarArquivosDeCasos(PastaCases) do
    begin
      Caso := CarregarCasoDeArquivo(Arquivo);
      Resultado := Motor.Calcular(Caso.Entrada);

      ResultadoJson := ResultadoParaJson(Resultado);
      try
        Json := ResultadoJson.Format(2);
        TFile.WriteAllText(TPath.Combine(PastaResultados, Caso.Id + '.json'), Json, TEncoding.UTF8);
      finally
        ResultadoJson.Free;
      end;

      Inc(Total);
      Writeln('OK  ', Caso.Id);
    end;

    Writeln(Format('%d caso(s) processado(s). Resultados em %s', [Total, PastaResultados]));
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
