#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public OnPluginStart()
{
	AddNormalSoundHook(Hook_NormalSound);
}

public Action:Hook_NormalSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	new client = (entity > MaxClients ? GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") : entity);
	if ((client > 0 && client <= MaxClients) && IsClientInGame(client))
	{
		new newClients[64], newNumClients = 0;
		for (new i = 0; i < numClients; i++)
		{
			if (IsClientInGame(clients[i]) && (GetClientTeam(client) != GetClientTeam(clients[i])))
			{
				newClients[newNumClients] = clients[i];
				newNumClients++;
			}
		}
		if (newNumClients == 0)
		{
			return Plugin_Stop;
		}
		else if (numClients == newNumClients)
		{
			return Plugin_Continue;
		}
		numClients = newNumClients;
		for (new x = 0; x < numClients; x++)
		{
			clients[x] = newClients[x];
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
   SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
   SDKHook(client, SDKHook_TraceAttack, Hook_TraceAttack);
}

public Action:Hook_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (attacker > 1 || !IsClientInGame(attacker))
	{
		return Plugin_Continue;
	}
	if (GetClientTeam(victim) != GetClientTeam(attacker))
	{
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public Action:Hook_SetTransmit(client, entity)
{
	if (client == entity || GetClientTeam(client) != GetClientTeam(entity))
		return Plugin_Continue;
	return Plugin_Handled;
}