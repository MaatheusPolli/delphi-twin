import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import Ajv from 'ajv';

/**
 * Valida todo spec/cases/*.json contra spec/schema/case.schema.json
 * (que referencia operacao.schema.json e resultado.schema.json). RF08.
 */
const raizRepo = join(dirname(fileURLToPath(import.meta.url)), '..');
const pastaSchema = join(raizRepo, 'spec', 'schema');
const pastaCases = join(raizRepo, 'spec', 'cases');

function lerJson(caminho: string): unknown {
  return JSON.parse(readFileSync(caminho, 'utf8'));
}

function main(): void {
  const ajv = new Ajv({ allErrors: true, strict: true });

  ajv.addSchema(lerJson(join(pastaSchema, 'operacao.schema.json')) as object);
  ajv.addSchema(lerJson(join(pastaSchema, 'resultado.schema.json')) as object);
  const validateCaso = ajv.compile(lerJson(join(pastaSchema, 'case.schema.json')) as object);

  const arquivos = readdirSync(pastaCases)
    .filter((f) => f.endsWith('.json'))
    .sort();

  let totalErros = 0;
  for (const arquivo of arquivos) {
    const caminho = join(pastaCases, arquivo);
    const caso = lerJson(caminho);
    const valido = validateCaso(caso);

    if (valido) {
      console.log(`OK   ${arquivo}`);
    } else {
      totalErros++;
      console.log(`FAIL ${arquivo}`);
      for (const erro of validateCaso.errors ?? []) {
        console.log(`     ${erro.instancePath || '/'} ${erro.message}`);
      }
    }
  }

  console.log('');
  if (totalErros > 0) {
    console.log(`${totalErros} de ${arquivos.length} caso(s) invalido(s).`);
    process.exitCode = 1;
  } else {
    console.log(`${arquivos.length} caso(s) validado(s) com sucesso contra o schema.`);
  }
}

main();
