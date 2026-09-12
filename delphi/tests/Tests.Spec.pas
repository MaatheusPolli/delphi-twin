unit Tests.Spec;

{
  Executa TODOS os casos de spec/cases/*.json que ja tenham "esperado"
  preenchido, passando cada "entrada" pelo TMotorTributario e comparando
  campo a campo com tolerancia zero (RF08/RF09). Esta e a suite que prova,
  do lado Delphi, que a spec compartilhada e respeitada.
}

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestSpec = class
  public
    [Test]
    procedure TodosOsCasosComEsperado_DevemBaterComOMotor;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  Tributos.Types,
  Tributos.Motor,
  Tributos.SpecLoader;

function LocalizarPastaCases: string;
var
  Atual: string;
  Candidata: string;
  Nivel: Integer;
begin
  Atual := TDirectory.GetCurrentDirectory;
  for Nivel := 0 to 6 do
  begin
    Candidata := TPath.Combine(TPath.Combine(Atual, 'spec'), 'cases');
    if TDirectory.Exists(Candidata) then
      Exit(Candidata);
    Atual := TDirectory.GetParent(Atual);
    if Atual = '' then
      Break;
  end;
  Result := '';
end;

function DiferencaDeCurrency(const ARotulo: string; const AEsperado, AObtido: Currency): string;
begin
  if AEsperado <> AObtido then
    Result := Format('%s: esperado=%s obtido=%s; ', [ARotulo, CurrToStr(AEsperado), CurrToStr(AObtido)])
  else
    Result := '';
end;

function CompararTributoBase(const APrefixo: string; const AEsperado, AObtido: TTributoBase): string;
begin
  Result :=
    DiferencaDeCurrency(APrefixo + '.bc', AEsperado.Bc, AObtido.Bc) +
    DiferencaDeCurrency(APrefixo + '.aliquota', AEsperado.Aliquota, AObtido.Aliquota) +
    DiferencaDeCurrency(APrefixo + '.valor', AEsperado.Valor, AObtido.Valor);
end;

function CompararResultado(const AEsperado, AObtido: TResultadoTributos): string;
begin
  Result :=
    CompararTributoBase('icms', AEsperado.Icms, AObtido.Icms) +
    CompararTributoBase('ipi', AEsperado.Ipi, AObtido.Ipi) +
    CompararTributoBase('pis', AEsperado.Pis, AObtido.Pis) +
    CompararTributoBase('cofins', AEsperado.Cofins, AObtido.Cofins) +
    DiferencaDeCurrency('totalTributos', AEsperado.TotalTributos, AObtido.TotalTributos);

  if AEsperado.TemIcmsSt <> AObtido.TemIcmsSt then
    Result := Result + Format('icmsSt: esperado presente=%s obtido presente=%s; ',
      [BoolToStr(AEsperado.TemIcmsSt, True), BoolToStr(AObtido.TemIcmsSt, True)])
  else if AEsperado.TemIcmsSt then
    Result := Result +
      DiferencaDeCurrency('icmsSt.bc', AEsperado.IcmsSt.Bc, AObtido.IcmsSt.Bc) +
      DiferencaDeCurrency('icmsSt.aliquota', AEsperado.IcmsSt.Aliquota, AObtido.IcmsSt.Aliquota) +
      DiferencaDeCurrency('icmsSt.valor', AEsperado.IcmsSt.Valor, AObtido.IcmsSt.Valor) +
      DiferencaDeCurrency('icmsSt.mvaAplicada', AEsperado.IcmsSt.MvaAplicada, AObtido.IcmsSt.MvaAplicada);

  if AEsperado.TemDifal <> AObtido.TemDifal then
    Result := Result + Format('difal: esperado presente=%s obtido presente=%s; ',
      [BoolToStr(AEsperado.TemDifal, True), BoolToStr(AObtido.TemDifal, True)])
  else if AEsperado.TemDifal then
    Result := Result +
      DiferencaDeCurrency('difal.valorOrigem', AEsperado.Difal.ValorOrigem, AObtido.Difal.ValorOrigem) +
      DiferencaDeCurrency('difal.valorDestino', AEsperado.Difal.ValorDestino, AObtido.Difal.ValorDestino) +
      DiferencaDeCurrency('difal.fcp', AEsperado.Difal.Fcp, AObtido.Difal.Fcp);
end;

procedure TTestSpec.TodosOsCasosComEsperado_DevemBaterComOMotor;
var
  PastaCases: string;
  Arquivo: string;
  Caso: TCasoDeTeste;
  Motor: IMotorTributario;
  Obtido: TResultadoTributos;
  Diferencas: string;
  Falhas: TStringList;
  TotalCasos, CasosVerificados: Integer;
begin
  PastaCases := LocalizarPastaCases;
  Assert.IsTrue(PastaCases <> '', 'Pasta spec/cases nao encontrada a partir de: ' + TDirectory.GetCurrentDirectory);

  Motor := TMotorTributario.CreatePadrao;
  Falhas := TStringList.Create;
  try
    TotalCasos := 0;
    CasosVerificados := 0;
    for Arquivo in ListarArquivosDeCasos(PastaCases) do
    begin
      Inc(TotalCasos);
      Caso := CarregarCasoDeArquivo(Arquivo);
      if not Caso.TemEsperado then
        Continue;

      Inc(CasosVerificados);
      Obtido := Motor.Calcular(Caso.Entrada);
      Diferencas := CompararResultado(Caso.Esperado, Obtido);
      if Diferencas <> '' then
        Falhas.Add(Format('[%s] %s', [Caso.Id, Diferencas]));
    end;

    Assert.IsTrue(CasosVerificados > 0, 'Nenhum caso com "esperado" foi encontrado em ' + PastaCases);
    Assert.IsTrue(Falhas.Count = 0, Format('%d de %d casos verificados falharam:'#10'%s',
      [Falhas.Count, CasosVerificados, Falhas.Text]));
  finally
    Falhas.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSpec);

end.
