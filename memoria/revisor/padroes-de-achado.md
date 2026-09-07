---
name: padroes-de-achado
description: Classes de achado que se repetem nas revisões de diff do sofia-bot — onde o bloqueador costuma estar (texto e raio de alcance, não lógica) e as duas medições que os revelam
metadata:
  type: project
---

Nas revisões desta base, o código quase sempre está certo; **o bloqueador nasce
no texto que acompanha o código e na afirmação de raio de alcance**.

**Why:** medido na `prompt-condicional` (07/09, primeira revisão minha): 8 dos 9
achados eram comentário/commit/teste afirmando o que o código não faz, e os dois
ALTA eram (a) mudança de default do core motivada pelo extra de UM tenant,
atingindo outro tenant em produção, e (b) a única frase de raio de alcance do
commit medindo o tenant errado. Nenhum achado era de lógica. Isso casa com o
histórico que o `AGENTS.md` registra das fatias `coex-commit2`, `audio-transcrito`,
`log-waba` e `fala-do-dono-completa`.

**How to apply:** em toda revisão, rodar estas duas medições ANTES de olhar a
lógica linha a linha, porque são as que produzem os achados caros:

1. **Rederivar o raio de alcance por dado, não por texto.** Quantos tenants
   existem, quais estão `active`, e o que cada um tem (produtos, profissionais,
   token de Pix, `coexistencia`) muda sem aviso e é o que decide quem sente o
   diff. `psql -d sofia_bot` com contagens e `IS NOT NULL` (nunca o valor de
   segredo, nunca `system_prompt_extra`). Frase de commit que diz "para o cliente
   X nada muda" é premissa até ser medida — e já nasceu falsa uma vez, apontando
   para um tenant inativo com nome parecido.
2. **Montar o artefato real nos dois lados do diff** (worktree temporária em
   `main` + `cp -al` do `node_modules`, remover no fim). Serve para a prova
   negativa E para conferir número medido citado no commit. Foi assim que
   apareceu que o "antes" de uma medição não se reproduzia e que um fixture
   byte-a-byte tinha perdido um bloco em silêncio.

**Armadilha específica desta base:** fixture congelado (`tests/fixtures/`) perde
cobertura sem ninguém notar quando o código passa a condicionar uma seção a um
campo que o tenant do fixture NÃO tem — o teste continua verde e o comentário ao
lado continua dizendo que congela "o caso completo". Conferir sempre, por `grep`
no próprio fixture, que os blocos que o diff tornou condicionais ainda estão lá.

Ver também [[medicoes-do-revisor]].
