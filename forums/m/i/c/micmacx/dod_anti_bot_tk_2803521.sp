#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "2.0"

public Plugin:myinfo = 
{
	name = "Dod Anti Bot Tk",
	author = "Micmacx",
	description = "Protects Player from Bot Tk",
	version = PLUGIN_VERSION,
	url = "https://dods.135db.fr"
}

public OnPluginStart()
{
	CreateConVar("dod_anti_bot_tk", PLUGIN_VERSION, "Spawn Protection Version", FCVAR_NOTIFY);
} 

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(client, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType)
{
	if (IsValidClient(client) && IsValidClient(iAttacker) && client != iAttacker && !IsFakeClient(client) && IsFakeClient(iAttacker))
	{
		new TeamClient = GetClientTeam(client);
		new TeamAttacker = GetClientTeam(iAttacker);
		if((TeamClient == 2 || TeamClient == 3) && (TeamAttacker == 2 || TeamAttacker == 3) && TeamAttacker == TeamClient)
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}



bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client)){
		return true;
	}else{
		return false;
	}
}

