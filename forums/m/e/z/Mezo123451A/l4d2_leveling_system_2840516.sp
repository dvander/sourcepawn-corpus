#include <sourcemod>
#include <sdktools>

#define BASE_XP_PER_LEVEL 200
#define XP_MULTIPLIER 1.1
#define PLUGIN_VERSION "2.5.3"
#define MAX_PLAYERS 64

#define XP_REGULAR_MIN 5
#define XP_REGULAR_MAX 15
#define XP_SPECIAL_MIN 20
#define XP_SPECIAL_MAX 35
#define XP_BOSS_MIN 40
#define XP_BOSS_MAX 60
#define XP_WITCH_AS_WORLDSPAWN 50

// Add these new lines for the fix
#define MAX_LOAD_ATTEMPTS 5
#define LOAD_RETRY_DELAY 2.0
Handle g_loadRetryTimers[MAX_PLAYERS + 1];
int g_loadAttempts[MAX_PLAYERS + 1];

// New integrity check system
#define MAX_LEVEL_CAP 1000
#define MAX_XP_CAP 1000000
#define INTEGRITY_VERSION 1
bool g_dataLoaded[MAX_PLAYERS + 1];
char g_lastKnownSteamID[MAX_PLAYERS + 1][64];

int g_playerLevels[MAX_PLAYERS + 1];
int g_playerXP[MAX_PLAYERS + 1];
int g_selectedAchievement[MAX_PLAYERS + 1];
int g_doubleXPEvent = 0;

// Variables for playtime tracking
int g_playerPlaytime[MAX_PLAYERS + 1];
float g_playerSessionStartTime[MAX_PLAYERS + 1];

// NEW: Prevent double-save during map change
bool g_mapChanging = false;

ConVar g_cvarPluginVersion;
ConVar g_cvarAutoMessageInterval;
ConVar g_cvarPluginEnabled;
ConVar g_cvarDebugLogging;
Handle g_saveTimer;
Handle g_autoMessageTimer;
Handle g_doubleXPMessageTimer;
Handle g_eventCountdownTimer = null;
Handle g_playtimeTimer = null;
Handle g_allPlaytimesTimer = null;

new String:g_achievementNames[][] = {
    "Novato",       // Level 10
    "Aprendiz",     // Level 20
    "Adepto",       // Level 30
    "Oficial",      // Level 40
    "Experto",      // Level 50
    "Maestro",      // Level 60
    "Gran Maestro", // Level 70
    "Leyenda",      // Level 80
    "Mítico",       // Level 90
    "Inmortal",     // Level 100
    "Semidiós",     // Level 110
    "Conquistador", // Level 120
    "Héroe",        // Level 130
    "Vencedor",     // Level 140
    "Señor de la Guerra", // Level 150
    "Campeón",      // Level 160
    "Titán",        // Level 170
    "Fantasma",     // Level 180
    "Espectro",     // Level 190
    "Eterno",       // Level 200
    "Ascendido",    // Level 210
    "Supremo",      // Level 220
    "Invencible",   // Level 230
    "Señor Supremo",// Level 240
    "Héroe Inmortal",// Level 250
    "Celestial",    // Level 260
    "Divino",       // Level 270
    "Omnipotente",  // Level 280
    "Etéreo",       // Level 290
    "Divino",       // Level 300
    "Behemot",      // Level 310
    "Coloso",       // Level 320
    "Juggernaut",   // Level 330
    "Leviatán",     // Level 340
    "Monolito",     // Level 350
    "Titánico",     // Level 360
    "Goliat",       // Level 370
    "Brutal",       // Level 380
    "Implacable",   // Level 390
    "Gobernante Supremo",// Level 400
    "Infinito",     // Level 410
    "Imparable",    // Level 420
    "Inexorable",   // Level 430
    "Indomable",    // Level 440
    "Implacable",   // Level 450
    "Formidable",   // Level 460
    "Dominador",    // Level 470
    "Perpetuo",     // Level 480
    "Inmovible",    // Level 490
    "Omnisciente",  // Level 500
    "Trascendente", // Level 510
    "Definitivo",   // Level 520
    "Supremacía",   // Level 530
    "Señor Inmortal",// Level 540
    "Primordial",   // Level 550
    "Absoluto",     // Level 560
    "Inquebrantable", // Level 570
    "Soberano",     // Level 580
    "Supervisor",   // Level 590
    "Gobernante Invencible", // Level 600
    "Héroe Trascendente", // Level 610
    "Conquistador Inmortal", // Level 620
    "Líder Supremo", // Level 630
    "Guerrero Infinito", // Level 640
    "Campeón Divino", // Level 650
    "Deidad Inmortal", // Level 660
    "Omnipresente", // Level 670
    "Guardián Divino", // Level 680
    "Maestro Supremo", // Level 690
    "Gobernante Eterno", // Level 700
    "Señor Omnisciente", // Level 710
    "Rey Primordial", // Level 720
    "Soberano Absoluto", // Level 730
    "Guardián Inquebrantable", // Level 740
    "Campeón Eterno", // Level 750
    "Señor Supremo", // Level 760
    "Monarca Inmortal", // Level 770
    "Gobernante Divino", // Level 780
    "Campeón Infinito", // Level 790
    "Soberano Trascendente", // Level 800
    "Deidad Omnipotente", // Level 810
    "Rey Inmortal", // Level 820
    "Gobernante Supremo", // Level 830
    "Guerrero Divino", // Level 840
    "Fuerza Imparable", // Level 850
    "Entidad Divina", // Level 860
    "Entidad Suprema", // Level 870
    "Titán Inmortal", // Level 880
    "Poder Infinito", // Level 890
    "Campeón Omnipotente", // Level 900
    "Entidad Divina", // Level 910
    "Titán Supremo", // Level 920
    "Entidad Inmortal", // Level 930
    "Entidad Infinita", // Level 940
    "Poder Divino", // Level 950
    "Gobernante Omnipotente", // Level 960
    "Gobernante Divino", // Level 970
    "Poder Supremo", // Level 980
    "Poder Inmortal", // Level 990
    "Gobernante Infinito"  // Level 1000
};

public Plugin myinfo = 
{
    name = "Plugin de Subida de Nivel",
    author = "Mezo123451A",
    description = "Un sistema de nivelación con recompensas de XP aleatorias basadas en el tipo de enemigo",
    version = PLUGIN_VERSION
};

public void OnPluginStart()
{
    g_cvarPluginVersion = CreateConVar("levelup_version", PLUGIN_VERSION, "Versión del Plugin de Subida de Nivel", FCVAR_NOTIFY);
    g_cvarAutoMessageInterval = CreateConVar("levelup_auto_message_interval", "120.0", "Intervalo para mensajes automáticos en segundos", FCVAR_ARCHIVE, true, 10.0, true, 600.0);
    g_cvarPluginEnabled = CreateConVar("levelup_enabled", "1", "Habilitar o deshabilitar el plugin de Subida de Nivel", FCVAR_ARCHIVE);
    g_cvarDebugLogging = CreateConVar("levelup_debug_logging", "0", "Habilitar o deshabilitar el registro de depuración detallado (0=deshabilitado, 1=habilitado)", FCVAR_ARCHIVE);

    HookConVarChange(g_cvarAutoMessageInterval, OnAutoMessageIntervalChanged);
    AutoExecConfig(true, "levelup_plugin");

    EnsureLevelDataFolderExists(); // Asegurar que la carpeta de datos de nivel exista
    
    // Inicializar arrays de datos de jugadores
    for (int i = 1; i <= MaxClients; i++) {
        g_dataLoaded[i] = false;
        g_lastKnownSteamID[i][0] = '\0';
    }

    PrintToServer("Plugin de Subida de Nivel v%s ha iniciado correctamente!", PLUGIN_VERSION);

    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
    HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Post);
    
    // NEW: Guardar en fin de ronda y transición de mapa
    HookEvent("round_end",        Event_RoundEnd,        EventHookMode_PostNoCopy);
    HookEvent("map_transition",   Event_MapTransition,   EventHookMode_PostNoCopy);
    
    // Hookear procesamiento de chat
    AddCommandListener(Command_SayTeam, "say_team");
    AddCommandListener(Command_Say, "say");

    // Inicializar handles de timers
    g_saveTimer = INVALID_HANDLE;
    g_autoMessageTimer = INVALID_HANDLE;
    g_doubleXPMessageTimer = INVALID_HANDLE;
    g_eventCountdownTimer = INVALID_HANDLE;
    g_playtimeTimer = INVALID_HANDLE;
    g_allPlaytimesTimer = INVALID_HANDLE;

    // Luego crear tus timers
    g_saveTimer = CreateTimer(60.0, SaveAllPlayerDataTimer, _, TIMER_REPEAT);

    RegConsoleCmd("sm_lv", Command_ShowMainMenu);

    StartDoubleXPMessageTimer();
    StartAutoMessageTimer();
}

// NEW: Guardar en fin de ronda
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_mapChanging) {
        g_mapChanging = true;
        SaveAllPlayerData();
        DebugLog("Ronda finalizada – todos los datos de jugadores guardados.");
    }
}

// NEW: Guardar en transición de mapa
public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_mapChanging) {
        g_mapChanging = true;
        SaveAllPlayerData();
        DebugLog("Transición de mapa – todos los datos de jugadores guardados.");
    }
}

public void OnAutoMessageIntervalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    StartAutoMessageTimer();
}

void StartDoubleXPMessageTimer()
{
    if (g_doubleXPMessageTimer != INVALID_HANDLE)
    {
        KillTimer(g_doubleXPMessageTimer);
    }

    g_doubleXPMessageTimer = CreateTimer(120.0, DoubleXPMessageTimer, _, TIMER_REPEAT);
}

public Action DoubleXPMessageTimer(Handle timer, any data)
{
    char sDayOfWeek[2];
    FormatTime(sDayOfWeek, sizeof(sDayOfWeek), "%w", GetTime());
    int dayOfWeek = StringToInt(sDayOfWeek);

    if (dayOfWeek == 0 || dayOfWeek == 6)  // Sábado o Domingo
    {
        if (g_doubleXPEvent == 0)  // Solo establecer la duración cuando el evento inicia
        {
            g_doubleXPEvent = 1;
        }
        
        // Mensaje simplificado - eliminado tiempo restante
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                PrintHintText(i, "¡Fin de Semana de XP Doble Activo!");
            }
        }
    }
    else
    {
        g_doubleXPEvent = 0;
    }

    return Plugin_Continue;
}

void StartAutoMessageTimer()
{
    if (g_autoMessageTimer != INVALID_HANDLE)
    {
        KillTimer(g_autoMessageTimer);
    }

    float interval = g_cvarAutoMessageInterval.FloatValue;
    g_autoMessageTimer = CreateTimer(interval, AutoMessageTimer, _, TIMER_REPEAT);
}

public Action AutoMessageTimer(Handle timer, any data)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return Plugin_Continue;

    PrintToChatAll("\x04[Nivelación de Sobrevivientes]\x01 Usa \x05!lv\x01 para ver tu nivel, logros y estado del evento!");

    return Plugin_Continue;
}

// Menú Principal
public Action Command_ShowMainMenu(int client, int args)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return Plugin_Handled;

    Menu menu = new Menu(MenuHandler_MainMenu);
    menu.SetTitle("★ Menú del Jugador ★");

    menu.AddItem("1", "➤ Tu Nivel & XP");
    menu.AddItem("2", "➤ Niveles de Todos los Jugadores");
    menu.AddItem("3", "➤ Tabla de Líderes");
    menu.AddItem("4", "➤ Logros");
    menu.AddItem("5", "➤ Estado del Evento");
    menu.AddItem("6", "➤ Tu Tiempo de Juego");
    menu.AddItem("7", "➤ Tiempo de Juego de Todos");
    menu.AddItem("0", "➤ Salir");

    menu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public int MenuHandler_MainMenu(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        switch (itemIndex)
        {
            case 0: ShowLevelMenu(client);
            case 1: ShowAllLevelsMenu(client);
            case 2: ShowLeaderboardMenu(client);
            case 3: ShowAchievementsMenu(client);
            case 4: ShowEventStatusMenu(client);
            case 5: ShowPlaytimeMenu(client);
            case 6: ShowAllPlaytimesMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

void AddBackButton(Menu menu)
{
    menu.AddItem("back", "◄ Volver al Menú Principal");
}

public int MenuHandler_Generic(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(itemIndex, info, sizeof(info));
        
        if (StrEqual(info, "back"))
        {
            // Limpiar timers al volver
            if (g_playtimeTimer != null)
            {
                KillTimer(g_playtimeTimer);
                g_playtimeTimer = null;
            }
            if (g_allPlaytimesTimer != null)
            {
                KillTimer(g_allPlaytimesTimer);
                g_allPlaytimesTimer = null;
            }
            Command_ShowMainMenu(client, 0);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

// Menú de Nivel
void ShowLevelMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Tu Nivel & XP ★");

    int level = g_playerLevels[client];
    int xp = g_playerXP[client];
    int xpNextLevel = GetXPForNextLevel(level);

    char item[128];
    Format(item, sizeof(item), "➤ Nivel: %d\n➤ XP: %d / %d", level, xp, xpNextLevel);
    menu.AddItem("", item, ITEMDRAW_DISABLED);

    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

// Menú de Todos los Niveles
void ShowAllLevelsMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Niveles de Todos los Jugadores ★");

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            char playerName[64];
            GetClientName(i, playerName, sizeof(playerName));
            int level = g_playerLevels[i];
            int xp = g_playerXP[i];
            int xpNextLevel = GetXPForNextLevel(level);

            char item[128];
            int achievementIndex = g_selectedAchievement[i];
            if (achievementIndex >= 0)
            {
                Format(item, sizeof(item), "➤ [%s] %s: Nivel %d | XP: %d / %d",
                       g_achievementNames[achievementIndex], playerName, level, xp, xpNextLevel);
            }
            else
            {
                Format(item, sizeof(item), "➤ %s: Nivel %d | XP: %d / %d", playerName, level, xp, xpNextLevel);
            }
            menu.AddItem("", item, ITEMDRAW_DISABLED);
        }
    }

    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

// Menú de Tabla de Líderes
void ShowLeaderboardMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Tabla de Líderes ★");

    int players[MAX_PLAYERS + 1];
    int playerCount = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            players[playerCount++] = i;
        }
    }

    SortPlayerArray(players, playerCount);

    for (int i = 0; i < playerCount && i < 10; i++)
    {
        int player = players[i];
        char playerName[64];
        GetClientName(player, playerName, sizeof(playerName));
        char item[128];
        int achievementIndex = g_selectedAchievement[player];
        if (achievementIndex >= 0)
        {
            Format(item, sizeof(item), "➤ %d. [%s] %s - Nivel %d (XP: %d)",
                   i + 1, g_achievementNames[achievementIndex], playerName, g_playerLevels[player], g_playerXP[player]);
        }
        else
        {
            Format(item, sizeof(item), "➤ %d. %s - Nivel %d (XP: %d)",
                   i + 1, playerName, g_playerLevels[player], g_playerXP[player]);
        }
        menu.AddItem("", item, ITEMDRAW_DISABLED);
    }

    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

// Menú de Logros
void ShowAchievementsMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Achievements);
    menu.SetTitle("★ Tus Logros ★");

    // Añadir opción para deshabilitar la visualización de logros
    menu.AddItem("-1", "➤ Sin Logro");

    int level = g_playerLevels[client];
    for (int i = 0; i < sizeof(g_achievementNames); i++)
    {
        int achievementLevel = (i + 1) * 10;
        if (level >= achievementLevel)
        {
            char item[128];
            Format(item, sizeof(item), "➤ %s (Nivel %d)", g_achievementNames[i], achievementLevel);
            menu.AddItem(IntToChar(i), item);
        }
        else
        {
            break;
        }
    }

    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Achievements(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(itemIndex, info, sizeof(info));
        
        if (StrEqual(info, "back"))
        {
            Command_ShowMainMenu(client, 0);
        }
        else
        {
            int achievementIndex = StringToInt(info);
            g_selectedAchievement[client] = achievementIndex;
            
            if (achievementIndex == -1)
            {
                PrintToChat(client, "Has deshabilitado la visualización de logros en el chat.");
            }
            else
            {
                PrintToChat(client, "Has seleccionado el título '%s'", g_achievementNames[achievementIndex]);
            }
            
            ShowAchievementsMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

// Menú de Estado del Evento
void ShowEventStatusMenu(int client)
{
    // Iniciar o reiniciar el timer de cuenta regresiva
    if (g_eventCountdownTimer != null)
    {
        KillTimer(g_eventCountdownTimer);
    }
    g_eventCountdownTimer = CreateTimer(1.0, Timer_UpdateEventStatus, client, TIMER_REPEAT);
    
    // Visualización inicial
    Timer_UpdateEventStatus(INVALID_HANDLE, client);
}

public Action Timer_UpdateEventStatus(Handle timer, any client)
{
    if (!IsClientInGame(client))
    {
        g_eventCountdownTimer = null;
        return Plugin_Stop;
    }

    Menu menu = new Menu(MenuHandler_EventStatus);
    menu.SetTitle("★ Estado del Evento ★");

    char status[256];
    int currentTime = GetTime();
    int dayOfWeek = GetDayOfWeek();
    
    // Calcular tiempo hasta el próximo sábado si no es fin de semana
    if (dayOfWeek != 0 && dayOfWeek != 6)
    {
        int daysUntilSaturday = (6 - dayOfWeek + 7) % 7;
        if (daysUntilSaturday == 0) daysUntilSaturday = 7;
        
        int secondsInADay = 86400;
        int timeLeftToday = secondsInADay - (currentTime % secondsInADay);
        int totalSecondsUntilEvent = (daysUntilSaturday * secondsInADay) + timeLeftToday;
        
        int days = totalSecondsUntilEvent / 86400;
        int hours = (totalSecondsUntilEvent % 86400) / 3600;
        int minutes = (totalSecondsUntilEvent % 3600) / 60;
        int seconds = totalSecondsUntilEvent % 60;

        Format(status, sizeof(status), "➤ No hay evento en ejecución.\nEl próximo evento de XP Doble inicia en:\n%d días, %d horas, %d minutos, %d segundos", 
            days, hours, minutes, seconds);
    }
    // Si es fin de semana (sábado o domingo), mostrar tiempo restante hasta fin del domingo
    else
    {
        int secondsInDay = 86400;
        int daysUntilEnd = (dayOfWeek == 6) ? 2 : 1; // 2 días si sábado, 1 si domingo
        int currentSecondOfDay = currentTime % secondsInDay;
        int totalSecondsLeft = (daysUntilEnd * secondsInDay) - currentSecondOfDay;
        
        int days = totalSecondsLeft / 86400;
        int hours = (totalSecondsLeft % 86400) / 3600;
        int minutes = (totalSecondsLeft % 3600) / 60;
        int seconds = totalSecondsLeft % 60;

        Format(status, sizeof(status), "➤ ¡Fin de Semana de XP Doble Activo!\nTiempo restante:\n%d días, %d horas, %d minutos, %d segundos", 
            days, hours, minutes, seconds);
    }

    menu.AddItem("refresh", status);
    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);

    return Plugin_Continue;
}

// Añadir nuevo manejador de menú para estado del evento
public int MenuHandler_EventStatus(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(itemIndex, info, sizeof(info));
        
        if (StrEqual(info, "back"))
        {
            // Matar el timer de cuenta regresiva al volver
            if (g_eventCountdownTimer != null)
            {
                KillTimer(g_eventCountdownTimer);
                g_eventCountdownTimer = null;
            }
            Command_ShowMainMenu(client, 0);
        }
        else if (StrEqual(info, "refresh"))
        {
            ShowEventStatusMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

// Mostrar Menú de Tiempo de Juego
void ShowPlaytimeMenu(int client)
{
    // Iniciar o reiniciar el timer de cuenta regresiva
    if (g_playtimeTimer != null)
    {
        KillTimer(g_playtimeTimer);
    }
    g_playtimeTimer = CreateTimer(1.0, Timer_UpdatePlaytime, client, TIMER_REPEAT);
    
    // Visualización inicial
    Timer_UpdatePlaytime(INVALID_HANDLE, client);
}

// Añadir nuevo callback de timer para actualizar tiempo de juego personal
public Action Timer_UpdatePlaytime(Handle timer, any client)
{
    if (!IsClientInGame(client))
    {
        g_playtimeTimer = null;
        return Plugin_Stop;
    }

    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Tu Tiempo de Juego ★");

    int totalSeconds = g_playerPlaytime[client];
    if (g_playerSessionStartTime[client] > 0.0)
    {
        float sessionTime = GetGameTime() - g_playerSessionStartTime[client];
        totalSeconds += RoundToFloor(sessionTime);
    }

    int days = totalSeconds / 86400;
    int hours = (totalSeconds % 86400) / 3600;
    int minutes = (totalSeconds % 3600) / 60;
    int seconds = totalSeconds % 60;

    char timeString[256];
    Format(timeString, sizeof(timeString), "➤ Tiempo de Juego Total:\n%d días, %d horas, %d minutos, %d segundos", 
           days, hours, minutes, seconds);

    menu.AddItem("", timeString, ITEMDRAW_DISABLED);
    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);

    return Plugin_Continue;
}

// Mostrar Tiempo de Juego de Todos los Jugadores
void ShowAllPlaytimesMenu(int client)
{
    // Iniciar o reiniciar el timer de cuenta regresiva
    if (g_allPlaytimesTimer != null)
    {
        KillTimer(g_allPlaytimesTimer);
    }
    g_allPlaytimesTimer = CreateTimer(1.0, Timer_UpdateAllPlaytimes, client, TIMER_REPEAT);
    
    // Visualización inicial
    Timer_UpdateAllPlaytimes(INVALID_HANDLE, client);
}

// Añadir nuevo callback de timer para actualizar tiempo de juego de todos los jugadores
public Action Timer_UpdateAllPlaytimes(Handle timer, any client)
{
    if (!IsClientInGame(client))
    {
        g_allPlaytimesTimer = null;
        return Plugin_Stop;
    }

    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Tiempo de Juego de Todos ★");

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            char playerName[64];
            GetClientName(i, playerName, sizeof(playerName));

            int totalSeconds = g_playerPlaytime[i];
            if (g_playerSessionStartTime[i] > 0.0)
            {
                float sessionTime = GetGameTime() - g_playerSessionStartTime[i];
                totalSeconds += RoundToFloor(sessionTime);
            }

            int days = totalSeconds / 86400;
            int hours = (totalSeconds % 86400) / 3600;
            int minutes = (totalSeconds % 3600) / 60;
            int seconds = totalSeconds % 60;

            char item[256];
            Format(item, sizeof(item), "➤ %s:\n%d días, %d horas, %d minutos, %d segundos", 
                   playerName, days, hours, minutes, seconds);

            menu.AddItem("", item, ITEMDRAW_DISABLED);
        }
    }

    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);

    return Plugin_Continue;
}

// Funciones de Utilidad
void SortPlayerArray(int players[MAX_PLAYERS + 1], int count)
{
    for (int i = 0; i < count - 1; i++)
    {
        for (int j = 0; j < count - i - 1; j++)
        {
            int playerA = players[j];
            int playerB = players[j + 1];

            if (g_playerLevels[playerA] < g_playerLevels[playerB] ||
                (g_playerLevels[playerA] == g_playerLevels[playerB] && g_playerXP[playerA] < g_playerXP[playerB]))
            {
                int temp = players[j];
                players[j] = players[j + 1];
                players[j + 1] = temp;
            }
        }
    }
}

int GetXPForNextLevel(int currentLevel)
{
    float xpRequired = float(BASE_XP_PER_LEVEL);
    for (int i = 1; i < currentLevel; i++)
    {
        xpRequired *= XP_MULTIPLIER;
    }
    return RoundToNearest(xpRequired);
}

bool IsPlayerHuman(int client)
{
    return GetClientTeam(client) == 2;
}

int GetDayOfWeek()
{
    char sDayOfWeek[2];
    FormatTime(sDayOfWeek, sizeof(sDayOfWeek), "%w", GetTime());

    return StringToInt(sDayOfWeek);
}

char[] IntToChar(int value)
{
    char buffer[16];
    IntToString(value, buffer, sizeof(buffer));
    return buffer;
}

void AddXP(int client, int xp)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    char sDayOfWeek[2];
    FormatTime(sDayOfWeek, sizeof(sDayOfWeek), "%w", GetTime());

    int dayOfWeek = StringToInt(sDayOfWeek);

    if (dayOfWeek == 0 || dayOfWeek == 6)
    {
        xp *= 2;
    }

    g_playerXP[client] += xp;

    while (g_playerXP[client] >= GetXPForNextLevel(g_playerLevels[client]))
    {
        int xpRequired = GetXPForNextLevel(g_playerLevels[client]);
        g_playerXP[client] -= xpRequired;
        g_playerLevels[client]++;
        
        ClientCommand(client, "play UI/gift_drop.wav");

        char message[256];
        int level = g_playerLevels[client];
        if (level % 10 == 0)
        {
            int achievementIndex = (level / 10) - 1;
            Format(message, sizeof(message), "\x04[Nivelación de Sobrevivientes]\x01 %N ha subido a nivel \x04%d\x01 y ha ganado el LOGRO '\x05%s\x01'!", client, level, g_achievementNames[achievementIndex]);
            PrintToChatAll(message);
        }
        else
        {
            Format(message, sizeof(message), "\x04[Nivelación de Sobrevivientes]\x01 ¡Felicidades! %N ha subido a nivel \x04%d\x01!", client, level);
            PrintToChatAll(message);
        }

        SavePlayerData(client);
    }
}

int CheckByClassname(int victim, int client)
{
    char classname[64];
    GetEdictClassname(victim, classname, sizeof(classname));

    char model[PLATFORM_MAX_PATH];
    GetEntPropString(victim, Prop_Data, "m_ModelName", model, sizeof(model));

    int xp = 0;

    if (StrEqual(classname, "infected"))
    {
        xp = GetRandomInt(XP_REGULAR_MIN, XP_REGULAR_MAX);
        PrintToConsole(client, "Otorgados %d XP por matar a un Infectado Común.", xp);
    }
    else if (StrEqual(classname, "witch"))
    {
        xp = XP_WITCH_AS_WORLDSPAWN;
        PrintToConsole(client, "Otorgados %d XP por matar a una Bruja.", xp);
    }
    else if (StrEqual(classname, "tank") || StrContains(model, "tank") != -1 || StrContains(model, "hulk") != -1)
    {
        xp = GetRandomInt(XP_BOSS_MIN, XP_BOSS_MAX);
        PrintToConsole(client, "Otorgados %d XP por matar a un Tanque.", xp);
    }
    else if (StrEqual(classname, "boomer") || StrContains(model, "boomer") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Otorgados %d XP por matar a un Boomer.", xp);
    }
    else if (StrEqual(classname, "smoker") || StrContains(model, "smoker") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Otorgados %d XP por matar a un Smoker.", xp);
    }
    else if (StrEqual(classname, "hunter") || StrContains(model, "hunter") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Otorgados %d XP por matar a un Hunter.", xp);
    }
    else if (StrEqual(classname, "spitter") || StrContains(model, "spitter") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Otorgados %d XP por matar a una Spitter.", xp);
    }
    else if (StrEqual(classname, "jockey") || StrContains(model, "jockey") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Otorgados %d XP por matar a un Jockey.", xp);
    }
    else if (StrEqual(classname, "charger") || StrContains(model, "charger") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Otorgados %d XP por matar a un Charger.", xp);
    }
    else
    {
        xp = GetRandomInt(XP_REGULAR_MIN, XP_REGULAR_MAX);
        PrintToConsole(client, "Otorgados %d XP por matar a una entidad desconocida.", xp);
    }

    return xp;
}

// Nuevas funciones para la corrección de reinicio de progreso
public Action Timer_DelayedLoadData(Handle timer, any client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Stop;
        
    LoadPlayerDataWithRetry(client);
    return Plugin_Stop;
}

void LoadPlayerDataWithRetry(int client)
{
    if (g_loadAttempts[client] >= MAX_LOAD_ATTEMPTS)
    {
        PrintToServer("Falló la carga de datos para %N después de %d intentos", client, MAX_LOAD_ATTEMPTS);
        DebugLog("Falló la carga de datos para %N después de %d intentos", client, MAX_LOAD_ATTEMPTS);
        return;
    }
    
    char steamID[64];
    if (!GetSteamIDWithFallback(client, steamID, sizeof(steamID)) || steamID[0] == '\0')
    {
        g_loadAttempts[client]++;
        // Aumentado el retraso de reintento de 1.0 a 3.0 segundos
        g_loadRetryTimers[client] = CreateTimer(3.0, Timer_RetryLoad, client);
        PrintToServer("SteamID no disponible para %N aún, intento de reintento %d programado en 3 segundos", client, g_loadAttempts[client]);
        DebugLog("SteamID no disponible para %N aún, intento de reintento %d programado en 3 segundos", client, g_loadAttempts[client]);
        return;
    }
    
    // Almacenar el Steam ID para chequeos de integridad
    strcopy(g_lastKnownSteamID[client], sizeof(g_lastKnownSteamID[]), steamID);
    
    PrintToServer("SteamID para %N: %s", client, steamID);
    DebugLog("SteamID para %N: %s", client, steamID);
    LoadPlayerData(client);
}

public Action Timer_RetryLoad(Handle timer, any client)
{
    g_loadRetryTimers[client] = null;
    
    if (!IsClientConnected(client))
    {
        LogMessage("Cliente %d se desconectó antes de que el reintento se completara", client);
        return Plugin_Stop;
    }
    
    LogMessage("Reintentando carga de datos para %N (intento %d de %d)", client, g_loadAttempts[client] + 1, MAX_LOAD_ATTEMPTS);
    LoadPlayerDataWithRetry(client);
    return Plugin_Stop;
}

char[] FormatSteamIDForFilePath(const char[] steamID)
{
    char result[64];
    strcopy(result, sizeof(result), steamID);
    
    // Reemplazar caracteres problemáticos en rutas de archivos
    ReplaceString(result, sizeof(result), ":", "_");
    ReplaceString(result, sizeof(result), "/", "_");
    ReplaceString(result, sizeof(result), "\\", "_");
    ReplaceString(result, sizeof(result), "?", "_");
    ReplaceString(result, sizeof(result), "*", "_");
    ReplaceString(result, sizeof(result), "\"", "_");
    ReplaceString(result, sizeof(result), "<", "_");
    ReplaceString(result, sizeof(result), ">", "_");
    ReplaceString(result, sizeof(result), "|", "_");
    
    return result;
}

// Función auxiliar para obtener el Steam ID en múltiples formatos
bool GetSteamIDWithFallback(int client, char[] buffer, int bufferSize)
{
    // Intentar formato Steam2 primero (STEAM_X:Y:Z)
    if (GetClientAuthId(client, AuthId_Steam2, buffer, bufferSize, true) && buffer[0] != '\0')
    {
        DebugLog("Obtenido Steam2 ID para %N: %s", client, buffer);
        return true;
    }
    
    // Si falla, intentar formato Steam3 (numérico)
    if (GetClientAuthId(client, AuthId_Steam3, buffer, bufferSize, true) && buffer[0] != '\0')
    {
        DebugLog("Obtenido Steam3 ID para %N: %s", client, buffer);
        return true;
    }
    
    // Si eso falla también, intentar SteamID64
    if (GetClientAuthId(client, AuthId_SteamID64, buffer, bufferSize, true) && buffer[0] != '\0')
    {
        DebugLog("Obtenido SteamID64 para %N: %s", client, buffer);
        return true;
    }
    
    DebugLog("Falló la obtención de cualquier formato de Steam ID para %N", client);
    return false;
}

// Nueva función para calcular hash de integridad de datos
int CalculateIntegrityHash(int level, int xp, int playtime)
{
    // Hash simple pero efectivo que combina los valores
    // Esto detectará si cualquiera de estos valores cambia inesperadamente
    return ((level * 31337) ^ (xp * 27183)) + playtime;
}

// Nueva función para verificar integridad de datos
bool VerifyDataIntegrity(int client, int level, int xp, int playtime, int storedHash)
{
    int calculatedHash = CalculateIntegrityHash(level, xp, playtime);
    
    if (calculatedHash != storedHash)
    {
        DebugLog("Chequeo de integridad falló para %N: Hash esperado %d, obtenido %d", client, storedHash, calculatedHash);
        return false;
    }
    
    // También validar valores razonables
    if (level < 1 || level > MAX_LEVEL_CAP)
    {
        DebugLog("Valor de nivel inválido para %N: %d (fuera del rango 1-%d)", client, level, MAX_LEVEL_CAP);
        return false;
    }
    
    if (xp < 0 || xp > MAX_XP_CAP)
    {
        DebugLog("Valor de XP inválido para %N: %d (fuera del rango 0-%d)", client, xp, MAX_XP_CAP);
        return false;
    }
    
    if (playtime < 0)
    {
        DebugLog("Valor de tiempo de juego inválido para %N: %d (negativo)", client, playtime);
        return false;
    }
    
    return true;
}

void LoadPlayerData(int client)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    char steamID[64];
    if (!GetSteamIDWithFallback(client, steamID, sizeof(steamID)) || steamID[0] == '\0')
    {
        PrintToServer("Falló la obtención de Steam ID para el jugador %N", client);
        DebugLog("Falló la obtención de Steam ID para el jugador %N", client);
        return;
    }

    // Formatear el ID para nombre de archivo seguro - igual que en SavePlayerData
    char formattedID[64];
    strcopy(formattedID, sizeof(formattedID), FormatSteamIDForFilePath(steamID));
    
    // Usar BuildPath para una ruta de archivo más confiable - igual que en SavePlayerData
    char filePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, filePath, sizeof(filePath), "data/level_data/%s.kv", formattedID);
    
    PrintToServer("Cargando datos para %N desde: %s", client, filePath);
    DebugLog("Cargando datos para %N desde: %s (SteamID: %s)", client, filePath, steamID);

    // Verificar archivo de respaldo si el principal no existe
    char backupPath[PLATFORM_MAX_PATH];
    Format(backupPath, sizeof(backupPath), "%s.bak", filePath);
    
    if (!FileExists(filePath) && !FileExists(backupPath))
    {
        PrintToServer("No existe archivo de datos para %N en la ruta: %s", client, filePath);
        DebugLog("No existe archivo de datos para %N en la ruta: %s (SteamID: %s)", client, filePath, steamID);
        g_playerLevels[client] = 1;
        g_playerXP[client] = 0;
        g_selectedAchievement[client] = -1;
        g_playerPlaytime[client] = 0;
        g_dataLoaded[client] = true; // Marcar como cargado con valores predeterminados
        return;
    }

    // Intentar cargar desde archivo principal primero
    bool loadedSuccessfully = TryLoadFromFile(client, filePath, steamID);
    
    // Si el archivo principal falló, intentar respaldo
    if (!loadedSuccessfully && FileExists(backupPath))
    {
        PrintToServer("Intentando cargar desde archivo de respaldo para %N: %s", client, backupPath);
        DebugLog("Intentando cargar desde archivo de respaldo para %N: %s", client, backupPath);
        loadedSuccessfully = TryLoadFromFile(client, backupPath, steamID);
        
        if (loadedSuccessfully)
        {
            // Si el respaldo se cargó correctamente, restaurarlo como archivo principal
            PrintToServer("Restaurando archivo de respaldo para %N", client);
            DebugLog("Restaurando archivo de respaldo para %N", client);
            DeleteFile(filePath);
            CopyFile(backupPath, filePath);
        }
    }
    
    // Si ambos archivos fallaron, establecer valores predeterminados
    if (!loadedSuccessfully)
    {
        PrintToServer("Falló la carga de datos para %N desde ambos archivos principal y de respaldo, usando predeterminados", client);
        DebugLog("Falló la carga de datos para %N desde ambos archivos principal y de respaldo, usando predeterminados", client);
        g_playerLevels[client] = 1;
        g_playerXP[client] = 0;
        g_selectedAchievement[client] = -1;
        g_playerPlaytime[client] = 0;
    }
    
    g_dataLoaded[client] = true;
}

bool TryLoadFromFile(int client, const char[] filePath, const char[] steamID)
{
    KeyValues kv = new KeyValues("PlayerData");
    
    if (!kv.ImportFromFile(filePath))
    {
        delete kv;
        return false;
    }
    
    // Leer valores
    int level = kv.GetNum("level", 1);
    int xp = kv.GetNum("xp", 0);
    int achievement = kv.GetNum("achievement", -1);
    int playtime = kv.GetNum("playtime", 0);
    
    // Verificar integridad
    int storedHash = kv.GetNum("integrity_hash", 0);
    int integrityVersion = kv.GetNum("integrity_version", 0);
    
    // Verificar Steam ID almacenado si está disponible
    char storedSteamID[64];
    kv.GetString("steam_id", storedSteamID, sizeof(storedSteamID), "");
    
    bool dataValid = true;
    
    // Si tenemos un hash de integridad almacenado, verificarlo
    if (integrityVersion == INTEGRITY_VERSION && storedHash > 0)
    {
        dataValid = VerifyDataIntegrity(client, level, xp, playtime, storedHash);
    }
    
    // Chequeo adicional: si tenemos un Steam ID almacenado, asegurarnos de que coincida
    if (dataValid && storedSteamID[0] != '\0' && !StrEqual(storedSteamID, steamID))
    {
        DebugLog("Discordancia de Steam ID para %N: Archivo tiene %s pero actual es %s", 
                client, storedSteamID, steamID);
        dataValid = false;
    }
    
    // Si los datos son válidos, usarlos
    if (dataValid)
    {
        g_playerLevels[client] = level;
        g_playerXP[client] = xp;
        g_selectedAchievement[client] = achievement;
        g_playerPlaytime[client] = playtime;
        
        PrintToServer("Datos cargados correctamente para el jugador %N: Nivel %d, XP %d, Tiempo de juego %d segundos", 
                     client, g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client]);
        DebugLog("Datos cargados correctamente para el jugador %N: Nivel %d, XP %d, Tiempo de juego %d segundos (SteamID: %s)", 
                client, g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client], steamID);
        
        // Notificar al jugador
        PrintToChat(client, "\x04[Nivelación de Sobrevivientes]\x01 Tus datos han sido cargados: Nivel \x05%d\x01, XP \x05%d\x01", 
                   g_playerLevels[client], g_playerXP[client]);
                   
        delete kv;
        return true;
    }
    
    delete kv;
    return false;
}

// Función auxiliar para copiar un archivo
bool CopyFile(const char[] source, const char[] destination)
{
    File sourceFile = OpenFile(source, "rb");
    if (sourceFile == null)
    {
        return false;
    }
    
    File destFile = OpenFile(destination, "wb");
    if (destFile == null)
    {
        delete sourceFile;
        return false;
    }
    
    int buffer[4096];
    int bytesRead;
    
    while ((bytesRead = sourceFile.Read(buffer, sizeof(buffer), 1)) > 0)
    {
        destFile.Write(buffer, bytesRead, 1);
    }
    
    delete sourceFile;
    delete destFile;
    return true;
}

void SavePlayerData(int client)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    if (!IsClientInGame(client) || IsFakeClient(client))
    {
        DebugLog("No guardando datos para %d - no en juego o es un bot", client);
        return;
    }
    
    // No guardar si los datos nunca se cargaron correctamente
    if (!g_dataLoaded[client])
    {
        DebugLog("No guardando datos para %N - los datos nunca se cargaron correctamente", client);
        return;
    }

    if (g_playerSessionStartTime[client] > 0.0)
    {
        float sessionTime = GetGameTime() - g_playerSessionStartTime[client];
        g_playerPlaytime[client] += RoundToFloor(sessionTime);
        g_playerSessionStartTime[client] = GetGameTime();
    }

    char steamID[64];
    if (!GetSteamIDWithFallback(client, steamID, sizeof(steamID)) || steamID[0] == '\0')
    {
        PrintToServer("Falló la obtención de Steam ID para el jugador %N al guardar datos", client);
        DebugLog("Falló la obtención de Steam ID para el jugador %N al guardar datos", client);
        return;
    }
    
    // Verificar consistencia de Steam ID
    if (g_lastKnownSteamID[client][0] != '\0' && !StrEqual(steamID, g_lastKnownSteamID[client]))
    {
        PrintToServer("ADVERTENCIA: Steam ID cambió para %N de %s a %s - no guardando datos", 
                     client, g_lastKnownSteamID[client], steamID);
        DebugLog("ADVERTENCIA: Steam ID cambió para %N de %s a %s - no guardando datos", 
                client, g_lastKnownSteamID[client], steamID);
        return;
    }

    // Formatear el ID para nombre de archivo seguro
    char formattedID[64];
    strcopy(formattedID, sizeof(formattedID), FormatSteamIDForFilePath(steamID));
    
    // Asegurarse de que el directorio exista
    EnsureLevelDataFolderExists();
    
    // Usar BuildPath para una ruta de archivo más confiable
    char filePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, filePath, sizeof(filePath), "data/level_data/%s.kv", formattedID);
    
    PrintToServer("Guardando datos para %N en: %s", client, filePath);
    DebugLog("Guardando datos para %N en: %s (SteamID: %s)", client, filePath, steamID);

    // Validar datos antes de guardar
    if (g_playerLevels[client] < 1)
    {
        PrintToServer("Advertencia: No guardando nivel inválido (%d) para %N", g_playerLevels[client], client);
        DebugLog("Advertencia: No guardando nivel inválido (%d) para %N", g_playerLevels[client], client);
        return;
    }
    
    if (g_playerXP[client] < 0 || g_playerXP[client] > MAX_XP_CAP)
    {
        PrintToServer("Advertencia: No guardando XP inválido (%d) para %N", g_playerXP[client], client);
        DebugLog("Advertencia: No guardando XP inválido (%d) para %N", g_playerXP[client], client);
        return;
    }

    KeyValues kv = new KeyValues("PlayerData");

    kv.SetNum("level", g_playerLevels[client]);
    kv.SetNum("xp", g_playerXP[client]);
    kv.SetNum("achievement", g_selectedAchievement[client]);
    kv.SetNum("playtime", g_playerPlaytime[client]);
    kv.SetString("steam_id", steamID); // Almacenar el Steam ID original para referencia
    
    // Añadir datos de integridad
    int integrityHash = CalculateIntegrityHash(g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client]);
    kv.SetNum("integrity_hash", integrityHash);
    kv.SetNum("integrity_version", INTEGRITY_VERSION);
    
    // Almacenar timestamp
    kv.SetNum("last_save_time", GetTime());

    // Crear un respaldo del archivo existente si existe
    if (FileExists(filePath))
    {
        char backupPath[PLATFORM_MAX_PATH];
        Format(backupPath, sizeof(backupPath), "%s.bak", filePath);
        DeleteFile(backupPath); // Eliminar cualquier respaldo existente
        RenameFile(backupPath, filePath);
        DebugLog("Creado respaldo del archivo de datos existente en %s", backupPath);
    }

    if (kv.ExportToFile(filePath))
    {
        PrintToServer("Datos guardados correctamente para el jugador %N: Nivel %d, XP %d, Tiempo de juego %d segundos", client, g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client]);
        DebugLog("Datos guardados correctamente para el jugador %N: Nivel %d, XP %d, Tiempo de juego %d segundos (SteamID: %s)", client, g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client], steamID);
    }
    else
    {
        PrintToServer("Falló el guardado de datos para el jugador %N en la ruta: %s", client, filePath);
        DebugLog("Falló el guardado de datos para el jugador %N en la ruta: %s (SteamID: %s)", client, filePath, steamID);
        
        // Intentar restaurar desde respaldo si el guardado falló
        char backupPath[PLATFORM_MAX_PATH];
        Format(backupPath, sizeof(backupPath), "%s.bak", filePath);
        if (FileExists(backupPath))
        {
            PrintToServer("Intentando restaurar archivo de respaldo para %N", client);
            DebugLog("Intentando restaurar archivo de respaldo para %N desde %s", client, backupPath);
            RenameFile(filePath, backupPath);
        }
    }

    delete kv;
}

void SaveAllPlayerData()
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            SavePlayerData(i);
        }
    }
}

public void OnClientPutInServer(int client)
{
    if (!g_cvarPluginEnabled.BoolValue || IsFakeClient(client))
        return;

    // Reiniciar datos del cliente
    g_playerSessionStartTime[client] = GetGameTime();
    g_loadAttempts[client] = 0;
    g_dataLoaded[client] = false;
    g_lastKnownSteamID[client][0] = '\0';
    
    // Limpiar cualquier timer existente por si acaso
    if (g_loadRetryTimers[client] != null)
    {
        KillTimer(g_loadRetryTimers[client]);
        g_loadRetryTimers[client] = null;
    }
    
    // Crear timer para retrasar la carga inicial - aumentado de 0.5 a 3.0 segundos
    CreateTimer(3.0, Timer_DelayedLoadData, client);
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && client <= MaxClients && IsClientInGame(client))
    {
        // Puedes incluir cualquier código necesario aquí para cuando un jugador spawnea
    }
}

public void OnPlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && client <= MaxClients)
    {
        if (g_loadRetryTimers[client] != null)
        {
            KillTimer(g_loadRetryTimers[client]);
            g_loadRetryTimers[client] = null;
        }
        
        if (g_playerSessionStartTime[client] > 0.0)
        {
            float sessionTime = GetGameTime() - g_playerSessionStartTime[client];
            g_playerPlaytime[client] += RoundToFloor(sessionTime);
            g_playerSessionStartTime[client] = 0.0;
        }

        SavePlayerData(client);
    }
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim = GetClientOfUserId(event.GetInt("userid"));

    if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && IsPlayerHuman(attacker) && GetClientTeam(attacker) <= 2)
    {
        if (!IsFakeClient(attacker))
        {
            int xpAwarded = CheckByClassname(victim, attacker);
            AddXP(attacker, xpAwarded);
        }
    }
}

public Action SaveAllPlayerDataTimer(Handle timer, any data)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return Plugin_Handled;

    SaveAllPlayerData();
    g_mapChanging = false;  // Re-habilitar guardados al final del mapa
    return Plugin_Continue;
}

public void OnPluginEnd()
{
    if (g_saveTimer != INVALID_HANDLE)
    {
        KillTimer(g_saveTimer);
        g_saveTimer = INVALID_HANDLE;
    }
    
    // También limpiar otros timers mientras estamos en ello
    if (g_autoMessageTimer != INVALID_HANDLE)
    {
        KillTimer(g_autoMessageTimer);
        g_autoMessageTimer = INVALID_HANDLE;
    }
    
    if (g_doubleXPMessageTimer != INVALID_HANDLE)
    {
        KillTimer(g_doubleXPMessageTimer);
        g_doubleXPMessageTimer = INVALID_HANDLE;
    }
    
    SaveAllPlayerData();
}

void EnsureLevelDataFolderExists()
{
    char dirPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, dirPath, sizeof(dirPath), "data/level_data");
    
    if (!DirExists(dirPath))
    {
        PrintToServer("Creando directorio de datos de nivel: %s", dirPath);
        CreateDirectory(dirPath, 511); // 511 = permisos completos
    }
}

// Eliminar la función Command_Say y reemplazar con hook de User Message
public Action Command_Say(int client, const char[] command, int args)
{
    return ProcessChatMessage(client, false);
}

public Action Command_SayTeam(int client, const char[] command, int args)
{
    return ProcessChatMessage(client, true);
}

public Action ProcessChatMessage(int client, bool team)
{
    if (!g_cvarPluginEnabled.BoolValue || client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Continue;
    
    // Obtener el índice de logro
    int achievementIndex = g_selectedAchievement[client];
    if (achievementIndex < 0) // No se seleccionó logro o deshabilitado específicamente
        return Plugin_Continue; // Dejar que el mensaje original pase
    
    // Obtener texto
    char text[256];
    GetCmdArgString(text, sizeof(text));
    
    // Eliminar comillas
    if (text[0] == '"' && text[strlen(text)-1] == '"')
    {
        text[strlen(text)-1] = '\0';
        strcopy(text, sizeof(text), text[1]);
    }
    
    // Formatear con etiqueta de logro en verde claro (cambiado de \x04 a \x05)
    char message[512];
    if (team)
    {
        Format(message, sizeof(message), "\x01(EQUIPO) \x05[%s]\x01 %N: %s", 
            g_achievementNames[achievementIndex], client, text);
    }
    else
    {
        Format(message, sizeof(message), "\x05[%s]\x01 %N: %s", 
            g_achievementNames[achievementIndex], client, text);
    }
    
    // Imprimir mensaje a los clientes apropiados
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            if (!team || GetClientTeam(i) == GetClientTeam(client))
            {
                PrintToChat(i, "%s", message);
            }
        }
    }
    
    return Plugin_Handled; // Bloquear mensaje original
}

// Añadir una función de registro de depuración
void DebugLog(const char[] format, any ...)
{
    if (!g_cvarDebugLogging.BoolValue)
        return;
        
    char buffer[512];
    VFormat(buffer, sizeof(buffer), format, 2);
    
    char logFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, logFile, sizeof(logFile), "logs/levelup_debug.log");
    
    LogToFileEx(logFile, "%s", buffer);
}