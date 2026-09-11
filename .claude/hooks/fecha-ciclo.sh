#!/bin/bash
# Hook SessionEnd — escreve um RASCUNHO do que a sessão mudou, para a próxima
# sessão aplicar ao ESTADO.md com julgamento.
#
# POR QUE ISTO EXISTE: o dono do projeto formulou  — "fila, estado, tudo isso
# fica obsoleto muito rápido, e eu tenho que pedir". O estado corrente só é
# atualizado quando alguém lembra, e quem lembra é ele. Este hook tira o PEDIDO
# do caminho: a próxima sessão abre sabendo que há mudança não registrada.
#
# O QUE ELE NÃO FAZ, e é deliberado: não escreve no ESTADO.md, não resume a
# conversa, não interpreta nada. Ele coleta FATO MECÂNICO — commits, arquivos,
# saúde — e deixa o texto para quem tem julgamento. Doc escrito por máquina que
# ninguém leu é mais texto durável não conferido, que é a doença que este
# projeto passa o dia combatendo. O hook ACUSA que há o que registrar; quem
# registra é uma sessão.
#
# CONTRATO: somente leitura do repositório, nenhum segredo, escreve em UM
# arquivo fora do git (~/para-revisao/). Sai sempre 0 — SessionEnd não pode
# travar o encerramento, e toda saída dele é descartada de qualquer forma.
#
# LIMITE DECLARADO: o marco de início vem do SessionStart (estado.sh). Se ele
# não rodou — sessão aberta antes deste hook existir, ou hook desativado —, o
# rascunho cai para "commits das últimas 12 horas nesta branch", que é mais
# amplo e diz isso de si mesmo.

set -u
exec 2>/dev/null

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 0
cd "$RAIZ" || exit 0

MAQ="$(hostname 2>/dev/null || echo desconhecida)"
MARCO_DIR="$HOME/.cache/<processo>"
SAIDA="$HOME/para-revisao/estado-pendente-${MAQ}.md"

entrada="$(timeout 2 cat || true)"
motivo="$(printf '%s' "$entrada" | python3 -c '
import json,sys
try: print(json.load(sys.stdin).get("reason") or "")
except Exception: print("")
' || echo "")"
sid="$(printf '%s' "$entrada" | python3 -c '
import json,sys
try: print(json.load(sys.stdin).get("session_id") or "")
except Exception: print("")
' || echo "")"

# --- de onde a sessão partiu ---
marco=""
[ -n "$sid" ] && [ -f "$MARCO_DIR/inicio-$sid" ] && marco="$(cat "$MARCO_DIR/inicio-$sid")"
[ -z "$marco" ] && [ -f "$MARCO_DIR/inicio-ultimo" ] && marco="$(cat "$MARCO_DIR/inicio-ultimo")"

if [ -n "$marco" ] && git cat-file -e "${marco}^{commit}" 2>/dev/null; then
  intervalo="${marco}..HEAD"
  origem_marco="marco do SessionStart (${marco:0:7})"
else
  intervalo=""
  origem_marco="SEM marco do SessionStart — caiu para as últimas 12 h, que é mais amplo"
fi

if [ -n "$intervalo" ]; then
  commits="$(git log --oneline "$intervalo" 2>/dev/null)"
  arquivos="$(git diff --name-only "$intervalo" 2>/dev/null)"
else
  commits="$(git log --oneline --since='12 hours ago' 2>/dev/null)"
  arquivos="$(git log --name-only --pretty=format: --since='12 hours ago' 2>/dev/null | sort -u | grep -v '^$')"
fi

sujo="$(git status --short 2>/dev/null)"
# Arquivo NAO RASTREADO nao decide se ha rascunho. Motivo, medido: um
# PDF que mora na raiz ha dias faria o rascunho nascer em TODA sessao, e
# detector que dispara sempre e detector que ninguem le -- a doenca que o
# AGENTS.md nomeia em "otimizar para o contador". Ele aparece no rascunho
# quando houver outro motivo, mas nao cria um sozinho.
rastreado_sujo="$(printf '%s\n' "$sujo" | grep -v '^??' | grep -v '^$')"

# Nada aconteceu: não deixa arquivo para trás, para "existe rascunho" continuar
# significando alguma coisa.
if [ -z "$commits" ] && [ -z "$rastreado_sujo" ]; then
  rm -f "$SAIDA"
  [ -n "$sid" ] && rm -f "$MARCO_DIR/inicio-$sid"
  exit 0
fi

mkdir -p "$(dirname "$SAIDA")" || exit 0

{
  echo "# Rascunho de estado — sessão encerrada em $(date -u '+%d/%m %H:%M UTC')"
  echo
  echo "**NÃO é o \`ESTADO.md\`, e não foi conferido por ninguém.** São fatos"
  echo "mecânicos coletados pelo hook \`fecha-ciclo.sh\` quando a sessão fechou."
  echo "Quem aplica ao \`ESTADO.md\` é uma sessão, com julgamento — e apaga este"
  echo "arquivo depois. Se o que está aqui já estiver registrado, apague sem mais."
  echo
  echo "    máquina:  $MAQ"
  echo "    branch:   $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  echo "    HEAD:     $(git rev-parse --short HEAD 2>/dev/null || echo '?')"
  echo "    encerrou: ${motivo:-(motivo não informado)}"
  echo "    escopo:   $origem_marco"
  echo

  if [ -n "$commits" ]; then
    echo "## Commits desta sessão"
    echo
    printf '%s\n' "$commits" | sed 's/^/    /'
    echo
  else
    echo "## Commits desta sessão"
    echo
    echo "Nenhum."
    echo
  fi

  if [ -n "$arquivos" ]; then
    echo "## Arquivos tocados"
    echo
    printf '%s\n' "$arquivos" | sed 's/^/    /'
    echo
  fi

  if [ -n "$sujo" ]; then
    echo "## ATENÇÃO — a sessão fechou com working tree suja"
    echo
    printf '%s\n' "$sujo" | sed 's/^/    /'
    echo
    echo "Trabalho não commitado. Confira antes de seguir: pode ser sobra a"
    echo "descartar, ou pode ser o que a sessão não terminou de registrar."
    echo
  fi

  # Pergunta, não afirmação: o hook não sabe o que é digno do estado corrente.
  echo "## O que conferir ao aplicar"
  echo
  echo "- Algum destes commits mudou o que está EM PRODUÇÃO? Se sim, vira linha"
  echo "  em \`ESTADO.md\` → \"Em produção\", e o detalhe fica no \`LOG.md\`."
  echo "- Algum fechou item da \`docs/contexto/fila.md\`? O marcador de lá foi trocado?"
  echo "- O \`ESTADO.md\` continua abaixo do teto de ~120 linhas que ele declara?"
  echo "- Fatia mergeada: o plano dela foi para \`docs/plans/arquivo/\`?"
} > "$SAIDA" || exit 0

[ -n "$sid" ] && rm -f "$MARCO_DIR/inicio-$sid"
exit 0
