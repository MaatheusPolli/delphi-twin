import { d } from '../src/domain/decimal.js';
import type { OperacaoFiscal } from '../src/domain/types.js';

/** Fabrica de OperacaoFiscal com valores padrao sensatos - espelha delphi/tests/Tests.Helpers.pas. */
export function operacaoPadrao(): OperacaoFiscal {
  return {
    ufOrigem: 'SP',
    ufDestino: 'SP',
    destinatarioContribuinte: true,
    regimeEmitente: 'normal',
    item: {
      valorProduto: d('1000'),
      quantidade: d('1'),
      frete: d('0'),
      seguro: d('0'),
      desconto: d('0'),
      outras: d('0'),
      ipi: { aliquota: d('0'), cst: '53', incluirNaBaseIcms: false },
      icms: { cst: '00', aliquotaInterna: d('18'), aliquotaInterestadual: d('18') },
      pisCofins: {
        regime: 'cumulativo',
        cstPis: '01',
        cstCofins: '01',
        aliquotaPis: d('0.65'),
        aliquotaCofins: d('3'),
      },
    },
  };
}
