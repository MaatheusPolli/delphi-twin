import { describe, expect, it } from 'vitest';
import { d } from '../src/domain/decimal.js';
import { calcularFcp, fcpAplicavel } from '../src/tributos/fcp.js';
import { calcularTributos } from '../src/tributos/motor.js';
import { operacaoPadrao } from './helpers.js';

describe('FCP', () => {
  it('nao se aplica sem aliquota de FCP informada', () => {
    expect(fcpAplicavel(operacaoPadrao())).toBe(false);
  });

  it('incide sobre a base do ICMS em operacao interna', () => {
    const operacao = operacaoPadrao();
    const comFcp = { ...operacao, item: { ...operacao.item, icms: { ...operacao.item.icms, fcp: d('2') } } };

    expect(fcpAplicavel(comFcp)).toBe(true);
    const resultado = calcularFcp(comFcp, d('1000.00'));
    expect(resultado.valor.toFixed(2)).toBe('20.00');
  });

  it('nao se aplica em operacao interestadual (coberto pelo DIFAL)', () => {
    const operacao = operacaoPadrao();
    const interestadual = {
      ...operacao,
      ufDestino: 'RJ' as const,
      destinatarioContribuinte: true,
      item: { ...operacao.item, icms: { ...operacao.item.icms, fcp: d('2') } },
    };

    expect(fcpAplicavel(interestadual)).toBe(false);
    expect(calcularTributos(interestadual).fcp).toBeUndefined();
  });
});
