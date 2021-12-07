#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.1"

new g_iLastClass[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Wearables/Unusuals Stacking Glitch Fix",
	author = "EHG" ,
	description = "Can't stack this",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("tf2_wearables_stack_fix_version", PLUGIN_VERSION, "Wearables/Unusuals Stacking Glitch Fix version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	
	HookEvent("player_spawn", player_spawn);
	
	for (new i = 0; i <= MaxClients; i++) OnClientPostAdminCheck(i);
}


public OnClientPostAdminCheck(client)
{
	g_iLastClass[client] = -1;
}

public player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || IsFakeClient(client)) return;
	new playerclass = _:TF2_GetPlayerClass(client);
	
	if (g_iLastClass[client] != playerclass)
	{
		RemoveAllWearables(client);
		TF2_RegeneratePlayer(client);
	}
	g_iLastClass[client] = playerclass;
}

stock RemoveAllWearables(client)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(edict, "Kill");
			}
		}
	}
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

stock bool:IsValidClient(client)
{
	if (client < 1 || client > MaxClients)
		return false;
	return IsClientInGame(client);
}
