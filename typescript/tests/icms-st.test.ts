import { describe, expect, it } from 'vitest';
import { d } from '../src/domain/decimal.js';
import { calcularIcmsSt } from '../src/tributos/icms-st.js';
import { operacaoPadrao } from './helpers.js';

describe('calcularIcmsSt', () => {
  it('nao ajusta a MVA em operacao interna', () => {
    const operacao = operacaoPadrao();
    const comSt = {
      ...operacao,
      item: { ...operacao.item, frete: d('50'), icms: { ...operacao.item.icms, mva: d('40') } },
    };

    const resultado = calcularIcmsSt(comSt, d('0'), d('189.00'));

    expect(resultado.mvaAplicada.toFixed(2)).toBe('40.00');
    expect(resultado.bc.toFixed(2)).toBe('1470.00');
  });

  it('ajusta a MVA pela formula do Convenio 52/2017 em operacao interestadual', () => {
    // Exemplo classico de literatura tributaria: MVA original 40%, aliquota
    // interna do destino 18%, aliquota interestadual 12% => MVA ajustada 50.24%.
    const operacao = operacaoPadrao();
    const comSt = {
      ...operacao,
      ufDestino: 'MG' as const,
      item: {
        ...operacao.item,
        frete: d('50'),
        icms: { ...operacao.item.icms, mva: d('40'), aliquotaInterna: d('18'), aliquotaInterestadual: d('12') },
      },
    };

    const resultado = calcularIcmsSt(comSt, d('0'), d('126.00'));

    expect(resultado.mvaAplicada.toFixed(2)).toBe('50.24');
    expect(resultado.bc.toFixed(2)).toBe('1577.52');
  });

  it('subtrai o ICMS proprio do valor de BC_ST x aliquota', () => {
    const operacao = operacaoPadrao();
    const comSt = {
      ...operacao,
      ufDestino: 'MG' as const,
      item: {
        ...operacao.item,
        frete: d('50'),
        icms: { ...operacao.item.icms, mva: d('40'), aliquotaInterna: d('18'), aliquotaInterestadual: d('12') },
      },
    };

    const resultado = calcularIcmsSt(comSt, d('0'), d('126.00'));

    expect(resultado.valor.toFixed(2)).toBe('157.95');
  });

  it('rejeita aliquota interna de destino >= 100% em vez de propagar Infinity', () => {
    const operacao = operacaoPadrao();
    const invalida = {
      ...operacao,
      ufDestino: 'MG' as const,
      item: {
        ...operacao.item,
        icms: { ...operacao.item.icms, mva: d('40'), aliquotaInterna: d('100'), aliquotaInterestadual: d('12') },
      },
    };

    expect(() => calcularIcmsSt(invalida, d('0'), d('126.00'))).toThrow(/deve ser menor que 100/);
  });
});
