unit Tributos.Motor;

{
  TMotorTributario orquestra as calculadoras individuais (ICMS, ICMS-ST,
  IPI, PIS/COFINS, DIFAL) para produzir o TResultadoTributos completo de
  uma TOperacaoFiscal. As calculadoras sao injetadas via interface
  (constructor injection) para permitir substituicao em testes.

  Ordem de calculo (importa por causa das dependencias entre bases):
    1. IPI       - nao depende de nenhum outro tributo.
    2. ICMS      - pode precisar do valor do IPI (se compuser a base).
    3. ICMS-ST   - precisa do valor do IPI e do ICMS proprio.
    4. PIS/COFINS- independente.
    5. DIFAL     - so quando aplicavel (interestadual + nao contribuinte);
                   usa a mesma base do ICMS proprio.
}

interface

uses
  Tributos.Types,
  Tributos.Icms,
  Tributos.IcmsST,
  Tributos.Ipi,
  Tributos.PisCofins,
  Tributos.Difal;

type
  IMotorTributario = interface
    ['{7ACF6195-D07A-4092-BE8C-D06C4E7F0A06}']
    function Calcular(const AOperacao: TOperacaoFiscal): TResultadoTributos;
  end;

  TMotorTributario = class(TInterfacedObject, IMotorTributario)
  private
    FCalculadoraIcms: ICalculadoraIcms;
    FCalculadoraIcmsST: ICalculadoraIcmsST;
    FCalculadoraIpi: ICalculadoraIpi;
    FCalculadoraPisCofins: ICalculadoraPisCofins;
    FCalculadoraDifal: ICalculadoraDifal;
  public
    constructor Create(
      const ACalculadoraIcms: ICalculadoraIcms;
      const ACalculadoraIcmsST: ICalculadoraIcmsST;
      const ACalculadoraIpi: ICalculadoraIpi;
      const ACalculadoraPisCofins: ICalculadoraPisCofins;
      const ACalculadoraDifal: ICalculadoraDifal);
    class function CreatePadrao: IMotorTributario;
    function Calcular(const AOperacao: TOperacaoFiscal): TResultadoTributos;
  end;

implementation

constructor TMotorTributario.Create(
  const ACalculadoraIcms: ICalculadoraIcms;
  const ACalculadoraIcmsST: ICalculadoraIcmsST;
  const ACalculadoraIpi: ICalculadoraIpi;
  const ACalculadoraPisCofins: ICalculadoraPisCofins;
  const ACalculadoraDifal: ICalculadoraDifal);
begin
  inherited Create;
  FCalculadoraIcms := ACalculadoraIcms;
  FCalculadoraIcmsST := ACalculadoraIcmsST;
  FCalculadoraIpi := ACalculadoraIpi;
  FCalculadoraPisCofins := ACalculadoraPisCofins;
  FCalculadoraDifal := ACalculadoraDifal;
end;

class function TMotorTributario.CreatePadrao: IMotorTributario;
begin
  Result := TMotorTributario.Create(
    TCalculadoraIcms.Create,
    TCalculadoraIcmsST.Create,
    TCalculadoraIpi.Create,
    TCalculadoraPisCofins.Create,
    TCalculadoraDifal.Create);
end;

function TMotorTributario.Calcular(const AOperacao: TOperacaoFiscal): TResultadoTributos;
var
  BaseDifal: Currency;
begin
  Result := Default(TResultadoTributos);

  Result.Ipi := FCalculadoraIpi.Calcular(AOperacao);
  Result.Icms := FCalculadoraIcms.Calcular(AOperacao, Result.Ipi.Valor);

  Result.TemIcmsSt := AOperacao.Item.Icms.TemMva;
  if Result.TemIcmsSt then
    Result.IcmsSt := FCalculadoraIcmsST.Calcular(AOperacao, Result.Ipi.Valor, Result.Icms.Valor);

  Result.Pis := FCalculadoraPisCofins.CalcularPis(AOperacao);
  Result.Cofins := FCalculadoraPisCofins.CalcularCofins(AOperacao);

  Result.TemDifal := FCalculadoraDifal.Aplicavel(AOperacao);
  if Result.TemDifal then
  begin
    BaseDifal := Result.Icms.Bc;
    Result.Difal := FCalculadoraDifal.Calcular(AOperacao, BaseDifal);
  end;

  Result.TotalTributos := Result.Icms.Valor + Result.Ipi.Valor + Result.Pis.Valor + Result.Cofins.Valor;
  if Result.TemIcmsSt then
    Result.TotalTributos := Result.TotalTributos + Result.IcmsSt.Valor;
  if Result.TemDifal then
    Result.TotalTributos := Result.TotalTributos + Result.Difal.ValorOrigem + Result.Difal.ValorDestino + Result.Difal.Fcp;
end;

end.
