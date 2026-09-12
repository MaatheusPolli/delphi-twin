/* eslint-disable @typescript-eslint/no-explicit-any -- fronteira de parsing de JSON nao tipado vindo da spec */
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { d } from './domain/decimal.js';
import type {
  ItemIcms,
  ItemIpi,
  ItemOperacao,
  ItemPisCofins,
  OperacaoFiscal,
  RegimeEmitente,
  RegimePisCofins,
  ResultadoTributos,
  TributoBase,
  UF,
} from './domain/types.js';

/**
 * Le os casos de teste de spec/cases/*.json (formato descrito em
 * spec/schema/case.schema.json) e converte para os tipos de domain/types.ts,
 * e vice-versa para serializar um ResultadoTributos.
 *
 * Espelha delphi/src/Tributos.SpecLoader.pas. Todo valor decimal trafega
 * como string no JSON (nunca number), para preservar precisao exata.
 */
export interface CasoDeTeste {
  readonly id: string;
  readonly descricao: string;
  readonly entrada: OperacaoFiscal;
  readonly esperado?: ResultadoTributos;
}

function parseItemIpi(json: any): ItemIpi {
  return {
    aliquota: d(json.aliquota),
    cst: json.cst,
    ...(json.incluirNaBaseIcms !== undefined ? { incluirNaBaseIcms: json.incluirNaBaseIcms } : {}),
  };
}

function parseItemIcms(json: any): ItemIcms {
  return {
    cst: json.cst,
    aliquotaInterna: d(json.aliquotaInterna),
    aliquotaInterestadual: d(json.aliquotaInterestadual),
    ...(json.reducaoBC !== undefined ? { reducaoBC: d(json.reducaoBC) } : {}),
    ...(json.mva !== undefined ? { mva: d(json.mva) } : {}),
    ...(json.reducaoBCST !== undefined ? { reducaoBCST: d(json.reducaoBCST) } : {}),
    ...(json.fcp !== undefined ? { fcp: d(json.fcp) } : {}),
  };
}

function parseItemPisCofins(json: any): ItemPisCofins {
  return {
    regime: json.regime as RegimePisCofins,
    cstPis: json.cstPis,
    cstCofins: json.cstCofins,
    aliquotaPis: d(json.aliquotaPis),
    aliquotaCofins: d(json.aliquotaCofins),
  };
}

function parseItemOperacao(json: any): ItemOperacao {
  return {
    valorProduto: d(json.valorProduto),
    quantidade: d(json.quantidade),
    frete: d(json.frete),
    seguro: d(json.seguro),
    desconto: d(json.desconto),
    outras: d(json.outras),
    ipi: parseItemIpi(json.ipi),
    icms: parseItemIcms(json.icms),
    pisCofins: parseItemPisCofins(json.pisCofins),
  };
}

export function parseOperacao(json: any): OperacaoFiscal {
  return {
    ufOrigem: json.ufOrigem as UF,
    ufDestino: json.ufDestino as UF,
    destinatarioContribuinte: json.destinatarioContribuinte,
    regimeEmitente: json.regimeEmitente as RegimeEmitente,
    item: parseItemOperacao(json.item),
  };
}

function parseTributoBase(json: any): TributoBase {
  return { bc: d(json.bc), aliquota: d(json.aliquota), valor: d(json.valor) };
}

export function parseResultado(json: any): ResultadoTributos {
  return {
    icms: parseTributoBase(json.icms),
    ipi: parseTributoBase(json.ipi),
    pis: parseTributoBase(json.pis),
    cofins: parseTributoBase(json.cofins),
    totalTributos: d(json.totalTributos),
    ...(json.icmsSt !== undefined
      ? {
          icmsSt: {
            bc: d(json.icmsSt.bc),
            aliquota: d(json.icmsSt.aliquota),
            valor: d(json.icmsSt.valor),
            mvaAplicada: d(json.icmsSt.mvaAplicada),
          },
        }
      : {}),
    ...(json.difal !== undefined
      ? {
          difal: {
            valorOrigem: d(json.difal.valorOrigem),
            valorDestino: d(json.difal.valorDestino),
            fcp: d(json.difal.fcp),
          },
        }
      : {}),
  };
}

/**
 * Mesmo padrao de spec/schema/case.schema.json para o campo "id". Validado
 * aqui (alem da validacao via tools/validate-spec.ts) porque o id e usado
 * para montar nomes de arquivo em results/{delphi,ts}/<id>.json - um id
 * malicioso ou malformado (ex.: contendo "../") nao pode escapar da pasta
 * de resultados.
 */
const ID_VALIDO = /^[a-z0-9]+(-[a-z0-9]+)*$/;

function validarId(id: unknown, arquivo: string): string {
  if (typeof id !== 'string' || !ID_VALIDO.test(id)) {
    throw new Error(`Caso invalido em ${arquivo}: "id" deve casar com ${ID_VALIDO} (recebido: ${JSON.stringify(id)})`);
  }
  return id;
}

export function carregarCasoDeArquivo(caminhoArquivo: string): CasoDeTeste {
  const texto = readFileSync(caminhoArquivo, 'utf8');
  const json = JSON.parse(texto);

  return {
    id: validarId(json.id, caminhoArquivo),
    descricao: json.descricao,
    entrada: parseOperacao(json.entrada),
    ...(json.esperado !== undefined ? { esperado: parseResultado(json.esperado) } : {}),
  };
}

export function listarArquivosDeCasos(pastaCases: string): string[] {
  return readdirSync(pastaCases)
    .filter((f) => f.endsWith('.json'))
    .sort()
    .map((f) => join(pastaCases, f));
}

function tributoBaseParaJson(t: TributoBase) {
  return { bc: t.bc.toFixed(2), aliquota: t.aliquota.toString(), valor: t.valor.toFixed(2) };
}

export function resultadoParaJson(resultado: ResultadoTributos): object {
  return {
    icms: tributoBaseParaJson(resultado.icms),
    ipi: tributoBaseParaJson(resultado.ipi),
    pis: tributoBaseParaJson(resultado.pis),
    cofins: tributoBaseParaJson(resultado.cofins),
    totalTributos: resultado.totalTributos.toFixed(2),
    ...(resultado.icmsSt
      ? {
          icmsSt: {
            bc: resultado.icmsSt.bc.toFixed(2),
            aliquota: resultado.icmsSt.aliquota.toString(),
            valor: resultado.icmsSt.valor.toFixed(2),
            mvaAplicada: resultado.icmsSt.mvaAplicada.toString(),
          },
        }
      : {}),
    ...(resultado.difal
      ? {
          difal: {
            valorOrigem: resultado.difal.valorOrigem.toFixed(2),
            valorDestino: resultado.difal.valorDestino.toFixed(2),
            fcp: resultado.difal.fcp.toFixed(2),
          },
        }
      : {}),
  };
}
