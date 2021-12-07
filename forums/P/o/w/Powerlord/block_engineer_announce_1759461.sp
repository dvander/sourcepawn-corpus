#include <sourcemod>
#include <sdktools>

new String:samples[][] = { "engineer_autobuildingsentry",
						   "engineer_autobuildingteleporter",
						   "engineer_autobuildingdispenser",
						   "engineer_sentrymoving",
						   "engineer_sentrypacking",
						   "engineer_sentryplanting"
						 };

public Plugin:myinfo = 
{
	name = "Block Engineer Announcements",
	author = "Powerlord",
	description = "Shh, I'm buildin' a sentry.",
	version = "1.1",
	url = "https://forums.alliedmods.net/showthread.php?t=191220"
}

public OnPluginStart()
{
	AddNormalSoundHook(EngySoundHook);
}

public Action:EngySoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	new size = sizeof(samples);
	for (new i = 0; i < size; i++)
	{
		if (StrContains(sample, samples[i], false) > -1)
		{
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}
