import { describe, expect, it } from 'vitest';
import { d } from '../src/domain/decimal.js';
import { calcularIcms } from '../src/tributos/icms.js';
import { operacaoPadrao } from './helpers.js';

describe('calcularIcms', () => {
  it('aplica aliquota interna sobre o valor do produto em operacao simples', () => {
    const resultado = calcularIcms(operacaoPadrao(), d('0'));

    expect(resultado.bc.toFixed(2)).toBe('1000.00');
    expect(resultado.aliquota.toFixed(2)).toBe('18.00');
    expect(resultado.valor.toFixed(2)).toBe('180.00');
  });

  it('reduz a base antes do imposto quando ha reducao de BC', () => {
    const operacao = operacaoPadrao();
    const comReducao = {
      ...operacao,
      item: { ...operacao.item, icms: { ...operacao.item.icms, reducaoBC: d('33.33') } },
    };

    const resultado = calcularIcms(comReducao, d('0'));

    expect(resultado.bc.toFixed(2)).toBe('666.70');
    expect(resultado.valor.toFixed(2)).toBe('120.01');
  });

  it('usa aliquota interestadual quando a operacao e interestadual', () => {
    const operacao = operacaoPadrao();
    const interestadual = {
      ...operacao,
      ufDestino: 'MG' as const,
      item: {
        ...operacao.item,
        icms: { ...operacao.item.icms, aliquotaInterna: d('18'), aliquotaInterestadual: d('12') },
      },
    };

    const resultado = calcularIcms(interestadual, d('0'));

    expect(resultado.aliquota.toFixed(2)).toBe('12.00');
    expect(resultado.valor.toFixed(2)).toBe('120.00');
  });

  it('compoe a base do ICMS com o IPI quando sinalizado', () => {
    const operacao = operacaoPadrao();
    const comIpiNaBase = {
      ...operacao,
      ufDestino: 'RJ' as const,
      destinatarioContribuinte: false,
      item: {
        ...operacao.item,
        icms: { ...operacao.item.icms, aliquotaInterna: d('20'), aliquotaInterestadual: d('12') },
        ipi: { ...operacao.item.ipi, aliquota: d('10'), incluirNaBaseIcms: true },
      },
    };

    const resultado = calcularIcms(comIpiNaBase, d('100.00'));

    expect(resultado.bc.toFixed(2)).toBe('1100.00');
    expect(resultado.valor.toFixed(2)).toBe('132.00');
  });

  it('resulta em imposto zero quando a aliquota e zero', () => {
    const operacao = operacaoPadrao();
    const isento = {
      ...operacao,
      item: {
        ...operacao.item,
        icms: { ...operacao.item.icms, cst: '40', aliquotaInterna: d('0'), aliquotaInterestadual: d('0') },
      },
    };

    const resultado = calcularIcms(isento, d('0'));

    expect(resultado.valor.toFixed(2)).toBe('0.00');
  });
});
