#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[L4D] ESpawn Preventor",
	author = "Patrick Evans, MasterMind420",
	description = "Plugin to instantly kill an infected that trys to espawn",
	version = "1.0.0.1",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
    HookEvent("player_spawn", ePlayerSpawned);
}

public void ePlayerSpawned(Event event, const char[] name, bool dontBroadcast)
{
	char output[128];
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(client) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 3)
	{
		//if (GetEntProp(client, Prop_Data, "m_afButtonPressed") & IN_USE)
		//{
		int iTarget = -1;
		iTarget = GetClosestTarget(client, "player", 50);

		if (IsValidClient(iTarget) && IsClientInGame(iTarget) && GetClientTeam(iTarget) == 2)
		{
			ForcePlayerSuicide(client);
			Format(output, sizeof(output), "[SM] %N tried to espawn and was killed for it.", client);
			PrintToChatAll(output);
		}
		//}
	}
}

int GetClosestTarget(int client, const char[] ClsName, int num = 50)
{
	if (!IsValidClient(client))
		return -1;

	int i = -1;
	int ClosestTarget = -1;

	while ((i = FindEntityByClassname(i, ClsName)) != -1)
	{
		if (StrEqual(ClsName, "player"))
		{
			if (!IsValidClient(i) || GetClientTeam(i) != 2)
				continue;
		}

		float cPos[3], tPos[3];
		float TargetDistance = 0.0;

		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", cPos);
		GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", tPos);

		float distance = GetVectorDistance(cPos, tPos);

		if (distance > num)
			continue;

		if (TargetDistance)
		{
			if (distance < TargetDistance)
			{
				ClosestTarget = i;
				TargetDistance = distance;
			}
		}
		else
		{
			ClosestTarget = i;
			TargetDistance = distance;
		}
	}

	return ClosestTarget;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients);
}