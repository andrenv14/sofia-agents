# Relato — fatia `fala-do-dono-completa`

Branch `fala-do-dono-completa`, base `main` @ `8d55955`.
Plano aprovado pelo fundador: `docs/plans/fala-do-dono-completa.md` (versionado no
primeiro commit da branch, antes da implementação).

## O que a fatia faz

A `fala-do-dono` pôs a resposta do dono no histórico como turno de `assistant` —
o dono e a Sofia são o mesmo lado da conversa, e isso é o desenho. O que faltava
era a segunda metade: **dentro desse lado, a Sofia não distinguia uma promessa
própria de uma frase do dono.** A dona oferecia um horário, o paciente dizia
"confirmado então", e ela confirmava um horário que nunca ofereceu nem verificou.

Esta fatia dá autoria a cada linha do próprio lado, e ensina a Sofia a **delegar**
em vez de agendar quando o paciente aceita uma oferta que não foi dela. E
transcreve o áudio do dono, que antes virava só um marcador sem conteúdo.

## Os commits

Volta 1 (código): `4cd0912` o plano aprovado, versionado antes da implementação;
`3bb64cd` as quatro dívidas do parecer v7; `f23117f` **a marca de autoria**, a
peça central; `1ae1b1e` o plano reescrito para o desenho real; `6db84cd` a
transcrição do áudio; `5b779d9` os achados do `revisor`; `85956ce` os achados do
`/code-review`.

Volta 2 (**só texto** — o Codex confirmou o código inteiro): `bb71c59` os achados
do parecer v1; `a1fd787` o achado do `conferidor`; `c691c51` os achados do
`revisor` sobre o delta.

A lista corrente rederiva-se com
`git log --oneline 8d55955..HEAD`, e é o que o pacote traz em
`commits-fala-do-dono-completa.txt` — escrever o número de commits aqui seria
contagem que envelhece na volta seguinte.

## A peça central, e como ela funciona

Nenhuma das peças abaixo basta sozinha:

- **`MARCA_ATENDIMENTO`** (`src/coex/marcaAtendimento.js`), prefixo do `content`
  de toda linha escrita pela mão da clínica. O módulo é folha —
  `grep -n "^import" src/coex/marcaAtendimento.js` não devolve nada — e tinha de
  o ser: `buildSystemPrompt` o consome, e a constante ao lado de
  `CORPO_SEM_CONTEUDO` em `src/server.js` faria ciclo de import.
- **Os escritores de linha da clínica** usam o mesmo helper: `registrarFalaDoDono`
  (`src/session/sessionStore.js`), a porta do echo, e a rota de envio manual de
  `adminRouter` (`src/admin/panel.js`), a porta do painel — que **não tinha teste
  nenhum** e agora tem arquivo próprio.
- **A regra no prompt**, num bloco condicionado a `tenant.coexistencia` em
  `buildSystemPrompt`. Ele **interpola** `MARCA_ATENDIMENTO` em vez de repetir a
  string: marca e instrução não têm como divergir.

**Uma forma só de prefixo, e o alcance dessa afirmação:** ela vale sobre o que o
helper produz — não sobre o que outros caminhos podem escrever no `content`, que é
a seção seguinte. O caso de teor indisponível declarava a autoria dentro da
própria frase; isso dava duas formas de linha da clínica no histórico e o modelo
teria de reconhecer as duas. Aquela constante passou a ser só o corpo
(`CORPO_SEM_CONTEUDO`).

## O que a marca persegue, e por que não é garantia

A meta é que a marca só apareça em histórico cujo prompt de sistema a explique —
daí a rota do painel marcar só sob `tenant.coexistencia`, a mesma condição do
bloco. **Mas é meta, não garantia, e a v1 do parecer pegou-me a afirmá-la como
absoluto.** A marca é convenção sobre texto livre: `messages.content` é uma coluna
de texto, e o critério que descreve o buraco dispensa lista — *toda escrita de
`assistant` em `messages` que não passe por `comMarcaDeAtendimento` sob
Coexistence pode pôr o literal lá sem a regra junto.* Os escritores se enumeram
com `grep -rn "INSERT INTO messages" src/ | grep -v "//"` — sem o `grep -v` o
comando casa os próprios comentários que o citam.

Os casos conhecidos ficam declarados juntos no comentário do sítio
(`src/admin/panel.js`), sem numerar, cada um com a direção em que falha e o que o
encerra. **Nem todos se fecham sozinhos** — e a versão anterior deste relato
dizia que sim, no mesmo parágrafo em que descrevia um deles como permanente:

- *marca sem regra* — tenant que DESLIGUE Coexistence depois de linhas marcadas
  terem sido gravadas. No contexto fecha-se por `MAX_MESSAGES`; no banco a linha
  fica até `retention_days` ou até alguém limpar a conversa pelo painel. A
  distinção contexto/banco é do Codex na v2; o "não é para sempre", na v3;
- *marca sem regra, determinística e sem modelo no meio, e sem autocura no
  contexto enquanto a conversa não andar* — o operador de um tenant fora de
  Coexistence digitando no painel um texto que COMEÇA com o literal da marca.
  Mesma separação do caso anterior: no contexto sai por `MAX_MESSAGES`, no banco
  fica até `retention_days` ou até alguém limpar a conversa. **Achado do Codex, e
  é o bloqueador da v1**: com o escopo fechado fica descrita, sem mecanismo novo;
- *marca FALSA*, de outra espécie e o caso caro — `pushTurn` grava a resposta da
  própria Sofia sem passar pelo helper. Se o modelo escrever o literal na resposta
  dele, no turno seguinte o histórico diz que a equipe ofereceu aquilo, a regra do
  prompt manda delegar, e a cadeia segue determinística até `silenciarPorHandoff`:
  **a Sofia cala o contato por 15 min por causa de uma oferta que ela mesma
  verificou**. Exclusivo de Coexistence não é o literal chegar ao contexto — o
  operador põe-no lá em qualquer tenant, e `getHistory` não filtra —, são a REGRA
  que manda delegar e o MODO de handoff. Achado do `revisor` na volta 2, que
  mostrou que o meu rótulo ("sem regra") e o meu fecho ("nenhum silencia ninguém")
  eram os dois falsos; a precisão sobre o exclusivo é do Codex na v2;
- *marca sem regra, por até `CACHE_TTL_MS`*, e esta FECHA sozinha — ao LIGAR a
  caixa, o painel já lê o tenant fresco e marca enquanto `buildSystemPrompt`
  ainda recebe o do cache. Achado do `revisor`;
- *regra sem marca*, a direção oposta, e FECHA sozinha por `MAX_MESSAGES` —
  histórico acumulado enquanto o tenant estava fora de Coexistence. Recorre em
  todo onboarding, não só no primeiro deploy.

**O dano NÃO é o mesmo em todos** — escrevi que era, e o `revisor` derrubou.
Onde a marca falta ou sobra, o modelo vê um prefixo que instrução nenhuma explica,
ou linhas da equipe sem prefixo: ninguém perde dado, ninguém é silenciado. O caso
da **marca falsa** é o caro e é o único que pediria mecanismo; não o ganha aqui
por escopo fechado, e fica como limite declarado.

**O gatilho para o reabrir é do BANCO, não do log**, e chegou aí na terceira
tentativa. As duas anteriores procuravam sinal no log e erraram: a primeira
apontava para uma linha que não existia; a segunda ("escalonamento sem echo
antes") acusava comportamento CORRETO, porque a oferta real do dono também chega
pela rota do painel, que não gera echo — o `revisor` mediu um turno impecável
produzindo o padrão idêntico ao do caso vigiado.

O que distingue é estrutural: `pushTurn` grava `user` e `assistant` num INSERT
único, e os dois nascem com o mesmo `created_at` porque `now()` é o carimbo da
transação (razão longa no docblock de `getHistory`); as linhas da equipe gravam
`assistant` sozinho. A consulta está no comentário do sítio, em
`src/admin/panel.js`, e foi **medida nos três caminhos de escrita** num
`BEGIN`/`ROLLBACK` do `sofia_test`: `pushTurn` devolve verdadeiro,
`registrarFalaDoDono` e a rota do painel devolvem falso. O falso positivo
conhecido — duas transações no mesmo instante — fica nomeado lá.

**A linha de log do escalonamento não é o gatilho**, e serve para achar
candidatos sem varrer a tabela. Ela nasceu nesta fatia porque handoff
bem-sucedido não emitia linha nenhuma; é o único LOG novo depois da linha de
transcrição do áudio do dono. Quem a grepar usa `grep -F`: a máscara de telefone
é `****NNNN` e os `*` seriam quantificadores de regex — sem `-F` o comando não
casa nada, em silêncio.

*(O trecho acima, do "gatilho" até aqui, é CÓPIA do plano, não paráfrase — contá-lo
em parágrafos seria número que muda na primeira edição. Foi por reescrever
de memória que este relato ficou a prescrever o gatilho que a volta 3 já tinha
rejeitado, enquanto o plano e o comentário do sítio já usavam o do banco —
bloqueador do parecer v3. Quem seguisse o relato acusaria atendimento correto
pelo painel como marca falsa.)*

**Nota sobre a linha de log**, que não está no plano porque lá ela é implementação
e aqui é histórico: escrevi antes que ela era "a única linha executável nova", e o
`conferidor` apertou com razão — o `finally` também ganhou o `const`, o
`return null` e o `if` que guarda a emissão, nenhum com efeito observável próprio.
O que muda no mundo é o LOG.

## Limites declarados

- **A baixabilidade da mídia de um echo NÃO foi medida, e não era mensurável antes
  do merge.** O `id` da mídia nunca chegou a log nenhum, porque `observar`
  registra chaves e nunca valores — não havia com que testar o Graph antes deste
  código existir. O primeiro teste real é no tenant 4, no deploy, com o fundador
  mandando um áudio pelo app dele. **O que torna isso seguro é o fallback, e ele é
  provado por teste**, porta a porta: metadados recusados, bytes recusados, `audio`
  sem `id` utilizável, `audio` que não é objeto, transcrição vazia — todos gravam
  a linha com o marcador, sem lançar e sem tocar o silêncio.
- **A forma interna de `echo.audio` não foi medida.** A linha do echo passou a
  imprimir as CHAVES de `audio` (nunca valores), e é isso que a torna medível no
  primeiro áudio real.
- **A transcrição atrasa a linha do dono, e a ordem gravada pode inverter.** Medido
  pelo `revisor`: contra a base a ordem sai `assistant → user`; aqui sai
  `user → assistant` quando uma mensagem do paciente chega durante a transcrição.
  Aceita-se pelo desempate de sempre — perder ordem é reversível na conversa
  seguinte, perder a fala do dono não —, e a alternativa (gravar o marcador e
  reescrever depois) poria o modelo a ler a versão intermédia.
- **A ordem "transcrever antes de cortar o lote" não tem trava de teste.** Tentei
  travá-la por portão do mock e desisti na terceira variante: o portão do Graph
  não prende download de mídia, o da IA é consumido pela primeira chamada, e o
  buffer dispara por temporizador próprio. O que sairia dali passa ou falha pelo
  relógio. Está declarado no código e na fila, não implícito.
- **A prova do comportamento do modelo não é desta suíte.** A IA aqui é mockada e
  não lê o prompt. Quem prova é o cenário `17-marca-de-autoria-do-dono` do
  `sofia-eval`, com IA real — não verificável desta máquina, e por isso marcado
  como suposição em tudo o que dele depende.

## Medições

- **Suíte:** `~/para-revisao/suite-fala-do-dono-completa.log`, com cabeçalho de
  SHA, ref e estado da working tree. O SHA do cabeçalho é o HEAD da branch, e é
  isso que liga o número ao commit sem depender da minha palavra.
- **Prova negativa por mutação dirigida:**
  `~/para-revisao/prova-mutacao-fala-do-dono-completa.log`, nove mutações, todas
  vermelhas. **O cabeçalho dela é `85956ce`, o último SHA da volta 1.** A volta 2
  não mexeu em código nenhum; a volta 3 acrescentou o bloco do `finally` de
  `processarBuffer`, e **nenhuma das nove mutações toca esse bloco** — elas vivem
  em `identidadeDoEstado`, `decisaoDoEstado`, `descricaoDoEstado`,
  `registrarFalaDoDono`, o bloco condicional do prompt e o `marcar` do painel.
  (A versão anterior deste parágrafo justificava a reutilização dizendo que o
  diff de `src/` desde `85956ce` saía vazio de linhas não-comentário. Deixou de
  ser verdade nesta volta — o bloco do `finally` tem linhas de código —, e o
  `revisor` apanhou. Escrevi "são dez" ao corrigir, e o `conferidor` rederivou 12:
  quinta contagem errada minha nesta fatia, e a única classe de erro que
  atravessou as quatro voltas. A justificativa
  certa é a de cima, e é verificável função a função.)
  Quatro mutações a mais foram medidas nas voltas 2 e 3, nas mensagens dos
  commits: painel incondicional, bloco de prompt movido para o fim, literal da
  marca duplicado, e conteúdo do lote colado na linha de escalonamento.

**A prova negativa contra a base é FRACA, e está dito no próprio log.** Quatro dos
cinco arquivos de teste falham contra `main` por `ERR_MODULE_NOT_FOUND` de
`src/coex/marcaAtendimento.js` — isso prova que o módulo é novo e **não prova
comportamento nenhum**, porque nenhum teste chega a executar. Foi o agente
`prova-negativa` que insistiu nessa distinção, e ele estava certo. A prova de
comportamento é a das mutações sobre o código novo.

A que mais vale é a **M8**: tirando `chavesAudio` da identidade, a propriedade
fica vermelha — o campo novo entrou no produto cartesiano **sozinho**, sem
ninguém tocar no teste. É a trava de reflexão do commit 1 a funcionar no primeiro
campo acrescentado depois dela.

**A peça central está PROVADA fora desta suíte:** o `sofia-eval` mediu o cenário
17 contra `85956ce` — verde 3/3 com `humano_pendente: true`, e o controle contra
a `main` vermelho, com agendamento criado. Medição da sessão do eval, não minha;
não verificável desta máquina, e por isso marcada como tal em tudo o que dela
depende.

## O pipeline, e o que ele achou

`revisor` → `conferidor-de-citacoes` → `/code-review` → `prova-negativa`, em
sequência, cada um sobre o código já corrigido pelo anterior.

- **O `revisor` bloqueou, e o bloqueador era real: `Object.keys` não invoca
  getter.** A leitura de `audioCru.id` estava fora do `try`, com um
  comentário meu a afirmar que a cláusula única a cobria. Não cobria — o objeto
  atravessava a cláusula sem disparar, e o getter só era chamado lá fora, depois
  de `silenciarPorEcho` e de `marcarProcessada`: a linha do dono perdia-se para
  sempre e o resto do payload era abandonado. Era a classe da `audio-transcrito`
  reaberta um nível mais fundo. Ele também derrubou três afirmações do bloco do
  prompt — incluindo uma superfície de injeção que eu criei, porque a regra dizia
  "toda linha do histórico" sem qualificar o papel, e o paciente pode escrever o
  prefixo.
- **O `conferidor` passou limpo:** 20 citações e 20 afirmações conferem, zero
  `file:line`, dois quantificadores verificados no código e não só afirmados. Um
  aperto veio dele — a enumeração de um `grep` no plano estava incompleta, e virou
  critério em vez de lista.
- **O `/code-review` achou o que mais me incomoda ter escrito:** a linha do log
  dizia "entra o marcador" mesmo quando a transcrição entrava. O log é o
  instrumento da pergunta que esta fatia deixa em aberto de propósito, e ele
  respondia o contrário do banco. Mesma classe que o docblock daquela função diz
  ter removido do ramo `ilegivel`, de volta pela porta do áudio.

**A receita de auto-verificação era a culpada de fundo, e virou critério.** Ela
grepava dois campos por NOME (`text|type`) e por isso não cobriu `audio` quando
ele chegou. Agora é `grep -nE "\b(echo|audioCru)\?*\." src/server.js` com a regra
de que toda desreferência dentro de `decidirFalaDoDono` cai entre o `try` e o
`catch`, e as de fora leem só `id`, `to` e `to_user_id`. Campo novo entra sozinho.
E existe **uma** vez: estava copiada em dois docblocks, e nenhuma das cópias
envelheceu junto.
