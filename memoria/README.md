# memoria/

Um agente com `memory: project` guarda o que aprendeu entre execuções. Aqui
está a memória real do `revisor`, sem edição — é a parte do arranjo que quase
nunca se mostra, e a que prova que os papéis acumulam experiência em vez de
recomeçar do zero a cada chamada.

[`revisor/padroes-de-achado.md`](revisor/padroes-de-achado.md) é o achado mais
útil que ele produziu sobre si mesmo: **nesta base o código quase sempre está
certo, e o bloqueador nasce no texto que acompanha o código e na afirmação de
raio de alcance.** Dele saíram as duas medições que ele passou a rodar ANTES de
olhar a lógica linha a linha.

[`revisor/medicoes-do-revisor.md`](revisor/medicoes-do-revisor.md) é como ele
mede sem sujar a cópia de trabalho principal, e traz uma armadilha que vale
para qualquer um: um `pgrep` com o truque do colchete deu positivo em si mesmo
porque a palavra estava na mensagem de fallback do próprio comando.

As memórias dos outros agentes ficaram de fora da extração: descrevem a
infraestrutura real, com caminho de backup e nome de cliente.
