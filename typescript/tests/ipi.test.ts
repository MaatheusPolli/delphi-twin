import { describe, expect, it } from 'vitest';
import { d } from '../src/domain/decimal.js';
import { calcularIpi } from '../src/tributos/ipi.js';
import { operacaoPadrao } from './helpers.js';

describe('calcularIpi', () => {
  it('aplica a aliquota sobre valor do produto mais despesas', () => {
    const operacao = operacaoPadrao();
    const comFreteEAliquota = {
      ...operacao,
      item: { ...operacao.item, frete: d('100'), ipi: { ...operacao.item.ipi, aliquota: d('10') } },
    };

    const resultado = calcularIpi(comFreteEAliquota);

    expect(resultado.bc.toFixed(2)).toBe('1100.00');
    expect(resultado.valor.toFixed(2)).toBe('110.00');
  });

  it('resulta em imposto zero quando a aliquota e zero', () => {
    const resultado = calcularIpi(operacaoPadrao());
    expect(resultado.valor.toFixed(2)).toBe('0.00');
  });

  it('desconta o valor do desconto incondicional', () => {
    const operacao = operacaoPadrao();
    const comDesconto = {
      ...operacao,
      item: { ...operacao.item, desconto: d('100'), ipi: { ...operacao.item.ipi, aliquota: d('10') } },
    };

    const resultado = calcularIpi(comDesconto);

    expect(resultado.bc.toFixed(2)).toBe('900.00');
    expect(resultado.valor.toFixed(2)).toBe('90.00');
  });
});
