---
name: medicoes-do-revisor
description: Como o revisor mede sem sujar a working tree principal — worktree temporária para prova negativa, cabeçalho de identidade na suíte, e o pgrep que casa a si mesmo
metadata:
  type: project
---

Receita de medição que funciona e não deixa resíduo na cópia principal:

- **Prova negativa:** `git worktree add --detach ~/pn-<fatia> main` a partir da
  worktree de revisão, `cp -al ~/sofia-bot/node_modules` (hardlink, mesmo
  filesystem), copiar POR CIMA o arquivo de teste da branch e rodar só ele com
  `npx vitest run <arquivo>`. No fim: `git worktree remove --force` e conferir
  `git status` da principal. `rm -rf` é negado para subagente — o
  `worktree remove --force` sozinho dá conta.
- **Suíte:** sempre com o cabeçalho SHA/ref/tree do `AGENTS.md` e `> arquivo.log
  2>&1`. Minha medição e a da guia no mesmo SHA são duas fontes que PODEM
  discordar, então corroboram de verdade.

**Why:** o parecer não pode se apoiar em número de quem implementou, e a
atribuição do número ao commit só existe se o log carregar SHA + árvore limpa.

**How to apply:** rodar antes de escrever qualquer severidade, e nunca em
paralelo com outro filtro (disputam `sofia_test` e a porta 3000).

**Cuidado que me pegou na prática:** `pgrep -f "[v]itest" || echo "nenhum vitest
rodando"` dá positivo em si mesmo — não pelo padrão, mas porque a PALAVRA está na
mensagem de fallback do próprio comando. O truque do colchete não salva se o
texto ao redor contiver o literal. Escrever a mensagem sem a palavra.

Ver também [[padroes-de-achado]].
