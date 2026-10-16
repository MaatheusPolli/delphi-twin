# Delphi Twin

MigraÃ§Ã£o de um motor de cÃ¡lculo tributÃ¡rio (ICMS, ICMS-ST, IPI, PIS/COFINS,
DIFAL) de **Delphi** para **TypeScript**, com a mesma suÃ­te de testes
provando â€” caso a caso â€” que as duas implementaÃ§Ãµes calculam exatamente o
mesmo imposto.

> ðŸ“„ Projeto de portfÃ³lio. Ver [LICENSE](LICENSE) â€” todos os direitos
> reservados â€” antes de reutilizar qualquer parte do cÃ³digo.

## 1. VisÃ£o geral

**Delphi Twin** Ã© um projeto de demonstraÃ§Ã£o tÃ©cnica que resolve um problema
muito concreto do mercado de ERP/software fiscal brasileiro: **como migrar
um mÃ³dulo de cÃ¡lculo de impostos de um sistema legado (Delphi) para uma
stack moderna (TypeScript) sem introduzir uma regressÃ£o silenciosa no
cÃ¡lculo do imposto**.

O repositÃ³rio contÃ©m **duas implementaÃ§Ãµes independentes** do mesmo motor de
cÃ¡lculo tributÃ¡rio â€” ICMS (prÃ³prio e substituiÃ§Ã£o tributÃ¡ria), IPI,
PIS/COFINS e DIFAL â€” uma em Object Pascal (Delphi) e outra em TypeScript, e
uma **suÃ­te de testes compartilhada** (`spec/cases/*.json`) que ambas devem
satisfazer, byte a byte, valor a valor. Um relatÃ³rio automÃ¡tico
(`report/comparison.md`) compara os resultados das duas implementaÃ§Ãµes caso
a caso e prova que elas concordam.

### O problema que isso demonstra

Reescrever um sistema Ã© fÃ¡cil de descrever e difÃ­cil de fazer com seguranÃ§a.
O risco real de uma migraÃ§Ã£o de regras de negÃ³cio â€” especialmente regras
fiscais, onde um arredondamento diferente ou uma fÃ³rmula ligeiramente errada
gera nota fiscal rejeitada, imposto pago a maior ou passivo tributÃ¡rio â€” nÃ£o
estÃ¡ em "traduzir a sintaxe" de uma linguagem para outra. EstÃ¡ em **mudar o
comportamento sem perceber**: um `Round()` que arredonda diferente, uma base
de cÃ¡lculo que esquece de somar o frete, uma condiÃ§Ã£o `>` que devia ser
`>=`. Nenhuma dessas coisas aparece em uma revisÃ£o de cÃ³digo superficial;
todas aparecem quando as duas implementaÃ§Ãµes rodam o mesmo caso e os
resultados divergem.

### A soluÃ§Ã£o: characterization testing

Este projeto aplica, na prÃ¡tica, a tÃ©cnica de **characterization tests**
(Michael Feathers, *Working Effectively with Legacy Code*): antes de
reescrever, **capture o comportamento atual em testes**; sÃ³ depois
reimplemente, guiado por esses testes, atÃ© que a nova implementaÃ§Ã£o
concorde com a antiga em todos os casos.

Aqui isso significa:

1. As fÃ³rmulas fiscais foram implementadas **primeiro em Delphi**
   (o "legado").
2. Os valores esperados de cada caso de teste foram derivados dessas
   fÃ³rmulas â€” capturando o comportamento exato, nÃ£o uma reinterpretaÃ§Ã£o
   dele.
3. A implementaÃ§Ã£o em **TypeScript** foi escrita depois, olhando apenas
   para a especificaÃ§Ã£o de casos (nunca para o cÃ³digo Delphi diretamente),
   e validada contra os mesmos casos.
4. Um relatÃ³rio de comparaÃ§Ã£o automatizado prova, caso a caso, que as duas
   implementaÃ§Ãµes concordam â€” e continuarÃ¡ provando isso a cada mudanÃ§a
   futura em qualquer um dos dois lados, via CI.

### Objetivos deste projeto

- Servir como peÃ§a de portfÃ³lio demonstrando Delphi (Object Pascal)
  certificado e TypeScript moderno **no mesmo repositÃ³rio, resolvendo o
  mesmo problema**.
- Demonstrar uma metodologia de migraÃ§Ã£o segura â€” nÃ£o apenas "reescrevi e
  parece funcionar", mas "reescrevi e tenho prova automatizada de que o
  comportamento Ã© idÃªntico".
- Mostrar domÃ­nio de regras fiscais brasileiras reais (ICMS, ICMS-ST com
  MVA ajustada, DIFAL, PIS/COFINS) com a base legal de cada fÃ³rmula
  documentada no prÃ³prio cÃ³digo.
- Servir de material para um post tÃ©cnico ("como migrar um legado sem
  quebrar o cÃ¡lculo do imposto").

### Fora de escopo (v1)

Este Ã© um projeto de demonstraÃ§Ã£o de metodologia, nÃ£o um produto fiscal
completo: nÃ£o hÃ¡ persistÃªncia, UI, nem integraÃ§Ã£o com ERP. A v1 cobre
cenÃ¡rios representativos (parametrizados por alÃ­quota, MVA, reduÃ§Ã£o de
base), nÃ£o a tabela completa de todos os 27 estados e todas as exceÃ§Ãµes da
legislaÃ§Ã£o tributÃ¡ria brasileira â€” isso Ã© reconhecido explicitamente como
limitaÃ§Ã£o, nÃ£o como lacuna escondida.

## 2. Arquitetura

```
                 â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
                 â”‚  spec/cases/*.json    â”‚  â† fonte da verdade
                 â”‚  (schema em spec/schema)
                 â””â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”˜
                        â”‚          â”‚
        â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”   â”Œâ”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
        â”‚ delphi/           â”‚   â”‚ typescript/           â”‚
        â”‚  src/Tributos.*   â”‚   â”‚  src/tributos/*.ts    â”‚
        â”‚  tests/ (DUnitX)  â”‚   â”‚  tests/ (Vitest)      â”‚
        â”‚  â†’ results/delphi â”‚   â”‚  â†’ results/ts         â”‚
        â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”˜   â””â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                        â”‚          â”‚
                 â”Œâ”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”
                 â”‚   tools/compare.ts    â”‚ â†’ report/comparison.md
                 â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

### Estrutura de pastas

```
delphi-twin/
â”œâ”€â”€ LICENSE                     # todos os direitos reservados
â”œâ”€â”€ planejamento.md             # plano original do projeto (requisitos, roadmap)
â”œâ”€â”€ spec/
â”‚   â”œâ”€â”€ schema/                 # JSON Schema (operacao, resultado, case)
â”‚   â””â”€â”€ cases/                  # 11 casos de teste compartilhados
â”œâ”€â”€ delphi/
â”‚   â”œâ”€â”€ DelphiTwin.dpr/.dproj    # executa a spec e grava results/delphi/*.json
â”‚   â”œâ”€â”€ src/Tributos.*.pas       # o motor tributario (tipos, decimal, calculadoras)
â”‚   â””â”€â”€ tests/                   # suite DUnitX + runner alternativo em Free Pascal
â”‚       â””â”€â”€ fpc-runner/           # RunSpecFPC.dpr - roda de verdade sem IDE
â”œâ”€â”€ typescript/
â”‚   â”œâ”€â”€ src/                     # espelho funcional do motor Delphi
â”‚   â””â”€â”€ tests/                   # suite Vitest (39 testes)
â”œâ”€â”€ tools/
â”‚   â”œâ”€â”€ validate-spec.ts         # valida spec/cases/*.json contra o schema
â”‚   â””â”€â”€ compare.ts               # compara results/delphi vs results/ts
â”œâ”€â”€ results/                     # saida das execucoes (gitignored)
â”œâ”€â”€ report/comparison.md         # relatorio gerado, commitado como evidencia
â””â”€â”€ .github/workflows/           # CI para os dois lados
```

## 3. Modelo de domÃ­nio

O mesmo modelo Ã© espelhado, campo a campo, nas duas linguagens
(`TOperacaoFiscal`/`TResultadoTributos` em Delphi;
`OperacaoFiscal`/`ResultadoTributos` em TypeScript):

```ts
interface OperacaoFiscal {
  ufOrigem: UF; ufDestino: UF;
  destinatarioContribuinte: boolean;
  regimeEmitente: 'normal' | 'simples';
  item: {
    valorProduto: Decimal; quantidade: Decimal;
    frete: Decimal; seguro: Decimal; desconto: Decimal; outras: Decimal;
    ipi: { aliquota: Decimal; cst: string; incluirNaBaseIcms?: boolean };
    icms: { cst: string; aliquotaInterna: Decimal; aliquotaInterestadual: Decimal;
            reducaoBC?: Decimal; mva?: Decimal; reducaoBCST?: Decimal; fcp?: Decimal };
    pisCofins: { regime: 'cumulativo' | 'nao-cumulativo'; cstPis: string; cstCofins: string;
                 aliquotaPis: Decimal; aliquotaCofins: Decimal };
  };
}
```

Todo valor decimal â€” monetÃ¡rio ou percentual â€” trafega como **string** no
JSON da spec (nunca `number`), justamente para nÃ£o reintroduzir o erro de
ponto flutuante binÃ¡rio que este projeto existe para evitar.

## 4. FÃ³rmulas e base legal

Todo valor monetÃ¡rio usa `Currency` no Delphi (ponto fixo de 4 casas
decimais, imune ao erro de representaÃ§Ã£o binÃ¡ria do `Double`) e
`decimal.js` no TypeScript, ambos configurados com **arredondamento
bancÃ¡rio** (`ROUND_HALF_EVEN`) â€” o mesmo critÃ©rio que o `Round()` nativo do
Delphi aplica sobre `Currency` (ver
[`Tributos.Decimal.pas`](delphi/src/Tributos.Decimal.pas) /
[`domain/decimal.ts`](typescript/src/domain/decimal.ts)).

| Tributo | Base de cÃ¡lculo | Base legal |
|---|---|---|
| **ICMS prÃ³prio** | `ValorProduto âˆ’ Desconto + Frete + Seguro + Outras` (+ IPI, se compuser a base). ReduÃ§Ã£o de BC aplicada antes do imposto, se houver. AlÃ­quota interna se a operaÃ§Ã£o for dentro do mesmo estado; interestadual caso contrÃ¡rio â€” vale tanto para venda a contribuinte quanto a nÃ£o contribuinte, pois o DIFAL absorve a diferenÃ§a. | Art. 13, LC 87/1996 |
| **ICMS-ST** | `BC_ST = (BaseICMS + IPI) Ã— (1 + MVA/100)`. MVA original se a operaÃ§Ã£o for interna; **MVA ajustada** se interestadual: `[(1+MVA/100)Ã—(1âˆ’AliqInter/100)/(1âˆ’AliqIntra/100) âˆ’ 1] Ã— 100`. `Valor = BC_ST Ã— AliqInterna âˆ’ ICMS prÃ³prio` (nunca negativo). | ConvÃªnios ICMS 142/2018 e 52/2017 |
| **IPI** | `ValorProduto âˆ’ Desconto + Frete + Seguro + Outras` Ã— alÃ­quota. | Art. 190, RIPI/2010 |
| **PIS/COFINS** | Mesma base do IPI Ã— alÃ­quota do regime (cumulativo: 0,65%/3,00%; nÃ£o cumulativo: 1,65%/7,60% â€” configurÃ¡veis por caso). | Leis 9.718/1998, 10.637/2002, 10.833/2003 |
| **DIFAL** | SÃ³ para interestadual a **nÃ£o contribuinte** (EC 87/2015). `(AliqInterna_destino âˆ’ AliqInterestadual) Ã— BaseICMS`, 100% ao destino desde 2019; FCP sobre a mesma base. | EC 87/2015, ConvÃªnio ICMS 236/2021 |

Cada fÃ³rmula estÃ¡ comentada no cÃ³digo-fonte com a referÃªncia legal completa.

## 5. Casos da spec (`spec/cases/`)

| Caso | Cobre |
|---|---|
| `icms-00-simples` | ICMS CST 00, operaÃ§Ã£o interna simples |
| `icms-20-reducao-bc` | ReduÃ§Ã£o de base de cÃ¡lculo (CST 20) |
| `icms-st-mva` | ICMS-ST interno, MVA sem ajuste |
| `icms-st-mva-ajustada` | ICMS-ST interestadual, MVA ajustada (ConvÃªnio 52/2017) â€” exemplo clÃ¡ssico 40%â†’50,24% |
| `ipi-na-base-icms` | IPI compondo a base do ICMS (venda a nÃ£o contribuinte, dispara tambÃ©m DIFAL) |
| `difal-nao-contribuinte` | DIFAL + FCP para consumidor final nÃ£o contribuinte |
| `pis-cofins-cumulativo` | Regime cumulativo (0,65%/3,00%) |
| `pis-cofins-nao-cumulativo` | Regime nÃ£o cumulativo (1,65%/7,60%) |
| `arredondamento-limite` | Empate exato de arredondamento (x,xx5) â€” prova ROUND_HALF_EVEN |
| `icms-40-isento` | AlÃ­quota zero / isenÃ§Ã£o |
| `base-frete-seguro-desconto` | Frete, seguro, desconto e outras despesas compondo a base |

## 6. Como rodar

### TypeScript (Vitest)

Requer **Node.js â‰¥ 22.12** (declarado em `typescript/package.json` â†’
`engines`).

```bash
cd typescript
npm ci
npm test              # suite Vitest completa (39 testes), incluindo spec.test.ts
npm run typecheck     # tsc --noEmit, modo strict
npm run lint          # ESLint
npm run run-spec      # calcula todos os casos e grava results/ts/*.json
```

### Delphi (DUnitX na IDE, ou Free Pascal via linha de comando)

> **Delphi 12 Community Edition nÃ£o compila via linha de comando** (`dcc32`
> recusa com "This version of the product does not support command line
> compiling"). A suÃ­te DUnitX completa (com leitura de `spec/cases/*.json`
> via `System.JSON`) sÃ³ roda pela IDE:

1. Abra `delphi/tests/DelphiTwinTests.dproj` no Delphi 12 (ou compatÃ­vel).
2. Compile e rode (F9). O runner de console do DUnitX mostra os resultados;
   `Tests.Spec.pas` valida os 11 casos de `spec/cases/*.json`.
3. Para gerar `results/delphi/*.json` via Delphi de verdade, abra e rode
   `delphi/DelphiTwin.dproj`.

**Alternativa sem IDE, usando Free Pascal** (compila o **mesmo
cÃ³digo-fonte** de `delphi/src/*.pas`, em modo Delphi) â€” Ã© o que este
repositÃ³rio usa de fato, jÃ¡ que o ambiente onde ele foi desenvolvido nÃ£o
tem uma licenÃ§a de Delphi que compile via CLI:

```bash
# instala o FPC uma unica vez (Windows, via winget)
winget install --id FreePascal.FreePascalCompiler

cd delphi/tests/fpc-runner
fpc -Mdelphi -Sc -FEout -FUout RunSpecFPC.dpr
./out/RunSpecFPC.exe
```

`RunSpecFPC.dpr` roda o `TMotorTributario` contra os 11 casos (replicados
como literais Pascal, jÃ¡ que o FPC nÃ£o tem equivalente de `System.JSON`),
grava `results/delphi/*.json` e â€” mais importante â€” **prova em tempo de
execuÃ§Ã£o** que `Round()` sobre `Currency` se comporta como
`ROUND_HALF_EVEN` tambÃ©m fora da IDE, e que uma entrada invÃ¡lida (alÃ­quota
interna â‰¥ 100%) Ã© rejeitada com um erro claro em vez de travar
silenciosamente. `.github/workflows/delphi.yml` roda exatamente isso em CI.

### ComparaÃ§Ã£o e validaÃ§Ã£o da spec

```bash
npm ci                        # na raiz do repo
npm run validate-spec         # valida spec/cases/*.json contra o JSON Schema (Ajv)
npm run compare                # compara results/delphi/*.json x results/ts/*.json
                                # e gera report/comparison.md
```

## 7. Qualidade, testes e seguranÃ§a

Este projeto passou por uma revisÃ£o dedicada de correÃ§Ã£o e seguranÃ§a, com os
seguintes resultados e decisÃµes registrados:

**Testes executados de verdade** (nÃ£o apenas escritos):

- TypeScript: **39 testes Vitest** (unitÃ¡rios por calculadora + `spec.test.ts`
  rodando os 11 casos compartilhados), `tsc --noEmit` em modo `strict`, e
  ESLint â€” todos passando.
- Delphi: **104 verificaÃ§Ãµes via Free Pascal Compiler** (o mesmo
  cÃ³digo-fonte de `delphi/src/*.pas`, compilado em modo Delphi), incluindo
  a prova em tempo de execuÃ§Ã£o de que `Round()` sobre `Currency` arredonda
  em `ROUND_HALF_EVEN`.
- **11 de 11 casos idÃªnticos** entre as duas implementaÃ§Ãµes
  (`report/comparison.md`), zero divergÃªncias.

**Problema real encontrado e corrigido durante a revisÃ£o**: a fÃ³rmula de
MVA ajustada (`Tributos.IcmsST` / `icms-st.ts`) divide por
`(1 âˆ’ AliqIntra/100)`. Com uma alÃ­quota interna de destino de 100% (entrada
invÃ¡lida, mas nÃ£o impedida pelo schema), o lado Delphi lanÃ§ava
`EZeroDivide`, enquanto o `decimal.js` do lado TypeScript retornava
`Infinity` **silenciosamente** e propagava esse valor pelo resto do
cÃ¡lculo sem erro nenhum â€” exatamente o tipo de divergÃªncia de comportamento
que este projeto existe para capturar. Corrigido com uma validaÃ§Ã£o
explÃ­cita e simÃ©trica nos dois lados, que rejeita a entrada com uma
mensagem de erro clara (`Calcular_AliquotaInternaCemPorCento_LancaExcecao`
no DUnitX, teste equivalente no Vitest, e verificaÃ§Ã£o #104 no runner FPC).

**Hardening aplicado**: o campo `id` de cada caso da spec Ã© usado para
montar nomes de arquivo em `results/{delphi,ts}/<id>.json`. Um `id`
malformado (por exemplo, contendo `../`) poderia, em tese, escapar da pasta
de resultados pretendida. Ainda que os arquivos de `spec/cases/` sejam
sempre conteÃºdo do prÃ³prio repositÃ³rio (nÃ£o input de usuÃ¡rio nÃ£o confiÃ¡vel),
foi adicionada validaÃ§Ã£o explÃ­cita do formato do `id`
(`^[a-z0-9]+(-[a-z0-9]+)*$`) em `typescript/src/spec-loader.ts`,
`tools/compare.ts` e `Tributos.SpecLoader.pas`, como defesa em profundidade.

**DependÃªncias**: `npm audit` estÃ¡ limpo (**0 vulnerabilidades**) em ambos
`package.json` (raiz e `typescript/`). O Vitest foi atualizado de 2.x para
5.x especificamente para eliminar 5 vulnerabilidades conhecidas (1 crÃ­tica,
1 alta, 3 moderadas) em dependÃªncias transitivas do dev-server do Vite â€”
risco baixo na prÃ¡tica (exigiria rodar o dev-server do Vite, o que este
projeto nunca faz, apenas o executor de testes), mas corrigido porque havia
correÃ§Ã£o disponÃ­vel. Essa atualizaÃ§Ã£o elevou o requisito mÃ­nimo de Node
para `>=22.12.0`, refletido em `engines` e no CI.

**LimitaÃ§Ã£o documentada e aceita conscientemente**: os valores decimais da
spec sÃ£o limitados a no mÃ¡ximo 4 casas decimais (`spec/schema/*.json`),
porque o `Currency` do Delphi tem exatamente essa precisÃ£o nativa â€” um
valor com mais casas seria truncado/arredondado silenciosamente ao
converter para `Currency`, mas manteria precisÃ£o total do lado TypeScript
antes do arredondamento final, divergindo entre as duas implementaÃ§Ãµes. O
schema agora impÃµe esse limite explicitamente em vez de deixar a
divergÃªncia acontecer silenciosamente em algum caso futuro.

**O que ainda nÃ£o foi verificado**: a suÃ­te DUnitX completa
(`DelphiTwinTests.dproj`) e `Tributos.SpecLoader.pas`/`DelphiTwin.dproj`
(que dependem de `System.JSON`/`System.IOUtils`, sem equivalente direto no
Free Pascal) nunca rodaram de fato numa IDE Delphi â€” sÃ³ foram revisados
manualmente e comparados byte a byte com a implementaÃ§Ã£o TypeScript
equivalente. Como Ã© o **mesmo arquivo-fonte** que compila e passa via FPC,
a confianÃ§a de que tambÃ©m compilarÃ¡ e passarÃ¡ na IDE Ã© alta, mas nÃ£o Ã© uma
certeza absoluta enquanto ninguÃ©m rodar `F9` de fato.

## 8. Status e Definition of Done

- [x] Schema JSON + 11 casos de teste compartilhados.
- [x] Motor tributÃ¡rio completo (ICMS, ICMS-ST, IPI, PIS/COFINS, DIFAL) nas
      duas linguagens.
- [x] 100% dos casos da spec passando em Delphi (via FPC) e TypeScript
      (Vitest).
- [x] `report/comparison.md` sem divergÃªncias, commitado.
- [x] `tools/validate-spec.ts` valida os 11 casos contra o JSON Schema.
- [x] CI para os dois lados (`.github/workflows/{ts,delphi}.yml`).
- [x] RevisÃ£o de seguranÃ§a e correÃ§Ã£o (ver seÃ§Ã£o 7) â€” 0 vulnerabilidades
      npm, 1 bug de divergÃªncia real encontrado e corrigido, hardening de
      path traversal aplicado.
- [x] README com visÃ£o geral, arquitetura, fÃ³rmulas e status.
- [x] LicenÃ§a de todos os direitos reservados.
- [ ] SuÃ­te DUnitX completa e `DelphiTwin.dproj` rodados numa IDE Delphi
      real (hoje validados via Free Pascal â€” ver seÃ§Ã£o 7).
- [ ] Post de divulgaÃ§Ã£o â€” publicaÃ§Ã£o externa, fica a critÃ©rio de quem for
      divulgar o projeto.

## 9. Autor e licenÃ§a

Projeto pessoal de portfÃ³lio. Consulte [planejamento.md](planejamento.md)
para o plano original completo (requisitos funcionais/nÃ£o funcionais,
roadmap detalhado). Todos os direitos reservados â€” ver
[LICENSE](LICENSE) para os termos completos de uso.


## Licença

### Uso Pessoal
Este projeto é licenciado sob a **Licença MIT** para uso pessoal, educacional e não comercial.

### Uso Comercial
Se você deseja usar este projeto comercialmente, deve obter uma licença comercial do autor.

**Uso comercial inclui:**
- Incorporar em um produto comercial
- Oferecer como serviço
- Usar em atividades com fins lucrativos
- Implantação empresarial

**Para obter uma licença comercial:**
Email: ma.polli@hotmail.com
