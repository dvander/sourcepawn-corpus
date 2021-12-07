#include <sourcemod>
#include <sdktools>

#define PENETRATION_SOUND "machina_doublekill_custom.mp3"
#define PENETRATION_SOUND_FILE "sound/machina_doublekill_custom.mp3"
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "[TF2] Machina Sound Overrider",
	author = "Dr. McKay",
	description = "Plays a custom sound for Machina double kills",
	version = PLUGIN_VERSION,
	url = "www.doctormckay.com"
}

public OnPluginStart()
{
    HookEvent("teamplay_broadcast_audio", Event_Audio, EventHookMode_Pre);
}

public OnMapStart()
{
    PrecacheSound(PENETRATION_SOUND);
    AddFileToDownloadsTable(PENETRATION_SOUND_FILE);
}

public Action:Event_Audio(Handle:event, const String:name[], bool:dontBroadcast)
{
    new String:strAudio[40];
    GetEventString(event, "sound", strAudio, sizeof(strAudio));

    if(strcmp(strAudio, "Game.PenetrationKill") == 0)
    {
        EmitSoundToAll(PENETRATION_SOUND);
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}