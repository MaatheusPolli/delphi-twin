import { Decimal } from '../domain/decimal.js';
import { aplicarPercentual, d, roundHalfEven2 } from '../domain/decimal.js';
import type { OperacaoFiscal, TributoBase } from '../domain/types.js';
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
  const valor = roundHalfEven2(aplicarPercentual(bc, aliquota));

  return { bc, aliquota, valor };
}
