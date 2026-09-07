Parecer independente — fala-do-dono-completa, volta 3 — 07/09/2026

SHA revisado: eb843cf929b67b975d43cf5700846628eac2ab20; base: 8d55955.
Máquina: a VPS. HEAD destacado e origin/fala-do-dono-completa no SHA pedido.
Árvore limpa na abertura, na suíte e no encerramento. Nenhum arquivo do repositório editado.

O discriminador do banco e a mudança executável passaram nas verificações desta volta. O bloqueador é a orientação operacional que continua no relato entregue: ela contradiz o plano e o comentário finais e ainda manda usar o gatilho rejeitado. Não peço mudança do desenho nem mecanismo contra a marca falsa.

Li AGENTS.md completo; prompts e pareceres v1/v2; mensagens dos commits da volta 3; spec docs/features/coexistence-onboarding.md; plano final docs/plans/fala-do-dono-completa.md; trechos de origem/superação de docs/plans/fala-do-dono.md; ESTADO.md e trechos pertinentes de LOG.md e docs/contexto/fila.md. Li o relato, os diffs, a lista de commits e os logs de suíte/provas do pacote.

O código foi lido por git show do SHA final: trechos alterados e funções de origem em src/server.js, src/admin/panel.js, src/ai/systemPrompt.js, src/session/sessionStore.js, src/coex/marcaAtendimento.js, src/coex/silencio.js, src/support/humanHandoff.js, src/tenants.js e src/ai/openrouter.js; testes coexEscalonamento/systemPrompt, configuração/setup da suíte, schema de messages e script limparConversas. Sobre os demais trechos inalterados, mantenho os pareceres anteriores; não alego nova leitura integral deles.

Achados:

1. ALTA — o relato corrente ainda prescreve o gatilho que esta volta rejeitou.

   ~/para-revisao/relato-fala-do-dono-completa.md:105 afirma haver um “gatilho que existe” e, nas linhas seguintes, o define como escalonamento sem linha anterior de silêncio por echo. É orientação vigente, não citação histórica desmentida ali.

   Contradiz src/admin/panel.js:2095 e docs/plans/fala-do-dono-completa.md:254, que substituem esse critério pela consulta ao banco. A escrita humana pelo painel em src/admin/panel.js:2151 grava assistant sem chamar silenciarPorEcho; a delegação posterior pode produzir normalmente a linha de src/server.js:1331. Ausência de echo não distingue esse atendimento correto da oferta escrita pela Sofia.

   Consequência: quem seguir o relato acusa atendimento correto como marca falsa. Prevalece o blob da branch para julgar o mecanismo; isso não torna verdadeira a orientação oposta no relato que acompanha o merge. A correção é sincronizar esse parágrafo com o discriminador e o falso positivo já declarados no comentário, deixando o log apenas para achar candidatos.

   Guardei os bytes lidos em /tmp/relato-lido-codex-fala-do-dono-completa-v3.md. SHA256: 4cda3fde81609c72afe1c466c580fd24e7dcafbab7e37f5e617d6d02f7ccdf8b.

2. BAIXA — a correção de duração ficou incompleta e acrescentou um absoluto sobre retenção.

   src/admin/panel.js:2041 continua dizendo que o literal digitado fora de Coexistence “NÃO se fecha sozinha”; o mesmo permanece em docs/plans/fala-do-dono-completa.md:222 e no relato:80. O achado da v2 nomeava também esse caso. Executei a rota final com texto literal e getHistory: depois de MAX_MESSAGES linhas novas, a marca sai do contexto e permanece na tabela TEMP. MAX_MESSAGES foi derivado do módulo, não fixado pela sonda.

   Além disso, src/admin/panel.js:2033 diz que a linha fica no banco “para sempre”. A própria rota de limpeza, em src/admin/panel.js:1988, apaga a conversa; src/scripts/limparConversas.js:17 apaga linhas conforme retention_days. Não medi instalação/execução do cron e não a suponho: a existência dessas operações já impede prometer permanência absoluta. Basta distinguir janela de contexto de persistência sujeita à limpeza/retenção. É exagero de duração, sem dano novo ocultado.

3. BAIXA — sobrou frase irmã da exclusividade no comentário do prompt.

   src/ai/systemPrompt.js:78 ainda justifica a condição com “é só aí que a marca existe”; src/ai/systemPrompt.js:80 fala de uma marca que “nunca aparece” fora de Coexistence. A correção em src/admin/panel.js:2058 reconhece precisamente o contrário.

   Medi o caminho final: o painel grava o literal fora de Coexistence, getHistory o devolve e buildSystemPrompt omite a regra. A exclusividade corrigida é da regra e do modo de handoff; o comentário deve limitar-se a isso ou à aplicação do helper. Não é pedido de alterar o prompt enviado ao modelo.

4. BAIXA — o novo chamador tornou falsa a contagem no comentário de origem de horaLocal.

   src/coex/silencio.js:124 descreve “QUATRO pontos” e os enumera sem o escalonamento. A chamada acrescentada em src/server.js:1331 faz a contagem executável passar de quatro para cinco, medida nos blobs c691c51 e eb843cf. Esse comentário era verdadeiro antes da mudança desta volta; a nova chamada é que o invalidou. Trocar a contagem por critério/referência aos chamadores evita repetir a mesma classe. Não há defeito de formatação de hora na execução medida.

Verificações aprovadas:

- A consulta de src/admin/panel.js:2110 confere com pushTurn e o docblock de getHistory. O schema real de teste tem created_at TIMESTAMPTZ, precisão 6 e DEFAULT now(). Executei os escritores finais contra tabela TEMP baseada nesse schema, com transações revertidas: pushTurn identificado; registrarFalaDoDono e os ramos texto/imagem do painel excluídos. Não inseri dados em tabelas persistentes nem consumi a sequência persistente de messages.
- O falso positivo por empate entre transações está declarado em src/admin/panel.js:2123. A medição confirma os caminhos normais, não impossibilidade de colisão. O discriminador aponta a origem provável da marca; não prova sozinho que o modelo a usou nem que houve silêncio indevido. A linha nova serve como candidato, conforme o plano final.
- O log novo usa mascararTelefone e horaLocal, sem interpolação de mensagem. Executei o bloco final extraído com silenciarPorHandoff simulado: sucesso chama o helper uma vez e produz uma linha com ****3333 e hora local; falha produz só o erro anterior; sem escalonamento não há chamada nem linha. Fuso inválido conserva o fallback UTC. O catch mantém o comportamento de erro anterior.
- Li prova-negativa-linha-escalonamento.log: o caso positivo falha contra c691c51 por zero linhas de sucesso; os controles de ausência passam e não foram contados como prova negativa. O teste desse log foi copiado de uma árvore ainda não commitada, como o cabeçalho admite. Nesta revisão executei também o corpo das asserções FINAIS contra o bloco antigo extraído: reprova pela mesma ausência.
- Executei o corpo final das asserções do log contra uma mutação que acrescenta textoCombinado: reprova pelo conteúdo. O pacote registra essa mutação no commit/relato, mas não localizei um log dedicado com sua execução Vitest. Minha sonda está registrada abaixo; não a apresento como nova execução Vitest nem como log do WSL.
- tests/systemPrompt.test.js:140 agora mede uma ocorrência do literal. Executei o corpo final do teste de ordem/unicidade: original passa, literal duplicado reprova. A afirmação anterior de unicidade deixou de depender de indexOf.
- O plano final não contém correspondência para \b[0-9a-f]{7,40}\b. As distâncias apontadas na v2 saíram do código/relato desta fatia. As distâncias adicionais encontradas no código já existiam na base; ficam fora de escopo, registrar no item de fila já aberto.
- O delta executável desde 85956ce limita-se ao bloco de log no finally. As funções cobertas por M1–M9 não mudaram; o cabeçalho antigo dessa prova é coerente. Não tomei concordância dos filtros como corroboração.

Pacote e frases irmãs:

O diff incremental v3, o diff completo e a lista de commits são iguais byte a byte aos derivados dos refs locais. As cópias plano-fala-do-dono-completa-v0.md e -v1.md divergem do plano final; usei o blob da branch. O relato tem atualização de medições da volta 3, mas conserva o gatilho anterior — divergência material descrita no achado 1.

Reexecutei os greps de daa03a0 e cca1685 com os placeholders substituídos pelo relato corrente, e o comando de classe registrado na fila por eb843cf. Os padrões literais antigos retornam zero; isso não cobre a frase irmã com outra redação em systemPrompt nem o gatilho ainda escrito no relato. A busca ampliada encontra ambos. Não comparei o total intermediário de um commit com o HEAD como se fossem a mesma medição.

Medições e evidências:

- Minha única suíte: 47 arquivos, 688/688, 237,48 s, exit 0; SHA/ref/tree no mesmo log, árvore 0 antes/depois, zero outras conexões com pid <> pg_backend_pid() imediatamente antes. /tmp/suite-codex-fala-do-dono-completa-v3.log.
- Guia: 47 arquivos, 688/688, 234,79 s, eb843cf, árvore 0; suite-fala-do-dono-completa-terceiro-v3.log. É a medição de terceiro que sustenta o merge; a minha é a terceira fonte.
- Implementador: 47 arquivos, 688/688, 170,23 s, eb843cf, árvore 0; suite-fala-do-dono-completa.log.
- Sondas isoladas, sem segunda suíte: /tmp/provas-codex-fala-do-dono-completa-v3.log e script .cjs homônimo. Funções/corpos extraídos dos blobs; helper de silêncio e envios simulados nas sondas correspondentes; escritores do histórico com SQL real em TEMP/ROLLBACK; zero outras conexões antes da sonda SQL.
- /tmp/greps-codex-fala-do-dono-completa-v3.log; /tmp/pacote-codex-fala-do-dono-completa-v3.log; /tmp/origens-codex-fala-do-dono-completa-v3.log. Merge-tree com main 59fd459 sem marcadores: /tmp/merge-tree-codex-fala-do-dono-completa-v3.log.

Fato relatado pela guia: cenário 17 do sofia-eval verde 3/3 contra 85956ce. Não executei eval nem verifiquei o modelo real nesta máquina. SUPOSIÇÃO mantida onde depender de acesso externo não realizado: forma e baixabilidade da mídia real de echo continuam não medidas aqui, conforme o limite aceito. O teste real no número da Riacho permanece no roteiro de deploy da guia.

Próximos passos:

1. Corrigir o relato corrente para usar o discriminador do banco, seu falso positivo e o log apenas como candidato; reenviar a cópia correta para a VPS.
2. Corrigir os BAIXA de duração, exclusividade e comentário de horaLocal, conferindo as irmãs pela afirmação, inclusive quando quebrada em linhas. Preservar o código e o escopo fechados desta volta.
3. Passar o delta de texto pelo conferidor e devolver o pacote coerente à revisão. Os achados não exigem redesenhar o mecanismo nem repetir o eval; eventual mudança executável exige sua própria validação.

BLOQUEADOR: o relato corrente ainda orienta usar o gatilho rejeitado de escalonamento sem echo
