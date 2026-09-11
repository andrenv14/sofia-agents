#!/bin/bash
# Acusa documento que se contradiz: item marcado como PENDENTE cujo próprio
# corpo diz que foi resolvido.
#
# POR QUE ISTO EXISTE:  uma varredura achou quatro documentos mentindo,
# e metade deles era desta forma exata — o marcador dizia 🔴 e o texto logo
# abaixo dizia "DESPACHADA ". Quem lê o marcador e não o corpo recomeça
# trabalho pronto. A `fila.md` é o arquivo que o AGENTS.md manda ler ANTES de
# propor qualquer próximo passo.
#
# O QUE ELE NÃO FAZ, e é a diferença para a fatia encerrada: não
# executa NADA vindo de documento. Nenhuma whitelist, nenhum parser de comando,
# nenhuma superfície de execução nova. Só lê texto e compara com texto. Aquela
# fatia custou quatro voltas do Codex por causa da peça que aqui não existe.
#
# LIMITE DECLARADO, e é grande: pega só CONTRADIÇÃO INTERNA. Item que mente sem
# se contradizer — um "[ ] Fatia P4" cujo código já existe — passa batido aqui;
# esse caso precisa de verificação contra o código, que é outra coisa.
#
# CONTRATO: somente leitura. Silencioso quando tudo bate. Sai sempre 0 — isto
# informa, não bloqueia.

set -u
cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null || exit 0

ALVOS=(
  "docs/contexto/fila.md"
  "ESTADO.md"
  "README.md"
  "docs/features/repositorio-em-ordem.md"
)

# Marcador de PENDÊNCIA no início do item.
PENDENTE='^[[:space:]]*-[[:space:]]*(🔴|🟡|[[] []])'
# Palavra que declara conclusão. Só palavra INTEIRA e em caixa alta ou seguida
# de data — "resolvido" em prosa comum não conta, senão isto vira ruído.
CONCLUIDO='(DESPACHAD[AO]|RESOLVID[AO]|ENTREGUE|CANCELAD[AO]|SAI DA FILA|CONCLUÍD[AO]|EM PRODUÇÃO)'

achados=0

for arq in "${ALVOS[@]}"; do
  [ -f "$arq" ] || continue

  # Percorre o arquivo guardando onde cada item começou. Um item vai do seu
  # marcador até o próximo item de mesmo nível ou até um cabeçalho.
  awk -v arquivo="$arq" -v pend="$PENDENTE" -v conc="$CONCLUIDO" '
    function fecha {
      if (ini > 0 && corpo ~ conc) {
        # acha a palavra que disparou
        t = corpo
        match(t, conc)
        printf "%s:%d: item marcado como PENDENTE diz \"%s\" no proprio corpo\n", \
               arquivo, ini, substr(t, RSTART, RLENGTH)
        printf "        %s\n", substr(titulo, 1, 100)
        achou++
      }
      ini = 0; corpo = ""; titulo = ""
    }
    /^#/ { fecha; next }
    $0 ~ pend {
      fecha
      ini = NR; titulo = $0; corpo = $0
      next
    }
    # linha em branco encerra o item
    /^[[:space:]]*$/ { fecha; next }
    ini > 0 { corpo = corpo " " $0 }
    END { fecha; exit (achou > 0 ? 10: 0) }
  ' "$arq"

  [ $? -eq 10 ] && achados=$((achados + 1))
done

if [ "$achados" -gt 0 ]; then
  echo
  echo "  Acima: item que diz PENDENTE no marcador e RESOLVIDO no corpo."
  echo "  Quem le so o marcador recomeca trabalho pronto. Troque o marcador, ou"
  echo "  mova o item para docs/contexto/fila-concluido.md."
  echo "  (este verificador nao executa nada vindo de documento, e so pega"
  echo "   contradicao INTERNA — item que mente sem se contradizer passa)"
fi

exit 0
