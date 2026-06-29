// contador_jugadores_chat.sp

#include <sourcemod>
#include <sdktools>

#define MIN_INTERVAL 90.0
#define MAX_INTERVAL 180.0
#define PLUGIN_VERSION "1.0.1"
#define DEFAULT_MAX_PLAYERS 4

ConVar g_cvVersion;
ConVar g_cvMaxPlayers;
Handle g_Timer = INVALID_HANDLE;

public Plugin:myinfo = 
{
    name = "Contador de Jugadores en Chat",
    author = "Mezo123451A",
    description = "Anuncia el número actual de jugadores en el chat a intervalos aleatorios",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    // Crear ConVar de versión
    g_cvVersion = CreateConVar("playercount_version", PLUGIN_VERSION, "Versión del Contador de Jugadores en Chat", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
    
    // Obtener la ConVar de jugadores máximos del servidor
    g_cvMaxPlayers = FindConVar("sv_maxplayers");
    
    if(g_cvMaxPlayers == null)
    {
        LogError("¡Error al encontrar la ConVar sv_maxplayers!");
        return;
    }
    
    // Establecer la versión
    g_cvVersion.SetString(PLUGIN_VERSION);
    
    // Crear archivo de configuración
    AutoExecConfig(true, "plugin_playercount");
    
    // Iniciar el temporizador inicial
    CreateRandomTimer();
    
    // Enganchar evento de inicio de mapa
    HookEvent("round_start", Event_RoundStart);
    
    // Registrar inicio del plugin
    LogMessage("Contador de Jugadores en Chat v%s ha sido cargado.", PLUGIN_VERSION);
}

public void OnMapStart()
{
    // Asegurar que el temporizador esté funcionando al cambiar de mapa
    if(g_Timer == INVALID_HANDLE)
    {
        CreateRandomTimer();
    }
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    // Asegurar que el temporizador esté funcionando al iniciar ronda
    if(g_Timer == INVALID_HANDLE)
    {
        CreateRandomTimer();
    }
    return Plugin_Continue;
}

public void CreateRandomTimer()
{
    // Eliminar temporizador existente si existe
    if(g_Timer != INVALID_HANDLE)
    {
        KillTimer(g_Timer);
        g_Timer = INVALID_HANDLE;
    }
    
    float interval = GetRandomFloat(MIN_INTERVAL, MAX_INTERVAL);
    LogMessage("Configurando temporizador para %.2f segundos", interval);
    g_Timer = CreateTimer(interval, Timer_AnnouncePlayerCount, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_AnnouncePlayerCount(Handle:timer)
{
    g_Timer = INVALID_HANDLE;
    AnnouncePlayerCount();
    CreateRandomTimer();
    return Plugin_Stop;
}

public void AnnouncePlayerCount()
{
    // Obtener contador actual de jugadores (excluyendo bots)
    int playerCount = 0;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientConnected(i) && !IsFakeClient(i))
        {
            playerCount++;
        }
    }
    
    // Obtener slots máximos de sv_maxplayers
    int maxSlots = g_cvMaxPlayers.IntValue;
    
    // Por defecto 4 jugadores si sv_maxplayers es -1
    if(maxSlots <= 0)
    {
        maxSlots = DEFAULT_MAX_PLAYERS;
    }
    
    LogMessage("Anunciando contador de jugadores: %d/%d", playerCount, maxSlots);
    PrintToChatAll("\x01[\x04Contador de Jugadores\x01] Jugadores Actuales: \x04%d\x01/\x04%d", playerCount, maxSlots);
}

public void OnPluginEnd()
{
    // Limpiar recursos
    if(g_Timer != INVALID_HANDLE)
    {
        KillTimer(g_Timer);
        g_Timer = INVALID_HANDLE;
    }
    LogMessage("Contador de Jugadores en Chat v%s ha sido descargado.", PLUGIN_VERSION);
}

public void OnMapEnd()
{
    // Limpiar temporizador
    if(g_Timer != INVALID_HANDLE)
    {
        KillTimer(g_Timer);
        g_Timer = INVALID_HANDLE;
    }
}