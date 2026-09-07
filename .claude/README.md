# .claude/

O que o harness lê. Tudo aqui é o arquivo real do repositório de origem, sem
edição.

- [`agents/`](agents/) — um arquivo por papel. O frontmatter declara as
  ferramentas, o modelo e o esforço de cada um; o corpo diz o que ele faz, o
  que **nunca** faz, e como devolve o resultado.
- [`hooks/`](hooks/) — três scripts. O cabeçalho de cada um diz por que ele
  existe, com o incidente e a data, e declara o contrato: só leitura, nunca
  afrouxa permissão, degrada com mensagem própria em vez de abortar a sessão.
- [`skills/deploy/SKILL.md`](skills/deploy/SKILL.md) — a sequência de deploy.
  Cresceu por achado: cada passo novo tem ao lado a revisão que o exigiu.
- [`settings.json`](settings.json) — os hooks, o `plansDirectory` e as três
  listas de permissão (`allow`, `ask`, `deny`).

**Exceção declarada:** as subpastas `agents/`, `hooks/` e `skills/deploy/` não
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

Este arquivo é reescrito pelo próprio harness em modo automático — em 02/09
entraram permissões em duas máquinas no mesmo dia, sem ninguém editar. Conferir
`git status` dele antes de todo `git add` é parte da checklist de encerramento.
