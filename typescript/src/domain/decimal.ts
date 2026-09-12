import { Decimal } from 'decimal.js';

/**
 * Configuracao global do decimal.js para todo o motor tributario.
 * ROUNDING_HALF_EVEN = arredondamento bancario, o mesmo criterio que o
 * Round() do Delphi aplica sobre Currency (ver delphi/src/Tributos.Decimal.pas).
 * Precisao alta (28 digitos) evita qualquer perda em operacoes intermediarias
 * antes do arredondamento final para 2 casas.
 */
Decimal.set({ precision: 28, rounding: Decimal.ROUND_HALF_EVEN });

export { Decimal };

export function d(value: string | number | Decimal): Decimal {
  return new Decimal(value);
}

/** Arredonda para 2 casas decimais usando ROUND_HALF_EVEN (bankers' rounding). */
export function roundHalfEven2(value: Decimal): Decimal {
  return value.toDecimalPlaces(2, Decimal.ROUND_HALF_EVEN);
}

/** ABase x APercentual / 100, sem arredondar - equivalente a AplicarPercentual do Delphi. */
export function aplicarPercentual(base: Decimal, percentual: Decimal): Decimal {
  return base.times(percentual).dividedBy(100);
}
