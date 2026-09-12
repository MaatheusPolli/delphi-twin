unit Tributos.Types;

{
  Tipos de dominio do motor tributario. Espelha, campo a campo, os tipos
  TypeScript em typescript/src/domain/types.ts (OperacaoFiscal / ResultadoTributos).

  Todo valor monetario ou percentual usa Currency (ponto fixo, 4 casas decimais
  armazenadas como escala de Int64) para evitar o erro de arredondamento do
  ponto flutuante binario em regra fiscal. Nunca usar Double/Extended aqui.
}

interface

uses
  SysUtils;

type
  TUF = string;

  TRegimeEmitente = (reNormal, reSimples);
  TRegimePisCofins = (rpcCumulativo, rpcNaoCumulativo);

  TItemIpi = record
    Aliquota: Currency;
    Cst: string;
    IncluirNaBaseIcms: Boolean;
  end;

  TItemIcms = record
    Cst: string;
    AliquotaInterna: Currency;
    AliquotaInterestadual: Currency;
    ReducaoBC: Currency;
    TemReducaoBC: Boolean;
    Mva: Currency;
    TemMva: Boolean;
    ReducaoBCST: Currency;
    TemReducaoBCST: Boolean;
    Fcp: Currency;
    TemFcp: Boolean;
  end;

  TItemPisCofins = record
    Regime: TRegimePisCofins;
    CstPis: string;
    CstCofins: string;
    AliquotaPis: Currency;
    AliquotaCofins: Currency;
  end;

  TItemOperacao = record
    ValorProduto: Currency;
    Quantidade: Currency;
    Frete: Currency;
    Seguro: Currency;
    Desconto: Currency;
    Outras: Currency;
    Ipi: TItemIpi;
    Icms: TItemIcms;
    PisCofins: TItemPisCofins;
  end;

  TOperacaoFiscal = record
    UfOrigem: TUF;
    UfDestino: TUF;
    DestinatarioContribuinte: Boolean;
    RegimeEmitente: TRegimeEmitente;
    Item: TItemOperacao;
    function OperacaoInterna: Boolean;
  end;

  TTributoBase = record
    Bc: Currency;
    Aliquota: Currency;
    Valor: Currency;
  end;

  TResultadoIcmsSt = record
    Bc: Currency;
    Aliquota: Currency;
    Valor: Currency;
    MvaAplicada: Currency;
  end;

  TResultadoDifal = record
    ValorOrigem: Currency;
    ValorDestino: Currency;
    Fcp: Currency;
  end;

  TResultadoTributos = record
    Icms: TTributoBase;
    IcmsSt: TResultadoIcmsSt;
    TemIcmsSt: Boolean;
    Ipi: TTributoBase;
    Pis: TTributoBase;
    Cofins: TTributoBase;
    Difal: TResultadoDifal;
    TemDifal: Boolean;
    TotalTributos: Currency;
  end;

implementation

function TOperacaoFiscal.OperacaoInterna: Boolean;
begin
  Result := SameText(UfOrigem, UfDestino);
end;

end.
