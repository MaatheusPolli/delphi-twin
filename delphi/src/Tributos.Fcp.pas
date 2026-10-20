unit Tributos.Fcp;

{
  Calculo do FCP (Fundo de Combate a Pobreza) sobre operacao interna.

  Base legal: art. 82 e seguintes do ADCT da CF/88 (EC 31/2000) e convenios
  do CONFAZ que autorizam a cobranca adicional de ate 2 p.p. de aliquota em
  favor do fundo estadual. Na operacao interna o FCP incide sobre a mesma
  base do ICMS proprio.

    FCP = BC do ICMS x AliquotaFCP / 100.

  Na operacao interestadual o FCP ja e tratado pelo DIFAL (Tributos.Difal),
  por isso nao se aplica nesse caso (evita dupla contagem).

  Espelha typescript/src/tributos/fcp.ts.
}

interface

uses
  Tributos.Types;

function FcpAplicavel(const AOperacao: TOperacaoFiscal): Boolean;
function CalcularFcp(const AOperacao: TOperacaoFiscal; const ABaseIcms: Currency): TResultadoFcp;

implementation

uses
  Tributos.Decimal;

function FcpAplicavel(const AOperacao: TOperacaoFiscal): Boolean;
begin
  Result := AOperacao.OperacaoInterna and AOperacao.Item.Icms.TemFcp;
end;

function CalcularFcp(const AOperacao: TOperacaoFiscal; const ABaseIcms: Currency): TResultadoFcp;
begin
  Result.Bc := ABaseIcms;
  Result.Aliquota := AOperacao.Item.Icms.Fcp;
  Result.Valor := RoundHalfEven2(AplicarPercentual(ABaseIcms, Result.Aliquota));
end;

end.
