#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

new bool:playSound = false;
new Handle:cvarTime;
new Handle:cvarSound;

public Plugin:myinfo =
{
    name = "RickRoll",
    author = "bl4nk",
    description = "Plays a sound if a point is captured within X time",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
    cvarTime = CreateConVar("sm_rickroll_time", "90", "Time from the start of the round to allow the sound", FCVAR_PLUGIN);
    cvarSound = CreateConVar("sm_rickroll_sound", "rr2a.mp3", "Sound to play", FCVAR_PLUGIN);

    HookEvent("teamplay_round_start", Event_RoundStart);
    HookEvent("teamplay_point_captured ", Event_PointCaptured);

	HookConVarChange(cvarSound, ConvarChange);
	
	AutoExecConfig(true, "plugin.rickroll"); 
}

public OnConfigsExecuted()
{
    decl String:sound[PLATFORM_MAX_PATH+1], String:path[PLATFORM_MAX_PATH+1];
    GetConVarString(cvarSound, sound, sizeof(sound));
    Format(path, sizeof(path), "sound/%s", sound);

    AddFileToDownloadsTable(path);
    PrecacheSound(sound);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    playSound = true;
    CreateTimer(GetConVarFloat(cvarTime), SoundOff, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Event_PointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (playSound)
    {
        decl String:sound[PLATFORM_MAX_PATH+1], String:path[PLATFORM_MAX_PATH+1];
        GetConVarString(cvarSound, sound, sizeof(sound));

        Format(path, sizeof(path), "sound/%s", sound);
        if (!FileExists(path))
        {
            LogError("Unable to find sound: %s", sound);
        }
        else
        {
            EmitSoundToAll(sound);
        }

        playSound = false;
    }
}

public ConvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    decl String:path[PLATFORM_MAX_PATH+1];
    Format(path, sizeof(path), "sound/%s", newValue);

    AddFileToDownloadsTable(path);
    PrecacheSound(newValue);
}

public Action:SoundOff(Handle:timer)
{
    playSound = false;
}  
