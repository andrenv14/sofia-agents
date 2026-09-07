# docs/contexto/

O contexto de negócio e de direção, particionado por finalidade. **Só os
cabeçalhos de escopo estão aqui** — o conteúdo é do projeto e ficou no
repositório privado.

O mecanismo é o cabeçalho: cada arquivo abre declarando o que vai nele e o que
NÃO vai, com o ponteiro para o irmão certo. É o que impede o mesmo fato de
existir em dois lugares e divergir, e o que permite a uma sessão carregar um
arquivo em vez de cinco.

| Arquivo | Escopo | NÃO vai aqui |
|---|---|---|
| `fila.md` | o que fazer em seguida e em que ordem, com o que depende de terceiros separado do que não depende | a DESCRIÇÃO de um bug (mora no diário; aqui entra uma linha de ponteiro), preço, implantação, portfólio, decisão técnica |
| `fila-concluido.md` | os itens fechados, com a MEDIÇÃO que justificou fechar cada um, texto integral | qualquer coisa que ainda seja próximo passo |
| `negocio.md` | o que a empresa vende, por quanto, para quem, com que discurso | o que fazer em seguida, estado técnico, implantação, portfólio |
| `onboarding.md` | a sequência de implantação de um cliente novo, do pré-requisito até o teste final | preço e discurso, fila geral, estado técnico |
| `carreira.md` | repositórios públicos, gate do currículo, candidaturas, e o que se decidiu NÃO construir | fila de produto, preço, estado técnico |

**Por que `fila-concluido.md` existe em vez de os itens serem apagados:** cada
um carrega a medição que justificou fechá-lo. Sem ela, a objeção volta com
outra roupa daqui a duas semanas e alguém refaz o trabalho para descobrir o que
já se sabia.

**Por que ele é um arquivo separado da fila:** a fila é lida por toda sessão
antes de propor um próximo passo, e item fechado não é próximo passo. Este é
lido sob demanda. A separação nasceu de uma auditoria que achou a fila
carregando o que já estava feito.
