---
name: deploy
description: Sequência de deploy do sofia-bot na VPS. Use quando for commitar, aplicar migration, reiniciar o PM2 ou publicar mudança em produção.
---

# Deploy do sofia-bot

Ordem obrigatória. Não pule etapa.

1. `git status` — confira que não há arquivo de outro escopo no stage.
   Se houver mudanças de escopos diferentes, faça commits separados.
2. `npm run test:agent` — suíte tem que estar verde ANTES de commitar.
   Por padrão a suíte roda no WSL; na VPS, só se for o caso.
3. `git add` (explícito, evite `-A` sem conferir) e commit com mensagem
   que descreva o que realmente mudou.
4. Só então aplique migration, se houver. Nunca migration antes do commit.
   Se o merge mudou `package-lock.json`: `npm ci` — COMPLETO, nunca
   `--omit=dev`. A VPS mantém as devDependencies porque o Codex roda a suíte
   nela; `--omit=dev` quebra a revisão seguinte.
   **MIGRATION NÃO-ADITIVA muda esta ordem.** Esta sequência — migration no
   passo 4, restart no passo 6 — só é segura quando a migration é ADITIVA
   (coluna nova anulável, índice, CHECK mais permissivo): o código velho
   continua funcionando entre os dois passos. Se a migration **muda tipo,
   renomeia, remove ou aperta constraint**, existe uma janela de segundos em
   que o processo antigo escreve contra um schema que já mudou, e ele falha —
   no sofia-bot isso vira uma desculpa espúria ao cliente, porque o `catch` de
   `processarBuffer` responde "tive um probleminha técnico". Achado do
   `/code-review` na fatia P4 (02/09), sobre a conversão de `messages.wamid_lote`
   de TEXT para TEXT[]. Nesse caso, uma das duas:
   - **migrate e restart em sequência imediata**, sem nenhum passo entre eles,
     em janela de tráfego baixo — e o deploy DECLARA que fez assim; ou
   - **coluna nova em vez de troca de tipo** (escreve nas duas, lê da nova,
     remove a velha numa fatia posterior), que elimina a janela mas custa duas
     fatias.
   Como saber em qual caso você está: leia o `.sql`. `ADD COLUMN ... NULL`,
   `CREATE INDEX`, `ADD CONSTRAINT ... CHECK` que só ACRESCENTA valor são
   aditivos. `ALTER COLUMN ... TYPE`, `DROP`, `RENAME` e CHECK que RESTRINGE
   não são.
   **SEGUNDO teste, e é o que evita alarme falso:** a janela só existe se o
   código ANTIGO — o que está rodando no PM2 agora — realmente LER ou ESCREVER
   a coluna que muda. Se a coluna nasceu na mesma fatia, o processo antigo não
   a conhece, insere sem ela, e não há falha nenhuma a evitar. Confira em
   produção antes de declarar risco: a coluna existe em `sofia_bot`? o código
   em execução a menciona? a migration já está em `schema_migrations`? Achado
   do Codex na 2ª volta da P4 (02/09), que mediu produção e derrubou o risco
   que a própria fatia — e esta skill — tinham dado como certo. Risco descrito
   sem medir vira ritual: custa deploy mais lento e ensina a desconfiar do
   aviso certo quando ele vier.
5. **Se o diff tocou `src/admin/`: `npm run build:css`.** O CSS do painel é
   GERADO (`src/admin/public/admin.css`, no `.gitignore`) e o Tailwind só
   emite as classes que existiam quando rodou — classe utilitária nova chega
   a produção **sem estilo, sem erro e sem aviso**. Não é hipótese: medido em
   02/09, `pr-4` e `border-t` estavam faltando desde 23/08, oito dias depois
   do último `build:css`, e a tabela de convites da aba de coexistence
   renderizava sem respiro e sem borda. Conferência barata depois de rodar:
   `grep -c 'pr-4' src/admin/public/admin.css`. Este passo **não precisa de
   restart** — o arquivo é servido por `express.static`, que lê do disco a
   cada requisição.
5b. **Se o diff tocou `ops/nginx/*`: Nginx ANTES do PM2.** `diff` da conf viva
   em `/etc/nginx/sites-available/` contra a cópia em `ops/nginx/` (para ver o
   que o `cp` vai mudar, e pegar divergência que alguém aplicou à mão), depois
   `sudo cp`, `sudo nginx -t` e `sudo systemctl reload nginx` — passos do
   fundador, com `sudo`. **A ordem importa e não é simétrica**, medido na
   `webhook-teto` (05/09): com o Express já aceitando 3 MB e o Nginx ainda em
   1 MB, o corpo grande é recusado no Nginx SEM linha no log do app — descarte
   silencioso que se lê como sucesso; com o Nginx em 3 MB e o Express ainda em
   100 kB, o Express recusa com 413 LOGADO. Entre os dois estados
   intermediários, passa-se pelo que grita. Confirmação de que o reload pegou:
   `ps -o pid,lstart,cmd -C nginx` mostra os workers com hora de início nova.
   Este passo não existia nesta skill até 05/09 — zero ocorrências de "nginx",
   achado do `/code-review` da fatia.
6. `pm2 restart sofia-bot` — **dispensável apenas** quando o diff
   comprovadamente não toca código que o processo do servidor carrega: doc,
   testes, `db/`, scripts de cron chamados direto pelo crontab, e o CSS
   gerado do passo 5. Nesse caso o deploy declara "sem restart: o diff não
   toca o processo", com a lista dos arquivos. **Na dúvida, reinicia** —
   restart inútil custa segundos; restart pulado por engano deixa produção
   rodando código velho em silêncio.
7. `pm2 list` — confirme uptime reiniciado E contador de restart estável.
   Não assuma que subiu limpo.
8. `pm2 logs sofia-bot --lines 30 --nostream` — confirme a linha
   `[server] Sofia (multi-tenant) ouvindo na porta 3000` e que não há linha de
   erro nova depois dela. Aqui rodava `npm run test:agent` de novo, o que não
   provava nada do processo no ar: a suíte sobe a PRÓPRIA instância na porta
   3099 e nunca toca o processo do PM2 na 3000 — rodá-la depois do restart
   testa outra vez o mesmo código do disco, não o bot que está atendendo.
9. Se `AGENTS.md` ou `LOG.md` mudaram: `npm run sincronizar-docs-drive`
   (passo manual, não é hook de git).

Regra: mudança em `src/` que afeta o processo rodando só conta como
"em produção" depois do passo 6.
