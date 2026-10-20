import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { Decimal } from 'decimal.js';
import { d } from '../src/domain/decimal.js';
import { carregarCasoDeArquivo, listarArquivosDeCasos } from '../src/spec-loader.js';
import { calcularTributos } from '../src/tributos/motor.js';
import type { ResultadoTributos, TributoBase } from '../src/domain/types.js';

/**
 * Roda TODOS os casos de spec/cases/*.json que ja tenham "esperado"
 * preenchido, passando cada "entrada" por calcularTributos e comparando
 * campo a campo com tolerancia zero (RF08/RF09). Equivalente TS de
 * delphi/tests/Tests.Spec.pas - e a suite que prova que a spec
 * compartilhada e respeitada tambem do lado moderno.
 */
const aqui = dirname(fileURLToPath(import.meta.url));
const pastaCases = join(aqui, '..', '..', 'spec', 'cases');

function expectTributoBase(rotulo: string, esperado: TributoBase, obtido: TributoBase): void {
  expect(obtido.bc.toString(), `${rotulo}.bc`).toBe(esperado.bc.toString());
  expect(obtido.aliquota.toString(), `${rotulo}.aliquota`).toBe(esperado.aliquota.toString());
  expect(obtido.valor.toString(), `${rotulo}.valor`).toBe(esperado.valor.toString());
}

function expectDecimalIgual(rotulo: string, esperado: Decimal, obtido: Decimal): void {
  expect(obtido.toString(), rotulo).toBe(esperado.toString());
}

function expectResultadoIgual(esperado: ResultadoTributos, obtido: ResultadoTributos): void {
  expectTributoBase('icms', esperado.icms, obtido.icms);
  expectTributoBase('ipi', esperado.ipi, obtido.ipi);
  expectTributoBase('pis', esperado.pis, obtido.pis);
  expectTributoBase('cofins', esperado.cofins, obtido.cofins);
  expectDecimalIgual('totalTributos', esperado.totalTributos, obtido.totalTributos);

  expect(!!obtido.icmsSt, 'presenca de icmsSt').toBe(!!esperado.icmsSt);
  if (esperado.icmsSt && obtido.icmsSt) {
    expectTributoBase('icmsSt', esperado.icmsSt, obtido.icmsSt);
    expectDecimalIgual('icmsSt.mvaAplicada', esperado.icmsSt.mvaAplicada, obtido.icmsSt.mvaAplicada);
  }

  expectDecimalIgual('icmsDesonerado', esperado.icmsDesonerado ?? d(0), obtido.icmsDesonerado ?? d(0));

  expect(!!obtido.fcp, 'presenca de fcp').toBe(!!esperado.fcp);
  if (esperado.fcp && obtido.fcp) {
    expectTributoBase('fcp', esperado.fcp, obtido.fcp);
  }

  expect(!!obtido.difal, 'presenca de difal').toBe(!!esperado.difal);
  if (esperado.difal && obtido.difal) {
    expectDecimalIgual('difal.valorOrigem', esperado.difal.valorOrigem, obtido.difal.valorOrigem);
    expectDecimalIgual('difal.valorDestino', esperado.difal.valorDestino, obtido.difal.valorDestino);
    expectDecimalIgual('difal.fcp', esperado.difal.fcp, obtido.difal.fcp);
  }
}

const arquivos = listarArquivosDeCasos(pastaCases);

describe('spec/cases (characterization tests)', () => {
  it('encontrou ao menos um caso de teste', () => {
    expect(arquivos.length).toBeGreaterThan(0);
  });

  for (const arquivo of arquivos) {
    const caso = carregarCasoDeArquivo(arquivo);
    if (!caso.esperado) continue;

    it(`${caso.id}: ${caso.descricao}`, () => {
      const obtido = calcularTributos(caso.entrada);
      expectResultadoIgual(caso.esperado!, obtido);
    });
  }
});
