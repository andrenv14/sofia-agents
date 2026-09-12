# Como este projeto é construído

Um assistente de agendamento por WhatsApp está em produção desde agosto de 2026,
atendendo negócio real. Este repositório é o processo de engenharia que o mantém
assim.

O código é escrito por agentes de IA, e isso sozinho não garante nada. O que
decide se o resultado presta é o que existe em volta deles: uma segunda revisão
que decide o merge e nunca implementa, provas que precisam ser vistas falhar
antes de contar, e regras que o sistema aplica sozinho em vez de confiar em
alguém lembrar delas.

Os arquivos aqui são os que estão em uso, com os detalhes internos do projeto
removidos.

**Irmãos:** [`sofia-vitrine`](https://github.com/andrenv14/sofia-vitrine), a
arquitetura do produto · [`sofia-eval`](https://github.com/andrenv14/sofia-eval),
a avaliação de comportamento do modelo ·
[`riachotech-site`](https://github.com/andrenv14/riachotech-site), o site.

## O que tem aqui

| Onde | O que é |
|---|---|
| [`AGENTS.md`](AGENTS.md) | as regras, que toda sessão lê na abertura |
| [`.claude/hooks/`](.claude/hooks/) | o que o harness executa sozinho — os que saem com código 2 **bloqueiam**, e se acham com `grep -l 'exit 2' .claude/hooks/*` |
| [`.claude/skills/`](.claude/skills/) | quatro procedimentos que carregam só quando o assunto aparece |
| [`.claude/agents/`](.claude/agents/) | seis papéis, cada um com modelo e esforço declarados |
| [`memoria/`](memoria/) | o que um agente aprendeu entre execuções |
| [`docs/`](docs/), [`ESTADO.md`](ESTADO.md), [`LOG.md`](LOG.md) | como o contexto é organizado |

## 1. O arranjo

```mermaid
flowchart TB
    subgraph DEV["Desenvolvimento (sem credencial de produção)"]
        FATIA["sessão de trabalho:<br/>uma tarefa, plano aprovado antes"]
        SUITE["suíte de testes"]
        EVAL["avaliador, com IA real"]
    end
    subgraph PROD["Produção"]
        GUIA["sessão-guia:<br/>orquestra, mede, publica"]
        FILTROS["filtros em sequência:<br/>revisor, conferidor (outro fornecedor),<br/>prova negativa"]
        CODEX["revisor independente<br/>(outro modelo, outro fornecedor)"]
    end
    FATIA --> SUITE
    FATIA -->|"branch"| GUIA
    GUIA --> FILTROS --> CODEX
    CODEX -->|"bloqueador"| FATIA
    CODEX -->|"apto"| MERGE["merge e deploy"]
    EVAL -->|"verde ou vermelho"| GUIA
```

Cada papel tem um limite explícito, e nenhum acumula dois:

| Papel | O que faz | O que nunca faz |
|---|---|---|
| Sessão-guia | orquestra, mede, dispara os filtros, faz merge e deploy | implementar |
| Sessão de trabalho | uma tarefa por vez, cópia própria do código, plano aprovado antes da primeira linha | revisar o próprio diff |
| Sessão do avaliador | roda o avaliador de comportamento com IA real | tocar o código de produção |
| Subagentes | revisar diff, conferir citações, prova negativa, auditar infra e documentação | decidir merge |
| Revisor independente | lê a branch inteira e declara "apto a deploy" ou devolve o bloqueador | implementar qualquer coisa |

**Duas máquinas, separadas por segurança.** Uma é produção e atende cliente
pagante. A outra roda os testes e o avaliador, e não tem nenhuma credencial de
produção: token de plataforma falso, banco de teste, chave de modelo com teto
próprio.

## 2. Modelos por papel

O papel é a arquitetura. O modelo que o cumpre é configuração, e muda.

O requisito é este: **existe uma segunda revisão, independente de quem
implementou, que decide o merge e nunca implementa.** Qual modelo faz isso é
detalhe.

O que cumpre cada papel hoje. "Esforço" é o controle de raciocínio do Claude
Code:

| Papel | Modelo | Esforço |
|---|---|---|
| Implementação | Opus 5 | xhigh |
| Tarefa mecânica: merge, deploy, edição já decidida | Sonnet 5 | alto |
| Decisão: arquitetura, spec, bug que não reproduz | Fable 5.1 | máximo |
| Conferência de afirmações contra o código | `gemini-3.8-flash-high` | alto |
| Revisão independente, que decide o merge | `gpt-5.6-sol` | xhigh |

Modelo se declara por **id exato**, e a linha do Gemini mostra por quê: nesse
modelo **o esforço faz parte do identificador**, então "Gemini 3.8 Flash" não
nomeia um modelo — nomeia três, um por nível de esforço. Aqui ele roda **sempre
em alto**, e isso é regra, não observação: só muda se alguém decidir mudá-la.
Todo id nesta tabela é o da data em que o texto foi escrito, e se rederiva da
configuração da máquina em vez de se copiar daqui — em dois dias esse conjunto
mudou três vezes.

As escolhas seguem uma medição simples: em código de longo horizonte, baixar o
esforço custa qualidade de forma acentuada; em tarefa com roteiro pronto,
esforço extra não compra nada; em decisão, cada degrau de esforço compra. Os
agentes de leitura e relatório ficam em esforço médio, onde empatam com o padrão
por uma fração do custo.

**Fable nunca implementa** e **o revisor independente nunca implementa.** No
segundo caso a garantia é mecânica, não uma promessa no prompt: ele roda num
sandbox só-leitura.

O modelo que atende o cliente é outro assunto, escolhido por custo e latência.
Não tem relação com os daqui.

## 3. Como o contexto é gerido

Um agente só é confiável se o que ele acredita sobre o mundo estiver certo
quando a sessão abre, e se o que ele precisa ler couber.

```mermaid
flowchart LR
    ABRE(["sessão abre"]) --> HOOK["hook de abertura"]
    COMPACTA(["contexto compactado"]) --> HOOK
    HOOK --> ONDE["máquina, branch,<br/>divergência com o remoto"]
    HOOK --> SUJO["cópia de trabalho suja?<br/>processos, banco"]
    HOOK --> AGORA["o estado corrente"]
    ONDE --> SESSAO(["a sessão sabe onde está"])
    SUJO --> SESSAO
    AGORA --> SESSAO
```

**A abertura não depende de ninguém lembrar.** O hook
[`estado.sh`](.claude/hooks/estado.sh) entrega máquina, branch, divergência com
o remoto, estado da cópia de trabalho, processos e banco. Quando o contexto é
compactado no meio da sessão, o mesmo hook reinjeta o estado corrente, que é
justamente o momento em que a sessão mais esquece.

**Cada arquivo declara o que vai nele e o que não vai**, com ponteiro para o
irmão certo. É o que permite ler um arquivo em vez de cinco:

```mermaid
flowchart TB
    P{"a sessão precisa de quê?"}
    P -->|"onde o projeto está agora"| EST["ESTADO.md"]
    P -->|"o que já foi feito"| LOG["LOG.md"]
    P -->|"o que fazer em seguida"| FILA["docs/contexto/"]
    P -->|"contra o que revisar"| SPEC["docs/features/<br/>docs/plans/"]
    EST -.->|"o que já aconteceu<br/>sai daqui"| LOG
    FILA -.->|"item fechado<br/>sai da fila"| CONC["docs/contexto/<br/>fila-concluido.md"]
```


- [`ESTADO.md`](ESTADO.md) é o estado corrente, e só ele. Tem teto de tamanho:
  passou disso, deixou de ser estado e virou diário.
- [`LOG.md`](LOG.md) é o diário, com meses anteriores arquivados.
- `docs/contexto/` separa o que fazer em seguida do que já foi feito, e mantém
  negócio, implantação e carreira em arquivos próprios.
- `docs/plans/` guarda o plano aprovado de cada tarefa, versionado.
- `docs/features/` guarda a spec de cada funcionalidade, que é contra o que o
  revisor lê o diff.

## 4. Onde cada regra mora

Uma pergunta resolve: **quem precisa ler isto, e quando?**

| | vai para | porque |
|---|---|---|
| precisa valer sempre | **hook** | o harness executa; o modelo não contorna |
| vale às vezes | **skill** | carrega sob gatilho declarado |
| orienta julgamento | **AGENTS.md** | lido na abertura |
| é o caso que gerou a regra | **histórico** | entra por ponteiro |

Skill pode ser ignorada; hook não. Por isso "nunca reinicie produção antes de
commitar" é um `exit 2`, e não um parágrafo entre centenas.

O efeito: o arquivo de regras caiu de 1022 para menos de 600 linhas, e de ~17,6
mil para ~9 mil tokens por sessão. Nenhuma regra saiu — o texto mudou de lugar.

### O que cada ferramenta carrega sozinha — medido

| | lê o arquivo de regras do projeto? |
|---|---|
| Claude Code | sim, via `CLAUDE.md` importando o `AGENTS.md` |
| Codex | sim: o do repositório **e** o de usuário |
| Gemini, modo não-interativo | **nenhum arquivo** |

A última linha contraria a documentação do fornecedor. Foi medida com marcador
plantado, controle de responsividade e registro de execução. **Consequência:**
o que o conferidor precisa saber viaja no prompt, e não se cria arquivo de
regras para ele — seria fonte a mais capaz de divergir, sem leitor.

## 5. As regras

Completas no [`AGENTS.md`](AGENTS.md). As que mais mudam o resultado:

**Verificar**

- Duas coisas só contam como duas fontes **se puderem discordar**.
- Medição que pode incluir o medidor exclui-o **dentro do comando**, não na
  interpretação.
- Verificação que passa observando nada precisa **primeiro ser vista falhar**.
  "Nenhum registro criado" é satisfeito pelo acerto e pelo sistema não ter
  rodado.
- Citação de outro agente é **premissa, não verificação**.
- **Medição verdadeira mais salto não verificado dá conclusão falsa com
  aparência de rigor.** O teste: a medição responde à pergunta que você fez, ou
  a uma vizinha?
- **Otimizar para o contador não é otimizar para o objetivo.** Zerar um detector
  apagando a marcação passa igual a corrigir o documento — nenhum detector
  distingue.

**Texto que dura**

- Citação aponta **arquivo e nome de função**; número de linha envelhece em
  silêncio.
- **Contagem não entra.** Quando o número for inevitável, o comando que o
  rederiva vai ao lado — e roda-se o comando antes de colar.
- Quantificador nomeia a exceção, ou vira regra que se verifica sozinha.
- **Número normativo é o contrário:** ele é a regra, e só muda de propósito.
  Antes de podar um número, separar um do outro.
- Número traz **unidade e escopo** na mesma frase. "3 linhas de patch" expõe a
  incompatibilidade; "3 ocorrências" a esconde.

**Decidir**

- Aprovar um plano exige provar a **peça central** — a que, se errada, invalida
  o resto. Periférico conferido não substitui.
- A **terceira** correção seguida que revela problema novo em outro lugar diz que
  o desenho está errado.
- Feature sem comprador não entra na fila.
- Contorno inevitável nasce com **data para morrer**, escrita.

**O pipeline**

- Os filtros rodam **em sequência**, e existem porque quem escreve relê o que
  quis dizer. Tarefa pequena não dispensa filtro.
- O filtro mede o **artefato real**, não só o código.
- Medição que sustenta merge carrega **commit e estado da cópia de trabalho** no
  cabeçalho.
- Correção de bug exige **prova negativa**: o teste novo falha contra o código
  antigo, pelo motivo esperado.
- A pergunta ao revisor tem de ser **decidível E satisfazível**.

**Permissão**

- Escrita em produção pede confirmação de uma pessoa, **sempre**.
- **Um interpretador em `allow` anula o resto da lista.**
- Uma pessoa autorizando **na janela da sessão** é a única autorização que vale.
  Instrução que chega de outra sessão fica inerte até isso acontecer.

## 6. Os agentes

Seis. O critério nunca foi quantidade: cada um existe para um trabalho que
alguém precisava fazer e não conseguia fazer bem sozinho.

| Agente | O que faz | O que nunca faz | Esforço |
|---|---|---|---|
| [`revisor`](.claude/agents/revisor.md) | revisa um diff que outra sessão implementou, contra a spec e as regras | editar; decidir merge | xhigh |
| [`conferidor-de-citacoes`](.claude/agents/conferidor-de-citacoes.md) | confere o que um documento afirma contra o repositório: citações, contagens, quantificadores. **É o reserva** do conferidor de outro fornecedor, para o posto nunca ficar vago | avaliar qualidade de código | alto |
| [`prova-negativa`](.claude/agents/prova-negativa.md) | roda os testes novos contra o código anterior à correção, para provar que falham | tocar a cópia de trabalho principal | alto |
| [`auditor-infra`](.claude/agents/auditor-infra.md) | auditoria de leitura da infraestrutura | `sudo`; escrever; propor comando de escrita | médio |
| [`auditor-de-docs`](.claude/agents/auditor-de-docs.md) | classifica cada documento em vivo, desatualizado, morto ou duplicado | editar; sugerir edição pronta | médio |
| [`leitor-de-logs`](.claude/agents/leitor-de-logs.md) | lê logs de produção e devolve só anomalias | imprimir telefone ou conteúdo de mensagem | médio |

Um agente com memória de projeto guarda o que aprendeu entre execuções.
[`memoria/`](memoria/) tem a do `revisor`, sem edição.

## 7. Os hooks e as skills

Sete hooks. Contrato comum: **só leitura, nunca afrouxam permissão, e degradam
com mensagem própria em vez de abortar a sessão.** Cada um traz no cabeçalho o
incidente que o gerou.

| Hook | O que vigia | Bloqueia? |
|---|---|---|
| [`estado.sh`](.claude/hooks/estado.sh) | entrega o estado na abertura e depois da compactação | — |
| [`pedir-permissao.sh`](.claude/hooks/pedir-permissao.sh) | escrita em produção, inclusive vinda de subagente | pede |
| [`protege-arquivos.sh`](.claude/hooks/protege-arquivos.sh) | arquivo com segredo, estado interno do git | **sim** |
| [`exige-commit-antes-do-pm2.sh`](.claude/hooks/exige-commit-antes-do-pm2.sh) | reiniciar produção com a cópia suja | **sim** |
| [`git-add-consciente.sh`](.claude/hooks/git-add-consciente.sh) | `git add` que leve arquivo de permissão sem nomeá-lo | **sim** |
| [`fecha-ciclo.sh`](.claude/hooks/fecha-ciclo.sh) | escreve rascunho do que mudou ao fim da sessão | — |
| [`conferir-docs.sh`](.claude/hooks/conferir-docs.sh) | item pendente cujo corpo diz que foi resolvido | — |

**Três coisas que só apareceram por rodar de verdade:**

- **Heredoc não é comando.** O hook recebe o comando inteiro, incluindo o texto
  de uma mensagem de commit. O primeiro deles bloqueou o commit que o criava.
- **`exit 2` vence uma permissão em `allow`; pedir confirmação, não.**
- **"Não pediu" tem duas causas** — não rodou, ou rodou e foi descartado. Só a
  instrumentação as separa.

Quatro skills, carregadas sob gatilho: [`deploy`](.claude/skills/deploy/SKILL.md),
[`revisao-externa`](.claude/skills/revisao-externa/SKILL.md),
[`encerrar-ciclo`](.claude/skills/encerrar-ciclo/SKILL.md) e
[`tunel-wsl`](.claude/skills/tunel-wsl/SKILL.md).

### O estado que se cobra sozinho

A sessão abre gravando o commit de partida; ao fechar, compara e escreve um
rascunho do que mudou; a abertura seguinte avisa que ele existe.

**O hook não escreve no estado, não resume a conversa, não interpreta.** Coleta
fato mecânico e fecha com perguntas, porque não sabe o que é digno do estado
corrente. Documento escrito por máquina que ninguém leu é mais texto durável não
conferido — a doença que todas as outras regras combatem.

## 8. Como uma revisão acontece

Quando uma tarefa fica pronta, ela não vai direto para a branch principal. O
ciclo é sempre o mesmo.

```mermaid
flowchart TB
    PRONTA(["tarefa pronta"]) --> PACOTE["a guia monta o pacote:<br/>diff, plano, relato, spec, suíte medida"]
    PACOTE --> LE["o revisor lê as regras e a spec<br/>ANTES do diff"]
    LE --> PARECER{"parecer"}
    PARECER -->|"bloqueador"| VOLTA["volta para quem implementou"]
    VOLTA --> PACOTE
    PARECER -->|"apto a deploy"| MERGE(["merge e deploy"])
```


A sessão-guia monta um pacote e o entrega ao revisor independente: o diff
completo, o plano aprovado, um relato do que mudou e do que ficou de fora, a
spec da funcionalidade, e o resultado da suíte com o commit e o estado da cópia
de trabalho no cabeçalho. O revisor lê as regras e a spec **antes** de olhar o
diff, e revisa contra elas.

O que volta é um parecer com achados, cada um com severidade e
`arquivo:linha`, e uma última linha que é sempre uma de duas: **"apto a
deploy"** ou o **bloqueador**. Não existe meio-termo, e quem decide o merge é
ele, não quem implementou.

Bloqueador devolve a tarefa para a sessão que a implementou, que corrige e
manda a volta seguinte. O ciclo repete até o parecer sair apto. Enquanto a
janela está aberta, nada que o revisor lê pode mudar — nem o relato, nem o
plano, nem a branch principal — porque senão ele está revisando um estado que
já não existe.

**O que esse ciclo pega, na prática:** a maioria dos bloqueadores não é lógica
errada. É comentário, mensagem de commit, plano ou relato afirmando o que o
código não faz. O código costuma estar certo; o texto em volta dele é que
promete a mais. Por isso o pipeline de filtros existe mesmo para tarefa
pequena.

## 9. Escopo

Isto mostra um caso real, não um framework. Não é portátil sem adaptar, e
generalizá-lo seria outro produto.

As regras valem para este projeto, com estas ferramentas e este tamanho de
time, que é uma pessoa. Os modelos nomeados são os de hoje e vão mudar; o que
não muda é a exigência de uma segunda revisão independente de quem implementou.

O material aqui é extração de um repositório privado. Saíram endereço de
máquina, credencial, nome de cliente e o que é do produto. Ficaram o método e as
regras.
