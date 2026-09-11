---
name: revisao-externa
description: Como disparar os filtros de encerramento de fatia — Gemini por agy, Codex por CLI, worktree para o revisor medir, e o cabeçalho de identidade da medição. Use ao encerrar uma fatia de código, ao preparar uma volta de revisão, ou quando precisar que um revisor externo rode a suíte.
---

# Disparar revisão externa

Esta skill é o PROCEDIMENTO. As regras de julgamento — o que vai para revisão,
quem decide, o que é bloqueador — estão no `AGENTS.md`, seção "Protocolo de
revisão de diff", e não se repetem aqui: cópia de regra envelhece em silêncio,
e foi o que aconteceu com o `~/.codex/AGENTS.md` num intervalo de dias.

## A sequência, e ela é o mecanismo

Cada filtro roda sobre o código já corrigido pelo anterior. Por isso em
SEQUÊNCIA, nunca em paralelo — eles disputam working tree, `<banco de teste>` e a
porta 3000, e rodá-los juntos numa fatia deu checkout perdido e falhas por
contenção.

    1. revisor          claude-opus-5 · xhigh      julga o diff contra a spec
    2. conferidor       gemini-3.8-flash-high      confere AFIRMAÇÃO contra o código
    3. /code-review     Claude                     corrige e simplifica
    4. prova-negativa   Claude                     os testes falham sem a correção?
    5. codex exec       gpt-5.6-sol · xhigh        DECIDE O MERGE

O degrau 4 é obrigatório quando a fatia corrige bug. Doc pura dispensa o
pipeline inteiro.

---

## Degrau 2 — o conferidor, por `agy -p`

Roda **em desenvolvimento**. O `agy` de produção está sem credencial de propósito, decisão de: ele autentica na conta Google do dono do projeto com escopo `cloud-platform`, e
a máquina de produção é máquina exposta.

Prompt em `~/para-revisao/prompt-conferidor-<fatia>.md`, parecer em
`~/para-revisao/parecer-conferidor-<fatia>.md`.

**A forma do disparo é obrigatória, e cada exigência foi medida:**

- **O prompt PRECISA trazer o inventário de arquivos e o aviso de que o shell
  está indisponível.** Sem esse bloco a rodada volta vazia — medido 2 de 2 sem
  ele, 0 de 5 com ele. O `agy` explora por shell por padrão, e o shell é
  auto-negado porque `command` não está no allow dele.
- **Valide pelo CONTEÚDO**: `response` não-vazia, com stderr capturado em
  arquivo PRÓPRIO (`2>`, nunca `2>&1`). Nem o código de saída nem o campo
  `status` do JSON servem: a rodada vazia sai com `exit=0` E com
  `"status": "SUCCESS"`, e o aviso que a explica vai só para o stderr.
- **Vazia duas vezes**: caia para o agente `conferidor-de-citacoes` (Claude) e
  avise. Sem esse fallback uma fatia passa sem conferidor nenhum e ninguém nota.

**O que o conferidor recebe tem de vir no PROMPT.** Medido, com
marcador plantado e dois controles: o `agy -p` **não carrega** `AGENTS.md`,
`GEMINI.md` nem `.agents/rules/*.md` — nem com o arquivo em maiúsculas, nem
rodando de dentro do diretório, nem dentro de repositório git. A documentação
do Antigravity afirma o contrário; ela está errada. Relatório em
`~/para-revisao/agy-carrega-agents.md`.

**O `read_file` dele É escopável, e o padrão errado desliga tudo em silêncio.**
Medido na 1.2.1, sempre de DENTRO e de FORA do diretório:

    read_file(/caminho/**)   NEGA TUDO, inclusive de dentro — rodada sai vazia
    read_file(/caminho/*)    NEGA TUDO, idem
    read_file(/caminho)      permite de dentro, inclusive aninhado; nega de fora

Os dois primeiros são o que qualquer um escreveria por analogia com glob de
shell, e **desligam o conferidor inteiro sem erro visível** — a rodada volta
vazia, que é o mesmo sintoma de prompt mal formado. Quem medisse só de fora
concluiria que escopou. **O teste que decide é de DENTRO**, com o de fora como
controle ao lado.

O casamento é por caminho, não por texto: sob `read_file(.../teste-escopo)`, um
diretório irmão chamado `teste-escopo-fora` — prefixo de string do padrão — foi
negado.

Uma medição anterior (, versão 1.1.27) registrou o contrário: que
`read_file(<caminho>)` não casava nada. As duas medições valem cada uma para a
sua versão; não há como voltar à anterior para desempatar.

**Dois limites que mudam como se lê o parecer dele:**

- **O auto-relato dele não é evidência.** Na medição ele declarou
  "Arquivos lidos: 1" tendo feito dezenas de chamadas. O que vale é o registro
  de trajetória, em `~/.gemini/antigravity-cli/conversations/<id>.db`, tabela
  `steps`. Parecer sem nenhuma leitura de arquivo no registro é parecer
  OPINADO, não conferido.
- **Ele lê o que alcança, não só o diretório da fatia.** Com `read_file(*)` no
  allow e sem barreira de caminho, uma rodada  saiu do diretório de
  trabalho e leu a transcrição da sessão do Claude Code que a disparou. Não
  dispare o conferidor em máquina que guarde segredo, e não conte com o
  diretório de trabalho como fronteira.

**Uma passada PORTEIA o que já se sabe procurar** — o gabarito saiu
5 de 5, com zero falso positivo. Não é exaustiva na periferia: para caçar o que
ninguém viu, mais de uma passada acha mais que uma.

---

## Degrau 5 — o Codex, por CLI

    codex exec --sandbox read-only - < ~/para-revisao/prompt-codex-<fatia>.md \
      > ~/para-revisao/parecer-codex-<fatia>.md

**Use o `codex` do PATH.** Decisão do dono do projeto, medida: existem duas
instalações, e a da extensão do VS Code é resolvida por glob com `head -1`, que
ordena por **nome de pasta** — sem relação com versão. O resultado já divergia
entre as máquinas (uma pegava `0.154.0-alpha`, a outra `0.153.0`), e o PATH tem
a mesma versão nas duas. Confira antes de disparar:

    which codex && codex --version

**`codex` e `agy` nunca entram em `allow`** — cada disparo abre diálogo, de
propósito. Sem shell, o `agy` não executa nada, e é isso que o mantém seguro
sem sandbox.

O Codex carrega sozinho o `AGENTS.md` do repositório e o `~/.codex/AGENTS.md`
do usuário —, medido nos dois canais, com marcador plantado e controle
negativo. Não copie regra do projeto para o prompt: ele já tem.

---

## Quando o revisor precisa MEDIR

**A regra é não medir.** A medição que sustenta o merge chega pronta, com
cabeçalho de identidade. Mandar o revisor reproduzir suíte ou prova negativa é
comprar a mesma fonte duas vezes: na volta 1 numa fatia isso deu
76 turnos e 503 mil tokens não cacheados, com a suíte rodada onze vezes e os
logs já prontos na mão de quem pediu.

**Volta só de TEXTO**: dispare com `--sandbox read-only` e **sem**
`node_modules` — assim a restrição é mecânica, não um pedido no prompt que a
volta seguinte esquece. Para provar que não há linha executável nova:

    git diff <sha-medido>..<head> -- src/ tests/

filtrado das linhas de comentário e vazias, com o comando e o resultado dentro
do prompt. **A exceção que reabre a suíte é qualquer linha fora de comentário
no diff, inclusive em teste.**

### A receita para o Codex medir, quando não há medição pronta

Vale só quando a fatia promete propriedade que só a execução mostra E não
existe medição com cabeçalho para entregar.

1. **`git fetch`** — feito por quem dispara; o sandbox não alcança o GitHub.
2. `git worktree add --detach ~/rev-<fatia> <branch>` — **nunca** a working
   tree principal, e **no mesmo filesystem do repositório**, não em `/tmp`.
3. `cp -al <raiz>/node_modules ~/rev-<fatia>/node_modules` — **hardlink,
   nunca symlink.**
4. `codex exec --sandbox workspace-write -C ~/rev-<fatia> -c sandbox_workspace_write.network_access=true`
   — a rede serve só ao Postgres local.
5. Ao fim: `git status` na principal (tem de estar limpa), remover o
   `node_modules` copiado, `git worktree remove --force`.

**Por que o passo 3 é assim, medido:** com `ln -s`, o `node_modules` aponta
para FORA da raiz gravável; sob `workspace-write` o Vite tenta criar
`node_modules/.vite-temp`, recebe `EROFS`, e a suíte nem inicia — derrubou a
10ª volta numa fatia e as três numa fatia. O `cp -al` exige
mesmo filesystem, e é por isso que o worktree sai de `/tmp`: em desenvolvimento `/tmp` é
outro device e o `cp -al` falha com cross-device; em produção os dois são o mesmo
disco. `~/rev-<fatia>` funciona nas duas máquinas.

**O teste certo da correção é o vitest INICIAR, não a suíte passar** — o
`EROFS` acontecia ao carregar o `vitest.config.js`, antes da descoberta de
testes.

**`danger-full-access` nunca.**

### O cabeçalho de identidade — medição sem ele não vale

Sem isto o número existe, mas a ATRIBUIÇÃO dele ao commit revisado depende da
palavra de quem mediu — e o terceiro existe justamente para o parecer não se
apoiar em palavra. Achado do Codex na 3ª volta numa fatia.

**Meça DEPOIS de commitar**, a partir da worktree:

    { echo "SHA:  $(git rev-parse HEAD)"
      echo "ref:  $(git log --oneline -1)"
      echo "tree: $(git status --porcelain | wc -l) arquivo(s) modificado(s)"
      npm run test:agent; } > arquivo.log 2>&1

O SHA sozinho não basta: é o "0 arquivo(s) modificado(s)" que liga o número ao
commit, porque suíte medida com working tree suja mede outra coisa. Vale para
qualquer medição que sustente decisão de merge, não só para a suíte.

**Salve a saída inteira em arquivo antes de cortar para ler.** `| tail -8`
devolve o resumo e joga fora o bloco que nomeia o teste que falhou — e o nome é
a diferença entre "1 falhou, não sei qual" e um item de fila de uma linha.

**Quando o sandbox ainda assim não medir**, o Codex declara que não mediu, e a
suíte é medida por um TERCEIRO antes do merge — apto apoiado em número de quem
implementou é parente próximo de parecer comprado.

---

## Conferir o pacote antes de disparar

**Cada artefato citado no prompt é conferido contra o objeto real da branch — e
"cada" é a palavra que importa, não "os importantes".**

    git hash-object <arquivo>        # comparado a
    git rev-parse <SHA>:<caminho>

Medido na 5ª volta numa fatia: os dois diffs foram conferidos
byte a byte e passaram; o PLANO que foi junto era o blob de dois commits antes.
O Codex percebeu sozinho e leu o da branch — a volta não se perdeu **por sorte,
não por desenho**. Um revisor menos cuidadoso teria emitido parecer contra um
documento que já não descrevia o código.

A escolha do que conferir é onde mora o ponto cego: ali, o que falhou foi
conferir a peça eleita central (o diff) e concluir sobre o conjunto.

## Antes de disparar qualquer volta

- **A janela de revisão protege TODO artefato que o revisor lê**, não só a
  `main`. Enquanto o parecer não sai, relato, spec, plano e prompt não mudam.
  Fato novo que apareça no meio vai no PROMPT da volta seguinte, nunca por
  edição do artefato sob leitura.
- **Rode em background** — a revisão demora minutos.
- O pacote em `~/para-revisao/` é **local por máquina**. Copie antes de
  referenciá-lo do outro lado:
  `scp ~/para-revisao/*.md <usuário>@<servidor>:~/para-revisao/`
