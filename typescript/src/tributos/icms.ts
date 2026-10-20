import { Decimal } from '../domain/decimal.js';
import { aplicarPercentual, d, roundHalfEven2 } from '../domain/decimal.js';
import type { ItemIcms, OperacaoFiscal, TributoBase } from '../domain/types.js';
import { operacaoInterna } from '../domain/types.js';

/**
 * Calculo do ICMS proprio (destaque na nota).
 *
 * Base legal geral: art. 13 da LC 87/1996 (Lei Kandir).
 *   BC = ValorProduto - Desconto + Frete + Seguro + Outras (+ IPI, se o
 *        destinatario nao for contribuinte e o IPI compuser a base).
 *   Se houver reducao de base de calculo (CST 20/70), aplica-se o percentual
 *   de reducao sobre a base antes de calcular o imposto.
 *   Aliquota: interna se a operacao for dentro do mesmo estado; interestadual
 *   caso contrario (Resolucao do Senado 22/1989) - vale tanto para venda a
 *   contribuinte quanto a nao contribuinte (EC 87/2015), pois neste ultimo
 *   caso o DIFAL (tributos/difal.ts) e que absorve a diferenca para o
 *   estado de destino.
 *
 * Espelha delphi/src/Tributos.Icms.pas.
 */
export function calcularIcms(operacao: OperacaoFiscal, valorIpiParaBase: Decimal): TributoBase {
  const { item } = operacao;

  let baseBruta = item.valorProduto.minus(item.desconto).plus(item.frete).plus(item.seguro).plus(item.outras);
  if (item.ipi.incluirNaBaseIcms) {
    baseBruta = baseBruta.plus(valorIpiParaBase);
  }

  const baseComReducao = item.icms.reducaoBC
    ? aplicarPercentual(baseBruta, d(100).minus(item.icms.reducaoBC))
    : baseBruta;

  const aliquota = operacaoInterna(operacao) ? item.icms.aliquotaInterna : item.icms.aliquotaInterestadual;

  const bc = roundHalfEven2(baseComReducao);
  const valor = icmsProprioDestacado(item.icms) ? roundHalfEven2(aplicarPercentual(bc, aliquota)) : d(0);

  return { bc, aliquota, valor };
}

/**
 * CST 30 (isenta/nao tributada com cobranca de ST) e CST 60 (ICMS cobrado
 * anteriormente por ST): o ICMS proprio nao e destacado na nota (valor 0),
 * mas a BC continua informada. Espelha Tributos.Icms.pas.
 */
export function icmsProprioDestacado(icms: ItemIcms): boolean {
  return !icms.desonerado && icms.cst !== '30' && icms.cst !== '60';
}

/**
 * ICMS desonerado (art. 155 par. 2 II 'a' CF/88 e Convenio ICMS 109/2019 - campo
 * vICMSDeson da NF-e): quando a operacao e desonerada, o imposto nao e cobrado
 * (valor do ICMS proprio = 0), mas o montante que deixou de ser cobrado e
 * informado separadamente.
 *
 *   ICMSDesonerado = BC x Aliquota / 100 (sem cobrar do destinatario).
 */
export function calcularIcmsDesonerado(icms: TributoBase): Decimal {
  return roundHalfEven2(aplicarPercentual(icms.bc, icms.aliquota));
}
