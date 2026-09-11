#!/bin/bash
# Hook PreToolUse (Bash) — BLOQUEIA `pm2 restart/start/reload` com working tree suja.
#
# POR QUE ISTO EXISTE: o AGENTS.md manda "nunca reiniciar o PM2 antes de
# commitar, não importa o quão pequena pareça a mudança" — e essa regra dependia
# de alguém lembrar de uma linha entre centenas. Reiniciar com a árvore suja põe
# em produção código que não está em commit nenhum: se der errado, não há para
# onde voltar, e ninguém sabe o que está rodando.
#
# DIFERENÇA PARA O pedir-permissao.sh: aquele PERGUNTA (permissionDecision ask)
# em toda escrita de produção. Este BLOQUEIA (exit 2) uma condição específica —
# reiniciar sem commit — que nenhuma resposta "sim" deveria liberar. Os dois
# rodam; este é o mais restritivo e vem primeiro na prática.
#
# CONTRATO: só leitura, nunca modifica nada. Sai 2 (bloqueia) apenas quando o
# comando reinicia o PM2 E a árvore tem mudança rastreada não commitada. Em
# qualquer erro de parsing sai 0 — a decisão volta para as listas normais de
# permissão, porque um hook quebrado nunca deve travar o trabalho.
#
# LIMITE DECLARADO: só olha arquivo JÁ RASTREADO pelo git. Arquivo novo não
# rastreado (`??`) não bloqueia, de propósito: PDF, captura e log solto vivem na
# raiz o tempo todo e não vão para produção.

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

# Só reinício. `pm2 list`, `pm2 logs --nostream` e `pm2 describe` passam.
if [[ ! "$cmd" =~ (^|[;\&\|][[:space:]]*)pm2[[:space:]]+(restart|reload|start) ]]; then
  exit 0
fi

cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null || exit 0

# Mudança RASTREADA e não commitada. Exclui `??` (arquivo novo não rastreado).
sujo="$(git status --porcelain 2>/dev/null | grep -v '^??' | head -20)"

[ -z "$sujo" ] && exit 0

{
  echo "BLOQUEADO: pm2 reinicia produção com a working tree suja."
  echo
  echo "Arquivo(s) rastreado(s) com mudança não commitada:"
  printf '%s\n' "$sujo" | sed 's/^/  /'
  echo
  echo "O AGENTS.md manda commitar ANTES de reiniciar o PM2. Reiniciar agora põe"
  echo "no ar código que não está em commit nenhum — sem rollback e sem registro."
  echo
  echo "Commite (skill 'encerrar-ciclo'), ou descarte, e reinicie depois."
} >&2

exit 2
