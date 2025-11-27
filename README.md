# APP - Chat de Conversa — Bate-papo por Proximidade

Nome do Aplicativo: GeoTalk
- Converse com quem está perto de você! Sem internet e sem Wi-Fi.
- Funciona 100% offline! 
• Wi-Fi Direct + Bluetooth 
• Totalmente gratuito e aberto

### O que é esse aplicativo?

**Chat de Conversa** é um aplicativo de mensagens instantâneas que permite conversar com pessoas que estão fisicamente próximas de você, mesmo sem internet, sem roteador, sem dados móveis.

Ideal para:
- Shows e festivais
- Sala de aula / universidade
- Metrô, ônibus, avião
- Acampamentos, trilhas, praia
- Lugares com internet ruim ou bloqueada
- Qualquer situação em que você queira trocar mensagem rápido e privado


### Como funciona?

O app usa a tecnologia **Nearby Connections** do Google (pacote oficial `nearby_connections`) que combina:
- Bluetooth (para descobrir dispositivos próximos)
- Wi-Fi Direct / Wi-Fi Aware (para trocar mensagens rápido e com baixa latência)

Você abre o app → ele começa a procurar pessoas → quando alguém estiver perto e com o app aberto, vocês se conectam automaticamente e podem conversar em tempo real.


### Funcionalidades 

- Conexão automática por proximidade
- Troca de mensagens de texto em tempo real
- Indicador de online/offline em tempo real
- Bolinha verde quando a pessoa está conectada no momento
- Contador de mensagens não lidas
- Busca por nome
- Excluir conversa 
- Configurações pra modo noturno
- Interface limpa, moderna e totalmente em português
- Não salva nada no servidor — tudo fica só no seu celular


### Tecnologias e Pacotes Utilizados

| Tecnologia / Pacote                  | Finalidade                                      | Versão usada |
|--------------------------------------|-------------------------------------------------|--------------|
| Flutter + Dart                       | Framework principal do app                      | 3.24+        |
| `nearby_connections`                 | Conexão Bluetooth + Wi-Fi Direct (Google)       | ^5.0.0       |
| Provider                             | Gerenciamento de estado                         | ^6.1.2       |
| SQflite                              | Banco de dados local (SQLite)                   | ^2.3.3       |
| shared_preferences                   | Salvar nome do usuário e configurações          | ^2.3.0       |
| intl                                 | Formatação de data e hora                       | ^0.19.0      |
| Material 3 (You)                     | Design moderno do Google                        | Padrão       |


### Como instalar e testar (passo a passo)

# Passo 1. Clone o repositório
git clone https://github.com/DaniellyBenicio/chat_comunicacao_proximidade.git

# 2. Entre na pasta
cd chat_de_conversa

# 3. Abra o vs code
cd .code
# 4. Abra o terminal do vs code 
ctrl j

# 5.Baixe as dependências
flutter pub get

# 6. Conecte o cabo USB no seu conputador e no seu celular

# 8. Execute no terminal do vs code:
flutter run

# 9. Aceite todas as permições no seu dispositivo

# 10. Faça seu cadastro e desfrute desse app moderno.