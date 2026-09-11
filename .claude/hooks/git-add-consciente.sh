#!/bin/bash
# Hook PreToolUse (Bash) — pede confirmação em `git add` amplo, e ACUSA quando
# um arquivo de permissão entrou no que vai ser commitado.
#
# POR QUE ISTO EXISTE — duas regras do AGENTS.md que dependiam de memória:
#
# 1. "git add é explícito, arquivo por arquivo; com `git add -A`, checar
#    git status antes". Já aconteceu de um add amplo levar documentação de outro
#    trabalho em curso junto de um commit cuja mensagem não a descrevia.
#
# 2. ".claude/settings.json (o VERSIONADO) é reescrito pelo próprio harness —
#    conferir git status dele antes de TODO git add". Medido  nas DUAS
#    máquinas no mesmo dia, sem ninguém editar: numa entrou um allow de
#    `rclone ls`, na outra entrou `Bash(npm run *)`, que dispensa o diálogo de
#    `npm run migrate`. Nas duas vezes quem salvou foi o add explícito.
#
# A segunda regra é a que mais precisa de mecanismo: o arquivo muda SOZINHO, e
# quem faz o add não tem motivo para suspeitar.
#
# CONTRATO: só leitura, nunca modifica nada. NUNCA bloqueia (exit 2) — pede
# confirmação, que é o que a regra manda. Em qualquer erro sai 0.

input="$(cat)"

if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
else
  cmd="$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get("tool_input", {}).get("command") or "")
except Exception:
    print("")
' 2>/dev/null)"
fi

# HEREDOC NAO E COMANDO. Sem isto, um commit cujo TEXTO mencione um comando
# vigiado dispara o hook — aconteceu no commit que criou este arquivo, na linha
# que documentava o proprio teste. Remove o corpo de cada heredoc antes de
# analisar; o que sobra e comando de verdade.
cmd="$(CMD="$cmd" python3 -c '
import os, re
c = os.environ.get("CMD", "")
pad = re.compile(r"<<-?\s*([\x27\"]?)([A-Za-z_][A-Za-z0-9_]*)\1")
while True:
    m = pad.search(c)
    if not m:
        break
    marc = m.group(2)
    fim = re.search(r"\n[ \t]*" + re.escape(marc) + r"[ \t]*(\n|$)", c[m.end:])
    if fim:
        c = c[:m.start] + " " + c[m.end + fim.end:]
    else:
        c = c[:m.start] + " " + c[m.end:]
print(c)
' 2>/dev/null || printf "%s" "$cmd")"

[ -z "$cmd" ] && exit 0
[[ ! "$cmd" =~ (^|[;\&\|][[:space:]]*)git[[:space:]]+add ]] && exit 0

cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null || exit 0

motivo=""

# 1. Arquivo de permissão mexido — vale para QUALQUER git add, inclusive explícito.
perm="$(git status --porcelain.claude/settings.json.claude/settings.local.json 2>/dev/null)"

# EXCECAO NECESSARIA: se o comando NOMEIA o arquivo de permissao, houve
# intencao -- a pessoa esta adicionando justamente ele, e ja o viu. Sem esta
# clausula o hook trava o proprio commit do settings.json: ele bloqueava o add
# e a mensagem mandava fazer "um git add proprio", que era bloqueado tambem.
# Deadlock encontrado ao vivo, no primeiro uso real.
# O caso que o hook existe para pegar continua coberto: o add AMPLO ou de
# OUTROS arquivos que leva o settings junto sem ninguem olhar.
if [[ "$cmd" =~ settings(\.local)?\.json ]]; then
  perm=""
fi

if [ -n "$perm" ]; then
  # BLOQUEIA, nao pede. Medido: `permissionDecision: ask` de hook NAO
  # vence um `allow` existente, e `Bash(git add *)` esta em allow nas duas
  # maquinas -- o pedido seria emitido e engolido, sem ninguem ver. `exit 2`
  # funciona com allow (provado no hook exige-commit-antes-do-pm2.sh).
  # Este e o caso que mais precisa de mecanismo: o arquivo muda SOZINHO.
  {
    echo "BLOQUEADO: arquivo de PERMISSAO com mudanca pendente."
    echo
    printf '%s\n' "$perm" | sed 's/^/  /'
    echo
    echo "O harness reescreve.claude/settings.json sozinho --, medido nas"
    echo "DUAS maquinas no mesmo dia, sem ninguem editar. Numa entrou um allow de"
    echo "rclone; na outra, Bash(npm run *), que dispensa o dialogo de npm run"
    echo "migrate. Confira o diff ANTES de deixar entrar no commit:"
    echo
    echo "    git diff.claude/settings.json"
    echo
    echo "Se apareceu sem edicao deliberada: git restore.claude/settings.json"
    echo "Se a mudanca e sua e voce ja conferiu, adicione o arquivo primeiro,"
    echo "num git add proprio, e refaca este comando."
  } >&2
  exit 2
fi
# 2. Add amplo.
# O alvo pode vir depois de outras flags: `git add -v -A` e `git add --dry-run -A`
# sao amplos do mesmo jeito. A primeira versao exigia o alvo colado no `add` e
# deixava os dois passarem -- achado ao testar com --dry-run.
# O ponto tem de ser argumento ISOLADO, senao `git add.claude/x` casaria.
if [[ "$cmd" =~ git[[:space:]]+add([[:space:]]+-[^[:space:]]+)*[[:space:]]+(-A|--all|\.)([[:space:]]|$) ]]; then
  n="$(git status --porcelain 2>/dev/null | wc -l)"
  amplo="\`git add\` amplo: ${n} caminho(s) entrariam de uma vez. O AGENTS.md pede add explícito, arquivo por arquivo, e commits separados para escopos diferentes"
  motivo="$amplo"
fi

[ -z "$motivo" ] && exit 0

# O motivo ESPECÍFICO é o que faz o aviso ser lido em vez de clicado. Os dois
# caminhos abaixo produzem a mesma mensagem; o python3 existe onde o jq não.
if command -v jq >/dev/null 2>&1; then
  printf '%s' "$motivo" | jq -R -s '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:("hook git-add-consciente.sh — " +.)}}'
else
  MOTIVO="$motivo" python3 -c '
import json, os
print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"hook git-add-consciente.sh — " + os.environ.get("MOTIVO","")}}, ensure_ascii=False))
' 2>/dev/null || printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"hook git-add-consciente.sh — confira antes do add"}}'
fi

exit 0
