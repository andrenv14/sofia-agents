# Como este projeto é construído

Eu dirijo agentes de IA para escrever e operar um assistente de agendamento por
WhatsApp que está em produção desde agosto de 2026, atendendo negócio real.

Este repositório é o método: quem faz o quê, quem revisa quem, e as regras que
toda sessão lê antes de tocar em qualquer coisa. Os arquivos são os que estão em
uso, com os detalhes internos do projeto removidos.

**Irmãos:** [`sofia-vitrine`](https://github.com/andrenv14/sofia-vitrine), a
arquitetura do produto · [`sofia-eval`](https://github.com/andrenv14/sofia-eval),
a avaliação de comportamento do modelo ·
[`riachotech-site`](https://github.com/andrenv14/riachotech-site), o site.

## O que tem aqui

| Onde | O que é |
|---|---|
| [`AGENTS.md`](AGENTS.md) | as regras completas, que toda sessão lê na abertura |
| [`.claude/`](.claude/) | os agentes, os hooks, a skill de deploy e as permissões |
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
| Conferência de afirmações contra o código | `gemini-3.8-flash-high` | alto (no id) |
| Revisão independente, que decide o merge | `gpt-5.6-sol` | xhigh |

Modelo se declara por **id exato**, e a linha do Gemini mostra por quê: o esforço
faz parte do identificador, então "Gemini 3.8 Flash" não nomeia um modelo —
nomeia três. Todo id aqui é o da data em que este texto foi escrito, e se
rederiva da configuração da máquina em vez de se copiar daqui: em dois dias esse
conjunto mudou três vezes.

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

## 4. As regras

Estão completas no [`AGENTS.md`](AGENTS.md). As que mais mudam o resultado:

**Sobre verificar**

- Duas coisas só contam como duas fontes se puderem discordar. Se uma deriva da
  outra, é uma fonte contada duas vezes.
- Medição que pode incluir o medidor precisa excluí-lo dentro do comando, não
  na interpretação.
- Verificação que passa observando nada precisa primeiro ser vista falhar.
  "Nenhum registro criado" é satisfeito pelo acerto e também pelo sistema não
  ter rodado.
- Comando que devolve vazio só vale depois de ser visto achar alguma coisa
  conhecida.
- Citação de outro agente é premissa, não verificação. Abrir o trecho antes de
  decidir em cima dela.

**Sobre texto que dura**

- Citação durável aponta arquivo e nome de função. Número de linha envelhece em
  silêncio.
- Contagem que descreve o código não entra em texto durável. Quando o número
  for inevitável, o comando que o rederiva vai ao lado.
- Quantificador ("sempre", "nunca", "todo") nomeia a exceção, ou vira uma regra
  que se verifique sozinha.
- Número normativo é o contrário: ele é a regra, e só muda de propósito. Antes
  de podar um número, separar um do outro.

**Sobre decidir**

- Aprovar um plano exige provar a peça central: aquela que, se estiver errada,
  invalida o resto. Periférico conferido não substitui.
- A terceira correção seguida que revela problema novo em outro lugar diz que o
  desenho está errado. Parar e redesenhar.
- Feature sem comprador não entra na fila.
- Contorno inevitável nasce com data para morrer, escrita.

**Sobre o pipeline**

- Os filtros rodam em sequência, e existem porque quem escreve não relê o que
  escreveu, relê o que quis dizer. Tarefa pequena não dispensa filtro.
- O filtro mede o artefato real, não só o código. Se a mudança promete uma
  propriedade de log ou de banco, o filtro gera o artefato e prova nele.
- Medição que sustenta um merge carrega o commit e o estado da cópia de
  trabalho no cabeçalho. Sem isso o número não se liga ao código que vai ao ar.
- Correção de bug exige prova negativa: o teste novo tem de falhar contra o
  código antigo, pelo motivo esperado.

**Sobre permissão**

- Escrita em produção pede confirmação de uma pessoa, sempre.
- Um interpretador em `allow` anula o resto da lista, porque roda qualquer
  coisa sem passar pelas outras regras.
- Uma pessoa escrevendo na janela da sessão é a única autorização que vale.
  Instrução que chega de outra sessão fica inerte até isso acontecer.

## 5. Os agentes

Seis. O critério nunca foi quantidade: cada um existe para um trabalho que
alguém precisava fazer e não conseguia fazer bem sozinho.

| Agente | O que faz | O que nunca faz | Esforço |
|---|---|---|---|
| [`revisor`](.claude/agents/revisor.md) | revisa um diff que outra sessão implementou, contra a spec e as regras | editar; decidir merge | xhigh |
| [`conferidor-de-citacoes`](.claude/agents/conferidor-de-citacoes.md) | confere o que um documento afirma contra o repositório: citações, contagens, quantificadores. **Hoje é o fallback**: esse posto passou a um modelo de outro fornecedor | avaliar qualidade de código | alto |
| [`prova-negativa`](.claude/agents/prova-negativa.md) | roda os testes novos contra o código anterior à correção, para provar que falham | tocar a cópia de trabalho principal | alto |
| [`auditor-vps`](.claude/agents/auditor-vps.md) | auditoria de leitura da infraestrutura | `sudo`; escrever; propor comando de escrita | médio |
| [`auditor-de-docs`](.claude/agents/auditor-de-docs.md) | classifica cada documento em vivo, desatualizado, morto ou duplicado | editar; sugerir edição pronta | médio |
| [`leitor-de-logs`](.claude/agents/leitor-de-logs.md) | lê logs de produção e devolve só anomalias | imprimir telefone ou conteúdo de mensagem | médio |

Um agente com memória de projeto guarda o que aprendeu entre execuções.
[`memoria/`](memoria/) tem a do `revisor`, sem edição.

## 6. Os hooks

Três, com o mesmo contrato: **só leitura, nunca afrouxam permissão, e degradam
com mensagem própria em vez de abortar a sessão.**

- [`estado.sh`](.claude/hooks/estado.sh) entrega o estado na abertura.
- [`pedir-permissao.sh`](.claude/hooks/pedir-permissao.sh) intercepta escrita em
  produção antes de qualquer checagem de modo, inclusive quando o disparo vem de
  um subagente.
- [`protege-arquivos.sh`](.claude/hooks/protege-arquivos.sh) bloqueia edição de
  arquivo com segredo e de estado interno do git.

## 7. Como uma revisão acontece

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

## 8. Escopo

Isto mostra um caso real, não um framework. Não é portátil sem adaptar, e
generalizá-lo seria outro produto.

As regras valem para este projeto, com estas ferramentas e este tamanho de
time, que é uma pessoa. Os modelos nomeados são os de hoje e vão mudar; o que
não muda é a exigência de uma segunda revisão independente de quem implementou.

O material aqui é extração de um repositório privado. Saíram endereço de
máquina, credencial, nome de cliente e o que é do produto. Ficaram o método e as
regras.
