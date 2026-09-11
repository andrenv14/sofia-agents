---
name: padroes-de-achado
description: Classes de achado que se repetem nas revisões de diff do projeto — onde o bloqueador costuma estar (texto e raio de alcance, não lógica) e as duas medições que os revelam
metadata:
  type: project
---

Nas revisões desta base, o código quase sempre está certo; **o bloqueador nasce
no texto que acompanha o código e na afirmação de raio de alcance**.

**Why:** a maioria dos achados é comentário, mensagem de commit ou teste
afirmando o que o código não faz. Os graves costumam ser dois: mudança de padrão
do núcleo motivada pela necessidade de um cliente só, atingindo outro em
produção; e a frase de raio de alcance do commit medindo o alvo errado. Achado
de lógica é a minoria.

**How to apply:** em toda revisão, rodar estas duas medições ANTES de olhar a
lógica linha a linha, porque são as que produzem os achados caros:

1. **Rederivar o raio de alcance por dado, não por texto.** Quantos tenants
   existem, quais estão ativos, e o que cada um tem configurado muda sem aviso
   e é o que decide quem sente o diff. Consultar o banco com contagens e
   `IS NOT NULL`, nunca o valor de segredo nem o prompt do cliente. Frase de
   commit que diz "para o cliente X nada muda" é premissa até ser medida: nome
   parecido entre um cliente ativo e um inativo faz a frase nascer falsa.
2. **Montar o artefato real nos dois lados do diff** (worktree temporária em
   `main` + `cp -al` do `node_modules`, remover no fim). Serve para a prova
   negativa E para conferir número citado no commit. É o que revela um "antes"
   que não se reproduz, e um fixture byte a byte que perdeu um bloco em
   silêncio.

**Armadilha específica desta base:** fixture congelado (`tests/fixtures/`) perde
cobertura sem ninguém notar quando o código passa a condicionar uma seção a um
campo que o tenant do fixture NÃO tem — o teste continua verde e o comentário ao
lado continua dizendo que congela "o caso completo". Conferir sempre, por `grep`
no próprio fixture, que os blocos que o diff tornou condicionais ainda estão lá.

Ver também [[medicoes-do-revisor]].
