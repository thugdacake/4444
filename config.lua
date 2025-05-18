Config = {}

-- General Settings
Config.CommandName = "tokyobox" -- Comando para abrir o Tokyo Box
Config.ToggleKey = "F3" -- Tecla para alternar o Tokyo Box (F3 por padrão)
Config.DefaultVolume = 50 -- Volume padrão (0-100)
Config.EnableVIPCheck = true -- Habilitar verificação de permissão VIP

-- VIP Settings 
Config.VIPGroups = {"tier3", "tier4", "tier5", "tier6", "tier7", "tokyobox", "admin"} -- Grupos VIP permitidos
Config.VIPJobName = nil -- Se seu servidor usa sistema de trabalho para VIP, defina o nome aqui (defina nil para desabilitar)
Config.VIPItemName = nil -- Se seu servidor usa um item para VIP, defina o nome aqui (defina nil para desabilitar)

-- UI Settings
Config.UIScale = 0.6 -- Escala da UI (0.5-1.0)
Config.UIPosition = "right" -- Posição da UI na tela (right, left)
Config.DefaultTheme = "galaxy" -- Tema padrão (galaxy)

-- Audio Settings
Config.EnableSpatialAudio = true -- Habilitar áudio 3D/espacial
Config.AudioRange = 10.0 -- Alcance para o áudio espacial em metros (se habilitado)
Config.DefaultMusicURL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ" -- URL padrão de música para teste
Config.DefaultAudioRange = 10.0 -- Alcance padrão de áudio (em metros)
Config.MaxAudioRange = 30.0 -- Alcance máximo de áudio (em metros)

-- Bluetooth Settings
Config.EnableBluetooth = true -- Habilitar funcionalidade Bluetooth
Config.DefaultBluetoothStatus = false -- Status padrão do Bluetooth (false = desligado, true = ligado)

-- Database Settings
Config.DatabaseRefreshRate = 60 -- Com que frequência sincronizar dados com o banco de dados (em segundos)
Config.MaxPlaylists = 10 -- Número máximo de playlists por usuário
Config.MaxSongsPerPlaylist = 50 -- Número máximo de músicas por playlist

-- Music API Settings
Config.MusicAPI = {
    URL = "https://www.googleapis.com/youtube/v3",
    Key = "AIzaSyAdzIskTxElZumF29pNBux-PYs7EOXWcDI", -- Chave da API do Google configurada
    EnableCache = true, -- Habilitar cache de músicas
    CacheTime = 3600 -- Tempo de cache em segundos (1 hora)
}

-- Debug Settings
Config.Debug = false -- Habilitar modo de depuração (logs mais detalhados)