#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

static const String:TRIGGER_STRING[]    = "weapons/";
static const String:STOP_STRING[]        = "melee";
public OnPluginStart()
{
	AddNormalSoundHook(NormalSHook:SoundHook);
}

public Action:SoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (StrContains(sample, TRIGGER_STRING) != -1
	&& StrContains(sample, STOP_STRING) == -1)
	{
		numClients = 0;
	
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i)
			&& !IsFakeClient(i))
			{
				if (i == entity)
				{
					EmitSoundToClient(i, sample, _, _, _, _, (volume * 0.5));
					continue;
				}
			
				clients[numClients] = i;
				numClients++;
			}
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}	