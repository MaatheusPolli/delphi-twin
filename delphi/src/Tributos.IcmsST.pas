unit Tributos.IcmsST;

{
  Calculo do ICMS-ST (Substituicao Tributaria).

  Base legal: Convenio ICMS 142/2018 (regras gerais de ST) e Convenio ICMS
  52/2017 (MVA ajustada em operacoes interestaduais).

    MVA aplicada:
      - Operacao interna: MVA original informada, sem ajuste.
      - Operacao interestadual: MVA ajustada =
          [(1 + MVA_original/100) x (1 - AliqInter/100) / (1 - AliqIntra/100) - 1] x 100
        onde AliqIntra e a aliquota interna do estado de destino e AliqInter
        e a aliquota interestadual da operacao.

    BC_ST = (ValorProduto - Desconto + Frete + Seguro + Outras + ValorIPI)
            com reducao de BC-ST (se houver) aplicada antes do MVA,
            multiplicada por (1 + MVA_aplicada/100).

    Valor_ST = (BC_ST x AliquotaInterna_destino) - ICMS proprio da operacao.
    Se o resultado for negativo (raro, mas possivel com BC-ST reduzida),
    o valor de ST fica zerado — nao ha ICMS-ST a recolher a menos.
}

interface

uses
  Tributos.Types;

type
  ICalculadoraIcmsST = interface
    ['{5EAE5F73-BE5E-4E70-9C6A-BE4A2C5D0A04}']
    function Calcular(const AOperacao: TOperacaoFiscal; const AValorIpi, AValorIcmsProprio: Currency): TResultadoIcmsSt;
  end;

  TCalculadoraIcmsST = class(TInterfacedObject, ICalculadoraIcmsST)
  private
    function CalcularMvaAplicada(const AOperacao: TOperacaoFiscal): Currency;
  public
    function Calcular(const AOperacao: TOperacaoFiscal; const AValorIpi, AValorIcmsProprio: Currency): TResultadoIcmsSt;
  end;

implementation

uses
  SysUtils,
  Tributos.Decimal;

function TCalculadoraIcmsST.CalcularMvaAplicada(const AOperacao: TOperacaoFiscal): Currency;
var
  MvaOriginal, AliqInter, AliqIntra, Fator: Currency;
begin
  MvaOriginal := AOperacao.Item.Icms.Mva;

  if AOperacao.OperacaoInterna then
    Exit(MvaOriginal);

  AliqInter := AOperacao.Item.Icms.AliquotaInterestadual;
  AliqIntra := AOperacao.Item.Icms.AliquotaInterna;

  { AliqIntra >= 100% zeraria (ou inverteria o sinal de) o denominador da
    formula de ajuste. Uma aliquota interna de 100% ou mais nao existe na
    legislacao brasileira - e melhor rejeitar com um erro claro do que
    deixar Currency lancar EZeroDivide (ou, do lado TypeScript, o
    decimal.js retornar Infinity silenciosamente e contaminar o resto do
    calculo sem erro nenhum). }
  if AliqIntra >= 100 then
    raise Exception.CreateFmt(
      'MVA ajustada (Convenio 52/2017): aliquota interna do destino invalida (%s%%) - deve ser menor que 100%%.',
      [CurrToStr(AliqIntra)]);

  Fator := (1 + MvaOriginal / 100) * (1 - AliqInter / 100) / (1 - AliqIntra / 100) - 1;
  Result := Fator * 100;
end;

function TCalculadoraIcmsST.Calcular(const AOperacao: TOperacaoFiscal; const AValorIpi, AValorIcmsProprio: Currency): TResultadoIcmsSt;
var
  Item: TItemOperacao;
  BaseAntesDoMva, BaseComReducaoST, BaseST, MvaAplicada, ValorST: Currency;
begin
  Item := AOperacao.Item;

  BaseAntesDoMva := Item.ValorProduto - Item.Desconto + Item.Frete + Item.Seguro + Item.Outras + AValorIpi;

  if Item.Icms.TemReducaoBCST then
    BaseComReducaoST := AplicarPercentual(BaseAntesDoMva, 100 - Item.Icms.ReducaoBCST)
  else
    BaseComReducaoST := BaseAntesDoMva;

  { A MVA ajustada e arredondada para 2 casas ANTES de compor a base, para
    que Delphi e TypeScript concordem bit a bit no valor intermediario -
    caso contrario a divisao (1-AliqInter)/(1-AliqIntra) poderia carregar
    mais casas decimais em cada lado e divergir no ultimo digito. }
  MvaAplicada := RoundHalfEven2(CalcularMvaAplicada(AOperacao));
  BaseST := AplicarPercentual(BaseComReducaoST, 100 + MvaAplicada);

  Result.Bc := RoundHalfEven2(BaseST);
  Result.Aliquota := Item.Icms.AliquotaInterna;
  Result.MvaAplicada := MvaAplicada;

  ValorST := RoundHalfEven2(AplicarPercentual(Result.Bc, Result.Aliquota)) - AValorIcmsProprio;
  if (ValorST < 0) or (AOperacao.Item.Icms.Cst = '60') then
    ValorST := 0;
  Result.Valor := ValorST;
end;

end.
