/**
 * Ambient Sounds
 * Extracted from Zombie:Reloaded by theY4Kman
 * ZR by Greyscale and rhelgeby
 */

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
    name = "Ambient Sounds", 
    author = "Greyscale/theY4Kman", 
    description = "Sounds that play everywhere.", 
    version = "1",
    url = ""
};

new bool:soundValid = false;

new Handle:g_cvAmbience = INVALID_HANDLE;
new Handle:g_cvAmbienceFile = INVALID_HANDLE;
new Handle:g_cvAmbienceVolume = INVALID_HANDLE;
new Handle:g_cvAmbienceLength = INVALID_HANDLE;

new Handle:tAmbience = INVALID_HANDLE;

public OnPluginStart()
{
    g_cvAmbience       = CreateConVar("sm_ambience", "1", "Enable creepy ambience to be played throughout the game (0: Disable)");
    g_cvAmbienceFile   = CreateConVar("sm_ambience_file", "ambient/zr/zr_ambience.mp3", "Path to ambient sound file that will be played throughout the game, when sm_ambience is 1");
    g_cvAmbienceLength = CreateConVar("sm_ambience_length", "60.0", "The length, in seconds, of the ambient sound file");
    g_cvAmbienceVolume = CreateConVar("sm_ambience_volume", "0.6", "Volume of ambient sounds when sm_ambience is 1 (0.0: Unhearable,  1.0: Max volume)");

    LoadTranslations("ambientsounds.phrases.txt");
    
    HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);
}

public OnConfigsExecuted()
{
    LoadAmbienceData();
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    RestartAmbience();
    PrintToServer("RoundStart");///////////////////////////////////////
}

LoadAmbienceData()
{
    new bool:ambience = GetConVarBool(g_cvAmbience);
    if (!ambience)
    {
        return;
    }
    
    decl String:sound[64];
    GetConVarString(g_cvAmbienceFile, sound, sizeof(sound));
    Format(sound, sizeof(sound), "sound/%s", sound);
    
    soundValid = FileExists(sound, true);
    
    if (soundValid)
    {
        AddFileToDownloadsTable(sound);
    }
    else
    {
        ZR_LogMessage("Ambient sound load failed", sound);
    }
}

RestartAmbience()
{
    if (tAmbience != INVALID_HANDLE)
    {
        CloseHandle(tAmbience);
    }
    PrintToServer("RestartAmbience");///////////////////////////////////////
    
    CreateTimer(0.0, AmbienceLoop, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:AmbienceLoop(Handle:timer)
{
    new bool:ambience = GetConVarBool(g_cvAmbience);
    
    if (!ambience || !soundValid)
    {
        return;
    }
    PrintToServer("AmbienceLoop");///////////////////////////////////////
    
    decl String:sound[64];
    GetConVarString(g_cvAmbienceFile, sound, sizeof(sound));
    
    EmitAmbience(sound);
    
    new Float:delay = GetConVarFloat(g_cvAmbienceLength);
    tAmbience = CreateTimer(delay, AmbienceLoop, _, TIMER_FLAG_NO_MAPCHANGE);
}

StopAmbience()
{
    new bool:ambience = GetConVarBool(g_cvAmbience);
    
    if (!ambience)
    {
        return;
    }
    
    tAmbience = INVALID_HANDLE;
    
    decl String:sound[64];
    GetConVarString(g_cvAmbienceFile, sound, sizeof(sound));
    
    new maxplayers = GetMaxClients();
    for (new x = 1; x <= maxplayers; x++)
    {
        if (!IsClientInGame(x))
        {
            continue;
        }
        
        StopSound(x, SNDCHAN_AUTO, sound);
    }
}

EmitAmbience(const String:sound[])
{
    PrecacheSound(sound);
    
    StopAmbience();
    
    new Float:volume = GetConVarFloat(g_cvAmbienceVolume);
    PrintToServer("EmitAmbience, volume: %f", volume);///////////////////////////////////////
    EmitSoundToAll(sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, volume, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

stock ZR_LogMessage(any:...)
{
    SetGlobalTransTarget(LANG_SERVER);
    
    decl String:phrase[192];
    
    VFormat(phrase, sizeof(phrase), "%t", 1);
    
    LogMessage(phrase);
}