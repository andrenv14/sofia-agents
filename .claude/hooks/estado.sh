#!/usr/bin/env bash
#
# estado.sh — estado de abertura de sessão, entregue pelo hook SessionStart.
#
# POR QUE ISTO EXISTE: prompt de sessão escrito com estado desatualizado faz a
# sessão trabalhar contra um mundo que não existe — branch errada em checkout,
# "branch pushada" afirmado com o remoto atrás. A regra de verificar antes de
# propor já existia; o que faltava era o estado CHEGAR ao contexto sem depender
# de alguém lembrar de buscá-lo. Este script faz o harness entregar o estado na
# abertura de toda sessão.
#
# CONTRATO: somente leitura, saída curta, NENHUM segredo (não lê .env, não
# imprime DATABASE_URL nem token). Falha de qualquer bloco degrada com mensagem
# própria e NUNCA aborta — o script sai sempre com 0, porque travar a abertura
# da sessão seria pior que a informação faltar.

cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null || true

echo "=== estado do repositório ==="
echo "máquina: $(hostname 2>/dev/null || echo '(hostname indisponível)')"

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')
sha=$(git rev-parse --short HEAD 2>/dev/null || echo '?')
echo "branch: ${branch} @ ${sha}"

main_local=$(git rev-parse main 2>/dev/null || echo '')
if remoto=$(timeout 5 git ls-remote origin main 2>/dev/null) && [ -n "$remoto" ]; then
  main_remoto=$(echo "$remoto" | awk '{print $1}')
  origem="origin/main (consultado agora)"
else
  main_remoto=$(git rev-parse origin/main 2>/dev/null || echo '')
  origem="origin/main LOCAL — remoto não consultado (sem rede?)"
fi
if [ -z "$main_local" ] || [ -z "$main_remoto" ]; then
  echo "main: não foi possível comparar com o remoto"
elif [ "$main_local" = "$main_remoto" ]; then
  echo "main: ${main_local:0:7} == ${origem}"
else
  echo "main: ${main_local:0:7} != ${main_remoto:0:7} — DIVERGENTE de ${origem}"
fi

sujo=$(git status --short 2>/dev/null)
if [ -z "$sujo" ]; then
  echo "working tree limpo"
else
  echo "working tree SUJO:"
  echo "$sujo" | sed 's/^/  /'
fi

naomerge=$(git branch --no-merged main --format='%(refname:short) %(objectname:short)' 2>/dev/null)
if [ -z "$naomerge" ]; then
  echo "branches não mergeadas em main: nenhuma"
else
  echo "branches não mergeadas em main: $(echo "$naomerge" | tr '\n' ';' | sed 's/;$//')"
fi

if command -v pm2 >/dev/null 2>&1; then
  pm2 jlist 2>/dev/null | node -e '
    let e="";process.stdin.on("data",d=>e+=d).on("end",()=>{
      try{
        const l=JSON.parse(e);
        if(!l.length) return console.log("PM2: nenhum processo");
        console.log("PM2: "+l.map(p=>{
          const u=p.pm2_env.pm_uptime?Math.round((Date.now()-p.pm2_env.pm_uptime)/60000):0;
          return `${p.name} ${p.pm2_env.status} restarts=${p.pm2_env.restart_time} uptime=${u}min`;
        }).join(" | "));
      }catch(_){console.log("PM2: saída não interpretável");}
    });' || echo "PM2: falha ao consultar"
else
  echo "PM2: ausente nesta máquina"
fi

if cron=$(crontab -l 2>/dev/null); then
  if echo "$cron" | grep -q 'varrer-orfas'; then
    echo "crontab: varredura de órfãs ATIVA"
  else
    echo "crontab: presente, SEM varredura de órfãs"
  fi
else
  echo "crontab: ausente"
fi

secao=$(grep -E '^#{2,3} ' LOG.md 2>/dev/null | tail -1)
echo "LOG.md, última seção: ${secao:-(não lido)}"

if [ -f ESTADO.md ]; then
  agora=$(awk '/^## Agora/{f=1;next} /^## /{if(f)exit} f' ESTADO.md 2>/dev/null)
  if [ -n "$agora" ]; then
    echo "estado (ESTADO.md, Agora):"
    echo "$agora" | sed 's/^/  /'
  else
    echo "estado (ESTADO.md, Agora): seção não encontrada"
  fi
else
  echo "estado: ESTADO.md ausente"
fi

if [ -f .env ]; then
  banco=$(grep -E '^DATABASE_URL=' .env 2>/dev/null | sed -E 's#.*/([^/?]+)(\?.*)?$#\1#')
  echo "banco: ${banco:-(DATABASE_URL não encontrada)}"
else
  echo "banco: .env ausente"
fi

if [ -f .claude/settings.local.json ]; then
  n=$(node -e '
    try{
      const j=require("./.claude/settings.local.json");
      const a=(j.permissions&&j.permissions.allow)||[];
      console.log(a.length);
    }catch(_){console.log("?");}
  ' 2>/dev/null)
  echo "settings.local.json: ${n:-?} entradas em permissions.allow"
else
  echo "settings.local.json: ausente (0 entradas)"
fi

procs=$(pgrep -fa -- 'src/server\.js|sofia_eval' 2>/dev/null | grep -v 'estado\.sh')
if [ -z "$procs" ]; then
  echo "processos node/eval nesta máquina: nenhum"
else
  echo "processos node/eval nesta máquina:"
  echo "$procs" | sed 's/^/  /'
fi
