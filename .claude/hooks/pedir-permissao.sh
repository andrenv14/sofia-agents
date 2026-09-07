#!/bin/bash
# Hook PreToolUse — pede confirmação para comandos de escrita em produção.
# Por que existe: a lista "ask" do settings.json não alcança subagentes rodando
# em modo Auto — a escrita passa sem diálogo. Um hook PreToolUse roda antes de
# qualquer checagem de modo, então intercepta aqui (git push, pm2, crontab,
# escrita via psql) mesmo quando o disparo vem de um subagente Auto.
# Contrato: só leitura, nunca modifica nada, SEMPRE sai com exit 0, e NUNCA
# afrouxa permissão — em qualquer erro de parsing, não imprime nada (a
# decisão fica com as listas normais de permissions).

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

regex='(^|[;&|]\s*)(git push|pm2 (restart|reload|stop|start|delete)|crontab|psql .*-c .*(INSERT|UPDATE|DELETE|DROP|TRUNCATE))'

if [[ "$cmd" =~ $regex ]]; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"escrita em produção — exige confirmação do fundador (hook pedir-permissao.sh)"}}'
fi

exit 0
