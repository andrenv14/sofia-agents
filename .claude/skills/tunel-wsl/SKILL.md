---
name: tunel-wsl
description: Abrir, descobrir e usar o túnel SSH reverso desenvolvimento → produção para leitura entre as duas máquinas — paridade de SHA, versão de Node, disco, resultado de suíte. Use quando precisar ler algo de desenvolvimento a partir de produção, ou quando o túnel cair.
---

# Túnel SSH reverso desenvolvimento → produção

**Só para LEITURA.** Paridade de SHA e versão de Node, disco, resultado de
suíte. **Não é canal de escrita**: nada de editar, commitar ou instalar em desenvolvimento
por ele — trabalho de escrita em desenvolvimento continua sendo sessão de lá.

O túnel existe **só enquanto o dono do projeto roda o `ssh -N`** num terminal fora do
VS Code. É efêmero: confira se está aberto antes de usar, e trate ausência como
normal, não como erro.

## Abrir (em desenvolvimento, terminal FORA do VS Code)

Reload da janela do VS Code mataria o túnel.

O desenvolvimento não sobe serviço sozinho depois de reboot, e **o `sshd` dele escuta na
2200, não na 22**:

    sudo service ssh start; ss -tln | grep 2200

Com o 2200 aparecendo:

    ssh -N -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes \
        -R 2224:localhost:2200 <usuário>@<servidor>

`ExitOnForwardFailure=yes` faz o SSH **morrer com erro visível** quando a porta
já está tomada, em vez de conectar sem encaminhamento nenhum. Falha silenciosa
foi o tema do dia em que essa opção entrou.

## Usar (em produção)

**A porta do lado de produção NÃO é fixa: descubra antes de usar**, em vez de confiar
em número escrito em documento. Ela já foi 2223, virou 2224 quando a 2223 ficou
com um forward zumbi de sessão morta, e depois estava de volta na 2223 com a
2224 recusando conexão.

    ss -tln | grep -E ':22(23|24) '        # qual está escutando
    ssh -i ~/.ssh/wsl -p <porta viva> andre@localhost "<comando>"

**Porta escrita em doc envelhece em silêncio** — foi o que fez o comando ser
reconstruído errado três vezes.

## Zumbi: descobrir, nunca consertar às cegas

Matar processo `sshd` às cegas arrisca derrubar o VS Code do dono do projeto — o
Remote-SSH também aparece como `sshd: <usuário>@notty`. A saída é **descobrir qual
porta está viva** e usar essa, não limpar a outra.

Se a porta pedida no `-R` já estiver tomada, troque o número **nos dois lados**
— o que importa é que o `-R` e a leitura usem o mesmo.

## O teste que vale

Porta escutando e leitura funcionando são coisas diferentes. O teste é a
leitura:

    ssh -i ~/.ssh/wsl -p 2224 andre@localhost "hostname; node --version"

Se responder `<desenvolvimento>`, o túnel está de pé de verdade.

## Risco registrado

Enquanto aberto, a máquina de produção — produção, exposta — guarda chave que entra no PC do
fundador. O teto de dano é a máquina de desenvolvimento, que não tem credencial de produção, e a regra
de só-leitura é parte do que mantém esse teto. Fechar o terminal fecha o túnel.
