import { aplicarPercentual, roundHalfEven2 } from '../domain/decimal.js';
import type { OperacaoFiscal, ResultadoFcp } from '../domain/types.js';
import { operacaoInterna } from '../domain/types.js';

/**
 * Calculo do FCP (Fundo de Combate a Pobreza) sobre operacao interna.
 *
 * Base legal: art. 82 e seguintes do ADCT da CF/88 (EC 31/2000) e convenios
 * do CONFAZ que autorizam a cobranca adicional de ate 2 p.p. de aliquota em
 * favor do fundo estadual. Na operacao interna o FCP incide sobre a mesma
 * base do ICMS proprio.
 *
 *   FCP = BC do ICMS x AliquotaFCP / 100.
 *
 * Na operacao interestadual o FCP ja e tratado pelo DIFAL (tributos/difal.ts),
 * por isso esta funcao nao se aplica nesse caso (evita dupla contagem).
 *
 * Espelha delphi/src/Tributos.Fcp.pas (pendente).
 */
export function fcpAplicavel(operacao: OperacaoFiscal): boolean {
  return operacaoInterna(operacao) && operacao.item.icms.fcp !== undefined;
}

export function calcularFcp(operacao: OperacaoFiscal, baseIcms: ResultadoFcp['bc']): ResultadoFcp {
  const aliquota = operacao.item.icms.fcp!;
  const valor = roundHalfEven2(aplicarPercentual(baseIcms, aliquota));
  return { bc: baseIcms, aliquota, valor };
}
