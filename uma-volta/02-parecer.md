Parecer independente — `fala-do-dono-completa`, volta 2

SHA revisado: `c691c51c5b2edbfdd4fc855651fd2b9fd95f4aef`; base: `8d55955`.
Máquina: a VPS. Worktree em HEAD destacado, conforme a receita de revisão
no AGENTS.md; `origin/fala-do-dono-completa` aponta para o mesmo SHA. Árvore limpa
na abertura, antes/depois da suíte e no encerramento. Nenhum arquivo do repositório
foi editado.

**Resultado:** a implementação de produção permanece igual à da v1. O bloqueador
está no gatilho operacional escrito para aceitar o risco da marca falsa. Não peço
mecanismo novo nem reabertura do desenho.

**O que li e conferi**

- AGENTS.md completo, prompt e parecer v1, prompt v2, mensagens dos commits da
  branch, relato corrente e logs de suíte/mutações do pacote.
- Spec `docs/features/coexistence-onboarding.md`; plano final completo
  `docs/plans/fala-do-dono-completa.md`; trechos de origem e superação do plano
  `docs/plans/fala-do-dono.md`; ESTADO.md e trechos pertinentes de LOG.md e fila.md.
- Blobs finais, por `git show c691c51:<arquivo>`, dos trechos tocados pelo delta:
  `src/admin/panel.js`, `src/ai/systemPrompt.js`, `src/server.js`,
  `tests/systemPrompt.test.js`, `tests/painelMarcaAtendimento.test.js`,
  `tests/echoAudioDoDono.test.js` e `tests/identidadeEchoForma.test.js`.
- Origens das afirmações conferidas nesta volta: `src/session/sessionStore.js`,
  `src/coex/marcaAtendimento.js`, `src/support/humanHandoff.js`,
  `src/coex/silencio.js`, `src/tenants.js` e os trechos de histórico, ferramenta e
  persistência de `handleUserMessage` em `src/ai/openrouter.js`.
- `package.json`, configuração e setup da suíte. Sobre código inalterado fora
  desses trechos, mantenho a revisão v1; não alego segunda leitura integral.

Os diffs completo e incremental e a lista de commits do pacote são iguais byte a
byte aos derivados dos refs locais. A comparação dos blobs de src/, excluindo
linhas inteiras de comentário e acompanhada da leitura do delta, confirmou que
nenhuma linha executável mudou desde `85956ce`. O cabeçalho antigo do log M1–M9
é coerente com isso; não é divergência de pacote.

**Achados**

1. **ALTA — o gatilho para reabrir a marca falsa não corresponde ao sinal produzido.**
   `src/admin/panel.js:2081`, `docs/plans/fala-do-dono-completa.md:247` e relato
   corrente mandam esperar a primeira linha `[silencio]` por handoff sem pedido
   do paciente.

   No handoff bem-sucedido, `processarBuffer` não emite essa linha:
   `src/server.js:1309` chama o helper e o único console desse bloco está no
   catch, em `src/server.js:1311`, para FALHA de gravação.
   `silenciarPorHandoff`, em `src/coex/silencio.js:89`, também não loga sucesso.
   Executei o helper e o bloco chamador extraídos dos blobs finais, com banco
   simulado: sucesso = uma escrita e zero logs; controle com rejeição da escrita
   = uma tentativa e o log de erro. Não é conclusão apoiada apenas em grep vazio.

   Há linhas genéricas posteriores de silêncio, por exemplo no gate em
   `src/server.js:3088`, mas dependem de outra mensagem e não identificam a causa
   como handoff. Além disso, ausência de pedido explícito de HUMANO não separa
   marca falsa de delegação correta: aceitar a oferta real do dono já deve
   delegar por `src/ai/systemPrompt.js:95`.

   Consequência: o operador recebe uma orientação que pode deixar passar o
   silêncio indevido ou confundi-lo com o comportamento desejado desta fatia.
   O dano do caso está declarado corretamente; seu gatilho operacional não.
   Correção dentro do escopo: descrever a evidência existente — pendência no
   painel/banco, histórico e origem da oferta — e exigir que a oferta marcada
   fosse da própria Sofia. A pendência já é exibida em `src/admin/panel.js:1855`.
   Não é pedido de novo log, automação ou mecanismo contra a colisão.

2. **BAIXA — a declaração de permanência também precisa distinguir contexto de banco.**
   `src/admin/panel.js:2029` diz que desligar Coexistence deixa a marca sem regra
   até alguém religar; `src/admin/panel.js:2036` estende a ausência de autocura ao
   literal digitado fora de Coexistence. O plano repete isso a partir de
   `docs/plans/fala-do-dono-completa.md:217`.

   `getHistory`, em `src/session/sessionStore.js:61`, limita as linhas por
   MAX_MESSAGES sem consultar Coexistence. Executei essa função final sobre uma
   tabela TEMP no sofia_test, em transação revertida: a linha marcada apareceu
   inicialmente e saiu do contexto após MAX_MESSAGES (=24, derivado do módulo)
   linhas novas, sem consultar ou alterar tenants. A linha pode continuar no
   banco; sua presença no contexto não exige religar para acabar.

   Corrijo aqui a precisão da minha v1: ela constatou a contradição entre
   “todas se fecham” e “permanente”, mas não provou a permanência. A medição de
   agora impede tratar aquele segundo enunciado como fato. É exagero do limite,
   não dano oculto novo, por isso este item não é o bloqueador.

3. **BAIXA — exclusividade do literal no contexto continua falsa.**
   `src/admin/panel.js:2054` e `docs/plans/fala-do-dono-completa.md:229` dizem que
   só sob Coexistence o literal está no contexto para ser copiado.
   O caso lexical recém-declarado no próprio painel contradiz isso: o operador
   pode gravá-lo fora de Coexistence (`src/admin/panel.js:2101`), e
   `handleUserMessage` inclui esse histórico sem filtro de Coexistence
   (`src/ai/openrouter.js:278` e `src/ai/openrouter.js:303`).

   A exclusividade verdadeira é a da regra específica e do modo de handoff,
   não a da presença do texto no contexto. Basta limitar a frase a isso; não
   solicito novo caso de comportamento ou mecanismo.

4. **BAIXA — o comentário do teste de ordem promete mais que suas asserções.**
   `tests/systemPrompt.test.js:127` promete ocorrência única e que bloco novo
   fora de lugar não passará despercebido. O código usa indexOf para marcadores
   enumerados manualmente e compara suas primeiras posições em ordem.

   Executei o corpo final desse teste, com asserções equivalentes de node:assert,
   contra o buildSystemPrompt final e variantes em memória: o original passou;
   duplicar o literal da marca também passou, com duas ocorrências medidas;
   mover o bloco de profissionais depois do cliente falhou. A correção de ordem
   pedida na volta anterior funciona. A promessa de unicidade/descoberta de
   blocos novos é que não está provada. Reescrever o comentário para a cobertura
   real basta dentro do escopo fechado.

5. **BAIXA — sobrou distância em linhas no trecho corrigido.**
   `src/server.js:1775` ainda localiza a leitura antiga como “oitenta linhas
   abaixo”, no mesmo parágrafo que declara ter removido essa classe de citação.
   Ela foi introduzida pela fatia e sobrevive ao delta v2. O relato corrente
   também conserva “três linhas antes” e “oitenta linhas fora”. A referência
   durável deve ficar em arquivo/função; a localização histórica, quando útil,
   pertence ao registro datado. Não proponho varrer código alheio à fatia.

**Verificações aprovadas e escopo**

A enumeração de INSERTs, com exclusão dos comentários, devolveu os escritores
esperados: pushTurn, registrarMensagemSemResposta, registrarFalaDoDono e os
ramos texto/imagem do painel. O escritor só de user não amplia o critério de
assistant. Não encontrei escritor adicional omitido no critério proposto.
O caso lexical do painel está declarado junto dos demais.

O retorno documentado de decisaoDoEstado agora corresponde ao objeto final,
incluindo audioId e estado. O docblock de decidirFalaDoDono e o plano apontam
para essa definição. As contagens citadas na v1 de leituras, consumidores e
asserções foram retiradas ou ganharam comando; as ocorrências restantes de
“TRÊS LEITURAS” citam o erro antigo, não o afirmam como contrato atual.

O caso de marca falsa está no comentário do sítio e descreve o dano relevante:
resposta da Sofia persistida como assistant, eventual chamada da ferramenta,
modo coexistencia, efeito de escalonamento, silêncio e pendência. A emissão do
literal e a decisão de chamar a ferramenta são comportamento do modelo; depois
da chamada com esse modo, a cadeia de efeitos de código confere.

Reexecutei os greps existentes nos commits v2, expandindo os placeholders para
o relato CORRENTE. Resultados completos em
`/tmp/greps-codex-fala-do-dono-completa-v2.log`. As antigas enumerações do retorno
não apareceram; “dependente do modelo” saiu na revisão posterior; as ocorrências
de “nenhum silencia ninguém” são citações da frase corrigida. Não confundi os
resultados intermediários de cada commit com a quantidade no HEAD final.
A busca adicional por distâncias encontrou o resíduo do achado 5.

Reproduzi também a ausência de marcadores de conflito no merge-tree de três
argumentos com main. Isso é verificação de processo, não novo achado de código.

**Medições e proveniência**

- Minha única suíte Vitest: 47 arquivos, **685/685**, 224,55 s, exit 0.
  SHA c691c51, ref HEAD destacado apontando ao mesmo origin da branch, tree 0
  antes/depois. O log registra zero outras conexões antes da execução,
  excluindo pid <> pg_backend_pid().
  Log completo: `/tmp/suite-codex-fala-do-dono-completa-v2.log`.
- Guia: 685/685 em c691c51, tree 0, no log terceiro-v2 do pacote. Essa é a
  medição de terceiro que sustenta o merge; a minha é a terceira fonte.
- Implementador: 685/685 em c691c51, tree 0, no log WSL do pacote.
- Li a prova negativa por mutações M1–M9 executada em 85956ce. A ausência de
  alteração executável preserva sua aplicabilidade, com a limitação contra a
  base por ERR_MODULE_NOT_FOUND já admitida no relato e na v1.
- Provas adicionais desta revisão, sem outra execução da suíte:
  `/tmp/provas-codex-fala-do-dono-completa-v2.log` e script `.cjs` homônimo;
  `/tmp/janela-codex-fala-do-dono-completa-v2.log` e script `.cjs` homônimo.
  A segunda usou apenas tabela TEMP e ROLLBACK no banco de teste livre.

**Fato relatado pela guia:** o cenário 17 do sofia-eval passou 3/3 com
humano_pendente true contra 85956ce e o controle na main criou agendamento;
repositório do eval em dd3db17, conferido por ela pelo túnel. Tratei isso como
fato relatado, conforme o prompt v2, sem alegar verificação local. A SUPOSIÇÃO
pendente da v1 recebe essa evidência externa. **Não foi medido aqui** o modelo
emitindo o literal indevidamente; esse permanece um risco condicional declarado.
Forma interna e baixabilidade de mídia real de echo continuam não medidas,
como já declarado e aceito na revisão v1.

**Próximos passos**

1. Reescrever o gatilho no comentário, plano e relato usando evidência existente
   e a origem da oferta; preservar o escopo fechado, sem mecanismo novo.
2. Corrigir as afirmações de duração/exclusividade, a promessa do teste e as
   distâncias restantes; conferir as frases irmãs no pacote corrente e registrar
   os comandos/resultados no commit.
3. Submeter o delta de correção aos filtros aplicáveis e à próxima revisão.

BLOQUEADOR: o gatilho declarado para reabrir a marca falsa não corresponde ao sinal produzido pelo handoff
