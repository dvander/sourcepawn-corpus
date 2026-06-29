#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <soundlib>

#define PLUGIN_VERSION "1.0"
#define CONFIG_FILE "configs/ambient_sounds.cfg"

public Plugin myinfo = 
{
    name = "Ambient Sounds",
    author = "liquidplasma",
    description = "Plays ambient sounds based on map names",
    version = PLUGIN_VERSION,
    url = ""
};

KeyValues g_hSoundConfig;
Handle g_hClientTimers[MAXPLAYERS + 1];
char g_sCurrentAmbientSound[PLATFORM_MAX_PATH];
char g_sMapName[PLATFORM_MAX_PATH];
float g_fCurrentVolume = 1.0;
bool g_bCurrentLoop = true;
float g_fSoundDuration;
bool g_bMapSoundLoaded = false;
bool g_bClientAllowsDownload[MAXPLAYERS + 1];

public void OnPluginStart()
{
    CreateConVar("sm_ambient_version", PLUGIN_VERSION, "Ambient Sounds Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    
    RegAdminCmd("sm_reload_ambient", Command_ReloadConfig, ADMFLAG_GENERIC, "Reload ambient sound configuration");
    RegAdminCmd("sm_stop_ambient", Command_StopAmbient, ADMFLAG_GENERIC, "Stop current ambient sound");
    RegAdminCmd("sm_play_ambient", Command_PlayAmbient, ADMFLAG_GENERIC, "Manually play ambient sound for current map");
    RegAdminCmd("sm_play_self", Command_PlaySelf, ADMFLAG_GENERIC, "Test ambient for self");
    
    for (int i = 1; i <= MaxClients; i++)
        g_hClientTimers[i] = null;

    LoadSoundConfig();
}

public void OnMapInit(const char[] mapName)
{
    strcopy(g_sMapName, sizeof(g_sMapName), mapName);
}

public void OnMapStart()
{
    g_bMapSoundLoaded = false;
    g_sCurrentAmbientSound[0] = '\0';

    StopAllClientTimers();

    LoadAmbientSound();
}

public void OnMapEnd()
{
    StopAllClientTimers();
    g_bMapSoundLoaded = false;
}

public void OnClientPutInServer(int client)
{
    if (client <= 0 || IsFakeClient(client))
        return;

    StopClientAmbientSound(client);

    QueryClientConVar(client, "cl_downloadfilter", CheckDownloads);
}

public void OnClientPostAdminCheck(int client)
{
    if (g_bMapSoundLoaded && strlen(g_sCurrentAmbientSound) > 0)
        CreateTimer(15.0, Timer_DelayedClientSound, GetClientUserId(client));
}

void CheckDownloads(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
    //LogMessage("Client %N cl_downloadfilters is set to '%s'", client, cvarValue);
    g_bClientAllowsDownload[client] = StrEqual(cvarValue, "all");
}

public Action Timer_DelayedClientSound(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!g_bClientAllowsDownload[client])
    {
        //LogMessage("Client %N has downloads turned off, not playing sounds", client);
        return Plugin_Stop;
    }

    if (client > 0 && IsClientInGame(client))
        StartClientAmbientSound(client);

    return Plugin_Stop;
}

public void OnClientDisconnect(int client)
{
    StopClientAmbientSound(client);
}

void LoadSoundConfig()
{
    char sConfigPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sConfigPath, sizeof(sConfigPath), CONFIG_FILE);
    
    if (g_hSoundConfig != null)
        delete g_hSoundConfig;

    g_hSoundConfig = new KeyValues("AmbientSounds");
    
    if (!g_hSoundConfig.ImportFromFile(sConfigPath))
    {
        LogError("Could not load ambient sounds config file: %s", sConfigPath);
        LogError("Config file not found, creating example...");
        CreateExampleConfig(sConfigPath);
        return;
    }
    
    //LogMessage("Configuration loaded successfully");
}

void CreateExampleConfig(const char[] path)
{
    KeyValues kv = new KeyValues("AmbientSounds");
    
    kv.JumpToKey("c1m1_hotel", true);
    kv.SetString("sound", "ambient/file.mp3");
    kv.SetFloat("volume", 0.5);
    kv.SetNum("loop", 1);
    kv.GoBack();
    
    kv.JumpToKey("c2m1_highway", true);
    kv.SetString("sound", "ambient/file.mp3");
    kv.SetFloat("volume", 0.3);
    kv.SetNum("loop", 1);
    kv.GoBack();
    
    kv.ExportToFile(path);
    delete kv;
    
    LogError("Example config created at: %s", path);
}

void LoadAmbientSound()
{
    if (g_hSoundConfig == null)
    {
        SetFailState("Sound configuration not loaded");
        return;
    }

    //LogMessage("Looking for ambient sound for map: %s", g_sMapName);

    if (g_hSoundConfig.JumpToKey(g_sMapName))
    {
        char sSoundPath[PLATFORM_MAX_PATH];
        g_hSoundConfig.GetString("sound", sSoundPath, sizeof(sSoundPath));
        
        if (strlen(sSoundPath) > 0 && IsValidGetSoundLength(sSoundPath, g_fSoundDuration))
        {
            //LogMessage("Path is %s", sSoundPath);

            g_fCurrentVolume = g_hSoundConfig.GetFloat("volume", 1.0);
            g_bCurrentLoop = view_as<bool>(g_hSoundConfig.GetNum("loop"));

            strcopy(g_sCurrentAmbientSound, sizeof(g_sCurrentAmbientSound), sSoundPath);

            AddToDownloadTable(sSoundPath);
            PrecacheSound(sSoundPath, true);
            
            g_bMapSoundLoaded = true;
            
            //LogMessage("Loaded ambient sound: %s (Volume: %.2f, Loop: %s, Duration: %.1fs)", sSoundPath, g_fCurrentVolume, g_bCurrentLoop ? "Yes" : "No", g_fSoundDuration);
        }
        
        g_hSoundConfig.GoBack();
    }
    else
    {
        //LogMessage("No ambient sound configured for map: %s", g_sMapName);
        g_bMapSoundLoaded = false;
    }
}

void AddToDownloadTable(const char[] soundPath)
{
    char sDownloadPath[PLATFORM_MAX_PATH];
    Format(sDownloadPath, sizeof(sDownloadPath), "sound/%s", soundPath);
    
    AddFileToDownloadsTable(sDownloadPath);
    //LogMessage("Added to download table: %s", sDownloadPath);
}

void StartClientAmbientSound(int client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
        return;

    if (!g_bMapSoundLoaded || strlen(g_sCurrentAmbientSound) == 0)
        return;

    StopClientAmbientSound(client);
    EmitSoundToClient(client, g_sCurrentAmbientSound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, g_fCurrentVolume);

    //LogMessage("Started ambient sound %s for client %N", g_sCurrentAmbientSound, client);

    if (g_bCurrentLoop)

        g_hClientTimers[client] = CreateTimer(g_fSoundDuration, Timer_ClientAmbientLoop, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ClientAmbientLoop(Handle timer, any data)
{
    int userid = data;
    int client = GetClientOfUserId(userid);
    
    if (client == 0 || !IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Stop;
    
    if (g_hClientTimers[client] != timer)
        return Plugin_Stop;
    
    if (!g_bMapSoundLoaded || strlen(g_sCurrentAmbientSound) == 0 || !g_bCurrentLoop)
    {
        g_hClientTimers[client] = null;
        return Plugin_Stop;
    }

    //LogMessage("Started looped ambient sound %s for client %N", g_sCurrentAmbientSound, client);
    EmitSoundToClient(client, g_sCurrentAmbientSound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, g_fCurrentVolume);
    return Plugin_Continue;
}

void StopClientAmbientSound(int client)
{
    if (strlen(g_sCurrentAmbientSound) > 0 && IsClientInGame(client) && !IsFakeClient(client))
        StopSound(client, SNDCHAN_STATIC, g_sCurrentAmbientSound);
    
    if (g_hClientTimers[client] != null)
    {
        KillTimer(g_hClientTimers[client]);
        g_hClientTimers[client] = null;
    }
}

void StopAllClientTimers()
{
    for (int i = 1; i <= MaxClients; i++)
        StopClientAmbientSound(i);
}

// Admin Commands
public Action Command_ReloadConfig(int client, int args)
{
    StopAllClientTimers();

    LoadSoundConfig();
    LoadAmbientSound();

    if (g_bMapSoundLoaded)
        for (int i = 1; i <= MaxClients; i++)
            if (IsClientInGame(i) && !IsFakeClient(i))
                StartClientAmbientSound(i);

    ReplyToCommand(client, "Configuration reloaded and sounds restarted");
    return Plugin_Handled;
}

Action Command_PlaySelf(int client, int args)
{
    ReplyToCommand(client, "Started ambient sound %s for client %N", g_sCurrentAmbientSound, client);
    StartClientAmbientSound(client);
    return Plugin_Handled;
}

public Action Command_StopAmbient(int client, int args)
{
    StopAllClientTimers();
    ReplyToCommand(client, "All ambient sounds stopped");
    return Plugin_Handled;
}

public Action Command_PlayAmbient(int client, int args)
{
    LoadAmbientSound();

    if (g_bMapSoundLoaded)
    {
        for (int i = 1; i <= MaxClients; i++)
            if (IsClientInGame(i) && !IsFakeClient(i))
                StartClientAmbientSound(i);

        ReplyToCommand(client, "Ambient sounds started for all clients");
    }
    else
        ReplyToCommand(client, "No ambient sound configured for current map");

    return Plugin_Handled;
}

/**
 * Thanks @malifox for this code
 */
bool IsValidGetSoundLength(const char[] sFile, float &fLength, bool bIsGameSound = false)
{
    SoundFile soundFile = new SoundFile(sFile);

    if (!soundFile)
    {
        if (bIsGameSound)
        {
            LogError("Sound Library Extension failed to read \"%s\". Detected as a game sound. Possible reasons: \n" ...
            "(1) Server VPKs use dummy sound files, extract from client VPKs maintaining folder structure. \n" ...
            "(2) File is relative to sound folder, use \"folder/file.mp3\" instead of \"sound/folder/file.mp3\" (3) User error.", sFile);
        }
        else
            LogError("Sound Library Extension failed to read \"%s\". File may not exist, or used \"sound/folder/file.mp3\" instead of \"folder/file.mp3\"", sFile);

        return false;
    }

    switch (soundFile.SamplingRate)
    {
        case 44100, 22050, 11025: {}
        default:
        {
            LogError("Invalid sample rate (%d Hz) for file \"%s\".Valid: 11025, 22050, 44100(prefered) Hz. Use CBR", soundFile.SamplingRate, sFile);
            delete soundFile;
            return false;
        }
    }

    fLength = soundFile.LengthFloat; //fox, maybe doesn't like VBR?
    delete soundFile;

    return true;
}