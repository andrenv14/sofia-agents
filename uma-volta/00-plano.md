# Plano — fatia `fala-do-dono-completa`

## Contexto

A fatia `fala-do-dono` pôs a resposta do dono no histórico da conversa. Ela
grava o que ele escreve pelo app dele, em Coexistence, como turno de
`assistant` — `registrarFalaDoDono` (`src/session/sessionStore.js`), chamada no
fim do laço de echos de `processarEchoDoDono` (`src/server.js`). O texto entra
tal e qual, **sem marca de autoria nenhuma**.

Para o modelo, o dono e a Sofia são o mesmo lado da conversa — é o desenho, e
está justificado no docblock de `registrarFalaDoDono`. O que falta é a segunda
metade: dentro desse lado, a Sofia não distingue uma promessa PRÓPRIA de uma
frase do dono. Se a dona escreve "consigo te encaixar depois de amanhã às 10h",
a Sofia lê aquilo no turno seguinte como oferta sua; o paciente responde
"confirmado então" e ela confirma um horário que nunca ofereceu nem verificou.

O instrumento que mede isto é o cenário `17-marca-de-autoria-do-dono` do
`sofia-eval`, que nasceu vermelho contra a `main` de propósito, antes desta
fatia existir. Ele não julga texto: julga efeito no banco. Esta fatia não toca
o `~/sofia-eval`.

A segunda lacuna é o áudio. Áudio do dono vira o marcador de teor indisponível,
sem conteúdo — a Sofia volta do silêncio sabendo que houve resposta e não o que
ela dizia. O caminho do paciente já resolve isso inteiro, com `baixarMidia`
(`src/meta/graphApi.js`) e `transcreverAudio` (`src/ai/transcricao.js`).

Resultado pretendido: a Sofia enxerga de quem foi cada linha do próprio lado, e
**delega** em vez de agendar quando o paciente aceita uma oferta que não foi
dela — decisão do fundador, registrada no `ESTADO.md`.

## Commit 1 — as quatro dívidas declaradas do parecer v7

Nenhuma é comportamento. Duas mudanças em `src/server.js`, as duas para tornar
o estado alcançável pelo teste de propriedade:

- acrescentar `identidadeDoEstado` e `descricaoDoEstado` à linha de `export` do
  fim do arquivo, onde `decidirFalaDoDono` já está exportada pelo mesmo motivo;
- `decisaoDoEstado` passa a devolver também `estado`. **O retorno inteiro não se
  enumera aqui:** ele vive no docblock daquela função, que é quem monta o objeto.
  Esta linha já foi a terceira cópia da enumeração e nasceu incompleta — omitia
  `audioId` — enquanto o docblock afirmava unicidade (achado do `revisor`).

**Por que devolver o `estado` e não extrair um `estadoDoEcho` exportado.** A
alternativa junta os dois pontos de construção do estado — o ramo do getter
hostil e o normal — numa função só, o que é diff estrutural num commit que não
é de comportamento, e mexe justamente no que a estabilidade da ordem das chaves
da identidade depende ("`estado` nasce sempre do mesmo literal, nos dois pontos
de construção", no docblock de `identidadeDoEstado`). Devolver o estado é uma
linha. O custo é uma chave que **nenhum caminho de produção lê** — dito como
critério e não como lista, porque a lista já nasceu incompleta uma vez neste
mesmo parágrafo: de tudo o que `grep -rn "\.estado\b" src/ tests/` devolve,
nada em `src/` toca um objeto de DECISÃO (o que aparece é `reconciliacao.estado`,
de `src/calendar/googleCalendar.js`, outro objeto de outro módulo), e o único
leitor de `decisao.estado` está em `tests/`. O arquivo já tem o precedente declarado —
`observacaoDoEcho` é exportada só para teste, com a razão escrita no docblock
dela.

Isto não alarga a exposição de conteúdo: o corpo do dono nunca entra no estado
(viaja em `texto`, e o estado guarda `temTexto`, um booleano), e é essa cláusula
que faz o log carregar forma e nunca teor.

**1a. A propriedade cruza `ilegivel × wamid`** —
`tests/identidadeEchoForma.test.js`.

Hoje o teste só alcança o estado por `decidirFalaDoDono`, que o CONSTRÓI a
partir de um echo; os eixos são a lista `formas`, escrita à mão, e o estado
`ilegivel` nem é alcançável por ela — precisa de getter hostil, e vive num `it`
isolado que compara só descrição e gravação. Foi por essa fresta que a mutação
do Codex passou.

O teste passa a enumerar por REFLEXÃO, como manda a cláusula do `AGENTS.md`:

- os EIXOS saem de `Object.keys(decisao.estado)` de um estado REAL — do ESTADO,
  nunca da identidade. Derivar os eixos da identidade seria enumerar a partir do
  instrumento sob teste: sob a mutação que tira `wamidUtil` da identidade
  SEMPRE, a identidade deixa de ter a chave, o produto cartesiano nunca varia
  esse campo, e o teste fica verde exatamente na regressão que existe para
  acusar. É por isso que a cláusula do `AGENTS.md` diz "`Object.keys` do próprio
  estado";
- os VALORES de cada eixo saem dos estados reais produzidos pelo corpus de
  echos que o arquivo já tem, colhidos por eixo;
- o produto cartesiano desses eixos alimenta `identidadeDoEstado` e
  `descricaoDoEstado` diretamente. `ilegivel` é uma coordenada como as outras,
  não um caso à parte;
- o invariante é verificado agrupando os casos por identidade num `Map` e
  exigindo uma descrição só por grupo — não pelo laço de pares de hoje.

Campo novo no estado entra no produto sozinho, chame-se ele como se chamar.

Prova obrigatória antes de contar como feita, em DUAS variantes, e as duas têm
de ficar VERMELHAS:

- tirar `wamidUtil` de `identidadeDoEstado` só quando `ilegivel` — a mutação do
  Codex, que o teste de hoje deixa passar;
- tirar `wamidUtil` de `identidadeDoEstado` SEMPRE — a que prova que os eixos
  não vieram da identidade.

**1b. "PISO" sai de onde afirma o que o código não sustenta.** O aviso de lote
não cortado sai por echo — nem piso nem teto —, como `docs/contexto/fila.md` já
diz corretamente e o próprio sítio de chamada em `processarEchoDoDono` mostra.
As irmãs se acham por comando, e o comando é case-INsensitive, porque duas
delas estão em minúsculo:

    grep -rniE "\bpiso\b" . ~/para-revisao/

A mensagem do commit traz esse comando, o resultado, e a lista do que NÃO é
irmã — os "piso" verdadeiros sobre outra coisa, para o comando não virar poda
cega.

**1c. `docs/contexto/fila.md` deixa de equiparar "mesmo segundo" a "mesmo
lote".** Dois webhooks distintos podem chegar no mesmo segundo, para o mesmo
telefone, e reservar mensagens diferentes. Telefone e instante ajudam a
investigar; não autorizam fundir os casos. Linguagem só investigativa.

**1d. O comentário obsoleto de `tests/identidadeEchoForma.test.js`** que diz
que o teste do eixo do wamid "compara só descrições" — ele já compara
identidades.

## Commit 2 — a marca de autoria (peça central)

**Onde a marca mora: no `content`, na ESCRITA.** Precedente `MARCADOR_AUDIO`
(`src/server.js`), que vai para `messages` e para o prompt do modelo, o mesmo
string nos dois. Marcar na leitura não é possível: `getHistory`
(`src/session/sessionStore.js`) não tem por onde separar a linha do dono da
linha do painel — as duas são `assistant` com `wamid_lote` NULL.

**Fonte única em `src/coex/marcaAtendimento.js`** — `MARCA_ATENDIMENTO` e
`comMarcaDeAtendimento`. **O módulo é FOLHA: `grep -n "^import"
src/coex/marcaAtendimento.js` não devolve nada.** E tinha de o ser:
`buildSystemPrompt` o consome, e uma constante que vivesse ao lado de
`CORPO_SEM_CONTEUDO` em `src/server.js` faria ciclo de import pelo caminho
`server.js` → `openrouter.js` → `systemPrompt.js`.

**Quem a consome, e o consumidor que fecha a classe do contrato copiado:** os
escritores de linha da clínica — `registrarFalaDoDono` e a rota de envio manual
do painel (`adminRouter`, `src/admin/panel.js`) — e, o que importa,
`buildSystemPrompt`, que **interpola** a mesma constante em vez de repetir a
string, de modo que marca e instrução não têm como divergir. Quem confere a lista
em vez de a ler daqui: `grep -rn "^import.*marcaAtendimento" src/` — o padrão é o
do IMPORT, e não o nome solto, porque o nome solto casa também as menções em
comentário e faria `src/server.js` parecer consumidor, que é justamente a leitura
errada que o comando existe para evitar.

**PREFIXO ÚNICO, SEM EXCEÇÃO, e a ausência de exceção é a feature.** O caso de
teor indisponível declarava a autoria dentro da própria frase, o que dava duas
formas de linha da clínica no histórico — uma com prefixo, outra com a autoria
embutida — e o modelo teria de reconhecer as duas. Aquela constante passou a ser
só o CORPO: `CORPO_SEM_CONTEUDO` (`src/server.js`), e o conteúdo gravado é o
prefixo mais ele.

**O texto da marca não pode afirmar mais do que o código garante** — dois
desenhos anteriores desta família foram reprovados por marcador que mentia. Ele
diz de quem é a linha, e nada além: não promete que o horário foi verificado,
não promete que não foi, não enumera tipo.

**Como o modelo chega a delegar.** A marca sozinha é indício, não garantia. O
mecanismo é a marca MAIS uma regra em `buildSystemPrompt`
(`src/ai/systemPrompt.js`), num bloco **condicionado a `tenant.coexistencia`**,
fora da lista numerada "COMO CONDUZIR O ATENDIMENTO" e fora do que a branch
`prompt-condicional` reescreve. Ele entra ANTES de `system_prompt_extra`: tudo o
que vem abaixo dali é texto específico do tenant ou do cliente, e esta regra é
mecânica da plataforma. Assim a ordem relativa das instruções do negócio fica
exatamente como era — travado em `tests/systemPrompt.test.js` —, e a justificativa
está no comentário do sítio.

A regra diz o que a marca significa e o que fazer, e para aí —
delegar por `chamar_atendente_humano` e dizer que a clínica confirma. O caminho
já existe inteiro e não se toca: a ferramenta devolve `modo: 'coexistencia'`
(`chamarAtendenteHumano`, `src/support/humanHandoff.js`), o laço de tools de
`src/ai/openrouter.js` marca `escalouParaHumano` no sink de efeitos, e
`processarBuffer` (`src/server.js`) chama `silenciarPorHandoff`
(`src/coex/silencio.js`) no `finally`, que grava `humano_pendente_desde`.

Os 15 minutos de silêncio por echo não mudam. A decisão é sobre o que acontece
quando o silêncio acaba e o paciente volta falando da oferta do dono.

**A prova da peça central é o eval, não teste de string.** O cenário 17 fica
verde com `humano_pendente: true`, medido pela sessão do `sofia-eval` a pedido
da guia, antes do Codex. Os testes de unidade desta fatia são guarda, não prova:
o bloco condicional só aparece sob `coexistencia`, e o conteúdo gravado leva a
marca.

**Os efeitos colaterais conhecidos, declarados:**

- o teste "a fala do dono é gravada CRUA, com as quebras de linha dele"
  (`tests/coexSilencioDono.test.js`) passa a esperar marca + cru. O cru continua
  cru: a marca é prefixo, e `limparTextoExterno` continua fora deste caminho. A
  prova negativa deste teste é obrigatória;
- a barreira do turno `dono:` do eval é `falas_do_dono`
  (`~/sofia-eval/sofia_eval/banco.py`), que casa `content` por **igualdade
  exata** — verificado. O prefixo a quebra. Quem muda é a sessão do eval, a
  pedido da guia; esta fatia não toca aquele repositório. O `wamid_lote` NULL
  das linhas do dono não muda, porque o painel e a barreira do eval o lêem.

**Mudança visível para o dono, declarada:** a bolha da conversa no painel lê
`messages.content` cru, então o prefixo passa a aparecer ali. É consequência de a
marca morar no conteúdo — a mesma do precedente `MARCADOR_AUDIO` —, e não se
esconde: quem lê o painel vê o que o modelo vê.

**O que a marca PERSEGUE, e por que não é garantia.** A meta é que a marca só
apareça em histórico cujo prompt de sistema a explique — daí a rota do painel
marcar só sob `tenant.coexistencia`, a mesma condição do bloco. Mas **a marca é
convenção sobre texto livre, não canal guardado**: `messages.content` é uma coluna
de texto, e o critério que descreve o buraco dispensa lista — *toda escrita de
`assistant` em `messages` que não passe por `comMarcaDeAtendimento` sob
Coexistence pode pôr o literal lá sem a regra junto.* Os escritores se enumeram
com `grep -rn "INSERT INTO messages" src/ | grep -v "//"` — o `grep -v` não é
zelo: sem ele o comando casa os próprios comentários que o citam, que é a família
"a medição inclui o medidor".

Os casos conhecidos ficam declarados juntos no comentário do sítio
(`src/admin/panel.js`), sem numerar — é a contagem que envelhece —, cada um com a
direção em que falha e o que o encerra. **Nem todos se fecham sozinhos**, e uma
versão anterior deste plano dizia que sim:

- *marca sem regra* — tenant que DESLIGUE Coexistence depois de linhas marcadas
  terem sido gravadas. **No contexto fecha-se** por `MAX_MESSAGES` (`getHistory`
  corta pela janela e não consulta Coexistence); **no banco a linha fica**, com a
  marca, até `retention_days` do tenant (`limparConversas.js`) ou até alguém
  limpar a conversa pelo painel — não "para sempre", como dizia a versão anterior.
  A marca continua verdadeira; perde-se a instrução de delegar enquanto ela ainda
  está na janela do contexto;
- *marca sem regra, determinística e sem modelo no meio, e sem autocura no
  contexto enquanto a conversa não andar* — o operador de um tenant fora de
  Coexistence digitando no painel um texto que COMEÇA com o literal da marca.
  Mesma separação do caso anterior: no contexto sai por `MAX_MESSAGES`, no banco
  fica até `retention_days` ou até alguém limpar a conversa. Achado do Codex; com
  o escopo fechado fica descrita, sem mecanismo novo;
- *marca FALSA*, de outra espécie e o caso caro — `pushTurn` grava a resposta da
  própria Sofia como `assistant` sem passar pelo helper. Se o modelo escrever o
  literal na resposta dele, no turno seguinte o histórico diz que a equipe ofereceu
  aquilo, e a regra do prompt manda não confirmar e delegar; daí a cadeia é
  determinística até `silenciarPorHandoff`, e **a Sofia cala o contato por 15 min
  por causa de uma oferta que ela mesma verificou**. O que é exclusivo de
  Coexistence não é o literal chegar ao contexto — o operador põe-no lá em
  qualquer tenant pelo painel, e `getHistory` não filtra —, é o que transforma a
  cópia em dano: a REGRA que manda delegar e o MODO de handoff, que
  só devolve `coexistencia` ali. Logo o rótulo "sem regra" seria errado: a regra
  existe e é ela que dispara. A marca sai do contexto por `MAX_MESSAGES`; o
  silêncio aplicado expira pelo próprio prazo. Achado do `revisor`, e a precisão
  sobre o que é exclusivo é do Codex;
- *marca sem regra, por até `CACHE_TTL_MS`* (`src/tenants.js`), e esta FECHA
  sozinha — ao LIGAR a caixa, o painel já lê o tenant fresco e marca enquanto
  `buildSystemPrompt` ainda recebe o do cache. Achado do `revisor`;
- *regra sem marca*, a direção oposta, e FECHA sozinha — histórico acumulado
  enquanto o tenant estava fora de Coexistence. Recorre em todo onboarding, não só
  no primeiro deploy; o mecanismo é `MAX_MESSAGES`
  (`src/session/sessionStore.js`), porque `getHistory` entrega uma janela das
  linhas mais recentes.

**O dano NÃO é o mesmo em todos**, e a versão anterior desta seção dizia que era.
Onde a marca falta ou sobra, o modelo vê um prefixo que instrução nenhuma explica,
ou linhas da equipe sem prefixo — ninguém perde dado, ninguém é silenciado, não há
migração. O caso da **marca falsa** é o caro, e é o único que pediria mecanismo:
não o ganha aqui por escopo fechado, e fica como limite declarado.

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

## Commit 3 — transcrição do áudio do dono

Reutiliza o caminho do paciente inteiro, sem duplicar: `transcreverMensagemDeAudio`
(`src/server.js`) passou a servir as DUAS pontas, por generalização e não por
cópia — ela recebe o ID da mídia em vez da mensagem, porque as duas pontas têm
envelopes diferentes e nada mais nela depende do envelope. Com isso `baixarMidia`
(`src/meta/graphApi.js`), o teto de tamanho, o saneamento do mime e a linha de
instrumentação existem uma vez só. O token é o do tenant já resolvido em
`processarEchoDoDono`. O áudio transcrito do dono leva a marca de autoria do
commit 2, e a origem entra na linha de log (`áudio do dono para <contato>`):
reusar o texto do paciente diria "áudio de <contato>" para um áudio que o contato
não mandou.

**A transcrição corre ANTES do corte do lote**, e a ordem é decisão: o corte
existe para a pergunta do paciente entrar antes da resposta do dono e mede o
buffer no instante em que roda. Transcrever depois dele deixaria segundos entre o
corte e a escrita — `sequenciaDeChegada` já documenta áudio parado segundos na
transcrição —, e uma mensagem que chegasse nessa janela voltaria a ser gravada
depois da fala do dono.

**A leitura dos campos internos de `echo.audio` fica na cláusula única que já
existe** — a mesma que `decidirFalaDoDono` aplica aos campos de conteúdo do
echo. Campo do echo é valor externo da Meta: guarda por cláusula, nunca sítio a
sítio. Foi guardar sítio a sítio que fez a mesma classe reaparecer a cada
correção, um nível mais fundo.

**As CHAVES de `audio` entram no estado; o `id` NÃO.** A distinção decide o
comportamento do log: chaves são forma e dedupam bem, mas o `id` é único por
áudio, e no estado ele faria o funil `observar` emitir uma linha por echo em vez
de colapsar forma repetida — o oposto do que a instrumentação existe para fazer.
O `id` viaja por fora do estado, pelo mesmo caminho que o corpo do texto já usa.

**A decisão de transcrever sai de `decisaoDoEstado`**, junto de `gravar`, e não
do sítio de chamada: só há o que transcrever quando o conteúdo ia ser o marcador
de teor indisponível E há `id` utilizável. Com texto legível o texto ganha; com
tipo ignorado ou sem wamid nada é gravado, e baixar mídia para descartar seria
gasto de rede sem efeito.

**O que NÃO estava medido quando o plano foi escrito — MEDIDO no deploy de
07/09/2026 às 15:03 UTC, com um áudio do fundador pelo app do número da Riacho
(tenant 4), e os dois fecharam positivos (registro no `LOG.md`):**

- a forma interna de `echo.audio`: `["mime_type","sha256","id","url","voice"]`
  — a linha de instrumentação das chaves de `audio` cumpriu o que existia para
  cumprir; pode continuar, mas já não é o instrumento de uma pergunta aberta;
- **a mídia de um echo É baixável com o token do tenant**: 4.179 bytes,
  `audio/ogg`, transcrição gravada com a marca de autoria. O texto original
  dizia que isto não era mediável antes do merge, e a razão continua verdadeira
  para a época: o id da mídia nunca chegava a log nenhum — `observar` registra
  as chaves de primeiro nível e nunca valores —, então não existia um
  `echo.audio.id` real com que testar o Graph antes deste código.

O que torna o não-medido seguro é o **fallback**, e ele é PROVADO por teste:
`baixarMidia` devolvendo `ok: false`, ou `audio.id` ausente, ou a transcrição
vindo vazia, resultam em `CORPO_SEM_CONTEUDO` sob a marca de autoria do commit 2
— a linha é gravada, o silêncio não é afetado, e nada lança. É o comportamento de
hoje, preservado como o desfecho mínimo do caminho novo. `tests/echoAudioDoDono.test.js`
cobre cada porta dessa degradação, e o caminho feliz carrega o controle positivo
que impede as asserções de ausência dele de passarem por vacuidade.

O relato declara em letras: baixabilidade da mídia de echo NÃO medida; o
primeiro teste é no tenant 4, no deploy, com o fundador mandando um áudio pelo
app dele — que é a regra do `AGENTS.md` para toda mudança de Coexistence.

## Fora do escopo

O status terminal de `mensagens_pendentes` gravado depois do `finally` de
`processarBuffer` **fica na fila**, e o motivo não é tamanho: esse instante é a
barreira que o `sofia-eval` usa hoje, inclusive para medir o cenário 17 contra
esta branch. Não se troca o instrumento durante a medição. O item da fila passa
a registrar que ele espera a barreira do eval deixar de depender desse instante.

## Verificação

1. **As duas mutações do commit 1**, antes de tudo: tirar `wamidUtil` de
   `identidadeDoEstado` só quando `ilegivel`, e depois tirá-lo SEMPRE. As duas
   têm de deixar `tests/identidadeEchoForma.test.js` vermelho. Reverter cada uma.
2. **Prova negativa** dos testes novos do commit 2 contra a `main`, pelo agente
   `prova-negativa` — obrigatória, e inclui o teste da fala gravada crua.
3. **Suíte medida DEPOIS de commitar**, com o cabeçalho que liga o número ao
   commit (SHA, ref, estado da working tree), saída inteira em arquivo.
4. **Pipeline em sequência:** `revisor` → `conferidor-de-citacoes` (com o `.md`
   E o intervalo `base..head`) → `/code-review` → `prova-negativa` → `scp` do
   pacote para a VPS. A guia dispara o Codex.
5. **A peça central:** cenário 17 do `sofia-eval` verde, com a asserção positiva
   `humano_pendente: true`, medido pela sessão do eval contra esta branch. Suíte
   e eval nunca ao mesmo tempo nesta máquina.
6. **No deploy:** áudio real do fundador como dono, no tenant 4, para medir a
   forma interna de `echo.audio` e a baixabilidade.
