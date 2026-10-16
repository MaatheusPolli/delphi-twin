# Delphi Twin

Migração de um motor de cálculo tributário (ICMS, ICMS-ST, IPI, PIS/COFINS,
DIFAL) de **Delphi** para **TypeScript**, com a mesma suíte de testes
provando — caso a caso — que as duas implementações calculam exatamente o
mesmo imposto.

> 📄 Projeto de portfólio com licença dupla (MIT para uso pessoal e
> educacional, licença comercial para uso comercial). Veja a seção
> [Licença](#licença) e o arquivo [LICENSE](LICENSE).

## 1. Visão geral

**Delphi Twin** é um projeto de demonstração técnica que resolve um problema
muito concreto do mercado de ERP/software fiscal brasileiro: **como migrar
um módulo de cálculo de impostos de um sistema legado (Delphi) para uma
stack moderna (TypeScript) sem introduzir uma regressão silenciosa no
cálculo do imposto**.

O repositório contém **duas implementações independentes** do mesmo motor de
cálculo tributário — ICMS (próprio e substituição tributária), IPI,
PIS/COFINS e DIFAL — uma em Object Pascal (Delphi) e outra em TypeScript, e
uma **suíte de testes compartilhada** (`spec/cases/*.json`) que ambas devem
satisfazer, byte a byte, valor a valor. Um relatório automático
(`report/comparison.md`) compara os resultados das duas implementações caso
a caso e prova que elas concordam.

### O problema que isso demonstra

Reescrever um sistema é fácil de descrever e difícil de fazer com segurança.
O risco real de uma migração de regras de negócio — especialmente regras
fiscais, onde um arredondamento diferente ou uma fórmula ligeiramente errada
gera nota fiscal rejeitada, imposto pago a maior ou passivo tributário — não
está em "traduzir a sintaxe" de uma linguagem para outra. Está em **mudar o
comportamento sem perceber**: um `Round()` que arredonda diferente, uma base
de cálculo que esquece de somar o frete, uma condição `>` que devia ser
`>=`. Nenhuma dessas coisas aparece em uma revisão de código superficial;
todas aparecem quando as duas implementações rodam o mesmo caso e os
resultados divergem.

### A solução: characterization testing

Este projeto aplica, na prática, a técnica de **characterization tests**
(Michael Feathers, *Working Effectively with Legacy Code*): antes de
reescrever, **capture o comportamento atual em testes**; só depois
reimplemente, guiado por esses testes, até que a nova implementação
concorde com a antiga em todos os casos.

Aqui isso significa:

1. As fórmulas fiscais foram implementadas **primeiro em Delphi**
   (o "legado").
2. Os valores esperados de cada caso de teste foram derivados dessas
   fórmulas — capturando o comportamento exato, não uma reinterpretação
   dele.
3. A implementação em **TypeScript** foi escrita depois, olhando apenas
   para a especificação de casos (nunca para o código Delphi diretamente),
   e validada contra os mesmos casos.
4. Um relatório de comparação automatizado prova, caso a caso, que as duas
   implementações concordam — e continuará provando isso a cada mudança
   futura em qualquer um dos dois lados, via CI.

### Objetivos deste projeto

- Servir como peça de portfólio demonstrando Delphi (Object Pascal)
  certificado e TypeScript moderno **no mesmo repositório, resolvendo o
  mesmo problema**.
- Demonstrar uma metodologia de migração segura — não apenas "reescrevi e
  parece funcionar", mas "reescrevi e tenho prova automatizada de que o
  comportamento é idêntico".
- Mostrar domínio de regras fiscais brasileiras reais (ICMS, ICMS-ST com
  MVA ajustada, DIFAL, PIS/COFINS) com a base legal de cada fórmula
  documentada no próprio código.
- Servir de material para um post técnico ("como migrar um legado sem
  quebrar o cálculo do imposto").

### Fora de escopo (v1)

Este é um projeto de demonstração de metodologia, não um produto fiscal
completo: não há persistência, UI, nem integração com ERP. A v1 cobre
cenários representativos (parametrizados por alíquota, MVA, redução de
base), não a tabela completa de todos os 27 estados e todas as exceções da
legislação tributária brasileira — isso é reconhecido explicitamente como
limitação, não como lacuna escondida.

## 2. Arquitetura

```
                 ┌───────────────────────┐
                 │  spec/cases/*.json    │  ← fonte da verdade
                 │  (schema em spec/schema)
                 └──────┬──────────┬─────┘
                        │          │
        ┌───────────────▼──┐   ┌──▼───────────────────┐
        │ delphi/           │   │ typescript/           │
        │  src/Tributos.*   │   │  src/tributos/*.ts    │
        │  tests/ (DUnitX)  │   │  tests/ (Vitest)      │
        │  → results/delphi │   │  → results/ts         │
        └───────────────┬──┘   └──┬───────────────────┘
                        │          │
                 ┌──────▼──────────▼─────┐
                 │   tools/compare.ts    │ → report/comparison.md
                 └────────────────────────┘
```

### Estrutura de pastas

```
delphi-twin/
├── LICENSE                     # licença dupla (MIT pessoal + comercial)
├── spec/
│   ├── schema/                 # JSON Schema (operacao, resultado, case)
│   └── cases/                  # 11 casos de teste compartilhados
├── delphi/
│   ├── DelphiTwin.dpr/.dproj    # executa a spec e grava results/delphi/*.json
│   ├── src/Tributos.*.pas       # o motor tributario (tipos, decimal, calculadoras)
│   └── tests/                   # suite DUnitX + runner alternativo em Free Pascal
│       └── fpc-runner/           # RunSpecFPC.dpr - roda de verdade sem IDE
├── typescript/
│   ├── src/                     # espelho funcional do motor Delphi
│   └── tests/                   # suite Vitest (39 testes)
├── tools/
│   ├── validate-spec.ts         # valida spec/cases/*.json contra o schema
│   └── compare.ts               # compara results/delphi vs results/ts
├── results/                     # saida das execucoes (gitignored)
├── report/comparison.md         # relatorio gerado, commitado como evidencia
└── .github/workflows/           # CI para os dois lados
```

## 3. Modelo de domínio

O mesmo modelo é espelhado, campo a campo, nas duas linguagens
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

Todo valor decimal — monetário ou percentual — trafega como **string** no
JSON da spec (nunca `number`), justamente para não reintroduzir o erro de
ponto flutuante binário que este projeto existe para evitar.

## 4. Fórmulas e base legal

Todo valor monetário usa `Currency` no Delphi (ponto fixo de 4 casas
decimais, imune ao erro de representação binária do `Double`) e
`decimal.js` no TypeScript, ambos configurados com **arredondamento
bancário** (`ROUND_HALF_EVEN`) — o mesmo critério que o `Round()` nativo do
Delphi aplica sobre `Currency` (ver
[`Tributos.Decimal.pas`](delphi/src/Tributos.Decimal.pas) /
[`domain/decimal.ts`](typescript/src/domain/decimal.ts)).

| Tributo | Base de cálculo | Base legal |
|---|---|---|
| **ICMS próprio** | `ValorProduto − Desconto + Frete + Seguro + Outras` (+ IPI, se compuser a base). Redução de BC aplicada antes do imposto, se houver. Alíquota interna se a operação for dentro do mesmo estado; interestadual caso contrário — vale tanto para venda a contribuinte quanto a não contribuinte, pois o DIFAL absorve a diferença. | Art. 13, LC 87/1996 |
| **ICMS-ST** | `BC_ST = (BaseICMS + IPI) × (1 + MVA/100)`. MVA original se a operação for interna; **MVA ajustada** se interestadual: `[(1+MVA/100)×(1−AliqInter/100)/(1−AliqIntra/100) − 1] × 100`. `Valor = BC_ST × AliqInterna − ICMS próprio` (nunca negativo). | Convênios ICMS 142/2018 e 52/2017 |
| **IPI** | `ValorProduto − Desconto + Frete + Seguro + Outras` × alíquota. | Art. 190, RIPI/2010 |
| **PIS/COFINS** | Mesma base do IPI × alíquota do regime (cumulativo: 0,65%/3,00%; não cumulativo: 1,65%/7,60% — configuráveis por caso). | Leis 9.718/1998, 10.637/2002, 10.833/2003 |
| **DIFAL** | Só para interestadual a **não contribuinte** (EC 87/2015). `(AliqInterna_destino − AliqInterestadual) × BaseICMS`, 100% ao destino desde 2019; FCP sobre a mesma base. | EC 87/2015, Convênio ICMS 236/2021 |

Cada fórmula está comentada no código-fonte com a referência legal completa.

## 5. Casos da spec (`spec/cases/`)

| Caso | Cobre |
|---|---|
| `icms-00-simples` | ICMS CST 00, operação interna simples |
| `icms-20-reducao-bc` | Redução de base de cálculo (CST 20) |
| `icms-st-mva` | ICMS-ST interno, MVA sem ajuste |
| `icms-st-mva-ajustada` | ICMS-ST interestadual, MVA ajustada (Convênio 52/2017) — exemplo clássico 40%→50,24% |
| `ipi-na-base-icms` | IPI compondo a base do ICMS (venda a não contribuinte, dispara também DIFAL) |
| `difal-nao-contribuinte` | DIFAL + FCP para consumidor final não contribuinte |
| `pis-cofins-cumulativo` | Regime cumulativo (0,65%/3,00%) |
| `pis-cofins-nao-cumulativo` | Regime não cumulativo (1,65%/7,60%) |
| `arredondamento-limite` | Empate exato de arredondamento (x,xx5) — prova ROUND_HALF_EVEN |
| `icms-40-isento` | Alíquota zero / isenção |
| `base-frete-seguro-desconto` | Frete, seguro, desconto e outras despesas compondo a base |

## 6. Como rodar

### TypeScript (Vitest)

Requer **Node.js ≥ 22.12** (declarado em `typescript/package.json` →
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

> **Delphi 12 Community Edition não compila via linha de comando** (`dcc32`
> recusa com "This version of the product does not support command line
> compiling"). A suíte DUnitX completa (com leitura de `spec/cases/*.json`
> via `System.JSON`) só roda pela IDE:

1. Abra `delphi/tests/DelphiTwinTests.dproj` no Delphi 12 (ou compatível).
2. Compile e rode (F9). O runner de console do DUnitX mostra os resultados;
   `Tests.Spec.pas` valida os 11 casos de `spec/cases/*.json`.
3. Para gerar `results/delphi/*.json` via Delphi de verdade, abra e rode
   `delphi/DelphiTwin.dproj`.

**Alternativa sem IDE, usando Free Pascal** (compila o **mesmo
código-fonte** de `delphi/src/*.pas`, em modo Delphi) — é o que este
repositório usa de fato, já que o ambiente onde ele foi desenvolvido não
tem uma licença de Delphi que compile via CLI:

```bash
# instala o FPC uma unica vez (Windows, via winget)
winget install --id FreePascal.FreePascalCompiler

cd delphi/tests/fpc-runner
fpc -Mdelphi -Sc -FEout -FUout RunSpecFPC.dpr
./out/RunSpecFPC.exe
```

`RunSpecFPC.dpr` roda o `TMotorTributario` contra os 11 casos (replicados
como literais Pascal, já que o FPC não tem equivalente de `System.JSON`),
grava `results/delphi/*.json` e — mais importante — **prova em tempo de
execução** que `Round()` sobre `Currency` se comporta como
`ROUND_HALF_EVEN` também fora da IDE, e que uma entrada inválida (alíquota
interna ≥ 100%) é rejeitada com um erro claro em vez de travar
silenciosamente. `.github/workflows/delphi.yml` roda exatamente isso em CI.

### Comparação e validação da spec

```bash
npm ci                        # na raiz do repo
npm run validate-spec         # valida spec/cases/*.json contra o JSON Schema (Ajv)
npm run compare                # compara results/delphi/*.json x results/ts/*.json
                                # e gera report/comparison.md
```

## 7. Qualidade, testes e segurança

Este projeto passou por uma revisão dedicada de correção e segurança, com os
seguintes resultados e decisões registrados:

**Testes executados de verdade** (não apenas escritos):

- TypeScript: **39 testes Vitest** (unitários por calculadora + `spec.test.ts`
  rodando os 11 casos compartilhados), `tsc --noEmit` em modo `strict`, e
  ESLint — todos passando.
- Delphi: **104 verificações via Free Pascal Compiler** (o mesmo
  código-fonte de `delphi/src/*.pas`, compilado em modo Delphi), incluindo
  a prova em tempo de execução de que `Round()` sobre `Currency` arredonda
  em `ROUND_HALF_EVEN`.
- **11 de 11 casos idênticos** entre as duas implementações
  (`report/comparison.md`), zero divergências.

**Problema real encontrado e corrigido durante a revisão**: a fórmula de
MVA ajustada (`Tributos.IcmsST` / `icms-st.ts`) divide por
`(1 − AliqIntra/100)`. Com uma alíquota interna de destino de 100% (entrada
inválida, mas não impedida pelo schema), o lado Delphi lançava
`EZeroDivide`, enquanto o `decimal.js` do lado TypeScript retornava
`Infinity` **silenciosamente** e propagava esse valor pelo resto do
cálculo sem erro nenhum — exatamente o tipo de divergência de comportamento
que este projeto existe para capturar. Corrigido com uma validação
explícita e simétrica nos dois lados, que rejeita a entrada com uma
mensagem de erro clara (`Calcular_AliquotaInternaCemPorCento_LancaExcecao`
no DUnitX, teste equivalente no Vitest, e verificação #104 no runner FPC).

**Hardening aplicado**: o campo `id` de cada caso da spec é usado para
montar nomes de arquivo em `results/{delphi,ts}/<id>.json`. Um `id`
malformado (por exemplo, contendo `../`) poderia, em tese, escapar da pasta
de resultados pretendida. Ainda que os arquivos de `spec/cases/` sejam
sempre conteúdo do próprio repositório (não input de usuário não confiável),
foi adicionada validação explícita do formato do `id`
(`^[a-z0-9]+(-[a-z0-9]+)*$`) em `typescript/src/spec-loader.ts`,
`tools/compare.ts` e `Tributos.SpecLoader.pas`, como defesa em profundidade.

**Dependências**: `npm audit` está limpo (**0 vulnerabilidades**) em ambos
`package.json` (raiz e `typescript/`). O Vitest foi atualizado de 2.x para
5.x especificamente para eliminar 5 vulnerabilidades conhecidas (1 crítica,
1 alta, 3 moderadas) em dependências transitivas do dev-server do Vite —
risco baixo na prática (exigiria rodar o dev-server do Vite, o que este
projeto nunca faz, apenas o executor de testes), mas corrigido porque havia
correção disponível. Essa atualização elevou o requisito mínimo de Node
para `>=22.12.0`, refletido em `engines` e no CI.

**Limitação documentada e aceita conscientemente**: os valores decimais da
spec são limitados a no máximo 4 casas decimais (`spec/schema/*.json`),
porque o `Currency` do Delphi tem exatamente essa precisão nativa — um
valor com mais casas seria truncado/arredondado silenciosamente ao
converter para `Currency`, mas manteria precisão total do lado TypeScript
antes do arredondamento final, divergindo entre as duas implementações. O
schema agora impõe esse limite explicitamente em vez de deixar a
divergência acontecer silenciosamente em algum caso futuro.

**O que ainda não foi verificado**: a suíte DUnitX completa
(`DelphiTwinTests.dproj`) e `Tributos.SpecLoader.pas`/`DelphiTwin.dproj`
(que dependem de `System.JSON`/`System.IOUtils`, sem equivalente direto no
Free Pascal) nunca rodaram de fato numa IDE Delphi — só foram revisados
manualmente e comparados byte a byte com a implementação TypeScript
equivalente. Como é o **mesmo arquivo-fonte** que compila e passa via FPC,
a confiança de que também compilará e passará na IDE é alta, mas não é uma
certeza absoluta enquanto ninguém rodar `F9` de fato.

## 8. Status e Definition of Done

- [x] Schema JSON + 11 casos de teste compartilhados.
- [x] Motor tributário completo (ICMS, ICMS-ST, IPI, PIS/COFINS, DIFAL) nas
      duas linguagens.
- [x] 100% dos casos da spec passando em Delphi (via FPC) e TypeScript
      (Vitest).
- [x] `report/comparison.md` sem divergências, commitado.
- [x] `tools/validate-spec.ts` valida os 11 casos contra o JSON Schema.
- [x] CI para os dois lados (`.github/workflows/{ts,delphi}.yml`).
- [x] Revisão de segurança e correção (ver seção 7) — 0 vulnerabilidades
      npm, 1 bug de divergência real encontrado e corrigido, hardening de
      path traversal aplicado.
- [x] README com visão geral, arquitetura, fórmulas e status.
- [x] Licença dupla (MIT pessoal + comercial) definida em `LICENSE`.
- [ ] Suíte DUnitX completa e `DelphiTwin.dproj` rodados numa IDE Delphi
      real (hoje validados via Free Pascal — ver seção 7).
- [ ] Post de divulgação — publicação externa, fica a critério de quem for
      divulgar o projeto.

## 9. Autor

Projeto pessoal de portfólio de Matheus Gasparotto Polli.

## Licença

Este projeto usa **licença dupla**. O texto completo está em [LICENSE](LICENSE).

- **Uso pessoal, educacional e não comercial:** livre, nos termos da licença MIT (mantenha o aviso de copyright).
- **Uso comercial:** exige licença comercial. Isso inclui usar em produto ou serviço comercial, vender acesso ou derivados, usar em atividades com fins lucrativos e implantar em empresas.

Contato para licença comercial: ma.polli@hotmail.com
