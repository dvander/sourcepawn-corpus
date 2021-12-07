#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

static const String:INFECTED_FALL_SOUND[]	= "player/jumplanding_zombie.wav";
static const		TEAM_INFECTED			= 3;

public OnPluginStart()
{
	AddNormalSoundHook(NormalSHook:SoundHook);
}

public Action:SoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity)
{
	if (StrEqual(sample, INFECTED_FALL_SOUND))
	{
		numClients = 0;
	
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i)
			&& !IsFakeClient(i)
			&& GetClientTeam(i) == TEAM_INFECTED)
			{
				clients[numClients] = i;
				numClients++;
			}
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}