import { describe, expect, it } from 'vitest';
import { d } from '../src/domain/decimal.js';
import { calcularDifal, difalAplicavel } from '../src/tributos/difal.js';
import { operacaoPadrao } from './helpers.js';

describe('difalAplicavel', () => {
  it('e verdadeiro para operacao interestadual a nao contribuinte', () => {
    const operacao = operacaoPadrao();
    const alvo = { ...operacao, ufDestino: 'RJ' as const, destinatarioContribuinte: false };
    expect(difalAplicavel(alvo)).toBe(true);
  });

  it('e falso para operacao interna', () => {
    const operacao = operacaoPadrao();
    const alvo = { ...operacao, destinatarioContribuinte: false };
    expect(difalAplicavel(alvo)).toBe(false);
  });

  it('e falso para operacao interestadual a contribuinte', () => {
    const operacao = operacaoPadrao();
    const alvo = { ...operacao, ufDestino: 'RJ' as const, destinatarioContribuinte: true };
    expect(difalAplicavel(alvo)).toBe(false);
  });
});

describe('calcularDifal', () => {
  it('atribui o valor integral ao destino, com FCP', () => {
    const operacao = operacaoPadrao();
    const alvo = {
      ...operacao,
      ufDestino: 'RJ' as const,
      destinatarioContribuinte: false,
      item: {
        ...operacao.item,
        icms: { ...operacao.item.icms, aliquotaInterna: d('20'), aliquotaInterestadual: d('12'), fcp: d('2') },
      },
    };

    const resultado = calcularDifal(alvo, d('1000.00'));

    expect(resultado.valorOrigem.toFixed(2)).toBe('0.00');
    expect(resultado.valorDestino.toFixed(2)).toBe('80.00');
    expect(resultado.fcp.toFixed(2)).toBe('20.00');
  });
});
