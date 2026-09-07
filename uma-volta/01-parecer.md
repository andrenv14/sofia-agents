# Parecer independente — `fala-do-dono-completa`, volta 1

## Identificação

- SHA revisado: `85956ce83df1fec9fd5c2807914bf8eb9aa79c98`.
- Base: `8d55955`.
- A worktree está em `HEAD` destacado, limpo; `origin/fala-do-dono-completa`
  aponta para o mesmo SHA. Isso é compatível com a worktree de revisão preparada
  pela guia.
- O diff do pacote é byte a byte igual a `git diff 8d55955..85956ce`.

## O que li

- `AGENTS.md`, inclusive decisões fechadas, convenções de texto durável,
  protocolo de revisão de diff, infraestrutura e critérios de julgamento.
- `docs/features/coexistence-onboarding.md`.
- Plano final `docs/plans/fala-do-dono-completa.md` e plano de origem
  `docs/plans/fala-do-dono.md`.
- `ESTADO.md` e o trecho pertinente do `LOG.md`.
- Os sete commits e seus corpos.
- Todos os blobs finais tocados pela branch: `docs/contexto/fila.md`, os dois
  planos, `src/admin/panel.js`, `src/ai/systemPrompt.js`,
  `src/coex/marcaAtendimento.js`, `src/server.js`,
  `src/session/sessionStore.js`, `tests/coexSilencioDono.test.js`,
  `tests/echoAudioDoDono.test.js`, `tests/identidadeEchoForma.test.js`,
  `tests/painelMarcaAtendimento.test.js` e `tests/systemPrompt.test.js`.
- Origens citadas necessárias para conferir as afirmações: `src/ai/openrouter.js`,
  `src/support/humanHandoff.js`, `src/coex/silencio.js`, `src/tenants.js`,
  `src/meta/graphApi.js`, `src/ai/transcricao.js` e
  `src/meta/enviosProprios.js`.
- Pacote corrente: relato, diff, lista de commits, suíte do implementador, prova
  por mutação, suíte da guia e as duas repetições isoladas de BSUID.

## Achados

### ALTA — o comentário que declara o invariante tem uma exceção omitida e se contradiz sobre autocura

Em `src/admin/panel.js:2011-2020`, o texto afirma que a marca só aparece onde o
prompt a explica, que as exceções conhecidas são três e que todas se fecham
sozinhas. Há dois problemas mecânicos no código final:

1. A primeira exceção é descrita logo em `src/admin/panel.js:2022-2025` como
   permanente até alguém mexer. Portanto ela não se fecha sozinha.
2. Existe uma quarta exceção lexical, produzida pelo próprio caminho declarado:
   a rota aceita texto arbitrário em `src/admin/panel.js:1994`; com
   `tenant.coexistencia === false`, `marcar` devolve esse texto sem alteração em
   `src/admin/panel.js:2046` e o grava como `assistant` em
   `src/admin/panel.js:2064-2065`. Se o operador enviar literalmente um texto que
   comece com `MARCA_ATENDIMENTO` (`src/coex/marcaAtendimento.js:35`), a marca
   aparece no histórico, mas o bloco que a explica fica ausente por
   `src/ai/systemPrompt.js:87`. Não depende do comportamento do modelo.

O próprio prompt reconhece que o literal pode ser escrito por outra origem e
qualifica o lado do paciente (`src/ai/systemPrompt.js:90-95`); a mesma colisão no
lado `assistant` fora de Coexistence não está declarada. Com o escopo fechado,
não peço mecanismo novo: o limite precisa ser descrito honestamente. Além disso,
o operador é informado de que um estado permanente se encerra sozinho.

### BAIXA — o contrato documentado de `decidirFalaDoDono`/`decisaoDoEstado` omite campos que a branch acrescentou

Os docblocks em `src/server.js:1671` e `src/server.js:2007` enumeram o retorno
como `{ texto, gravar, identidade, descricao, observavel }`. O objeto final
também devolve `audioId` em `src/server.js:2040` e `estado` em
`src/server.js:2059`. A branch acrescentou os campos e tornou as duas
enumerações obsoletas. É texto durável falso sobre o contrato da própria função.

### BAIXA — a branch reintroduz contagens descritivas sem comando de rederivação

O caso mais direto está em `src/server.js:1766`: “TRÊS LEITURAS DE audio”. O
mesmo bloco diz em `src/server.js:1795-1797` que a contagem anterior dessa classe
foi removida porque envelheceu, mas a reintroduz imediatamente acima. O critério
correto já existe em `src/server.js:1733-1741`: toda desreferência de conteúdo
deve ficar na cláusula, e fora dela só podem existir os campos permitidos.

A mesma classe aparece em afirmações operacionais novas de
`src/ai/systemPrompt.js:69-71`, `tests/echoAudioDoDono.test.js:103-107` e
`tests/painelMarcaAtendimento.test.js:80-84`, além das contagens de consumidores,
blocos, efeitos e exceções em `docs/plans/fala-do-dono-completa.md:133-137`,
`docs/plans/fala-do-dono-completa.md:155-160`,
`docs/plans/fala-do-dono-completa.md:177-194`. Nenhuma traz comando de
rederivação. A contagem de exceções também já é materialmente falsa pelo achado
anterior.

## Verificações que passaram

- `MARCA_ATENDIMENTO` está em módulo folha e os dois escritores humanos usam o
  helper: `registrarFalaDoDono` sempre; painel apenas sob Coexistence. A busca de
  `'assistant'` em `src/` não revelou terceiro escritor humano sem marca. O outro
  escritor é `pushTurn`, a resposta da IA.
- `buildSystemPrompt` condiciona o bloco a `tenant.coexistencia`, interpola a
  constante e qualifica corretamente que a regra vale para o lado `assistant`;
  o fixture sem Coexistence não mudou.
- A receita `grep -nE "\b(echo|audioCru)\?*\." src/server.js` existe uma vez.
  Todas as leituras de conteúdo dentro de `decidirFalaDoDono` estão entre
  `try`/`catch`; fora dela só aparecem `id`, `to` e `to_user_id`, como declarado.
- O fallback de áudio cobre recusa de metadados, recusa de bytes, `audio` sem ID,
  `audio` não objeto e transcrição vazia. Todos degradam para a linha marcada sem
  lançar; o silêncio já foi gravado antes e não é alterado por esses caminhos.
- A forma interna e a baixabilidade da mídia de echo estão declaradas como não
  medidas. Essa declaração é honesta.
- A propriedade deriva os eixos de `Object.keys(corpus[0].estado)`, põe o estado
  `ilegivel` no produto e varia todos os campos. As mutações dirigidas M6, M7 e
  M8 ficam vermelhas; M8 demonstra que `chavesAudio` entrou pela reflexão. Em
  produção, nenhum consumidor lê `.estado`.
- As quatro dívidas do parecer v7 estão corrigidas nos blobs da branch: “PISO”
  não sobrevive como afirmação falsa no plano, docblock ou relato corrente;
  “mesmo segundo” não identifica lote; “só descrições” saiu. O comando amplo de
  `3bb64cd` encontra cópias antigas e não integrantes do pacote corrente em
  `~/para-revisao/` (`plano-fala-do-dono.md` e versões intermediárias), portanto
  a alegação do commit não descreve o diretório da VPS hoje. Registrei como
  divergência de artefato; para o parecer, prevaleceu o blob da branch e o relato
  corrente, conforme o prompt.
- A inversão de ordem durante a transcrição é a que o texto descreve e a ausência
  de trava está declarada.
- A prova negativa contra a base é fraca como o relato admite, mas as mutações
  dirigidas M1-M9 exercitam os defeitos comportamentais e ficam vermelhas no SHA
  final. Considerei essa prova executada suficiente para as correções cobertas.

## Suíte e flake da guia

Antes da minha execução, `pg_stat_activity` mostrou zero outras conexões em
`sofia_test`, excluindo `pid <> pg_backend_pid()`. Rodei `npm run test:agent` uma
única vez, com SHA/ref/tree no mesmo arquivo: 47 arquivos, 685/685 testes, árvore
limpa, duração 221,71 s.

A medição da guia continua sendo 684/685; não a renomeio como verde. A evidência
basta, porém, para classificar a falha 5e de BSUID como flake alheio à branch:
arquivo e linha crítica não foram tocados, a mesma corrida está registrada antes
desta fatia, as duas repetições isoladas passaram 13/13 e a execução independente
completa no mesmo SHA passou 685/685. Ela não é o bloqueador desta volta.

## SUPOSIÇÃO

O comportamento da Sofia diante da marca — inclusive delegar e acionar
`humano_pendente` — depende do cenário 17 do `sofia-eval`. Não o medi nesta
máquina e não o usei para aprovar ou bloquear este parecer. Também não tratei
como achado a possibilidade de a própria IA emitir o literal da marca, pois sua
ocorrência depende do comportamento do modelo; o quarto caso acima é inteiramente
determinístico no código do painel.

## Próximos passos

1. Reescrever o comentário, o plano e o relato para declarar a colisão literal
   do painel fora de Coexistence e para não afirmar que a exceção permanente se
   fecha sozinha; sem ampliar o mecanismo da fatia.
2. Atualizar as duas enumerações do retorno para incluir `audioId` e `estado`.
3. Trocar as contagens descritivas citadas por critérios verificáveis ou pôr o
   comando de rederivação ao lado quando o número for indispensável.
4. Reexecutar os filtros de texto/citações sobre a correção e devolver a volta 2;
   a guia junta o parecer do `sofia-eval` separadamente.

BLOQUEADOR: o limite durável da marca omite uma exceção produzida pelo painel e afirma autocura para um estado permanente
