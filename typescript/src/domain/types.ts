import { Decimal } from 'decimal.js';

export type UF =
  | 'AC'
  | 'AL'
  | 'AP'
  | 'AM'
  | 'BA'
  | 'CE'
  | 'DF'
  | 'ES'
  | 'GO'
  | 'MA'
  | 'MT'
  | 'MS'
  | 'MG'
  | 'PA'
  | 'PB'
  | 'PR'
  | 'PE'
  | 'PI'
  | 'RJ'
  | 'RN'
  | 'RS'
  | 'RO'
  | 'RR'
  | 'SC'
  | 'SP'
  | 'SE'
  | 'TO';

export type RegimeEmitente = 'normal' | 'simples';
export type RegimePisCofins = 'cumulativo' | 'nao-cumulativo';

export interface ItemIpi {
  readonly aliquota: Decimal;
  readonly cst: string;
  readonly incluirNaBaseIcms?: boolean;
}

export interface ItemIcms {
  readonly cst: string;
  readonly aliquotaInterna: Decimal;
  readonly aliquotaInterestadual: Decimal;
  readonly reducaoBC?: Decimal;
  readonly mva?: Decimal;
  readonly reducaoBCST?: Decimal;
  readonly fcp?: Decimal;
}

export interface ItemPisCofins {
  readonly regime: RegimePisCofins;
  readonly cstPis: string;
  readonly cstCofins: string;
  readonly aliquotaPis: Decimal;
  readonly aliquotaCofins: Decimal;
}

export interface ItemOperacao {
  readonly valorProduto: Decimal;
  readonly quantidade: Decimal;
  readonly frete: Decimal;
  readonly seguro: Decimal;
  readonly desconto: Decimal;
  readonly outras: Decimal;
  readonly ipi: ItemIpi;
  readonly icms: ItemIcms;
  readonly pisCofins: ItemPisCofins;
}

export interface OperacaoFiscal {
  readonly ufOrigem: UF;
  readonly ufDestino: UF;
  readonly destinatarioContribuinte: boolean;
  readonly regimeEmitente: RegimeEmitente;
  readonly item: ItemOperacao;
}

export interface TributoBase {
  readonly bc: Decimal;
  readonly aliquota: Decimal;
  readonly valor: Decimal;
}

export interface ResultadoIcmsSt {
  readonly bc: Decimal;
  readonly aliquota: Decimal;
  readonly valor: Decimal;
  readonly mvaAplicada: Decimal;
}

export interface ResultadoDifal {
  readonly valorOrigem: Decimal;
  readonly valorDestino: Decimal;
  readonly fcp: Decimal;
}

export interface ResultadoTributos {
  readonly icms: TributoBase;
  readonly icmsSt?: ResultadoIcmsSt;
  readonly ipi: TributoBase;
  readonly pis: TributoBase;
  readonly cofins: TributoBase;
  readonly difal?: ResultadoDifal;
  readonly totalTributos: Decimal;
}

export function operacaoInterna(operacao: OperacaoFiscal): boolean {
  return operacao.ufOrigem === operacao.ufDestino;
}
