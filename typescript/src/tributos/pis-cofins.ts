import { aplicarPercentual, roundHalfEven2 } from '../domain/decimal.js';
import type { OperacaoFiscal, TributoBase } from '../domain/types.js';

/**
 * Calculo de PIS e COFINS.
 *
 * Base legal: Leis 10.637/2002 (PIS nao cumulativo), 10.833/2003 (COFINS
 * nao cumulativo) e 9.718/1998 (regime cumulativo).
 *   BC = ValorProduto - Desconto + Frete + Seguro + Outras.
 *   Valor = BC x Aliquota (a aliquota ja vem definida de acordo com o
 *   regime - esta funcao apenas aplica o que vier em item.pisCofins).
 *
 * Espelha delphi/src/Tributos.PisCofins.pas.
 */
function baseCalculo(operacao: OperacaoFiscal) {
  const { item } = operacao;
  return item.valorProduto.minus(item.desconto).plus(item.frete).plus(item.seguro).plus(item.outras);
}

export function calcularPis(operacao: OperacaoFiscal): TributoBase {
  const bc = roundHalfEven2(baseCalculo(operacao));
  const aliquota = operacao.item.pisCofins.aliquotaPis;
  const valor = roundHalfEven2(aplicarPercentual(bc, aliquota));
  return { bc, aliquota, valor };
}

export function calcularCofins(operacao: OperacaoFiscal): TributoBase {
  const bc = roundHalfEven2(baseCalculo(operacao));
  const aliquota = operacao.item.pisCofins.aliquotaCofins;
  const valor = roundHalfEven2(aplicarPercentual(bc, aliquota));
  return { bc, aliquota, valor };
}
