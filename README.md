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

### Delphi (DUnitX)

> **Delphi 12 Community Edition não compila via linha de comando** (`dcc32`
> recusa com "This version of the product does not support command line
> compiling"). Por isso, o build precisa ser feito na IDE:

1. Abra `delphi/tests/DelphiTwinTests.dproj` no Delphi 12 (ou compatível).
2. Compile e rode (F9). O runner de console do DUnitX mostra os resultados
   e `Tests.Spec.pas` valida os 11 casos de `spec/cases/*.json`.
3. Para gerar `results/delphi/*.json` (usado pela comparação), abra e rode
   `delphi/DelphiTwin.dproj` — ele executa a spec e grava um JSON por caso.

O fallback de CI documentado (`.github/workflows/delphi.yml`) usa o Free
Pascal Compiler apenas para um *compile-check* do núcleo de regras fiscais
(units que dependem só de `System.SysUtils`); a suíte DUnitX completa
depende da IDE ou de um runner com licença de build headless.

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
4. Quando o Delphi puder ser compilado neste ambiente (via IDE), rodar
   `DelphiTwin.dproj` produz `results/delphi/*.json`, e `npm run compare`
   fecha o ciclo comparando os dois lados byte a byte.

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
- [ ] Etapa 6 — build Delphi real (via IDE) para gerar `results/delphi/*.json` e fechar o `report/comparison.md` sem divergências; post de divulgação

O lado Delphi foi escrito e revisado com o mesmo rigor do lado TypeScript,
mas **ainda não foi compilado neste ambiente** — o Delphi 12 Community
Edition instalado aqui recusa build via linha de comando, e não há Free
Pascal instalado como alternativa. Assim que alguém abrir
`delphi/tests/DelphiTwinTests.dproj` na IDE e rodar os testes, o
`report/comparison.md` pode ser regenerado com os dois lados completos.
