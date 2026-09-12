unit Tributos.Difal;

{
  Calculo do DIFAL (diferencial de aliquota) para operacao interestadual
  destinada a consumidor final NAO contribuinte do ICMS.

  Base legal: EC 87/2015 e Convenio ICMS 236/2021 (partilha). Desde 2019 a
  partilha e 100% para o estado de destino (o periodo de transicao de
  2016-2018, com percentuais crescentes para o destino, ja se encerrou),
  portanto v1 aplica a regra vigente: ValorDestino = DIFAL integral,
  ValorOrigem = 0.

    BaseDifal = mesma base do ICMS proprio (ValorProduto - Desconto + Frete
                + Seguro + Outras, + IPI se compuser a base).
    DIFAL = BaseDifal x (AliquotaInterna_destino - AliquotaInterestadual) / 100.
    FCP   = BaseDifal x AliquotaFCP_destino / 100 (integralmente ao destino).

  So se aplica quando a operacao e interestadual E o destinatario nao e
  contribuinte (RF05). Para destinatario contribuinte, a diferenca de
  aliquota e tratada por antecipacao/ST conforme legislacao estadual, fora
  do escopo v1.
}

interface

uses
  Tributos.Types;

type
  ICalculadoraDifal = interface
    ['{6FBF6084-CF6F-4F81-AD7B-CF5B3D6E0A05}']
    function Aplicavel(const AOperacao: TOperacaoFiscal): Boolean;
    function Calcular(const AOperacao: TOperacaoFiscal; const ABaseDifal: Currency): TResultadoDifal;
  end;

  TCalculadoraDifal = class(TInterfacedObject, ICalculadoraDifal)
  public
    function Aplicavel(const AOperacao: TOperacaoFiscal): Boolean;
    function Calcular(const AOperacao: TOperacaoFiscal; const ABaseDifal: Currency): TResultadoDifal;
  end;

implementation

uses
  Tributos.Decimal;

function TCalculadoraDifal.Aplicavel(const AOperacao: TOperacaoFiscal): Boolean;
begin
  Result := (not AOperacao.OperacaoInterna) and (not AOperacao.DestinatarioContribuinte);
end;

function TCalculadoraDifal.Calcular(const AOperacao: TOperacaoFiscal; const ABaseDifal: Currency): TResultadoDifal;
var
  DiferencaAliquota: Currency;
begin
  DiferencaAliquota := AOperacao.Item.Icms.AliquotaInterna - AOperacao.Item.Icms.AliquotaInterestadual;

  Result.ValorDestino := RoundHalfEven2(AplicarPercentual(ABaseDifal, DiferencaAliquota));
  Result.ValorOrigem := 0;

  if AOperacao.Item.Icms.TemFcp then
    Result.Fcp := RoundHalfEven2(AplicarPercentual(ABaseDifal, AOperacao.Item.Icms.Fcp))
  else
    Result.Fcp := 0;
end;

end.
