import { aplicarPercentual, roundHalfEven2 } from '../domain/decimal.js';
import type { OperacaoFiscal, TributoBase } from '../domain/types.js';

/**
 * Calculo do IPI (Imposto sobre Produtos Industrializados).
 *
 * Base legal: RIPI/2010 (Decreto 7.212/2010), art. 190.
 *   BC = ValorProduto - Desconto + Frete + Seguro + Outras.
 *   Valor = BC x Aliquota.
 *
 * Espelha delphi/src/Tributos.Ipi.pas.
 */
export function calcularIpi(operacao: OperacaoFiscal): TributoBase {
  const { item } = operacao;
  const base = item.valorProduto.minus(item.desconto).plus(item.frete).plus(item.seguro).plus(item.outras);

  const bc = roundHalfEven2(base);
  const aliquota = item.ipi.aliquota;
  const valor = roundHalfEven2(aplicarPercentual(bc, aliquota));

  return { bc, aliquota, valor };
}
