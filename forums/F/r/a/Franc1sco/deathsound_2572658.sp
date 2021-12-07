#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <emitsoundany>

#pragma newdecls required

public Plugin myinfo =
{
	name = "Simple Death Sound",
	author = "Franc1sco franug",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug/"
}

public void OnPluginStart()
{
	AddNormalSoundHook(OnNormalSoundPlayed); // hook sounds
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/zr/zombie_die1.mp3");
	
	PrecacheSoundAny("zr/zombie_die1.mp3"); // Example sound
	
}

public Action OnNormalSoundPlayed(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if(entity && entity <= MaxClients)
	{
		if(StrContains(sample, "death") != -1 && GetClientTeam(entity) == CS_TEAM_T)
		{
			// Block current death sound and emit a new one
			EmitSoundToAllAny("zr/zombie_die1.mp3");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}