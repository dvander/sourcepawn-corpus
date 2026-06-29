#include <sourcemod>
#include <sdktools>
#include <tf2attributes>
#pragma semicolon 1

public OnPluginStart()
{
	AddNormalSoundHook(SoundHook);
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (IsValidEntity(ent) && ent < 1 || ent > MaxClients || channel < 1)
		return Plugin_Continue;
		
	if (IsValidClient(ent))
	{
		if (StrContains(sound, "player/footsteps/", false) != -1)
		{
			switch(GetRandomInt(0,6))
			{
				case 0:
					TF2Attrib_SetByName(ent, "SPELL: set Halloween footstep type", 14540032.0);
				case 1:
					TF2Attrib_SetByName(ent, "SPELL: set Halloween footstep type", 39168.0);
				case 2:
					TF2Attrib_SetByName(ent, "SPELL: set Halloween footstep type", 3100495.0);
				case 3:
					TF2Attrib_SetByName(ent, "SPELL: set Halloween footstep type", 16742399.0);
				case 4:
					TF2Attrib_SetByName(ent, "SPELL: set Halloween footstep type", 2490623.0);
				case 5:
					TF2Attrib_SetByName(ent, "SPELL: set Halloween footstep type", 9109759.0);
				case 6:
					TF2Attrib_SetByName(ent, "SPELL: set Halloween footstep type", 16737280.0);
			}
			return Plugin_Changed;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}