unit Tributos.Decimal;

{
  Utilitarios de aritmetica decimal deterministica sobre Currency.

  Currency e um tipo de ponto fixo (escala de Int64 com 4 casas decimais
  implicitas), portanto imune ao erro de representacao binaria que afeta
  Double/Extended em regra fiscal.

  RoundHalfEven2 arredonda para 2 casas usando ROUND_HALF_EVEN (arredondamento
  bancario): em caso de empate exato (x.xx5), arredonda para o vizinho par.
  Isso depende do comportamento de Round() do Delphi, que no runtime padrao
  (modo de arredondamento da FPU/SSE = "round to nearest, ties to even")
  resolve empates para o inteiro mais proximo par — o mesmo criterio adotado
  por decimal.js com ROUND_HALF_EVEN no lado TypeScript. Ver testes em
  Tests.Decimal.pas para os casos de borda.
}

interface

function RoundHalfEven2(const AValue: Currency): Currency;
function AplicarPercentual(const ABase, APercentual: Currency): Currency;

implementation

function RoundHalfEven2(const AValue: Currency): Currency;
var
  Centavos: Int64;
begin
  Centavos := Round(AValue * 100);
  Result := Centavos / 100;
end;

function AplicarPercentual(const ABase, APercentual: Currency): Currency;
begin
  Result := ABase * APercentual / 100;
end;

end.
