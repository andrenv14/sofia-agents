# docs/plans/

**Plano aprovado é artefato versionado**, apontado por `plansDirectory` em
[`.claude/settings.json`](../../.claude/settings.json). Implementação e revisão
se comparam contra ele, não contra a memória da conversa.

Três regras que o formato carrega, cada uma de um custo pago:

- **Aprovar um plano exige provar a PEÇA CENTRAL** — quem aprova nomeia a peça
  que, se errada, invalida o resto, e a verifica com prova. A primeira linha da
  aprovação é "peça central: X — verificada por Y". Periférico conferido não
  substitui: um plano aprovado pelos periféricos custou 4 rodadas de revisão;
  o seguinte, com a peça central provada antes, foi aprovado na 1ª volta.
- **Número MEDIDO não entra no plano — entra no relato.** O plano é escrito
  ANTES; qualquer contagem nele nasce provisória. Um plano cravou uma contagem
  final e a medição real deu outra: bloqueador do revisor independente por
  citação durável falsa.
- **Congelar o escopo congela a PROMESSA.** Quando o desenho fecha, o plano é
  reescrito NA HORA para afirmar só o que o código garante. Sem isso o revisor
  continua medindo contra a promessa antiga — e está certo em fazê-lo: ele
  revisa o texto que está lá.

[`uma-volta/00-plano.md`](../../uma-volta/00-plano.md) é um exemplo real.
