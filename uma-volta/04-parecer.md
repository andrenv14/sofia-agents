Parecer independente — fala-do-dono-completa, volta 4 — 07/09/2026

SHA: cca1c00f5b1d93f5492647bd7c0adf0858e5c787. Base: 8d55955b14db25d906f45848578d4895b1ce76ba.
Máquina: a VPS. Ref: HEAD destacado; origin/fala-do-dono-completa no mesmo SHA.
Main local: 59fd459ec6bfb9ecb27e9e9c470f41533d9a9d2d. Working tree limpa na abertura e no encerramento.
Nenhum arquivo do repositório editado. Escopo: somente os quatro pontos da v3.

O bloqueador ALTA da v3 está corrigido. Resta um achado BAIXA de duração no plano e no relato, sem impedir o deploy. Não confirmo a coerência integral afirmada pelo conferidor: o gatilho está sincronizado, mas essa frase de duração não está.

Leitura realizada: AGENTS.md; prompts v2/v3 e pareceres v1/v2/v3; mensagem completa de cca1c00; spec docs/features/coexistence-onboarding.md; plano final docs/plans/fala-do-dono-completa.md; relato corrente; diffs e lista de commits; cabeçalhos/resultados das suítes citadas abaixo. Também li os trechos de origem/superação de docs/plans/fala-do-dono.md e o trecho citado de docs/plans/coex-commit2.md.

Código final lido por git show cca1c00:<arquivo>: comentários alterados e trechos pertinentes de src/admin/panel.js, src/ai/systemPrompt.js, src/coex/silencio.js e src/server.js; origens em src/session/sessionStore.js (getHistory, pushTurn, registrarFalaDoDono), src/scripts/limparConversas.js (main), src/support/humanHandoff.js (chamarAtendenteHumano), src/ai/openrouter.js (efeito de escalonamento), src/coex/marcaAtendimento.js e src/tenants.js. Não alego nova revisão integral do comportamento já julgado na v3.

1. Gatilho do banco — corrigido.

   O trecho do plano iniciado em docs/plans/fala-do-dono-completa.md:256 está copiado byte a byte no relato:108; medi igualdade dos 1463 bytes. A nota de cópia está no relato:131.

   Plano, relato e src/admin/panel.js:2099 descrevem o mesmo discriminador: pushTurn grava user+assistant no mesmo INSERT, com created_at da transação; registrarFalaDoDono e painel gravam assistant sozinho. Conferido nos escritores finais: src/session/sessionStore.js:81, src/session/sessionStore.js:156 e src/admin/panel.js:2150/2159. A consulta em src/admin/panel.js:2114 exige o mesmo tenant, contato e created_at para o par.

   O falso positivo de transações distintas no mesmo instante está declarado nos três textos. O log serve para achar candidatos, conforme src/admin/panel.js:2133, plano:272, relato:124 e src/server.js:1319. A investigação da conversa continua necessária; não trato o discriminador como prova isolada de silêncio indevido.

   “Escalonamento sem echo antes” aparece no relato:110 como tentativa rejeitada, desmentida imediatamente por acusar atendimento correto pelo painel. É histórico, não prescrição. O achado ALTA anterior não permanece.

   As exceções aparecem na mesma ordem nas três fontes: desligamento de Coexistence; literal digitado pelo operador fora de Coexistence; marca falsa produzida por pushTurn; defasagem do cache ao ligar; histórico anterior sem marca. A divergência remanescente é a duração da segunda, detalhada abaixo.

2. BAIXA — o plano e o relato ainda exageram a duração do literal digitado fora de Coexistence.

   docs/plans/fala-do-dono-completa.md:224 e ~/para-revisao/relato-fala-do-dono-completa.md:81 continuam afirmando “também NÃO fecha sozinha”. São afirmações vigentes. O comentário correspondente em src/admin/panel.js:2043 foi corrigido para “sem autocura no contexto enquanto a conversa não andar”. Portanto a correção não chegou às cópias irmãs.

   getHistory, em src/session/sessionStore.js:61, limita o histórico por MAX_MESSAGES sem consultar Coexistence: com linhas novas suficientes, o literal sai do contexto. No banco, a rota de limpeza em src/admin/panel.js:1988 e main de src/scripts/limparConversas.js:17 podem apagá-lo. O parecer v3 já registra execução desse caso; nesta volta reli o mecanismo final, que permanece idêntico, sem apresentar aquela execução como medição nova.

   A permanência “para sempre” foi corrigida no caso de desligar Coexistence, nas três fontes. Falta aplicar a mesma distinção contexto/banco ao caso lexical, mantendo a qualificação do painel e nomeando MAX_MESSAGES e limpeza/retenção.

   Consequência: exagero da duração de um limite já declarado. Não oculta dano adicional, não muda o gatilho investigativo e não cria regressão executável. Mantém a severidade BAIXA da v3; não é bloqueador de deploy.

3. Exclusividade — corrigida no ponto solicitado.

   src/ai/systemPrompt.js:78 reconhece expressamente que o literal pode aparecer fora de Coexistence. As redações antigas em src/ai/systemPrompt.js:87 são citadas e desmentidas ali mesmo. A condição executável de buildSystemPrompt continua em src/ai/systemPrompt.js:96. chamarAtendenteHumano devolve o modo coexistencia apenas nesse ramo; o efeito em src/ai/openrouter.js:483 exige esse modo. Fora dele não se aplica esse silêncio. A exclusividade da presença literal deixou de ser a justificativa.

4. horaLocal — corrigido.

   src/coex/silencio.js:124 substitui a contagem por critério e comando. Reexecutei o comando de src/coex/silencio.js:129: ele retorna as chamadas em src/server.js:784, 1154, 1338, 2531 e 3118, incluindo o escalonamento. A definição e o próprio comando ficam excluídos pelo filtro. “QUATRO pontos” em src/coex/silencio.js:131 é citação do erro anterior, não contagem atual.

Verificações e proveniência:

- Há um commit desde eb843cf. Li o delta e comparei a árvore sintática dos arquivos JavaScript alterados, removendo apenas comentários e posições: todas idênticas. O controle da comparação detectou mudança de literal executável. tests/, package.json, package-lock.json e vitest.config.js não mudaram. Confirmei a alegação de ausência de alteração executável.
- Suíte dispensada nesta volta, conforme autorização expressa para delta textual. Não acessei o banco de teste. A medição de terceiro permanece sendo suite-fala-do-dono-completa-terceiro-v3.log: SHA eb843cf929b67b975d43cf5700846628eac2ab20, ref do commit, tree 0, 47 arquivos, 688/688, 234,79 s. A equivalência executável acima sustenta sua reutilização; não a atribuo ao SHA novo.
- Implementador: suite-fala-do-dono-completa.log, SHA cca1c00f5b1d93f5492647bd7c0adf0858e5c787, ref do commit, tree 0, 47 arquivos, 688/688, 163,03 s. A terceira fonte continua sendo a execução independente registrada na v3, sem nova execução nesta volta. Provas negativas e eval não foram repetidos neste delta textual.
- Reexecutei o grep de exclusividade registrado no commit, com <relato> substituído pelo arquivo corrente, e o comando de horaLocal. Completei a busca por duração/gatilho considerando frases quebradas em linhas. O resíduo BAIXA sobrevive a essa busca. As correspondências históricas desmentidas e as que descrevem outro assunto não foram tratadas como novas prescrições.
- Delta v4, diff completo e lista de commits do pacote são idênticos aos derivados dos refs locais. As cópias plano-fala-do-dono-completa-v0.md e -v1.md divergem do plano final; usei o blob da branch. O relato foi preservado em /tmp/relato-lido-codex-fala-do-dono-completa-v4.md, SHA256 740dd45b8705fdf5b41c5dd1a1ed6d616260dc98db10c93a16ca17a3030872b5.
- Evidência executada: /tmp/verificacao-codex-fala-do-dono-completa-v4.log; script homônimo .mjs; /tmp/greps-codex-fala-do-dono-completa-v4.log.

Limites de verificação: a instalação/execução corrente do cron de limpeza não foi verificada — crontab -l retornou Permission denied. SUPOSIÇÃO se depender dessa instalação; o SQL de retenção e a limpeza do painel foram lidos. A medição externa do cenário 17 permanece fato relatado pela guia nas voltas anteriores. Forma e baixabilidade da mídia real de echo continuam não medidas aqui, conforme limite aceito. Nenhum desses limites foi reaberto nesta revisão de texto.

Próximos passos:

1. Registrar o BAIXA e alinhar a duração do caso lexical no plano e no relato ao comentário do painel, sem alterar o mecanismo. É pendência documental não bloqueante.
2. A guia pode seguir com merge/deploy e o teste real de áudio já previsto, preservando os logs e este parecer junto do pacote.

apto a deploy
