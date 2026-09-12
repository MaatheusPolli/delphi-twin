unit Tributos.Icms;

{
  Calculo do ICMS proprio (destaque na nota).

  Base legal geral: art. 13 da LC 87/1996 (Lei Kandir).
    BC = ValorProduto - Desconto + Frete + Seguro + Outras (+ IPI, se o
         destinatario nao for contribuinte e o IPI compuser a base, art. 155
         par. 2 XI CF/88 a contrario senso).
    Se houver reducao de base de calculo (CST 20/70), aplica-se o percentual
    de reducao sobre a base antes de calcular o imposto.
    Aliquota: interna se a operacao for dentro do mesmo estado; interestadual
    caso contrario (Resolucao do Senado 22/1989) — vale tanto para venda a
    contribuinte quanto a nao contribuinte (EC 87/2015), pois neste ultimo
    caso o DIFAL (Tributos.Difal) e que absorve a diferenca para o estado
    de destino.
}

interface

uses
  Tributos.Types;

type
  ICalculadoraIcms = interface
    ['{2B7B2C40-8B2B-4B4D-9C7E-8B1D9F2A0A01}']
    function Calcular(const AOperacao: TOperacaoFiscal; const AValorIpiParaBase: Currency): TTributoBase;
  end;

  TCalculadoraIcms = class(TInterfacedObject, ICalculadoraIcms)
  public
    function Calcular(const AOperacao: TOperacaoFiscal; const AValorIpiParaBase: Currency): TTributoBase;
  end;

implementation

uses
  Tributos.Decimal;

function TCalculadoraIcms.Calcular(const AOperacao: TOperacaoFiscal; const AValorIpiParaBase: Currency): TTributoBase;
var
  Item: TItemOperacao;
  BaseBruta, BaseComReducao, Aliquota: Currency;
begin
  Item := AOperacao.Item;

  BaseBruta := Item.ValorProduto - Item.Desconto + Item.Frete + Item.Seguro + Item.Outras;
  if Item.Ipi.IncluirNaBaseIcms then
    BaseBruta := BaseBruta + AValorIpiParaBase;

  if Item.Icms.TemReducaoBC then
    BaseComReducao := AplicarPercentual(BaseBruta, 100 - Item.Icms.ReducaoBC)
  else
    BaseComReducao := BaseBruta;

  if AOperacao.OperacaoInterna then
    Aliquota := Item.Icms.AliquotaInterna
  else
    Aliquota := Item.Icms.AliquotaInterestadual;

  Result.Bc := RoundHalfEven2(BaseComReducao);
  Result.Aliquota := Aliquota;
  Result.Valor := RoundHalfEven2(AplicarPercentual(Result.Bc, Aliquota));
end;

end.
