import { Decimal } from '../domain/decimal.js';
import { aplicarPercentual, d, roundHalfEven2 } from '../domain/decimal.js';
import type { OperacaoFiscal, ResultadoIcmsSt } from '../domain/types.js';
import { operacaoInterna } from '../domain/types.js';

/**
 * Calculo do ICMS-ST (Substituicao Tributaria).
 *
 * Base legal: Convenio ICMS 142/2018 (regras gerais de ST) e Convenio ICMS
 * 52/2017 (MVA ajustada em operacoes interestaduais).
 *
 *   MVA aplicada:
 *     - Operacao interna: MVA original informada, sem ajuste.
 *     - Operacao interestadual: MVA ajustada =
 *         [(1 + MVA_original/100) x (1 - AliqInter/100) / (1 - AliqIntra/100) - 1] x 100
 *       onde AliqIntra e a aliquota interna do estado de destino e AliqInter
 *       e a aliquota interestadual da operacao.
 *
 *   BC_ST = (ValorProduto - Desconto + Frete + Seguro + Outras + ValorIPI)
 *           com reducao de BC-ST (se houver) aplicada antes do MVA,
 *           multiplicada por (1 + MVA_aplicada/100).
 *
 *   Valor_ST = (BC_ST x AliquotaInterna_destino) - ICMS proprio da operacao,
 *   nunca negativo.
 *
 * A MVA ajustada e arredondada para 2 casas ANTES de compor a base, para
 * que Delphi e TypeScript concordem no valor intermediario - do contrario a
 * divisao (1-AliqInter)/(1-AliqIntra) poderia carregar precisao diferente
 * em cada lado e divergir no ultimo digito.
 *
 * Espelha delphi/src/Tributos.IcmsST.pas.
 */
function calcularMvaAplicada(operacao: OperacaoFiscal): Decimal {
  const mvaOriginal = operacao.item.icms.mva ?? d(0);

  if (operacaoInterna(operacao)) {
    return mvaOriginal;
  }

  const aliqInter = operacao.item.icms.aliquotaInterestadual;
  const aliqIntra = operacao.item.icms.aliquotaInterna;

  // AliqIntra >= 100% zeraria (ou inverteria o sinal de) o denominador da
  // formula de ajuste. Uma aliquota interna de 100% ou mais nao existe na
  // legislacao brasileira - e melhor rejeitar com um erro claro do que
  // deixar decimal.js retornar Infinity silenciosamente e contaminar o
  // resto do calculo sem erro nenhum (o lado Delphi lanca EZeroDivide na
  // mesma situacao - ver Tributos.IcmsST.pas).
  if (aliqIntra.greaterThanOrEqualTo(100)) {
    throw new Error(
      `MVA ajustada (Convenio 52/2017): aliquota interna do destino invalida (${aliqIntra.toString()}%) - deve ser menor que 100%.`,
    );
  }

  const fator = d(1)
    .plus(mvaOriginal.dividedBy(100))
    .times(d(1).minus(aliqInter.dividedBy(100)))
    .dividedBy(d(1).minus(aliqIntra.dividedBy(100)))
    .minus(1);

  return fator.times(100);
}

export function calcularIcmsSt(
  operacao: OperacaoFiscal,
  valorIpi: Decimal,
  valorIcmsProprio: Decimal,
): ResultadoIcmsSt {
  const { item } = operacao;

  const baseAntesDoMva = item.valorProduto
    .minus(item.desconto)
    .plus(item.frete)
    .plus(item.seguro)
    .plus(item.outras)
    .plus(valorIpi);

  const baseComReducaoST = item.icms.reducaoBCST
    ? aplicarPercentual(baseAntesDoMva, d(100).minus(item.icms.reducaoBCST))
    : baseAntesDoMva;

  const mvaAplicada = roundHalfEven2(calcularMvaAplicada(operacao));
  const baseST = aplicarPercentual(baseComReducaoST, d(100).plus(mvaAplicada));

  const bc = roundHalfEven2(baseST);
  const aliquota = item.icms.aliquotaInterna;

  let valor = roundHalfEven2(aplicarPercentual(bc, aliquota)).minus(valorIcmsProprio);
  if (valor.isNegative() || item.icms.cst === '60') {
    // CST 60: o ICMS-ST ja foi retido na operacao anterior, nada e devido aqui.
    valor = d(0);
  }

  return { bc, aliquota, valor, mvaAplicada };
}
