Como configurar WireGuard VPN Servidor em Ubuntu 20.04

Neste tutorial, veremos as etapas para configurar e configurar o WireGuard VPN servidor e client.

WireGuard instalação

Instale o WireGuard pacote no servidor e client máquinas usando este comando:

sudo apt install wireguard

A configuração do sistema

Primeiro, você precisa permitir o tráfego UDP de entrada em alguma porta para o VPN conexão.

sudo ufw allow 61951/udp

Permitir o redirecionamento de pacotes de rede no nível do kernel.

sudo nano /etc/sysctl.conf

Descomente a seguinte linha.

net.ipv4.ip_forward=1

Aplique as alterações.

sudo sysctl -p

Criação de pares de chaves privadas e públicas

Use este comando para gerar chaves e tornar uma privada acessível apenas ao usuário root por motivos de segurança.

wg genkey | sudo tee /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key

Execute a mesma ação no climáquina ent para o client_private.key e client_public.key.

Para ver os valores das chaves, use o comando 'cat', por exemplo:

sudo cat /etc/wireguard/server_private.key
cat /etc/wireguard/server_public.key

WireGuard configuração do servidor

Criar o WireGuard arquivo de configuração.

sudo nano /etc/wireguard/wg0.conf

Preencha-o com as seguintes linhas:

# Server configuration
[Interface]
PrivateKey = oCH7Z0g+ieQ99KkkR1E5EO22Evs5q75F+ES4O4Oc93E= # The server_private.key value.
Address = 10.5.5.1/24  # Internal IP address of the VPN server.
ListenPort = 61951  # Previously, we opened this port to listen for incoming connections in the firewall.
# Change "enp0s5" to the name of your network interface in the following two settings. This commands configures iptables for WireGuard.
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o enp0s5 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o enp0s5 -j MASQUERADE

# Configurations for the clients. You need to add a [Peer] section for each VPN client.
[Peer]
PublicKey = gsgfB29uYjpuFTCjC1+vHr9M7++MHJcG6Eg4rtuTu34= # client_public.key value.
AllowedIPs = 10.5.5.2/32 # Internal IP address of the VPN client.

Salve e feche este arquivo. Para iniciar o WireGuard VPN servidor digite o comando:

sudo systemctl start wg-quick@wg0

Configure a interface de execução automática após a reinicialização do sistema.

sudo systemctl enable wg-quick@wg0

WireGuard cliconfiguração ent

Você também precisa instalar o “resolvconf” no client.

sudo apt install resolvconf

Agora, crie o WireGuard arquivo de configuração do climáquina ent.

sudo nano /etc/wireguard/wg0.conf

Preencha-o com as seguintes linhas:

# Client configuration
[Interface]
PrivateKey = eLI6PoQf3xhLHu+wlIIME5ullpxxp8U+sYMKHGcv2VI= # The client_private.key value.
Address = 10.5.5.2/24 # IP address of the client's wg0 interface.
DNS = 8.8.8.8

# Server connection configuration
[Peer]
PublicKey = tsGQ8spwOQhpJb4BbhZtunLZEJCcPxUBIaQUpniQ+z4= # The server_public.key value.
AllowedIPs = 0.0.0.0/0 # Traffic for these addresses will be routed through the VPN tunnel. In this example, all addresses are selected.
Endpoint = 82.213.236.27:61951 # Public IP address of our VPN server and port number (ListenPort in the server configuration).
PersistentKeepalive = 25

Salve e feche-o.

Use este comando para estabelecer o VPN conexão:

sudo wg-quick up wg0

Para visualizar as informações de conexão, use este comando:

wg

Saída:

interface: wg0
public key: gsgfB29uYjpuFTCjC1+vHr9M7++MHJcG6Eg4rtuTu34=
private key: (hidden)
listening port: 58208



peer: tsGQ8spwOQhpJb4BbhZtunLZEJCcPxUBIaQUpniQ+z4=
endpoint: 82.213.236.27:61951
allowed ips: 0.0.0.0/0
...




Reference: https://serverspace.io/pt/support/help/set-up-wireguard-vpn-server-on-ubuntu/
