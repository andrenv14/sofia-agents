# docs/features/

Uma spec por feature entregue: o que ela faz, o que decidiu não fazer, e os
limites conhecidos.

**É contra este arquivo que o revisor lê o diff** — nunca contra a
justificativa de quem implementou, nunca contra a conversa que gerou a
mudança. A ordem está no `revisor` (`.claude/agents/revisor.md`): constituição
primeiro, spec depois, diff por último.

Armadilha conhecida: a spec "guarda-chuva", que cobre várias fatias, é a que
ninguém volta a atualizar depois de cada merge — porque o merge é anunciado no
diário, não nela. Auditoria de documentação a checa com prioridade.
