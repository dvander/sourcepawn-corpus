#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <vsh2>
#include <menus>
#include <clientprefs>
#include <morecolors>

#define MAX_BOSS_NAME_SIZE 64
#define MAX_BOSS_CONFIGS 128
#define MAX_SONG_NAME_SIZE 64
#define MUSIC_VOLUME_DEFAULT 0.5

enum struct BossMusicConfig {
    char bossName[MAX_BOSS_NAME_SIZE];
    char musicFile[PLATFORM_MAX_PATH];
    float duration;
    char songName[MAX_SONG_NAME_SIZE];
}

BossMusicConfig g_BossMusicConfigs[MAX_BOSS_CONFIGS];
int g_BossMusicConfigCount = 0;

bool g_bMusicEnabled[MAXPLAYERS + 1];
int g_iCurrentSong[MAXPLAYERS + 1];
bool g_bMusicPlaying[MAXPLAYERS + 1];
char g_sCurrentSong[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
float g_fMusicVolume[MAXPLAYERS + 1];
float g_fMusicStartTime[MAXPLAYERS + 1];
bool g_bRoundActive = false;
Handle g_hMusicTimer = null;

// Cookie-k
Handle g_hCookieEnabled = null;
Handle g_hCookieVolume = null;
Handle g_hCookieSong = null;

public Plugin myinfo = 
{
    name = "[VSH2] Boss Music",
    author = "Sajt",
    version = "1.0",
    description = "Plays client-specific music with volume control, song selection, auto-next, and cookie persistence",
};

public void OnPluginStart()
{
    LoadBossMusicConfig();
    RegConsoleCmd("sm_vsh2music", Command_VSH2Music, "Toggle VSH2 boss music on/off, adjust volume, or play random with 'on random' for yourself, or use 'menu'");
    HookEvent("arena_round_start", OnArenaRoundStart, EventHookMode_PostNoCopy);
    HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
    
    // Cookie-k inicializálása
    g_hCookieEnabled = RegClientCookie("vsh2music_enabled", "Music enabled state", CookieAccess_Private);
    g_hCookieVolume = RegClientCookie("vsh2music_volume", "Music volume", CookieAccess_Private);
    g_hCookieSong = RegClientCookie("vsh2music_song", "Last played song", CookieAccess_Private);
    
    for (int i = 1; i <= MaxClients; i++)
    {
        g_bMusicPlaying[i] = false;
        g_fMusicVolume[i] = MUSIC_VOLUME_DEFAULT;
        g_fMusicStartTime[i] = 0.0;
        if (IsClientInGame(i))
        {
            OnClientCookiesCached(i);
        }
    }
    
    if (g_hMusicTimer == null)
    {
        g_hMusicTimer = CreateTimer(1.0, Timer_CheckMusicEnd, _, TIMER_REPEAT);
    }
}

public void OnMapStart()
{
    for (int i = 0; i < g_BossMusicConfigCount; i++)
    {
        char soundPath[PLATFORM_MAX_PATH];
        Format(soundPath, sizeof(soundPath), "sound/%s", g_BossMusicConfigs[i].musicFile);
        PrecacheSound(g_BossMusicConfigs[i].musicFile, true);
        AddFileToDownloadsTable(soundPath);
        //PrintToServer("[VSH2 Music] Precached and added to downloads: %s (%.1f sec) for %s", 
                      //soundPath, g_BossMusicConfigs[i].duration, g_BossMusicConfigs[i].bossName);
    }
}

public void OnClientCookiesCached(int client)
{
    char enabled[2];
    char volume[8];
    char song[PLATFORM_MAX_PATH];
    
    GetClientCookie(client, g_hCookieEnabled, enabled, sizeof(enabled));
    GetClientCookie(client, g_hCookieVolume, volume, sizeof(volume));
    GetClientCookie(client, g_hCookieSong, song, sizeof(song));
    
    if (strlen(enabled) == 0)
    {
        g_bMusicPlaying[client] = false;
    }
    else
    {
        g_bMusicPlaying[client] = (StringToInt(enabled) == 1);
    }
    
    if (strlen(volume) == 0)
    {
        g_fMusicVolume[client] = MUSIC_VOLUME_DEFAULT;
    }
    else
    {
        g_fMusicVolume[client] = StringToFloat(volume);
    }
    
    if (strlen(song) > 0)
    {
        strcopy(g_sCurrentSong[client], sizeof(g_sCurrentSong[]), song);
    }
    
    bool hasBoss = false;
    char currentBossName[MAX_BOSS_NAME_SIZE];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && VSH2Player(i).bIsBoss)
        {
            hasBoss = true;
            VSH2Player(i).GetName(currentBossName);
            break;
        }
    }
    
    if (g_bMusicPlaying[client] && g_bRoundActive && hasBoss && strlen(song) > 0)
    {
        int musicIndex = GetMusicIndexByFile(client, song);
        bool songValid = false;
        
        if (musicIndex != -1)
        {
            if (StrEqual(currentBossName, g_BossMusicConfigs[musicIndex].bossName, false))
            {
                songValid = true;
            }
        }
        
        if (songValid)
        {
            StartBossMusic(client, musicIndex);
            MC_PrintToChat(client, "{olive}[VSH2 Music] {default}Now playing: {orange}%s", g_BossMusicConfigs[musicIndex].songName);
            //PrintToServer("[VSH2 Music] Music resumed for %N: %s", client, g_sCurrentSong[client]);
        }
        else
        {
            int newBossIndex = GetRandomBossMusicIndex();
            if (newBossIndex != -1)
            {
                StartBossMusic(client, newBossIndex);
                MC_PrintToChat(client, "{olive}[VSH2 Music] {default}Now playing: {orange}%s", g_BossMusicConfigs[musicIndex].songName);
                //PrintToServer("[VSH2 Music] Music resumed with new track for %N: %s", client, g_sCurrentSong[client]);
                SetClientCookie(client, g_hCookieSong, g_sCurrentSong[client]);
            }
            else
            {
                g_bMusicPlaying[client] = false;
                SetClientCookie(client, g_hCookieEnabled, "0");
            }
        }
    }
}

void LoadBossMusicConfig()
{
    char configPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, configPath, sizeof(configPath), "configs/vsh2music.cfg");
    
    if (!FileExists(configPath))
    {
        PrintToServer("[VSH2 Music] Config file not found: %s", configPath);
        LogError("[VSH2 Music] Config file not found: %s", configPath);
        return;
    }
    
    KeyValues kv = new KeyValues("VSH2Music");
    if (!kv.ImportFromFile(configPath))
    {
        PrintToServer("[VSH2 Music] Failed to parse config file: %s", configPath);
        LogError("[VSH2 Music] Failed to parse config file: %s", configPath);
        delete kv;
        return;
    }
    
    g_BossMusicConfigCount = 0; // Tömb ürítése
    
    if (!kv.GotoFirstSubKey())
    {
        PrintToServer("[VSH2 Music] No boss sections found in config file");
        LogError("[VSH2 Music] No boss sections found in config file");
        delete kv;
        return;
    }
    
    do
    {
        char bossName[MAX_BOSS_NAME_SIZE];
        kv.GetSectionName(bossName, sizeof(bossName));
        
        if (!kv.GotoFirstSubKey())
            continue;
        
        do
        {
            char musicFile[PLATFORM_MAX_PATH];
            char songName[MAX_SONG_NAME_SIZE];
            float duration;
            
            kv.GetString("file", musicFile, sizeof(musicFile), "");
            duration = kv.GetFloat("duration", 0.0);
            kv.GetString("name", songName, sizeof(songName), "Unknown Song");
            
            if (strlen(songName) == 0 || StrEqual(songName, "----------", false))
            {
                strcopy(songName, sizeof(songName), "Unknown Song");
            }
            
            if (strlen(musicFile) == 0 || duration <= 0.0)
            {
                PrintToServer("[VSH2 Music] Invalid music entry for boss %s (file: %s, duration: %.1f)", bossName, musicFile, duration);
                LogError("[VSH2 Music] Invalid music entry for boss %s (file: %s, duration: %.1f)", bossName, musicFile, duration);
                continue;
            }
            
            AddBossMusicConfig(bossName, musicFile, duration, songName);
            PrintToServer("[VSH2 Music] Loaded music for %s: %s (%.1f sec, %s)", bossName, musicFile, duration, songName);
            
        } while (kv.GotoNextKey());
        
        kv.GoBack();
        
    } while (kv.GotoNextKey());
    
    delete kv;
    PrintToServer("[VSH2 Music] Loaded %d music configs from %s", g_BossMusicConfigCount, configPath);
}

void AddBossMusicConfig(const char[] bossName, const char[] musicFile, float duration, const char[] songName)
{
    if (g_BossMusicConfigCount >= MAX_BOSS_CONFIGS) {
        PrintToServer("[VSH2 Music] Max boss configs reached!");
        return;
    }
    
    strcopy(g_BossMusicConfigs[g_BossMusicConfigCount].bossName, sizeof(g_BossMusicConfigs[].bossName), bossName);
    strcopy(g_BossMusicConfigs[g_BossMusicConfigCount].musicFile, sizeof(g_BossMusicConfigs[].musicFile), musicFile);
    g_BossMusicConfigs[g_BossMusicConfigCount].duration = duration;
    strcopy(g_BossMusicConfigs[g_BossMusicConfigCount].songName, sizeof(g_BossMusicConfigs[].songName), songName);
    g_BossMusicConfigCount++;
}

public Action OnArenaRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_bRoundActive = true;
    bool hasBoss = false;
    char currentBossName[MAX_BOSS_NAME_SIZE];
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && VSH2Player(i).bIsBoss)
        {
            hasBoss = true;
            VSH2Player(i).GetName(currentBossName);
            break;
        }
    }
    
    if (!hasBoss)
    {
        PrintToServer("[VSH2 Music] Round started, but no boss found - music disabled");
        return Plugin_Continue;
    }
    
    //PrintToServer("[VSH2 Music] Round started with boss, music can now be played");
    
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsValidClient(client) && g_bMusicPlaying[client] && AreClientCookiesCached(client))
        {
            int musicIndex = GetMusicIndexByFile(client, g_sCurrentSong[client]);
            bool songValid = false;
            
            if (musicIndex != -1)
            {
                if (StrEqual(currentBossName, g_BossMusicConfigs[musicIndex].bossName, false))
                {
                    songValid = true;
                }
            }
            
            if (songValid)
            {
                StartBossMusic(client, musicIndex);
                MC_PrintToChat(client, "{olive}[VSH2 Music] {default}Now playing: {orange}%s", g_BossMusicConfigs[musicIndex].songName);
                //PrintToServer("[VSH2 Music] Music resumed for %N: %s", client, g_sCurrentSong[client]);
            }
            else
            {
                int newBossIndex = GetRandomBossMusicIndex();
                if (newBossIndex != -1)
                {
                    StartBossMusic(client, newBossIndex);
                    MC_PrintToChat(client, "{olive}[VSH2 Music] {default}Now playing: {orange}%s", g_BossMusicConfigs[newBossIndex].songName);
                    //PrintToServer("[VSH2 Music] Music resumed with new track for %N: %s", client, g_sCurrentSong[client]);
                    SetClientCookie(client, g_hCookieSong, g_sCurrentSong[client]);
                }
                else
                {
                    g_bMusicPlaying[client] = false;
                    SetClientCookie(client, g_hCookieEnabled, "0");
                }
            }
        }
    }
    return Plugin_Continue;
}

int SwitchToPreviousSong(int client)
{
    if (!IsValidClient(client) || !g_bMusicPlaying[client] || !g_bRoundActive)
        return -1;

    // Keresd meg az aktuális bosszt
    char currentBossName[MAX_BOSS_NAME_SIZE];
    int bossClient = -1;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && VSH2Player(i).bIsBoss)
        {
            bossClient = i;
            VSH2Player(i).GetName(currentBossName);
            break;
        }
    }
    
    if (bossClient == -1)
    {
        //PrintToServer("[VSH2 Music] No boss found for previous song switch");
        return -1;
    }

    // Gyűjtsd össze az aktuális bossz zenéinek indexeit
    int musicIndices[MAX_BOSS_CONFIGS];
    int musicCount = 0;
    for (int j = 0; j < g_BossMusicConfigCount; j++)
    {
        if (StrEqual(currentBossName, g_BossMusicConfigs[j].bossName, false))
        {
            musicIndices[musicCount++] = j;
        }
    }
    
    if (musicCount == 0)
    {
        PrintToServer("[VSH2 Music] No music found for boss %s", currentBossName);
        return -1;
    }

    // Keresd meg az aktuális zene indexét
    int currentIndex = GetMusicIndexByFile(client, g_sCurrentSong[client]);
    if (currentIndex == -1)
    {
        //PrintToServer("[VSH2 Music] Current song not found for %N", client);
        return -1;
    }

    // Határozd meg az előző zene indexét
    int currentPos = -1;
    for (int i = 0; i < musicCount; i++)
    {
        if (musicIndices[i] == currentIndex)
        {
            currentPos = i;
            break;
        }
    }
    
    if (currentPos == -1)
    {
        //PrintToServer("[VSH2 Music] Current song index not found in boss music list for %N", client);
        return -1;
    }

    // Előző zene: ciklikus navigáció
    int previousPos = (currentPos - 1 + musicCount) % musicCount;
    int newIndex = musicIndices[previousPos];
    
    // Válts az előző zenére
    StopMusic(client);
    StartBossMusic(client, newIndex);
    SetClientCookie(client, g_hCookieEnabled, "1");
    SetClientCookie(client, g_hCookieSong, g_sCurrentSong[client]);
    
    return newIndex;
}

int SwitchToNextSong(int client)
{
    if (!IsValidClient(client) || !g_bMusicPlaying[client] || !g_bRoundActive)
        return -1;

    // Keresd meg az aktuális bosszt
    char currentBossName[MAX_BOSS_NAME_SIZE];
    int bossClient = -1;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && VSH2Player(i).bIsBoss)
        {
            bossClient = i;
            VSH2Player(i).GetName(currentBossName);
            break;
        }
    }
    
    if (bossClient == -1)
    {
        //PrintToServer("[VSH2 Music] No boss found for next song switch");
        return -1;
    }

    // Gyűjtsd össze az aktuális bossz zenéinek indexeit
    int musicIndices[MAX_BOSS_CONFIGS];
    int musicCount = 0;
    for (int j = 0; j < g_BossMusicConfigCount; j++)
    {
        if (StrEqual(currentBossName, g_BossMusicConfigs[j].bossName, false))
        {
            musicIndices[musicCount++] = j;
        }
    }
    
    if (musicCount == 0)
    {
        PrintToServer("[VSH2 Music] No music found for boss %s", currentBossName);
        return -1;
    }

    int currentIndex = GetMusicIndexByFile(client, g_sCurrentSong[client]);
    if (currentIndex == -1)
    {
        //PrintToServer("[VSH2 Music] Current song not found for %N", client);
        return -1;
    }
    
    int currentPos = -1;
    for (int i = 0; i < musicCount; i++)
    {
        if (musicIndices[i] == currentIndex)
        {
            currentPos = i;
            break;
        }
    }
    
    if (currentPos == -1)
    {
        //PrintToServer("[VSH2 Music] Current song index not found in boss music list for %N", client);
        return -1;
    }

    int nextPos = (currentPos + 1) % musicCount;
    int newIndex = musicIndices[nextPos];

    StopMusic(client);
    StartBossMusic(client, newIndex);
    SetClientCookie(client, g_hCookieEnabled, "1");
    SetClientCookie(client, g_hCookieSong, g_sCurrentSong[client]);
    
    return newIndex;
}

public Action Command_VSH2Music(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (args < 1)
    {
        MC_ReplyToCommand(client, "{olive}[VSH2 Music] {default}Usage: /vsh2music <on/off/menu/volume/next/previous> [random/value]");
        return Plugin_Handled;
    }

    char arg1[16];
    GetCmdArg(1, arg1, sizeof(arg1));

    if (StrEqual(arg1, "on", false))
    {
        if (!g_bRoundActive)
        {
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {default}Music can only be started when the round is active!");
            return Plugin_Handled;
        }
        
        bool isRandom = false;
        if (args >= 2)
        {
            char arg2[8];
            GetCmdArg(2, arg2, sizeof(arg2));
            if (StrEqual(arg2, "random", false))
            {
                isRandom = true;
            }
        }
        
        int bossIndex = GetRandomBossMusicIndex();
        if (bossIndex == -1)
        {
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {red}No active boss or music found!");
            return Plugin_Handled;
        }
        
        if (g_bMusicPlaying[client] && isRandom)
        {
            StopMusic(client);
            StartBossMusic(client, bossIndex);
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {default}Your music changed (random): {orange}%s", g_BossMusicConfigs[bossIndex].songName);
            //PrintToServer("[VSH2 Music] Music changed by %N (random): %s", client, g_sCurrentSong[client]);
            
            SetClientCookie(client, g_hCookieEnabled, "1");
            SetClientCookie(client, g_hCookieSong, g_sCurrentSong[client]);
        }
        else if (!g_bMusicPlaying[client])
        {
            StartBossMusic(client, bossIndex);
            g_bMusicPlaying[client] = true;
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {default}Your music started%s: {orange}%s", isRandom ? " (random)" : "", g_BossMusicConfigs[bossIndex].songName);
            //PrintToServer("[VSH2 Music] Music started by %N%s: %s", client, isRandom ? " (random)" : "", g_sCurrentSong[client]);
            
            SetClientCookie(client, g_hCookieEnabled, "1");
            SetClientCookie(client, g_hCookieSong, g_sCurrentSong[client]);
        }
        else
        {
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {default}Your music is already playing! Use '{orange}off{default}' or '{orange}on random{default}' to change.");
        }
    }
    else if (StrEqual(arg1, "off", false))
    {
        if (!g_bMusicPlaying[client])
        {
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {red}Your music is not playing!");
            return Plugin_Handled;
        }
        
        StopMusic(client);
        g_bMusicPlaying[client] = false;
        MC_ReplyToCommand(client, "{olive}[VSH2 Music] {red}Your music stopped!");
        //PrintToServer("[VSH2 Music] Music stopped by %N", client);
        
        SetClientCookie(client, g_hCookieEnabled, "0");
    }
    else if (StrEqual(arg1, "menu", false))
    {
        ShowMusicMenu(client);
    }
    else if (StrEqual(arg1, "volume", false))
    {
        if (args < 2)
        {
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {default}Usage: /vsh2music volume <0.0-1.0>");
            return Plugin_Handled;
        }
        
        char arg2[8];
        GetCmdArg(2, arg2, sizeof(arg2));
        float volume = StringToFloat(arg2);
        
        if (volume < 0.0 || volume > 1.0)
        {
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {default}Volume must be between 0.0 and 1.0!");
            return Plugin_Handled;
        }
        
        g_fMusicVolume[client] = volume;
        MC_ReplyToCommand(client, "{olive}[VSH2 Music] {default}Your music volume set to {lightblue}%.1f {default}(will apply on next track)", volume);
        //PrintToServer("[VSH2 Music] %N set volume to %.1f (will apply on next track)", client, volume);
        
        char volumeStr[8];
        Format(volumeStr, sizeof(volumeStr), "%.1f", volume);
        SetClientCookie(client, g_hCookieVolume, volumeStr);
    }
    else if (StrEqual(arg1, "next", false))
    {
        if (!g_bRoundActive)
        {
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {default}Music navigation is only available when the round is active!");
            return Plugin_Handled;
        }
        
        if (!g_bMusicPlaying[client])
        {
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {red}Your music is not playing! Use '{orange}on{default}' to start.");
            return Plugin_Handled;
        }
        
        int newIndex = SwitchToNextSong(client);
        if (newIndex != -1)
        {
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {default}Switched to next song: {orange}%s", g_BossMusicConfigs[newIndex].songName);
            //PrintToServer("[VSH2 Music] %N switched to next song: %s", client, g_sCurrentSong[client]);
        }
        else
        {
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {red}No more songs available for this boss!");
        }
    }
    else if (StrEqual(arg1, "previous", false))
    {
        if (!g_bRoundActive)
        {
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {default}Music navigation is only available when the round is active!");
            return Plugin_Handled;
        }
        
        if (!g_bMusicPlaying[client])
        {
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {red}Your music is not playing! Use '{orange}on{default}' to start.");
            return Plugin_Handled;
        }
        
        int newIndex = SwitchToPreviousSong(client);
        if (newIndex != -1)
        {
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {default}Switched to previous song: {orange}%s", g_BossMusicConfigs[newIndex].songName);
            PrintToServer("[VSH2 Music] %N switched to previous song: %s", client, g_sCurrentSong[client]);
        }
        else
        {
            MC_ReplyToCommand(client, "{olive}[VSH2 Music] {red}No more songs available for this boss!");
        }
    }
    else
    {
        MC_ReplyToCommand(client, "{olive}[VSH2 Music] {red}Invalid argument. Use 'on/off/menu/volume/next/previous' [random/value]");
    }

    return Plugin_Handled;
}

public Action Timer_CheckMusicEnd(Handle timer)
{
    if (!g_bRoundActive)
        return Plugin_Continue;

    float currentTime = GetGameTime();
    for (int client = 1; client <= MaxClients; client++)
    {
        if (g_bMusicPlaying[client] && IsValidClient(client))
        {
            float elapsed = currentTime - g_fMusicStartTime[client];
            int musicIndex = GetMusicIndexByFile(client, g_sCurrentSong[client]);
            if (musicIndex != -1 && elapsed >= g_BossMusicConfigs[musicIndex].duration)
            {
                StopMusic(client);
                int newBossIndex = GetRandomBossMusicIndex();
                if (newBossIndex != -1)
                {
                    StartBossMusic(client, newBossIndex);
                    MC_PrintToChat(client, "{olive}[VSH2 Music] {default}Your music ended, next track started: {orange}%s", g_BossMusicConfigs[newBossIndex].songName);
                    //PrintToServer("[VSH2 Music] Music ended for %N, next track started: %s", client, g_sCurrentSong[client]);
                    
                    SetClientCookie(client, g_hCookieEnabled, "1");
                    SetClientCookie(client, g_hCookieSong, g_sCurrentSong[client]);
                }
                else
                {
                    g_bMusicPlaying[client] = false;
                    MC_PrintToChat(client, "{olive}[VSH2 Music] {default}Your music ended, no more tracks available!");
                    //PrintToServer("[VSH2 Music] Music ended for %N, no more tracks", client);
                    
                    SetClientCookie(client, g_hCookieEnabled, "0");
                }
            }
        }
    }
    return Plugin_Continue;
}

int GetMusicIndexByFile(int client, const char[] musicFile)
{
    for (int i = 0; i < g_BossMusicConfigCount; i++)
    {
        if (StrEqual(g_BossMusicConfigs[i].musicFile, musicFile, false))
        {
            return i;
        }
    }
    return -1;
}

void ShowMusicMenu(int client)
{
    Menu menu = new Menu(MenuHandler_VSH2Music);
    menu.SetTitle("VSH2 Music Control");
    
    if (!g_bRoundActive)
    {
        menu.AddItem("", "Music unavailable until round starts", ITEMDRAW_DISABLED);
    }
    else if (!g_bMusicPlaying[client])
    {
        menu.AddItem("on", "Turn Music On");
        menu.AddItem("random", "Turn Music On (Random)");
    }
    else
    {
        menu.AddItem("off", "Turn Music Off");
        menu.AddItem("random", "Change to Random Music");
        menu.AddItem("previous", "Previous Song");
        menu.AddItem("next", "Next Song");
    }
    
    char volumeInfo[32];
    Format(volumeInfo, sizeof(volumeInfo), "Volume (Current: %.1f)", g_fMusicVolume[client]);
    menu.AddItem("volume", volumeInfo);
    
    menu.AddItem("songs", "View Songs");
    
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_VSH2Music(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        
        if (StrEqual(info, "on"))
        {
            int bossIndex = GetRandomBossMusicIndex();
            if (bossIndex == -1)
            {
                MC_PrintToChat(client, "{olive}[VSH2 Music] {red}No active boss or music found!");
                return 0;
            }
            
            StartBossMusic(client, bossIndex);
            g_bMusicPlaying[client] = true;
            MC_PrintToChat(client, "{olive}[VSH2 Music] {default}Now playing: {orange}%s", g_BossMusicConfigs[bossIndex].songName);
            //PrintToServer("[VSH2 Music] Music started by %N: %s", client, g_sCurrentSong[client]);
            
            SetClientCookie(client, g_hCookieEnabled, "1");
            SetClientCookie(client, g_hCookieSong, g_sCurrentSong[client]);
            ShowMusicMenu(client);
        }
        else if (StrEqual(info, "random"))
        {
            int bossIndex = GetRandomBossMusicIndex();
            if (bossIndex == -1)
            {
                MC_PrintToChat(client, "{olive}[VSH2 Music] {red}No active boss or music found!");
                return 0;
            }
            
            if (g_bMusicPlaying[client])
            {
                StopMusic(client);
            }
            StartBossMusic(client, bossIndex);
            g_bMusicPlaying[client] = true;
            MC_PrintToChat(client, "{olive}[VSH2 Music] {default}Your music changed (random): {orange}%s", g_BossMusicConfigs[bossIndex].songName);
            //PrintToServer("[VSH2 Music] Music changed by %N (random): %s", client, g_sCurrentSong[client]);
            
            SetClientCookie(client, g_hCookieEnabled, "1");
            SetClientCookie(client, g_hCookieSong, g_sCurrentSong[client]);
            ShowMusicMenu(client);
        }
        else if (StrEqual(info, "off"))
        {
            StopMusic(client);
            g_bMusicPlaying[client] = false;
            MC_PrintToChat(client, "{olive}[VSH2 Music] {red}Your music stopped!");
            //PrintToServer("[VSH2 Music] Music stopped by %N", client);
            
            SetClientCookie(client, g_hCookieEnabled, "0");
            ShowMusicMenu(client);
        }
        else if (StrEqual(info, "volume"))
        {
            ShowVolumeMenu(client);
        }
        else if (StrEqual(info, "songs"))
        {
            ShowSongsMenu(client);
        }
        else if (StrEqual(info, "previous"))
        {
            int newIndex = SwitchToPreviousSong(client);
            if (newIndex != -1)
            {
                MC_PrintToChat(client, "{olive}[VSH2 Music] {default}Switched to previous song: {orange}%s", g_BossMusicConfigs[newIndex].songName);
                //PrintToServer("[VSH2 Music] %N switched to previous song: %s", client, g_sCurrentSong[client]);
            }
            else
            {
                MC_PrintToChat(client, "{olive}[VSH2 Music] {red}No more songs available for this boss!");
            }
            ShowMusicMenu(client);
        }
        else if (StrEqual(info, "next"))
        {
            int newIndex = SwitchToNextSong(client);
            if (newIndex != -1)
            {
                MC_PrintToChat(client, "{olive}[VSH2 Music] {default}Switched to next song: {orange}%s", g_BossMusicConfigs[newIndex].songName);
                //PrintToServer("[VSH2 Music] %N switched to next song: %s", client, g_sCurrentSong[client]);
            }
            else
            {
                MC_PrintToChat(client, "{olive}[VSH2 Music] {red}No more songs available for this boss!");
            }
            ShowMusicMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    
    return 0;
}

void ShowVolumeMenu(int client)
{
    Menu menu = new Menu(MenuHandler_VSH2MusicVolume);
    menu.SetTitle("Set Music Volume");
    
    menu.AddItem("0.0", "Silent (0.0)");
    menu.AddItem("0.5", "Normal (0.5)");
    menu.AddItem("1.0", "Loud (1.0)");
    
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_VSH2MusicVolume(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        
        float volume = StringToFloat(info);
        g_fMusicVolume[client] = volume;
        MC_PrintToChat(client, "{olive}[VSH2 Music] {default}Your music volume set to {lightblue}%.1f {default}(will apply on next track)", volume);
        //PrintToServer("[VSH2 Music] %N set volume to %.1f (will apply on next track)", client, volume);
        
        char volumeStr[8];
        Format(volumeStr, sizeof(volumeStr), "%.1f", volume);
        SetClientCookie(client, g_hCookieVolume, volumeStr);
        
        ShowMusicMenu(client);
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        ShowMusicMenu(client);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    
    return 0;
}

void ShowSongsMenu(int client)
{
    Menu menu = new Menu(MenuHandler_VSH2MusicSongs);
    menu.SetTitle("Select a Song");
    
    if (!g_bRoundActive)
    {
        menu.AddItem("", "Music unavailable until round starts", ITEMDRAW_DISABLED);
    }
    else
    {
        int bossClient = -1;
        char currentBossName[MAX_BOSS_NAME_SIZE];
        
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && VSH2Player(i).bIsBoss)
            {
                bossClient = i;
                VSH2Player(i).GetName(currentBossName);
                break;
            }
        }
        
        if (bossClient == -1)
        {
            menu.AddItem("", "No active boss found", ITEMDRAW_DISABLED);
        }
        else
        {
            bool foundSong = false;
            for (int j = 0; j < g_BossMusicConfigCount; j++)
            {
                if (StrEqual(currentBossName, g_BossMusicConfigs[j].bossName, false))
                {
                    char indexStr[8];
                    IntToString(j, indexStr, sizeof(indexStr));
                    char displayName[128];
                    
                    int minutes = RoundToFloor(g_BossMusicConfigs[j].duration / 60.0);
                    int seconds = RoundToFloor(g_BossMusicConfigs[j].duration) % 60;
                    
                    if (g_bMusicPlaying[client] && StrEqual(g_sCurrentSong[client], g_BossMusicConfigs[j].musicFile, false))
                    {
                        Format(displayName, sizeof(displayName), "%s (%d:%02d) (Activated music)", 
                               g_BossMusicConfigs[j].songName, minutes, seconds);
                    }
                    else
                    {
                        Format(displayName, sizeof(displayName), "%s (%d:%02d)", 
                               g_BossMusicConfigs[j].songName, minutes, seconds);
                    }
                    
                    menu.AddItem(indexStr, displayName);
                    foundSong = true;
                }
            }
            
            if (!foundSong)
            {
                menu.AddItem("", "No music found for this boss", ITEMDRAW_DISABLED);
            }
        }
    }
    
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_VSH2MusicSongs(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        
        int musicIndex = StringToInt(info);
        if (musicIndex >= 0 && musicIndex < g_BossMusicConfigCount)
        {
            if (g_bMusicPlaying[client])
            {
                StopMusic(client);
            }
            StartBossMusic(client, musicIndex);
            g_bMusicPlaying[client] = true;
            
            int minutes = RoundToFloor(g_BossMusicConfigs[musicIndex].duration / 60.0);
            int seconds = RoundToFloor(g_BossMusicConfigs[musicIndex].duration) % 60;
            MC_PrintToChat(client, "{olive}[VSH2 Music] {default}Your music started: {orange}%s {default}({lightblue}%d{default}:{lightblue}%02d{default})", 
                        g_BossMusicConfigs[musicIndex].songName, minutes, seconds);
            //PrintToServer("[VSH2 Music] Music started by %N: %s", client, g_sCurrentSong[client]);
            
            SetClientCookie(client, g_hCookieEnabled, "1");
            SetClientCookie(client, g_hCookieSong, g_sCurrentSong[client]);
        }
        
        ShowSongsMenu(client);
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        ShowMusicMenu(client);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    
    return 0;
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    g_bRoundActive = false;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_bMusicPlaying[i])
        {
            StopMusic(i);
            //PrintToServer("[VSH2 Music] Music stopped for %N at round end", i);
        }
    }
    //PrintToServer("[VSH2 Music] Round ended, music disabled");
    return Plugin_Continue;
}

int GetRandomBossMusicIndex()
{
    int bossClient = -1;
    char currentBossName[MAX_BOSS_NAME_SIZE];
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && VSH2Player(i).bIsBoss)
        {
            bossClient = i;
            VSH2Player(i).GetName(currentBossName);
            PrintToServer("[VSH2 Music] Found boss: %s", currentBossName);
            break;
        }
    }
    
    if (bossClient == -1)
    {
        PrintToServer("[VSH2 Music] No boss found");
        return -1;
    }

    int musicIndices[MAX_BOSS_CONFIGS];
    int musicCount = 0;
    
    for (int j = 0; j < g_BossMusicConfigCount; j++)
    {
        if (StrEqual(currentBossName, g_BossMusicConfigs[j].bossName, false))
        {
            musicIndices[musicCount] = j;
            musicCount++;
        }
    }
    
    if (musicCount == 0)
    {
        PrintToServer("[VSH2 Music] No music found for boss %s", currentBossName);
        return -1;
    }
    
    int randomIndex = GetRandomInt(0, musicCount - 1);
    return musicIndices[randomIndex];
}

void StartBossMusic(int client, int musicIndex)
{
    strcopy(g_sCurrentSong[client], sizeof(g_sCurrentSong[]), g_BossMusicConfigs[musicIndex].musicFile);
    float duration = g_BossMusicConfigs[musicIndex].duration;
    g_fMusicStartTime[client] = GetGameTime();
    
    EmitSoundToClient(client, g_sCurrentSong[client], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, g_fMusicVolume[client]);
    //PrintToServer("[VSH2 Music] Playing %s to %N with volume %.1f (duration %.1f sec)", 
                  //g_sCurrentSong[client], client, g_fMusicVolume[client], duration);
}

void StopMusic(int client)
{
    StopSound(client, SNDCHAN_AUTO, g_sCurrentSong[client]);
    //PrintToServer("[VSH2 Music] Stopped %s for %N", g_sCurrentSong[client], client);
}

public void OnClientDisconnect(int client)
{
    if (g_bMusicEnabled[client] && IsClientInGame(client))
    {
        if (g_iCurrentSong[client] >= 0 && g_iCurrentSong[client] < g_BossMusicConfigCount)
        {
            StopSound(client, SNDCHAN_AUTO, g_BossMusicConfigs[g_iCurrentSong[client]].musicFile);
        }
    }
    
    if (g_hMusicTimer != null)
    {
        KillTimer(g_hMusicTimer);
        g_hMusicTimer = null;
    }
    
    g_bMusicEnabled[client] = false;
    g_iCurrentSong[client] = -1;
}

stock bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}