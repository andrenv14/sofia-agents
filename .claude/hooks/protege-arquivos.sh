#!/bin/bash
# Hook PreToolUse (Edit|Write) — bloqueia edição de arquivo protegido.
# Por que existe: .env carrega segredo real, package-lock.json trava versão
# resolvida (edição manual diverge do npm install), e .git/ é estado interno
# do git — nenhum dos três deve ser tocado por Edit/Write.
# Contrato: só leitura de stdin, nunca modifica nada, sai 2 (bloqueia) se o
# path bater num dos três padrões, senão sai 0. .env.example é permitido.

input="$(cat)"

if command -v jq >/dev/null 2>&1; then
  path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
else
  path="$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get("tool_input", {}).get("file_path") or "")
except Exception:
    print("")
' 2>/dev/null)"
fi

if [[ "$path" == *.env.example* ]]; then
  exit 0
fi

if [[ "$path" == *.env* || "$path" == *package-lock.json* || "$path" == */.git/* ]]; then
  echo "Bloqueado: $path é protegido (hook protege-arquivos.sh)" >&2
  exit 2
fi

exit 0
