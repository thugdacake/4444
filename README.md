# Tokyo Box - Documentação

## Sobre o Tokyo Box

Tokyo Box é um aplicativo de música para servidores FiveM QBCore que funciona como um Spotify dentro do jogo. O aplicativo possui interface estilo iPhone com tema de galáxia, sistema de permissão VIP e gerenciamento de playlists, permitindo que os jogadores VIP desfrutem de uma experiência de música personalizada enquanto jogam.

## Recursos Principais

- **Interface Estilo iPhone**: Design moderno e intuitivo com tema de galáxia
- **Sistema de Permissão VIP**: Acesso exclusivo para jogadores VIP
- **Gerenciamento de Playlists**: Crie, edite e compartilhe playlists personalizadas
- **Favoritos**: Marque suas músicas favoritas para acesso rápido
- **Sistema de Pesquisa**: Encontre músicas facilmente
- **Modo Bluetooth**: Reproduza músicas em seu veículo ou para jogadores próximos
- **Controle de Alcance**: Ajuste a distância de audibilidade do som
- **Integração com o Banco de Dados**: Armazenamento persistente de playlists e preferências

## Instalação

1. Copie a pasta `tokyo_box` para o diretório `resources` do seu servidor FiveM
2. Adicione `ensure tokyo_box` ao seu arquivo `server.cfg`
3. Configure a conexão com o banco de dados MySQL no arquivo `config.lua`
4. Configure a API de música conforme a seção abaixo
5. Reinicie seu servidor

## Configuração da API de Música

O Tokyo Box requer uma API de música para funcionar corretamente. Existem várias opções disponíveis:

### Opção 1: YouTube Data API (Recomendada)

1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Crie um novo projeto
3. Habilite a "YouTube Data API v3"
4. Crie uma chave de API em "Credenciais"
5. Copie a chave API gerada
6. Adicione a chave ao arquivo `config.lua`:

```lua
Config.MusicAPI = {
    URL = "https://www.googleapis.com/youtube/v3",
    Key = "SUA_CHAVE_API_AQUI",
    EnableCache = true,
    CacheTime = 3600
}
```

### Opção 2: Last.fm API

1. Crie uma conta no [Last.fm](https://www.last.fm/)
2. Acesse [Last.fm API](https://www.last.fm/api/account/create) e crie uma aplicação
3. Copie a chave API gerada
4. Adicione a chave ao arquivo `config.lua`:

```lua
Config.MusicAPI = {
    URL = "http://ws.audioscrobbler.com/2.0",
    Key = "SUA_CHAVE_API_AQUI",
    EnableCache = true,
    CacheTime = 3600
}
```

### Opção 3: API personalizada

Se você possui um serviço de streaming próprio ou outra fonte de músicas, pode configurá-lo no arquivo `config.lua`:

```lua
Config.MusicAPI = {
    URL = "URL_DA_SUA_API",
    Key = "SUA_CHAVE_API_SE_NECESSÁRIO",
    EnableCache = true,
    CacheTime = 3600
}
```

## Configuração do Banco de Dados

O Tokyo Box utiliza o oxmysql para armazenar dados. As tabelas serão criadas automaticamente ao iniciar o recurso pela primeira vez. Certifique-se de que a conexão com o banco de dados está configurada corretamente no seu servidor QBCore.

## Configuração do Sistema VIP

Por padrão, o Tokyo Box verifica se o jogador possui o grupo "vip" do QBCore. Você pode personalizar as verificações VIP no arquivo `config.lua`:

```lua
Config.EnableVIPCheck = true -- Habilitar verificação de permissão VIP
Config.VIPGroup = "vip" -- Nome do grupo VIP no seu servidor
Config.VIPJobName = nil -- Se seu servidor usa sistema de trabalho para VIP, defina o nome aqui
Config.VIPItemName = nil -- Se seu servidor usa um item para VIP, defina o nome aqui
```

## Comando e Teclas de Atalho

- Comando: `/tokyobox` - Abre ou fecha o aplicativo Tokyo Box
- Tecla padrão: `F3` - Pode ser alterada no arquivo `config.lua`

## Funcionalidade Bluetooth

A funcionalidade Bluetooth permite que as músicas sejam reproduzidas de forma espacial, sendo audíveis para outros jogadores e dentro de veículos:

1. **Ativar Bluetooth**: Ative o botão Bluetooth no player expandido
2. **Ajustar Alcance**: Use o controle deslizante para definir a distância de audibilidade (1-30 metros)
3. **No Veículo**: Quando o Bluetooth está ativo e você está em um veículo, a música será reproduzida pelo veículo

## Configuração Adicional

Todas as configurações podem ser personalizadas no arquivo `config.lua`:

```lua
-- Configurações gerais
Config.CommandName = "tokyobox" -- Comando para abrir o Tokyo Box
Config.ToggleKey = "F3" -- Tecla para alternar o Tokyo Box (F3 por padrão)
Config.DefaultVolume = 50 -- Volume padrão (0-100)

-- Configurações de áudio
Config.EnableSpatialAudio = true -- Habilitar áudio 3D/espacial
Config.AudioRange = 10.0 -- Alcance padrão para o áudio espacial em metros
Config.DefaultAudioRange = 10.0 -- Alcance padrão de áudio (em metros)
Config.MaxAudioRange = 30.0 -- Alcance máximo de áudio (em metros)

-- Configurações Bluetooth
Config.EnableBluetooth = true -- Habilitar funcionalidade Bluetooth
Config.DefaultBluetoothStatus = false -- Status padrão do Bluetooth
```

## Desenvolvimento e Extensão

O Tokyo Box foi desenvolvido de forma modular para facilitar a extensão e personalização. A estrutura do projeto é:

- `client/` - Scripts do lado do cliente
- `server/` - Scripts do lado do servidor
- `ui/` - Interface do usuário (HTML, CSS, JS)

Se você deseja estender a funcionalidade ou personalizar o Tokyo Box, recomendamos focar nos arquivos:

- `server/songs.lua` - Para adicionar suporte a novas fontes de música
- `ui/style.css` - Para personalizar o visual
- `config.lua` - Para ajustar as configurações

## Suporte a APIs Externas

Para adicionar suporte a outras APIs de música, modifique a função `SearchExternalAPI` no arquivo `server/songs.lua`. Esta função é responsável por buscar músicas na API configurada.

## Solução de Problemas

1. **Músicas não reproduzem**
   - Verifique se a chave API está configurada corretamente
   - Verifique se a URL da API está acessível
   - Certifique-se de que o xSound está instalado e funcionando

2. **Interface não abre**
   - Verifique se o jogador tem permissão VIP
   - Verifique se o comando `/tokyobox` está registrado
   - Certifique-se de que não há erros no console do cliente

3. **Problemas com banco de dados**
   - Verifique se o oxmysql está instalado e configurado
   - Certifique-se de que o usuário do banco de dados tem permissões para criar tabelas
   - Verifique se as tabelas foram criadas corretamente

## Licença

Este recurso é licenciado sob MIT License. Você pode usá-lo, modificá-lo e distribuí-lo conforme suas necessidades, desde que mantenha os créditos originais.

## Créditos

- Desenvolvido por Tokyo Box Team
- Design UI/UX inspirado em interfaces de iPhone e temas galáticos
- Utiliza as bibliotecas xSound e oxmysql# 4444
