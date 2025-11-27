# GeoTalk — Chat por Proximidade 

<div align="center">
  <img src="assets/images/logo.png" width="140" alt="GeoTalk Logo"/>
  <h2>Converse com quem está perto de você — 100% offline</h2>
  <p><strong>Wi-Fi Direct + Bluetooth • Sem internet • Sem cadastro • Totalmente gratuito</strong></p>
</div>

<br>

### O que é o GeoTalk?

O **GeoTalk** é um aplicativo de bate-papo por proximidade que permite trocar mensagens em tempo real com pessoas que estão fisicamente perto de você, mesmo sem internet, sem Wi-Fi público e sem usar seus dados móveis.

Útil para:
- Shows, festas e eventos
- Sala de aula, cursinho, universidade
- Metrô, ônibus, avião
- Acampamentos, praias, trilhas
- Lugares com sinal ruim ou internet bloqueada
- Qualquer lugar onde você quer falar rápido e privado

<br>

### Como funciona?

O app usa a tecnologia oficial do Google chamada **Nearby Connections** (`nearby_connections`) que combina:
- Bluetooth → para descobrir quem está por perto
- Wi-Fi Direct / Wi-Fi Aware → para enviar mensagens rápido e com baixa latência

Você abre o app → ele procura automaticamente → quando outra pessoa com o GeoTalk estiver perto, vocês se conectam e já podem conversar na hora.

<br>

### Funcionalidades 

- Conexão automática por proximidade
- Mensagens de texto em tempo real
- Indicador online/offline em tempo real
- Bolinha verde quando a pessoa está conectada agora
- Contador de mensagens não lidas
- Busca por nome ou última mensagem
- Excluir conversa rapidamente
- Configurações para modo noturno
- Interface limpa, moderna e 100% em português
- Tudo fica só no seu celular — zero servidor, zero rastreamento

<br>

### Tecnologias e Dependências Reais (conforme seu pubspec.yaml)

| Tecnologia / Pacote              | Finalidade                                       | Versão Atual |
|----------------------------------|--------------------------------------------------|--------------|
| Flutter + Dart                   | Framework principal                              | 3.24+        |
| `nearby_connections: ^4.3.0`     | Conexão Bluetooth + Wi-Fi Direct (Google)        | 4.3.0        |
| `provider: ^6.1.5+1`             | Gerenciamento de estado                          | 6.1.5+1      |
| `sqflite: ^2.3.3`                | Banco de dados local (SQLite)                    | 2.3.3        |
| `shared_preferences: ^2.5.3`     | Salvar nome do usuário e configurações           | 2.5.3        |
| `intl: ^0.19.0`                  | Formatação de hora (HH:mm)                       | 0.19.0       |
| `permission_handler: ^12.0.1`    | Pedir permissões de localização e Bluetooth      | 12.0.1       |
| `path_provider: ^2.1.5` + `path` | Caminhos para salvar o banco de dados            | 2.1.5        |
| `device_info_plus: ^10.0.0`      | Identificar dispositivo único                    | 10.0.0       |
| `logger: ^2.6.2`                 | Logs para debug (não aparece no app final)       | 2.6.2        |
| Material 3 (You)                 | Design moderno do Google                         | Padrão       |

<br>

### Como instalar e testar (passo a passo simples)

Precisa de **2 celulares Android** (ou 2 emuladores com suporte a Bluetooth)

```bash
# 1. Clone o projeto
git clone https://github.com/DaniellyBenicio/chat_comunicacao_proximidade.git

# 2. Entre na pasta
cd chat_comunicacao_proximidade

# 3. Abre o vs code
. code

# 4. Instale as dependências no terminal do vs code
flutter pub get

# 5. Conecte dois celulares Android via USB (ou use emuladores)

# 6. Execute nos dois dispositivos:
flutter run

# 7. Cadastre -se e desfrute desse app moderno