# docs/

A partição do contexto. Cada arquivo declara **o que vai nele e o que NÃO vai**,
com ponteiro para o irmão certo — e é isso que permite a uma sessão ler só o
que precisa em vez de carregar o projeto inteiro.

| Pasta | O que mora ali | Quem lê, e quando |
|---|---|---|
| [`contexto/`](contexto/) | o que fazer em seguida, negócio, implantação, carreira | a sessão-guia, ANTES de propor qualquer próximo passo |
| [`features/`](features/) | uma spec por feature entregue | o revisor, antes de ver o diff |
| [`plans/`](plans/) | o plano aprovado de cada fatia | quem implementa e quem revisa, contra o plano e não contra a memória da conversa |
| [`log/`](log/) | meses anteriores do diário | sob demanda, quase nunca |

Na raiz ficam os dois que toda sessão encosta: [`ESTADO.md`](../ESTADO.md), o
estado corrente, e [`LOG.md`](../LOG.md), o diário.

**O que é estável é a partição por finalidade com roteamento explícito.** O
corte atual dos arquivos é o de uma data — ele mudou quando um arquivo cresceu
demais, e vai mudar de novo.
