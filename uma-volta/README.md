# uma-volta/

Uma fatia inteira, do plano ao parecer que liberou o merge. É o mesmo material
que circulou de verdade, com os caminhos de máquina trocados por genéricos e
nada mais.

A fatia pôs uma **marca de autoria** no histórico da conversa: num modo em que
a dona do negócio e a assistente respondem pelo mesmo número de WhatsApp, o
sistema precisava saber de quem era cada linha antes de deixar a assistente
confirmar um horário. O instrumento que mediu isso foi um cenário do avaliador
de comportamento, escrito para nascer VERMELHO — e nasceu.

| Arquivo | O que é |
|---|---|
| [`00-plano.md`](00-plano.md) | o plano aprovado, com a peça central nomeada |
| [`00-relato.md`](00-relato.md) | o relato que acompanha o pacote de revisão |
| `0N-prompt.md` | o que foi pedido ao revisor independente em cada volta |
| `0N-parecer.md` | o que ele respondeu |

**As quatro voltas, pela última linha de cada parecer:**

1. BLOQUEADOR — o limite declarado no comentário omitia uma exceção que o
   próprio painel produz, e afirmava que um estado permanente se resolve
   sozinho.
2. BLOQUEADOR — o gatilho declarado para investigar não correspondia ao sinal
   que o sistema realmente produz.
3. BLOQUEADOR — o relato ainda prescrevia o gatilho que a volta anterior
   rejeitou.
4. **apto a deploy.**

**O que isso mostra, e é o motivo de estar aqui:** nenhuma das três voltas
bloqueou por lógica errada. As três foram texto durável afirmando o que o
código não fazia — e a terceira foi uma cópia que deveria ter sido cópia e foi
reescrita de memória. Foi essa volta que produziu a regra "o relato COPIA o
critério do plano, com nota de cópia".

Na volta 4 o revisor dispensou rodar a suíte, e disse por quê: comparou a
árvore sintática dos arquivos alterados removendo comentários e posições,
achou todas idênticas, e verificou o controle da própria comparação num
literal executável. Delta sem linha executável nova reaproveita a medição
anterior — que carrega o commit e o estado da cópia de trabalho no cabeçalho,
sem o que o número não se liga ao código que vai ao ar.
