
Artigo Retirado na integra sem modificações
de [Blogdopaulo](https://www.blogdopaulo.com/artigo/hospedando-um-site-na-rede-onion)


Hospedando um Site na Rede Onion

Fala Pessoal,

Hoje vou ensinar como hospedar um site na Rede Onion totalmente grátis na sua própria máquina!

Antes de começar, é importante mencionar que a Rede Onion é um espaço peculiar da internet que não é acessado da mesma forma que a web normal. 
É importante enfatizar que o uso da Rede Onion para hospedar sites deve ser feito estritamente para fins legais e éticos. 
O anonimato e a privacidade são fundamentais na Rede Onion, mas também podem ser usados para fins ilegais, portanto, é importante manter-se dentro dos limites legais e éticos.

Como requisito, vamos precisar do XAMPP e do Tor Browser instalados na sua máquina!

Para começar, vamos dar um start no XAMPP.

Note que ele estará rodando na porta 80!

Feito isso, vamos modificar um arquivo chamado torrc dentro da raiz do Tor Browser (Tor Browser\Browser\TorBrowser\Data\Tor\torrc).

Dentro do arquivo torrc, teremos o seguinte conteúdo:


<code>
#This file was generated by Tor; if you edit it, comments will not be preserved
#The old torrc file was renamed to torrc.orig.1, and Tor will ignore it

ClientOnionAuthDir C:\Users\Paulo\Desktop\Tor Browser\Browser\TorBrowser\Data\Tor\onion-auth
DataDirectory C:\Users\Paulo\Desktop\Tor Browser\Browser\TorBrowser\Data\Tor
GeoIPFile C:\Users\Paulo\Desktop\Tor Browser\Browser\TorBrowser\Data\Tor\geoip
GeoIPv6File C:\Users\Paulo\Desktop\Tor Browser\Browser\TorBrowser\Data\Tor\geoip6

#Vamos adicionar as seguintes linhas a este arquivo:
HiddenServiceDir "hidden_service"
HiddenServicePort 80 127.0.0.1:80 

</code>


Salve o arquivo e abra o Tor Browser.

Na raiz do Tor Browser, será criada uma pasta chamada "hidden_service". Dentro desta pasta, será criado um arquivo chamado "hostname".



Abra o arquivo "hostname" em um bloco de notas ou qualquer outro editor de texto. Dentro deste arquivo, você encontrará seu endereço na forma de uma sequência alfanumérica e ".onion". Este é o endereço que as pessoas usarão para acessar seu site na Rede Onion.

Lembre-se de manter seu site e atividades na Rede Onion legais e éticas. Além disso, considere a segurança do seu servidor, uma vez que a Rede Onion pode atrair a atenção de indivíduos mal-intencionados.
