# Revisão independente — fatia `fala-do-dono-completa`, volta 2

Mesmo papel e mesmas regras da volta 1 (`~/para-revisao/prompt-codex-fala-do-dono-completa.md`;
seu parecer v1 em `~/para-revisao/parecer-codex-fala-do-dono-completa-v1.md`).
Worktree `~/rev-fala-do-dono-completa` já em
`c691c51c5b2edbfdd4fc855651fd2b9fd95f4aef` (branch `fala-do-dono-completa`),
base `main` @ `8d55955` (merge-base). `git fetch` feito. Leia o código final com
`git show c691c51:<arquivo>`.

## O que mudou desde `85956ce` — e o que NÃO mudou
- Três commits, só texto e teste: `bb71c59` (achados do seu parecer v1),
  `a1fd787` (achado do `conferidor`), `c691c51` (achados do `revisor` no delta).
- **Nenhuma linha de CÓDIGO em `src/` mudou** — verificado pela guia:
  `git diff 85956ce..c691c51 -- src/`, filtrado das linhas de comentário, sai
  vazio. Por isso o log de mutações (`prova-mutacao-fala-do-dono-completa.log`)
  continua no cabeçalho `85956ce`, de propósito: mede o código, que é o mesmo.
  Confira você a afirmação; se achar uma linha de código no delta, é achado.
- Testes mudaram: `tests/systemPrompt.test.js` (a trava da ordem do bloco do
  prompt passou a asserir a sequência inteira — antes cobria 3 posições de 4;
  mutação medida: mover o bloco para o fim fica vermelho),
  `tests/painelMarcaAtendimento.test.js`, `tests/echoAudioDoDono.test.js`,
  `tests/identidadeEchoForma.test.js` (texto).
- Delta: `~/para-revisao/fala-do-dono-completa-delta-volta2.diff`
  (== `git diff 85956ce..c691c51`); completo: `fala-do-dono-completa.diff`
  (== `git diff 8d55955..c691c51`); commits: `commits-fala-do-dono-completa.txt`;
  relato reescrito: `relato-fala-do-dono-completa.md`.
- Suíte do implementador (WSL) e **da guia (VPS, esta worktree,
  `suite-fala-do-dono-completa-terceiro-v2.log`): 685/685 no `c691c51`, tree 0.**

## O que julgar, com escopo fechado e lupa mecânica
1. **Seu ALTA da v1:** o comentário do invariante em `src/admin/panel.js` (sítio
   da rota de envio manual) foi reescrito. Ele deixou de afirmar "todas se fecham
   sozinhas"; declara os casos SEM numerar, cada um com a direção da falha e o
   que o encerra; inclui o caso lexical do operador fora de Coexistence.
   Confira: verdadeiro contra o código? completo pelo critério que ele mesmo
   escreve ("toda escrita de `assistant` em `messages` que não passe por
   `comMarcaDeAtendimento` sob Coexistence")? O comando de enumeração dos
   escritores (`grep -rn "INSERT INTO messages" src/ | grep -v "//"`) devolve o
   que o texto diz?
2. **Um caso novo, achado pelo `revisor` na volta 2, e é o mais caro:** `pushTurn`
   grava a resposta da própria Sofia sem o helper; se o MODELO escrever o literal
   da marca na resposta dele, no turno seguinte a regra manda delegar e a cadeia
   é determinística até `silenciarPorHandoff` — marca FALSA, e silencia o contato
   por 15 min. Declarado em comentário, plano e relato como limite, sem
   mecanismo (escopo fechado), com gatilho para reabrir. Julgue a DECLARAÇÃO:
   está onde o leitor a encontra (o comentário do sítio), diz o dano certo, e o
   gatilho é observável? Não peça mecanismo; se achar que a declaração é menor
   do que o real, é achado.
3. **Seus dois BAIXA:** docblocks de `decidirFalaDoDono` e `decisaoDoEstado` com
   `audioId` e `estado`; contagens descritivas trocadas por critério ou com
   comando ao lado — inclusive "TRÊS LEITURAS", as afirmações contadas nos
   testes, e as do plano. Sobrou alguma contagem descritiva sem comando? Alguma
   distância ("N linhas acima") — que é `file:line` com outro nome?
4. **Frases irmãs:** as mensagens dos commits trazem o `grep` pelo núcleo de cada
   frase corrigida e o resultado, com ESCOPO nomeado. Reexecute os comandos.
5. O resto do código é o mesmo da v1; não precisa reler o que já confirmou,
   salvo se o delta o tocar.

## Contexto que fecha a SUPOSIÇÃO da v1
O comportamento do modelo foi medido pelo `sofia-eval` contra `85956ce` (mesmo
código): cenário 17 VERDE 3/3 com `humano_pendente: true`; controle contra a
`main` VERMELHO com agendamento criado. Não é verificável desta máquina; a guia
o conferiu pelo túnel (repo `sofia-eval` @ `dd3db17`). Trate como fato relatado
pela guia, e diga que o tratou assim.

## Nota de processo (não é achado de código)
A `main` recebeu dois commits de doc (`9c01899`, `59fd459`) entre o seu parecer
v1 e este disparo, tocando `docs/contexto/fila.md`, que a branch também altera.
`git merge-tree` de três argumentos entre `main` e `c691c51` não devolve
marcador de conflito. A base da branch continua `8d55955`.

## Suíte e saída
Rode a suíte UMA vez aqui, com cabeçalho SHA/ref/tree, depois de confirmar
`sofia_test` livre (`pid <> pg_backend_pid()`); o sandbox não grava em
`~/para-revisao/` — salve em `/tmp/` e diga o caminho, como fez na v1.
Parecer com achados (severidade + `file:line` do código final) e a última
linha "apto a deploy" ou "BLOQUEADOR: <um>", com próximos passos numerados.
