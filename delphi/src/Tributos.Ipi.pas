unit Tributos.Ipi;

{
  Calculo do IPI (Imposto sobre Produtos Industrializados).

  Base legal: RIPI/2010 (Decreto 7.212/2010), art. 190.
    BC = ValorProduto - Desconto + Frete + Seguro + Outras.
    Valor = BC x Aliquota.
  O IPI nao tem base propria reduzida nem substituicao tributaria neste
  escopo (v1); a decisao de compor ou nao a base do ICMS fica a cargo de
  Tributos.Icms, que consulta Item.Ipi.IncluirNaBaseIcms.
}

interface

uses
  Tributos.Types;

type
  ICalculadoraIpi = interface
    ['{3C8C3D51-9C3C-4C5E-AD8F-9C2E0A3B0A02}']
    function Calcular(const AOperacao: TOperacaoFiscal): TTributoBase;
  end;

  TCalculadoraIpi = class(TInterfacedObject, ICalculadoraIpi)
  public
    function Calcular(const AOperacao: TOperacaoFiscal): TTributoBase;
  end;

implementation

uses
  Tributos.Decimal;

function TCalculadoraIpi.Calcular(const AOperacao: TOperacaoFiscal): TTributoBase;
var
  Item: TItemOperacao;
  Base: Currency;
begin
  Item := AOperacao.Item;
  Base := Item.ValorProduto - Item.Desconto + Item.Frete + Item.Seguro + Item.Outras;

  Result.Bc := RoundHalfEven2(Base);
  if Item.Ipi.TemReducaoAliquota then
    Result.Aliquota := AplicarPercentual(Item.Ipi.Aliquota, 100 - Item.Ipi.ReducaoAliquota)
  else
    Result.Aliquota := Item.Ipi.Aliquota;
  Result.Valor := RoundHalfEven2(AplicarPercentual(Result.Bc, Result.Aliquota));
end;

end.
