import type { OperacaoFiscal, ResultadoTributos } from '../domain/types.js';
import { calcularDifal, difalAplicavel } from './difal.js';
import { calcularIcms } from './icms.js';
import { calcularIcmsSt } from './icms-st.js';
import { calcularIpi } from './ipi.js';
import { calcularCofins, calcularPis } from './pis-cofins.js';

/**
 * Orquestra as calculadoras individuais para produzir o ResultadoTributos
 * completo de uma OperacaoFiscal. Funcao pura, sem estado - equivalente
 * funcional do TMotorTributario em delphi/src/Tributos.Motor.pas.
 *
 * Ordem de calculo (importa por causa das dependencias entre bases):
 *   1. IPI       - nao depende de nenhum outro tributo.
 *   2. ICMS      - pode precisar do valor do IPI (se compuser a base).
 *   3. ICMS-ST   - precisa do valor do IPI e do ICMS proprio.
 *   4. PIS/COFINS- independente.
 *   5. DIFAL     - so quando aplicavel (interestadual + nao contribuinte);
 *                  usa a mesma base do ICMS proprio.
 */
export function calcularTributos(operacao: OperacaoFiscal): ResultadoTributos {
  const ipi = calcularIpi(operacao);
  const icms = calcularIcms(operacao, ipi.valor);

  const icmsSt = operacao.item.icms.mva !== undefined ? calcularIcmsSt(operacao, ipi.valor, icms.valor) : undefined;

  const pis = calcularPis(operacao);
  const cofins = calcularCofins(operacao);

  const difal = difalAplicavel(operacao) ? calcularDifal(operacao, icms.bc) : undefined;

  let totalTributos = icms.valor.plus(ipi.valor).plus(pis.valor).plus(cofins.valor);
  if (icmsSt) {
    totalTributos = totalTributos.plus(icmsSt.valor);
  }
  if (difal) {
    totalTributos = totalTributos.plus(difal.valorOrigem).plus(difal.valorDestino).plus(difal.fcp);
  }

  const resultado: ResultadoTributos = {
    icms,
    ipi,
    pis,
    cofins,
    totalTributos,
    ...(icmsSt ? { icmsSt } : {}),
    ...(difal ? { difal } : {}),
  };

  return resultado;
}
