import { Decimal } from '../domain/decimal.js';
import { aplicarPercentual, d, roundHalfEven2 } from '../domain/decimal.js';
import type { OperacaoFiscal, ResultadoDifal } from '../domain/types.js';
import { operacaoInterna } from '../domain/types.js';

/**
 * Calculo do DIFAL (diferencial de aliquota) para operacao interestadual
 * destinada a consumidor final NAO contribuinte do ICMS.
 *
 * Base legal: EC 87/2015 e Convenio ICMS 236/2021 (partilha). Desde 2019 a
 * partilha e 100% para o estado de destino (o periodo de transicao de
 * 2016-2018 ja se encerrou), portanto v1 aplica a regra vigente:
 * valorDestino = DIFAL integral, valorOrigem = 0.
 *
 *   BaseDifal = mesma base do ICMS proprio.
 *   DIFAL = BaseDifal x (AliquotaInterna_destino - AliquotaInterestadual) / 100.
 *   FCP   = BaseDifal x AliquotaFCP_destino / 100 (integralmente ao destino).
 *
 * So se aplica quando a operacao e interestadual E o destinatario nao e
 * contribuinte (RF05). Para destinatario contribuinte, a diferenca de
 * aliquota e tratada por antecipacao/ST estadual, fora do escopo v1.
 *
 * Espelha delphi/src/Tributos.Difal.pas.
 */
export function difalAplicavel(operacao: OperacaoFiscal): boolean {
  return !operacaoInterna(operacao) && !operacao.destinatarioContribuinte;
}

export function calcularDifal(operacao: OperacaoFiscal, baseDifal: Decimal): ResultadoDifal {
  const diferencaAliquota = operacao.item.icms.aliquotaInterna.minus(operacao.item.icms.aliquotaInterestadual);

  const valorDestino = roundHalfEven2(aplicarPercentual(baseDifal, diferencaAliquota));
  const valorOrigem = d(0);
  const fcp = operacao.item.icms.fcp ? roundHalfEven2(aplicarPercentual(baseDifal, operacao.item.icms.fcp)) : d(0);

  return { valorOrigem, valorDestino, fcp };
}
