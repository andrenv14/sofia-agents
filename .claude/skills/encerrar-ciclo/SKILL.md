---
name: encerrar-ciclo
description: A ordem de encerramento de um ciclo de trabalho — LOG, git add explícito, commit, push, sincronizar docs — e as conferências que precedem cada git add. Use ao terminar uma tarefa ou fatia, antes de commitar qualquer coisa, ou quando for fazer push.
---

# Encerrar um ciclo de trabalho

Vale ao terminar qualquer ciclo: deploy feito, ou tarefa concluída sem deploy.
Os passos não são opcionais, e a ordem é parte do mecanismo.

Para a sequência de DEPLOY em si (migration, `pm2 restart`, Nginx, confirmação
de uptime), a skill é `deploy` — esta aqui cuida do registro e da publicação.

## A ordem

    1. LOG.md        o que foi feito e por onde continuar
    2. conferências  (abaixo) — antes de tocar no git add
    3. git add       explícito, arquivo por arquivo
    4. commit        mensagem que descreve o que realmente mudou
    5. git push
    6. npm run sincronizar-docs-drive    se AGENTS.md ou LOG.md mudaram

**Começa no `LOG.md`. O push nunca é o primeiro passo.**

**Por que o push é obrigatório e não é detalhe:** ele é o que atualiza a
biblioteca de contexto dos outros agentes. Commit local que não subiu não existe
para ninguém além desta máquina — ciclo sem push deixa as outras sessões
trabalhando contra uma versão do repositório que já não é a verdade. As duas
máquinas não compartilham nada além do `origin`.

## As conferências antes do `git add`

### 1. `.claude/settings.json` — o VERSIONADO

**Confira `git status` dele antes de TODO `git add`.** O próprio harness o
reescreve, sem ninguém editar. Medido nas **duas máquinas no mesmo
dia**: em produção entrou um `allow` de `rclone ls` e as chaves foram reordenadas; no
desenvolvimento entrou `Bash(npm run *)` — que dispensa o diálogo de `npm run migrate`, ou
seja, o DROP atrás de allow largo que uma fatia proibiu. Nas duas vezes quem salvou
foi o `git add` explícito.

Se aparecer sem edição deliberada: `git diff` e `git restore.claude/settings.json`, na hora. Se for família proibida, vira achado do `LOG`.

### 2. `.claude/settings.local.json` — o que nunca pode estar lá

Entrada de família proibida sai **na hora em que for vista**, não no
encerramento. A lista e a exceção de leitura estão no `AGENTS.md`, seção
"Como trabalhar aqui" — não se repetem aqui.

Para ver o que a máquina corrente tem:

    grep -oE '"[^"]*(pm2|crontab)[^"]*"'.claude/settings.local.json

Na produção, confira e limpe antes do push. No desenvolvimento tolera-se acumular o que é
leitura, `git add`/`commit` e `npm run` — **nunca** as famílias proibidas.

### 3. Escopos misturados

Se houver mudanças de escopos diferentes pendentes, faça **commits separados**.
Já aconteceu de um `git add -A` levar documentação de outro trabalho em curso
junto de um commit cuja mensagem não a descrevia.

## Correção de texto falso: a prova vai NO COMMIT

Se o ciclo corrigiu uma frase falsa em texto durável, a mensagem do commit traz
o `grep -rn` que procura as irmãs, e o resultado. O revisor confere que o
comando está lá e o reexecuta.

**O grep é pela PALAVRA discriminante, nunca pela frase.** Frase quebra na
margem entre duas linhas, e `grep` é orientado a linha; redação muda e o literal
não casa. Medido numa fatia em três variantes: o grep
pelo literal perdeu a irmã com outra redação; o grep pela afirmação perdeu a
irmã partida em duas linhas; só a palavra sozinha, com as linhas LIDAS, achou as
três cópias.

A mensagem também lista o que **não** é irmã — ocorrências verdadeiras sobre
outra coisa — para a poda não ser cega.

## Antes de colar qualquer comando ou número no texto

**Execute-o e leia a saída INTEIRA.** Se ela traz linha que a frase não cobre,
ou a frase ou o comando está errado, e um dos dois muda antes de o texto entrar.
Medido numa fatia duas vezes no mesmo ciclo: um `grep` posto para
curar um quantificador devolvia sete posições, das quais duas não serviam; e a
correção escrita para curar esse mesmo ponto afirmava que o comando "não devolve
nenhum fora desses dois scripts" — e ele devolve três linhas.

## Saída longa vai para arquivo, não para a resposta

Saída destinada a outro agente (diff, relatório, spec) com mais de ~100 linhas
não vai colada: salve em `~/para-revisao/` com nome descritivo e termine a
resposta com `code ~/para-revisao/<arquivo>`.

Conteúdo longo redigitado corre risco de erro sutil de transcrição — e num diff
que vai para revisão, isso entra como se fosse código real.

**O `~/para-revisao/` é LOCAL em cada máquina.** Arquivo escrito em desenvolvimento não
existe em produção. Se a saída for referenciada do outro lado, copie antes:

    scp ~/para-revisao/*.md <usuário>@<servidor>:~/para-revisao/

 uma entrada do `LOG.md` apontou para um arquivo que só existia em desenvolvimento,
e a referência nasceu morta do lado de produção.
