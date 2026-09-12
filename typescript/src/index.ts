import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { calcularTributos } from './tributos/motor.js';
import { carregarCasoDeArquivo, listarArquivosDeCasos, resultadoParaJson } from './spec-loader.js';

/**
 * Executor da spec: le cada spec/cases/*.json, calcula o ResultadoTributos
 * via calcularTributos e grava o resultado em results/ts/<id>.json.
 * E o lado "moderno" do par comparado por tools/compare.ts (RF08/RF09).
 */
function localizarRaizDoRepo(inicio: string): string {
  let atual = inicio;
  for (let nivel = 0; nivel <= 6; nivel++) {
    if (existsSync(join(atual, 'spec'))) {
      return atual;
    }
    const pai = dirname(atual);
    if (pai === atual) break;
    atual = pai;
  }
  throw new Error(`Nao foi possivel localizar a pasta spec/ a partir de ${inicio}`);
}

function main(): void {
  const aqui = dirname(fileURLToPath(import.meta.url));
  const raizRepo = localizarRaizDoRepo(aqui);

  const pastaCases = join(raizRepo, 'spec', 'cases');
  const pastaResultados = join(raizRepo, 'results', 'ts');
  mkdirSync(pastaResultados, { recursive: true });

  let total = 0;
  for (const arquivo of listarArquivosDeCasos(pastaCases)) {
    const caso = carregarCasoDeArquivo(arquivo);
    const resultado = calcularTributos(caso.entrada);

    const json = JSON.stringify(resultadoParaJson(resultado), null, 2);
    writeFileSync(join(pastaResultados, `${caso.id}.json`), json, 'utf8');

    total++;
    console.log('OK ', caso.id);
  }

  console.log(`${total} caso(s) processado(s). Resultados em ${pastaResultados}`);
}

main();
