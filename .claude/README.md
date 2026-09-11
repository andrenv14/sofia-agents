# .claude/

O que o harness lê. Tudo aqui é o arquivo real do repositório de origem, sem
edição.

- [`agents/`](agents/) — um arquivo por papel. O frontmatter declara as
  ferramentas, o modelo e o esforço de cada um; o corpo diz o que ele faz, o
  que **nunca** faz, e como devolve o resultado.
- [`hooks/`](hooks/) — sete scripts. O cabeçalho de cada um diz por que ele
  existe, com o incidente que o gerou, e declara o contrato: só leitura, nunca
  afrouxa permissão, degrada com mensagem própria em vez de abortar a sessão.
  **Três deles BLOQUEIAM** (saem com código 2, que o harness não ignora):
  edição de arquivo com segredo, reinício do processo de produção com a cópia de
  trabalho suja, e `git add` que leve um arquivo de permissão alterado sem
  nomeá-lo. Os outros informam ou pedem confirmação.
- [`skills/`](skills/) — quatro procedimentos, carregados sob gatilho declarado:
  `deploy`, `revisao-externa`, `encerrar-ciclo` e `tunel-wsl`. A diferença para
  um hook é que **skill pode ser ignorada e hook não** — por isso procedimento
  vira skill, e regra que precisa valer sempre vira hook.
- [`settings.json`](settings.json) — os hooks, o `plansDirectory` e as três
  listas de permissão (`allow`, `ask`, `deny`).

**Exceção declarada:** as subpastas `agents/`, `hooks/` e `skills/*/` não
têm `README.md` próprio, e é de propósito — o harness lê **todo** `.md` de
`agents/` como definição de agente, e um README ali viraria um agente sem
frontmatter. Elas são documentadas por esta página.

## Sobre `settings.json`, que é onde mora a decisão de segurança

As três listas não são conveniência: `deny` para o que nunca deve rodar,
`ask` para o que exige uma pessoa decidindo, `allow` só para leitura.

Duas regras que custaram para aprender, e que estão na constituição:

- **Interpretador em `allow` anula o resto da lista.** `node -e` roda o cliente
  do banco e escreve, sem passar por nenhuma regra de `psql`. Vale para
  `python -c`, `bash -c` e para interpretador + caminho de arquivo mutável: o
  allow sobrevive à sessão que o pediu, o conteúdo do arquivo não.
- **O teste é o PADRÃO, não a intenção.** Se um glob admite UM argumento que
  reinicia, apaga, edita ou agenda, ele não é de leitura. Por isso
  `pm2 logs … --nostream` está em `allow` e `pm2 *` não.

Este arquivo é reescrito pelo próprio harness quando a sessão roda em modo
automático: permissões entram nele sem ninguém editar deliberadamente. Conferir
`git status` dele antes de todo `git add` é parte da checklist de encerramento.
