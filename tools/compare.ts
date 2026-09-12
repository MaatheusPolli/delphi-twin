import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Decimal } from 'decimal.js';

/**
 * Compara, caso a caso, os resultados de results/delphi/*.json e
 * results/ts/*.json (gerados por `delphi\bin\DelphiTwin.exe` e
 * `npm --prefix typescript run run-spec`) entre si e contra o "esperado"
 * de spec/cases/*.json, e gera report/comparison.md. RF09 - e o artefato
 * principal do post de divulgacao do projeto.
 */
const raizRepo = join(dirname(fileURLToPath(import.meta.url)), '..');
const pastaCases = join(raizRepo, 'spec', 'cases');
const pastaDelphi = join(raizRepo, 'results', 'delphi');
const pastaTs = join(raizRepo, 'results', 'ts');
const arquivoRelatorio = join(raizRepo, 'report', 'comparison.md');

type Campo = { rotulo: string; valor: string };

/**
 * Mesmo padrao de spec/schema/case.schema.json para "id". Validado aqui
 * porque o id vira nome de arquivo dentro de results/{delphi,ts}/ - um id
 * malformado (ex.: contendo "../") nao pode escapar dessas pastas.
 */
const ID_VALIDO = /^[a-z0-9]+(-[a-z0-9]+)*$/;

function validarId(id: unknown, arquivo: string): string {
  if (typeof id !== 'string' || !ID_VALIDO.test(id)) {
    throw new Error(`Caso invalido em ${arquivo}: "id" deve casar com ${ID_VALIDO} (recebido: ${JSON.stringify(id)})`);
  }
  return id;
}

function lerJsonSeExistir(caminho: string): any | undefined {
  if (!existsSync(caminho)) return undefined;
  return JSON.parse(readFileSync(caminho, 'utf8'));
}

function achatarTributoBase(prefixo: string, obj: any | undefined): Campo[] {
  if (!obj) return [];
  return [
    { rotulo: `${prefixo}.bc`, valor: obj.bc },
    { rotulo: `${prefixo}.aliquota`, valor: obj.aliquota },
    { rotulo: `${prefixo}.valor`, valor: obj.valor },
  ];
}

function achatarResultado(resultado: any | undefined): Campo[] {
  if (!resultado) return [];
  const campos: Campo[] = [
    ...achatarTributoBase('icms', resultado.icms),
    ...achatarTributoBase('ipi', resultado.ipi),
    ...achatarTributoBase('pis', resultado.pis),
    ...achatarTributoBase('cofins', resultado.cofins),
    { rotulo: 'totalTributos', valor: resultado.totalTributos },
  ];
  if (resultado.icmsSt) {
    campos.push(
      ...achatarTributoBase('icmsSt', resultado.icmsSt),
      { rotulo: 'icmsSt.mvaAplicada', valor: resultado.icmsSt.mvaAplicada },
    );
  }
  if (resultado.difal) {
    campos.push(
      { rotulo: 'difal.valorOrigem', valor: resultado.difal.valorOrigem },
      { rotulo: 'difal.valorDestino', valor: resultado.difal.valorDestino },
      { rotulo: 'difal.fcp', valor: resultado.difal.fcp },
    );
  }
  return campos;
}

function decimalIgual(a: string | undefined, b: string | undefined): boolean {
  if (a === undefined || b === undefined) return a === b;
  return new Decimal(a).equals(new Decimal(b));
}

interface DiferencaCampo {
  rotulo: string;
  delphi?: string;
  ts?: string;
}

interface ResultadoComparacaoCaso {
  id: string;
  descricao: string;
  temDelphi: boolean;
  temTs: boolean;
  identico: boolean;
  diferencas: DiferencaCampo[];
}

function compararCaso(id: string, descricao: string): ResultadoComparacaoCaso {
  const delphi = lerJsonSeExistir(join(pastaDelphi, `${id}.json`));
  const ts = lerJsonSeExistir(join(pastaTs, `${id}.json`));

  const camposDelphi = new Map(achatarResultado(delphi).map((c) => [c.rotulo, c.valor]));
  const camposTs = new Map(achatarResultado(ts).map((c) => [c.rotulo, c.valor]));

  const rotulos = new Set([...camposDelphi.keys(), ...camposTs.keys()]);
  const diferencas: DiferencaCampo[] = [];

  for (const rotulo of rotulos) {
    const valorDelphi = camposDelphi.get(rotulo);
    const valorTs = camposTs.get(rotulo);
    if (!decimalIgual(valorDelphi, valorTs)) {
      diferencas.push({ rotulo, delphi: valorDelphi, ts: valorTs });
    }
  }

  return {
    id,
    descricao,
    temDelphi: delphi !== undefined,
    temTs: ts !== undefined,
    identico: delphi !== undefined && ts !== undefined && diferencas.length === 0,
    diferencas,
  };
}

function gerarRelatorio(resultados: ResultadoComparacaoCaso[]): string {
  const linhas: string[] = [];
  linhas.push('# Relatorio de comparacao Delphi x TypeScript');
  linhas.push('');
  linhas.push(`Gerado em ${new Date().toISOString()}.`);
  linhas.push('');

  const totalCasos = resultados.length;
  const idênticos = resultados.filter((r) => r.identico).length;
  const semDelphi = resultados.filter((r) => !r.temDelphi).length;
  const semTs = resultados.filter((r) => !r.temTs).length;
  const divergentes = resultados.filter((r) => r.temDelphi && r.temTs && !r.identico).length;

  linhas.push('## Resumo');
  linhas.push('');
  linhas.push(`- Total de casos: ${totalCasos}`);
  linhas.push(`- Identicos (Delphi == TS): ${idênticos}`);
  linhas.push(`- Divergentes: ${divergentes}`);
  linhas.push(`- Sem resultado Delphi (results/delphi/*.json ausente): ${semDelphi}`);
  linhas.push(`- Sem resultado TypeScript (results/ts/*.json ausente): ${semTs}`);
  linhas.push('');

  linhas.push('## Casos');
  linhas.push('');
  linhas.push('| Caso | Delphi | TS | Status |');
  linhas.push('|------|--------|----|--------|');
  for (const r of resultados) {
    const statusDelphi = r.temDelphi ? 'OK' : '-';
    const statusTs = r.temTs ? 'OK' : '-';
    const status = !r.temDelphi || !r.temTs ? '⏳ incompleto' : r.identico ? '✅ identico' : '❌ divergente';
    linhas.push(`| \`${r.id}\` | ${statusDelphi} | ${statusTs} | ${status} |`);
  }
  linhas.push('');

  const incompletos = resultados.filter((r) => !r.temDelphi || !r.temTs);
  if (incompletos.length > 0) {
    linhas.push('## Casos incompletos');
    linhas.push('');
    linhas.push(
      'Estes casos ainda nao tem os dois lados gerados. Rode `delphi\\bin\\DelphiTwin.exe` ' +
        '(build via IDE do Delphi) e/ou `npm --prefix typescript run run-spec` para gerar os resultados faltantes.',
    );
    linhas.push('');
    for (const r of incompletos) {
      const faltando = [!r.temDelphi ? 'results/delphi' : null, !r.temTs ? 'results/ts' : null].filter(Boolean);
      linhas.push(`- \`${r.id}\`: falta ${faltando.join(' e ')}`);
    }
    linhas.push('');
  }

  const comDiferenca = resultados.filter((r) => r.temDelphi && r.temTs && r.diferencas.length > 0);
  if (comDiferenca.length > 0) {
    linhas.push('## Divergencias');
    linhas.push('');
    for (const r of comDiferenca) {
      linhas.push(`### ${r.id}`);
      linhas.push('');
      linhas.push(r.descricao);
      linhas.push('');
      linhas.push('| Campo | Delphi | TypeScript |');
      linhas.push('|-------|--------|------------|');
      for (const d of r.diferencas) {
        linhas.push(`| ${d.rotulo} | ${d.delphi ?? '_ausente_'} | ${d.ts ?? '_ausente_'} |`);
      }
      linhas.push('');
    }
  }

  return linhas.join('\n');
}

function main(): void {
  const arquivosCase = readdirSync(pastaCases)
    .filter((f) => f.endsWith('.json'))
    .sort();

  const resultados = arquivosCase.map((arquivo) => {
    const caso = JSON.parse(readFileSync(join(pastaCases, arquivo), 'utf8'));
    const id = validarId(caso.id, arquivo);
    return compararCaso(id, caso.descricao);
  });

  const relatorio = gerarRelatorio(resultados);
  mkdirSync(dirname(arquivoRelatorio), { recursive: true });
  writeFileSync(arquivoRelatorio, relatorio, 'utf8');

  console.log(relatorio);
  console.log(`\nRelatorio gravado em ${arquivoRelatorio}`);

  const algumDivergente = resultados.some((r) => r.temDelphi && r.temTs && !r.identico);
  if (algumDivergente) {
    process.exitCode = 1;
  }
}

main();
