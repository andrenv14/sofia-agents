# Revisão independente — fatia `fala-do-dono-completa`, volta 1

Você é o revisor independente (papel fixo, AGENTS.md "Protocolo de revisão de
diff"). Worktree preparada pela guia: `~/rev-fala-do-dono-completa`, já em
`85956ce83df1fec9fd5c2807914bf8eb9aa79c98` (branch `fala-do-dono-completa`),
base `main` @ `8d55955`. `git fetch` já feito. Leia o código final com
`git show 85956ce:<arquivo>`; o pacote em `~/para-revisao/` é cópia do WSL e
pode divergir da branch — se divergir, vale a branch (a guia conferiu por
`cmp` e blob: `~/para-revisao/conferir-pacote-fdc.sh`, saída "PACOTE CONFERIDO").

## Pacote
- `~/para-revisao/fala-do-dono-completa.diff` (== `git diff 8d55955..85956ce`)
- `~/para-revisao/commits-fala-do-dono-completa.txt` (7 commits)
- `~/para-revisao/relato-fala-do-dono-completa.md`
- plano: `git show 85956ce:docs/plans/fala-do-dono-completa.md` (versionado no
  1º commit da branch; reescrito em `1ae1b1e` para o desenho real)
- `~/para-revisao/suite-fala-do-dono-completa.log` — medição de quem implementou
  (WSL): 685/685, cabeçalho com SHA e `tree: 0`
- `~/para-revisao/prova-mutacao-fala-do-dono-completa.log` — nove mutações, todas
  vermelhas, no SHA final
- `~/para-revisao/suite-fala-do-dono-completa-terceiro.log` — **medição da guia**
  (VPS, esta worktree): **684/685**. A única falha é
  `tests/bsuid.test.js` 5e ("dois BSUIDs longos com o MESMO começo não colapsam"),
  duas linhas de log esperadas em ordem trocada. É o flake de ordenação já
  registrado em `docs/contexto/fila.md` ("Flake novo de ordenação em
  `tests/bsuid.test.js`", visto por você mesmo na VPS em 04/09), ambiental sob
  contenção (a suíte levou 236 s aqui). O diff desta fatia não toca esse teste
  nem a linha crítica do BSUID (`git diff 8d55955..85956ce -- tests/bsuid.test.js`
  vazio). Isolado na mesma worktree: 13/13 em duas rodadas
  (`~/para-revisao/bsuid-rerun-1.log`, `-2.log`). Julgue você se isso basta.

## Escopo FECHADO pelo fundador — o que julgar
O plano foi aprovado pelo fundador e reescrito para o que o código faz. Com
escopo fechado a lupa é MECÂNICA: "o que o texto durável afirma é verdade sobre o
código que está aí, e os limites declarados são completos e honestos?" — nunca
"existe desenho melhor". Gravidade pela CONSEQUÊNCIA (paciente, dado ou operador
enganado = ALTA; diagnóstico suprimido = não).

Peças a verificar no código final:
1. **A marca** `MARCA_ATENDIMENTO` (`src/coex/marcaAtendimento.js`, módulo folha) é
   prefixo de TODA linha escrita pela mão da clínica pelos DOIS escritores —
   `registrarFalaDoDono` (`src/session/sessionStore.js`) e a rota de envio manual
   do painel (`src/admin/panel.js`), esta só sob `tenant.coexistencia`. Confira
   que não existe terceiro escritor de `role='assistant'` que represente fala
   humana e fique sem marca (`grep -n "'assistant'" src/`).
2. **O bloco do prompt** em `buildSystemPrompt` (`src/ai/systemPrompt.js`):
   condicionado a `tenant.coexistencia`, interpola a constante, qualifica o PAPEL
   da linha (o `revisor` derrubou uma versão que dizia "toda linha do histórico" e
   abria injeção pelo paciente escrevendo o prefixo). O fixture
   `tests/fixtures/systemPrompt-referencia.txt` não muda para tenant sem
   Coexistence.
3. **O bloqueador do `revisor`, corrigido em `5b779d9`:** toda desreferência de
   campo do echo (inclusive `audio.*`) dentro de `decidirFalaDoDono` cai entre o
   `try` e o `catch`; fora dele só `id`, `to`, `to_user_id`. Receita declarada no
   código: `grep -nE "\b(echo|audioCru)\?*\." src/server.js`. Confirme que a
   receita existe UMA vez e que o grep não devolve desreferência fora da regra.
4. **Fallback do áudio** provado porta a porta (metadados recusados, bytes
   recusados, `audio` sem `id`, `audio` não-objeto, transcrição vazia → linha com
   o marcador, sem lançar, sem tocar o silêncio). A baixabilidade da mídia de echo
   está DECLARADA como não medida — julgue a declaração, não a ausência.
5. **A propriedade por reflexão** em `tests/identidadeEchoForma.test.js`: eixos
   de `Object.keys(decisao.estado)`, `ilegivel` dentro do produto; as mutações
   M6/M7/M8 do log. `decisaoDoEstado` passou a devolver `estado`
   (`grep -rn "\.estado\b" src/ tests/` — só o teste lê).
6. **As quatro dívidas do parecer v7** (`3bb64cd`): "PISO" fora de plano, docblock
   e relato (o commit traz `grep -rniE "\bpiso\b"` e o resultado — reexecute);
   "mesmo segundo = mesmo lote" fora da fila; comentário "só descrições" corrigido.
7. **As três exceções do invariante** ("a marca só aparece em histórico cujo
   prompt a explica") declaradas juntas no comentário do sítio: verdadeiras e
   completas? Existe uma quarta que o código produz e o texto não nomeia?
8. **Ordem gravada pode inverter durante a transcrição** e **não tem trava de
   teste** — limites declarados no relato e no código. Honestos? O caso é o que o
   texto diz?

## O que NÃO julgar aqui
- **O comportamento do MODELO** (a Sofia de fato delegar) é medido pelo
  `sofia-eval`, cenário 17, em paralelo a esta revisão, em outra máquina.
  Marque como SUPOSIÇÃO o que depender disso; a guia junta os dois pareceres.
- Achado sobre código que a fatia só EXERCITA (não escreveu) vai como "fora de
  escopo, registrar", não como bloqueador — dois já estão na `fila.md`
  (`jaMencionadoAntes` por substring; mídia bloqueando o laço de `changes`).

## Suíte
Rode UMA vez aqui (`npm run test:agent`), com o cabeçalho de SHA/ref/tree, saída
em `~/para-revisao/suite-codex-fala-do-dono-completa.log`. Antes, confirme que
ninguém usa `sofia_test` excluindo a sua conexão (`pid <> pg_backend_pid()`).

## Saída
Parecer em `~/para-revisao/parecer-codex-fala-do-dono-completa.md`: o que leu,
achados com severidade e `file:line` do código final, e a última linha
"apto a deploy" ou "BLOQUEADOR: <um>", com próximos passos numerados.
