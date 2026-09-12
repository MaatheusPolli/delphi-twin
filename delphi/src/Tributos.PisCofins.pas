unit Tributos.PisCofins;

{
  Calculo de PIS e COFINS.

  Base legal: Leis 10.637/2002 (PIS nao cumulativo), 10.833/2003 (COFINS nao
  cumulativo) e 9.718/1998 (regime cumulativo).
    BC = ValorProduto - Desconto + Frete + Seguro + Outras.
    Valor = BC x Aliquota (aliquota ja informada de acordo com o regime -
    cumulativo: 0,65% / 3,00%; nao cumulativo: 1,65% / 7,60% - a calculadora
    nao decide a aliquota, apenas aplica a que vier em Item.PisCofins).
}

interface

uses
  Tributos.Types;

type
  ICalculadoraPisCofins = interface
    ['{4D9D4E62-AD4D-4D6F-BE9F-AD3F1B4C0A03}']
    function CalcularPis(const AOperacao: TOperacaoFiscal): TTributoBase;
    function CalcularCofins(const AOperacao: TOperacaoFiscal): TTributoBase;
  end;

  TCalculadoraPisCofins = class(TInterfacedObject, ICalculadoraPisCofins)
  private
    function BaseCalculo(const AOperacao: TOperacaoFiscal): Currency;
  public
    function CalcularPis(const AOperacao: TOperacaoFiscal): TTributoBase;
    function CalcularCofins(const AOperacao: TOperacaoFiscal): TTributoBase;
  end;

implementation

uses
  Tributos.Decimal;

function TCalculadoraPisCofins.BaseCalculo(const AOperacao: TOperacaoFiscal): Currency;
var
  Item: TItemOperacao;
begin
  Item := AOperacao.Item;
  Result := Item.ValorProduto - Item.Desconto + Item.Frete + Item.Seguro + Item.Outras;
end;

function TCalculadoraPisCofins.CalcularPis(const AOperacao: TOperacaoFiscal): TTributoBase;
begin
  Result.Bc := RoundHalfEven2(BaseCalculo(AOperacao));
  Result.Aliquota := AOperacao.Item.PisCofins.AliquotaPis;
  Result.Valor := RoundHalfEven2(AplicarPercentual(Result.Bc, Result.Aliquota));
end;

function TCalculadoraPisCofins.CalcularCofins(const AOperacao: TOperacaoFiscal): TTributoBase;
begin
  Result.Bc := RoundHalfEven2(BaseCalculo(AOperacao));
  Result.Aliquota := AOperacao.Item.PisCofins.AliquotaCofins;
  Result.Valor := RoundHalfEven2(AplicarPercentual(Result.Bc, Result.Aliquota));
end;

end.
