unit Tests.Helpers;

{ Fabrica de TOperacaoFiscal com valores padrao sensatos, para os testes
  unitarios preencherem apenas os campos relevantes ao cenario testado. }

interface

uses
  Tributos.Types;

function OperacaoPadrao: TOperacaoFiscal;

implementation

function OperacaoPadrao: TOperacaoFiscal;
begin
  Result := Default(TOperacaoFiscal);
  Result.UfOrigem := 'SP';
  Result.UfDestino := 'SP';
  Result.DestinatarioContribuinte := True;
  Result.RegimeEmitente := reNormal;

  Result.Item.ValorProduto := 1000;
  Result.Item.Quantidade := 1;
  Result.Item.Frete := 0;
  Result.Item.Seguro := 0;
  Result.Item.Desconto := 0;
  Result.Item.Outras := 0;

  Result.Item.Ipi.Aliquota := 0;
  Result.Item.Ipi.Cst := '53';
  Result.Item.Ipi.IncluirNaBaseIcms := False;

  Result.Item.Icms.Cst := '00';
  Result.Item.Icms.AliquotaInterna := 18;
  Result.Item.Icms.AliquotaInterestadual := 18;

  Result.Item.PisCofins.Regime := rpcCumulativo;
  Result.Item.PisCofins.CstPis := '01';
  Result.Item.PisCofins.CstCofins := '01';
  Result.Item.PisCofins.AliquotaPis := 0.65;
  Result.Item.PisCofins.AliquotaCofins := 3;
end;

end.
