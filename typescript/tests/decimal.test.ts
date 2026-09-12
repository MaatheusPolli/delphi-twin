import { describe, expect, it } from 'vitest';
import { aplicarPercentual, d, roundHalfEven2 } from '../src/domain/decimal.js';

describe('roundHalfEven2', () => {
  it('arredonda para baixo quando abaixo do meio', () => {
    expect(roundHalfEven2(d('10.124')).toString()).toBe('10.12');
  });

  it('arredonda para cima quando acima do meio', () => {
    expect(roundHalfEven2(d('10.126')).toString()).toBe('10.13');
  });

  it.each([
    ['4.995', '5'],
    ['4.985', '4.98'],
    ['0.005', '0'],
    ['0.015', '0.02'],
    ['1.025', '1.02'],
  ])('empate exato %s vai para o vizinho par -> %s', (entrada, esperado) => {
    expect(roundHalfEven2(d(entrada)).toString()).toBe(esperado);
  });
});

describe('aplicarPercentual', () => {
  it('calcula proporcao simples', () => {
    expect(aplicarPercentual(d('100'), d('18')).toString()).toBe('18');
  });

  it('zero por cento resulta em zero', () => {
    expect(aplicarPercentual(d('1000'), d('0')).toString()).toBe('0');
  });
});
