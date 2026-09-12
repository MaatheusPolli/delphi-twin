# Delphi Twin

Modernização de um módulo de cálculo tributário (ICMS, ICMS-ST, IPI, PIS/COFINS)
de Delphi para TypeScript, com **a mesma suíte de testes** validando as duas
implementações — uma demonstração prática de *characterization testing*
(Michael Feathers) aplicada a uma migração de sistema legado.

O risco de migrar um sistema fiscal não é reescrever — é **mudar o
comportamento sem perceber**. Um arredondamento diferente gera nota fiscal
rejeitada ou imposto pago a mais. Este repositório ataca esse risco na raiz:
os dois lados (`delphi/` e `typescript/`) são obrigados a passar exatamente
pelos mesmos casos de teste, definidos uma única vez em `spec/cases/*.json`.

## Estrutura

```
delphi-twin/
├── spec/           # fonte da verdade: schema JSON + casos de teste
├── delphi/         # implementacao "legado" (Object Pascal + DUnitX)
├── typescript/     # implementacao "moderna" (TypeScript + Vitest)
├── tools/          # validate-spec.ts e compare.ts
├── results/        # saida das duas execucoes (gitignored)
└── report/         # comparison.md, gerado por tools/compare.ts
```

Veja [planejamento.md](planejamento.md) para o desenho completo (requisitos,
arquitetura, roadmap).

## Como rodar

### TypeScript (Vitest)

```bash
cd typescript
npm install
npm test              # roda a suite Vitest, incluindo spec.test.ts
npm run typecheck
npm run lint
npm run run-spec      # calcula todos os casos e grava results/ts/*.json
```

### Delphi (DUnitX na IDE, ou Free Pascal via linha de comando)

> **Delphi 12 Community Edition não compila via linha de comando** (`dcc32`
> recusa com "This version of the product does not support command line
> compiling"). A suíte DUnitX completa (com leitura de `spec/cases/*.json`
> via `System.JSON`) só roda pela IDE:

1. Abra `delphi/tests/DelphiTwinTests.dproj` no Delphi 12 (ou compatível).
2. Compile e rode (F9). O runner de console do DUnitX mostra os resultados
   e `Tests.Spec.pas` valida os 11 casos de `spec/cases/*.json`.
3. Para gerar `results/delphi/*.json` via Delphi de verdade, abra e rode
   `delphi/DelphiTwin.dproj`.

**Alternativa sem IDE, usando Free Pascal** (mesmo código-fonte de
`delphi/src/*.pas`, compilado em modo Delphi): é o que este repositório usa
de fato, já que o ambiente onde ele foi desenvolvido não tem uma licença de
Delphi que compile via CLI.

```bash
# instala o FPC (Windows, via winget) uma unica vez
winget install --id FreePascal.FreePascalCompiler

cd delphi/tests/fpc-runner
fpc -Mdelphi -Sc -FEout -FUout RunSpecFPC.dpr
./out/RunSpecFPC.exe
```

`RunSpecFPC.dpr` roda o `TMotorTributario` contra os 11 casos (replicados
como literais Pascal, já que o FPC não tem equivalente de `System.JSON`),
grava `results/delphi/*.json` e — mais importante — **prova em tempo de
execução** que `Round()` sobre `Currency` se comporta como
`ROUND_HALF_EVEN` também fora da IDE. `.github/workflows/delphi.yml` roda
exatamente isso em CI.

### Comparação e validação da spec

```bash
npm install                  # na raiz do repo
npm run validate-spec        # valida spec/cases/*.json contra o JSON Schema
npm run compare              # compara results/delphi/*.json x results/ts/*.json
                              # e gera report/comparison.md
```

## Metodologia: characterization testing

1. As fórmulas foram implementadas primeiro em Delphi (`delphi/src/Tributos.*.pas`).
2. Os valores `esperado` de cada caso em `spec/cases/*.json` foram calculados
   à mão, passo a passo, seguindo exatamente essas fórmulas (documentado nos
   comentários de cada unit) — o passo de *characterization*.
3. A implementação em TypeScript (`typescript/src/tributos/*.ts`) foi escrita
   depois, guiada apenas pela spec, e verificada com Vitest: **os 38 testes
   passam**, incluindo os 11 casos compartilhados batendo com os valores
   calculados na etapa 2.
4. O lado Delphi foi verificado de verdade compilando `delphi/src/*.pas` com
   o Free Pascal Compiler (`delphi/tests/fpc-runner/RunSpecFPC.dpr`) — **103
   verificações, 0 falhas**, incluindo a prova em tempo de execução de que
   `Round()` sobre `Currency` arredonda em `ROUND_HALF_EVEN`.
5. `npm run compare` fecha o ciclo: **11 de 11 casos idênticos** entre
   `results/delphi/*.json` e `results/ts/*.json`, zero divergências — ver
   [`report/comparison.md`](report/comparison.md).

## Fórmulas e base legal

Todo valor monetário usa `Currency` no Delphi (ponto fixo, imune a erro de
representação binária) e `decimal.js` no TypeScript, ambos configurados com
arredondamento bancário (**ROUND_HALF_EVEN**) — o mesmo critério que o
`Round()` nativo do Delphi aplica sobre `Currency` (ver
[`Tributos.Decimal.pas`](delphi/src/Tributos.Decimal.pas)).

| Tributo | Base de cálculo | Base legal |
|---|---|---|
| **ICMS próprio** | `ValorProduto − Desconto + Frete + Seguro + Outras` (+ IPI, se compuser a base), com redução de BC se houver. Alíquota interna se a operação for dentro do mesmo estado; interestadual caso contrário. | Art. 13, LC 87/1996 |
| **ICMS-ST** | `(BaseICMS + IPI) × (1 + MVA/100)`. MVA original se a operação for interna; **MVA ajustada** se interestadual: `[(1+MVA/100)×(1−AliqInter/100)/(1−AliqIntra/100) − 1] × 100`. `Valor = BC_ST × AliqInterna − ICMS próprio`. | Convênios ICMS 142/2018 e 52/2017 |
| **IPI** | `ValorProduto − Desconto + Frete + Seguro + Outras` × alíquota. | Art. 190, RIPI/2010 |
| **PIS/COFINS** | Mesma base do IPI × alíquota do regime (cumulativo: 0,65%/3,00%; não cumulativo: 1,65%/7,60% — configuráveis por caso). | Leis 9.718/1998, 10.637/2002, 10.833/2003 |
| **DIFAL** | Só para interestadual a **não contribuinte**. `(AliqInterna_destino − AliqInterestadual) × BaseICMS`, 100% ao destino desde 2019; FCP sobre a mesma base. | EC 87/2015, Convênio ICMS 236/2021 |

## Casos da spec (`spec/cases/`)

| Caso | Cobre |
|---|---|
| `icms-00-simples` | ICMS CST 00, operação interna simples |
| `icms-20-reducao-bc` | Redução de base de cálculo (CST 20) |
| `icms-st-mva` | ICMS-ST interno, MVA sem ajuste |
| `icms-st-mva-ajustada` | ICMS-ST interestadual, MVA ajustada (Convênio 52/2017) — exemplo clássico 40%→50,24% |
| `ipi-na-base-icms` | IPI compondo a base do ICMS (venda a não contribuinte) |
| `difal-nao-contribuinte` | DIFAL + FCP para consumidor final não contribuinte |
| `pis-cofins-cumulativo` | Regime cumulativo (0,65%/3,00%) |
| `pis-cofins-nao-cumulativo` | Regime não cumulativo (1,65%/7,60%) |
| `arredondamento-limite` | Empate exato de arredondamento (x,xx5) — prova ROUND_HALF_EVEN |
| `icms-40-isento` | Alíquota zero / isenção |
| `base-frete-seguro-desconto` | Frete, seguro, desconto e outras despesas compondo a base |

## Status atual

- [x] Etapa 1 — schema JSON + 11 casos iniciais
- [x] Etapa 2 — Delphi: tipos, decimal, ICMS/IPI/PIS-COFINS + DUnitX
- [x] Etapa 3 — Delphi: ICMS-ST, DIFAL, motor, spec runner; valores esperados calculados
- [x] Etapa 4 — TypeScript completo, guiado pela spec, 38 testes verificados
- [x] Etapa 5 — `tools/validate-spec.ts`, `tools/compare.ts`, CI dos dois lados
- [x] Etapa 6 — README; **`report/comparison.md` fechado, 11 de 11 casos idênticos**

### Definition of Done (planejamento.md, seção 9)

- [x] 100% dos cases da spec passando em Delphi (via FPC, mesmo código-fonte)
      e TypeScript (Vitest).
- [x] `report/comparison.md` sem divergências, commitado.
- [x] `tools/validate-spec.ts` valida os 11 casos contra o JSON Schema.
- [x] README com fórmulas e base legal.
- [ ] A suíte DUnitX completa (`DelphiTwinTests.dproj`) e o `DelphiTwin.dproj`
      baseado em `System.JSON` ainda não foram rodados numa IDE Delphi real —
      só via Free Pascal (que valida o mesmo código-fonte, mas não exercita
      `Tributos.SpecLoader` nem os asserts do DUnitX). Ver nota abaixo.
- [ ] Post no LinkedIn — publicação externa, fica a critério de quem for
      divulgar o projeto.

### Sobre a compilação Delphi

Este projeto foi desenvolvido numa máquina com **Delphi 12 Community
Edition**, que recusa compilar via linha de comando ("This version of the
product does not support command line compiling") — só a IDE compila.
Para validar o código de verdade sem depender de clicar em F9, o
`delphi/src/*.pas` (o motor tributário em si) foi compilado e executado com
o **Free Pascal Compiler** em modo Delphi — o mesmo fallback que
`planejamento.md` já previa. O resultado (103 verificações, 0 falhas, e os
11 casos gerando `results/delphi/*.json` idênticos ao TypeScript) dá alta
confiança de que o código compila e se comporta como esperado também no
Delphi real, já que é o **mesmo arquivo-fonte** nos dois compiladores.
`Tributos.SpecLoader.pas` (usa `System.JSON`/`System.IOUtils`, sem
equivalente direto no FPC) e a suíte DUnitX continuam precisando da IDE.
