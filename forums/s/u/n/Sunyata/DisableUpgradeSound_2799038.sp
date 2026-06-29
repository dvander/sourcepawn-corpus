#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.3"

public Plugin myinfo = 
{
	name = "Remove l4d1 upgrade sound effect",
	author = "Silvers + edit by Sunyata",
	description = "Remove l4d1 upgrade sound effect on map start",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showpost.php?p=2798977&postcount=65"
};

public void OnPluginStart()
{
    AddNormalSoundHook(SoundHook);
    AddAmbientSoundHook(AmbientHook);
}

public void OnPluginEnd()
{
    RemoveNormalSoundHook(SoundHook);
    RemoveAmbientSoundHook(AmbientHook);
}

Action SoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
    if( strcmp(sample, "player/orch_hit_Csharp_short.wav") == 0 )
    {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

Action AmbientHook(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
    if( strcmp(sample, "player/orch_hit_Csharp_short.wav") == 0 )
    {
        return Plugin_Handled;
    }

    return Plugin_Continue;
} 
