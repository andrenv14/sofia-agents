# Revisão independente — fatia `fala-do-dono-completa`, volta 3

Mesmo papel e regras das voltas 1 e 2 (`prompt-codex-fala-do-dono-completa.md`,
`-v2.md`; seus pareceres `parecer-codex-fala-do-dono-completa-v1.md` e `-v2.md`).
Worktree `~/rev-fala-do-dono-completa` em
`eb843cf929b67b975d43cf5700846628eac2ab20`, base `main` @ `8d55955`
(merge-base; a `main` corrente é `59fd459`, só doc, merge-tree sem conflito).
`git fetch` feito. Código final por `git show eb843cf:<arquivo>`.

## O que mudou desde `c691c51` (seu parecer v2)
Três commits: `daa03a0`, `cca1685`, `eb843cf`. Delta:
`~/para-revisao/fala-do-dono-completa-delta-volta3.diff` (== `git diff c691c51..eb843cf`).
**Uma mudança de CÓDIGO, decidida pelo fundador na janela da guia:** o `finally`
de `processarBuffer` (`src/server.js`) passa a emitir
`[silencio] [<slug>] escalonamento: contato <mascarado> silenciado até <hora local>, …`
quando `silenciarPorHandoff` resolve — hoje um handoff bem-sucedido era invisível
no log (seu achado 1 da v2). O `catch` de falha ficou como estava. A guia
conferiu que este bloco é a ÚNICA diferença executável em `src/` desde `85956ce`
(`git diff 85956ce..eb843cf -- src/` sem linhas de comentário); por isso a prova
por mutação M1–M9 continua no cabeçalho `85956ce` e o relato passou a justificar
isso função a função (o `conferidor` acusou a frase anterior, "única linha
executável", como imprecisa — commit `cca1685`).

## O que julgar
1. **O gatilho da marca falsa, terceira versão — agora ESTRUTURAL, no banco, não
   no log.** O `revisor` interno derrubou a segunda ("escalonamento sem echo
   antes"): acusava comportamento CORRETO, porque a oferta real do dono também
   entra pela rota do PAINEL, que não gera echo — medido ponta a ponta. E o
   `grep` proposto não casava a própria linha (`****NNNN` de `mascararTelefone`
   são quantificadores em regex). Terceira correção seguida → parou de remendar
   (teto de três do AGENTS). O discriminador declarado: `pushTurn` grava `user` e
   `assistant` num INSERT único, os dois com o MESMO `created_at` (carimbo da
   transação), enquanto as linhas da equipe (`registrarFalaDoDono` e painel)
   gravam `assistant` sozinho. Medido em `BEGIN`/`ROLLBACK` no `sofia_test`
   nos três caminhos. Falso positivo nomeado: duas transações no mesmo instante.
   A linha de log fica (decisão do fundador), como forma de achar candidatos, e
   com `grep -F`. **Julgue:** o discriminador é verdadeiro contra o código final
   (`pushTurn` em `src/session/sessionStore.js`; `getHistory` e seu docblock)?
   O texto (comentário em `src/admin/panel.js`, plano, relato) descreve
   exatamente isso, com o comando/consulta que rederiva, sem prometer mais?
2. **A linha de log nova:** nunca carrega conteúdo de mensagem (o `revisor`
   colou o texto do lote na linha e a suíte ficou verde — agora há asserção e
   mutação; confira o teste e a mutação no pacote); usa `mascararTelefone` e
   `horaLocal`; a prova negativa do teste contra `c691c51` está no pacote
   (o teste tem de falhar lá).
3. **Seus BAIXA da v2:** contexto vs banco no caso de desligar Coexistence;
   exclusividade limitada à REGRA e ao modo de handoff; comentário do teste de
   ordem agora com asserção de UMA ocorrência do literal (ou reescrito — veja
   qual); distâncias em linhas removidas do código e do relato.
4. **SHA no plano saiu** (artefato durável não cita commit) — confira que não
   sobrou `\b[0-9a-f]{7,40}\b` no plano.
5. Frases irmãs: os commits trazem os `grep`s com escopo; reexecute.

## Medições
- Implementador (WSL): 688/688 em `eb843cf`, tree 0 (`suite-fala-do-dono-completa.log`).
- **Guia (VPS, esta worktree): `suite-fala-do-dono-completa-terceiro-v3.log`** —
  cabeçalho com SHA/tree; leia o resultado lá.
- Eval: cenário 17 verde 3/3 contra `85956ce` (mesmo código de produto salvo a
  linha de log) — fato relatado pela guia, como na v2.

## Nota
Dois arquivos de OUTRA sessão apareceram no working tree do WSL durante a volta
(plano do site em `docs/plans/`, cópia de sondagem em `~/sonda-revisor-v3`);
nenhum entrou em commit. Não é achado da branch; registro da guia.

## Suíte e saída
Como nas voltas anteriores: UMA suíte com cabeçalho, `sofia_test` livre
(`pid <> pg_backend_pid()`), arquivos em `/tmp/` com o caminho no parecer.
Última linha "apto a deploy" ou "BLOQUEADOR: <um>", próximos passos numerados.
