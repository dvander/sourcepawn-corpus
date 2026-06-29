#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION  "1.0"

public Plugin:myinfo = {
	name = "No Pain Sounds",
	author = "MasterOfTheXP",
	description = "That's gotta hurt? Nah, bro.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

public OnPluginStart() AddNormalSoundHook(SoundHook);

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (StrContains(sound, "pain", false) != -1) return Plugin_Stop;
	return Plugin_Continue;
}