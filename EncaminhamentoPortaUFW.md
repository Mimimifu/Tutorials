1. Introdução
Embora possamos habilitar várias regras de firewall UFW usando comandos, as coisas são um pouco diferentes ao configurar o encaminhamento de portas. No entanto, os passos são simples.

Neste tutorial, analisaremos as etapas para ativar o encaminhamento de pacotes e configurar um encaminhamento de porta usando UFW.

2. Habilitando o encaminhamento de pacotes
Antes de configurarmos o UFW para permitir o encaminhamento de portas, devemos habilitar o encaminhamento de pacotes. Podemos fazer isso através de qualquer um de:

o arquivo de variáveis de rede UFW: /etc/ufw/sysctl.conf
O arquivo de variáveis do sistema: /etc/sysctl.conf
Neste tutorial, usaremos o arquivo de variáveis de rede UFW, já que o UFW o prioriza sobre o arquivo de variáveis do sistema.

Para habilitar o encaminhamento de pacotes, vamos abrir o arquivo /etc/ufw/sysctl.conf:

$ sudo nano /etc/ufw/sysctl.conf

Depois disso, vamos descomentar net/ipv4/ip_forward=1.

Se tivermos acesso ao usuário root, podemos habilitar o encaminhamento de pacotes em /etc/ufw/sysctl.conf executando:

echo 'net/ipv4/ip_forward=1' >> /etc/ufw/sysctl.conf

Esse comando basicamente acrescenta a string de encaminhamento de pacotes não comentada ao arquivo /etc/ufw/sysctl.conf.

3. Configurando o encaminhamento de porta no UFW
Podemos configurar o UFW para encaminhar o tráfego de uma porta externa para uma porta interna. Se precisarmos, também podemos configurá-lo para encaminhar o tráfego de uma porta externa para um servidor escutando em uma porta interna específica.

3.1. Encaminhamento de porta de uma porta externa para uma porta interna
Para configurar um port forward no UFW, devemos editar o arquivo /etc/ufw/before.rules:

$ sudo nano /etc/ufw/before.rules 

No arquivo before.rules, vamos adicionar uma tabela NAT após a tabela de filtro (a tabela que começa com *filter e termina com COMMIT):

*nat
:PREROUTING ACCEPT [0:0]
-A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 500
COMMIT

Essa tabela NAT redirecionará o tráfego de entrada da porta externa (80) para a porta interna (500). Claro, podemos ajustar a tabela para encaminhar o tráfego de qualquer outra porta externa para qualquer outra porta interna.

Agora que salvamos a tabela NAT no arquivo before.rules, vamos permitir o tráfego pela porta interna, já que não fizemos isso antes:

$ sudo ufw allow 500/tcp
Rule added
Rule added (v6)

Por fim, vamos reiniciar o UFW:

$ sudo systemctl restart ufw

3.2. Encaminhamento de porta de uma porta externa para um servidor escutando em uma porta interna específica
Podemos encaminhar o tráfego de entrada de uma porta externa para um servidor que escuta em uma porta interna específica usando as mesmas etapas acima. No entanto, usaremos uma tabela NAT diferente para essa finalidade:

*nat :PREROUTING ACCEPT [0:0]
-A PREROUTING -p tcp -i eth0 --dport 443 -j DNAT \ --to-destination 192.168.56.9:600
COMMIT

Ao contrário da outra tabela, isso redireciona o tráfego de entrada da porta 443 (porta externa) para 192.168.56.9 (o servidor) escutando na porta 600 (porta interna). Como fizemos antes, garantiremos que permitimos o tráfego através da porta interna.

4. Conclusão
Neste artigo, discutimos como habilitar o encaminhamento de porta no UFW. Cobrimos o encaminhamento de porta de uma porta externa para uma porta interna. Depois, passamos pela tabela NAT para encaminhamento de porta para um servidor escutando em uma porta interna específica.

Embora tenhamos usado o arquivo de variáveis de rede UFW para habilitar o encaminhamento de pacotes, também poderíamos ter trabalhado com o arquivo de variáveis do sistema. Para fazer isso, teríamos modificado o valor da variável IP_SYSCTL no arquivo /etc/default/ufw, alterando-o de seu valor padrão para /etc/sysctl.conf.

Reference: https://www.baeldung.com/linux/ufw-port-forward
