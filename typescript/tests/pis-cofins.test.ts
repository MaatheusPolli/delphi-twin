import { describe, expect, it } from 'vitest';
import { d } from '../src/domain/decimal.js';
import { calcularCofins, calcularPis } from '../src/tributos/pis-cofins.js';
import { operacaoPadrao } from './helpers.js';

describe('calcularPis / calcularCofins', () => {
  it('aplica as aliquotas padrao do regime cumulativo', () => {
    const operacao = operacaoPadrao();

    const pis = calcularPis(operacao);
    const cofins = calcularCofins(operacao);

    expect(pis.bc.toFixed(2)).toBe('1000.00');
    expect(pis.valor.toFixed(2)).toBe('6.50');
    expect(cofins.valor.toFixed(2)).toBe('30.00');
  });

  it('aplica as aliquotas maiores do regime nao cumulativo', () => {
    const operacao = operacaoPadrao();
    const naoCumulativo = {
      ...operacao,
      item: {
        ...operacao.item,
        pisCofins: {
          regime: 'nao-cumulativo' as const,
          cstPis: '01',
          cstCofins: '01',
          aliquotaPis: d('1.65'),
          aliquotaCofins: d('7.6'),
        },
      },
    };

    const pis = calcularPis(naoCumulativo);
    const cofins = calcularCofins(naoCumulativo);

    expect(pis.valor.toFixed(2)).toBe('16.50');
    expect(cofins.valor.toFixed(2)).toBe('76.00');
  });
});
