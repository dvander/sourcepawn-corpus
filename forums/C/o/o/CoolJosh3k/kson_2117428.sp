#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo =
{
	name = "Preview Killstreaker Effect",
	author = "Pelipoika, CoolJosh3k",
	description = "Use command sm_kson and sm_ksoff to show killstreak effects",
	version = "1.1",
};

new bool:kstoggle[MAXPLAYERS + 1];

public OnPluginStart()
{
	RegConsoleCmd( "sm_kson", Cmd_Enable);
	RegConsoleCmd( "sm_ksoff", Cmd_Disable);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action:Cmd_Enable( client, args )
{
	if (IsValidClient(client))
	{
		SetEntProp( client, Prop_Send, "m_iKillStreak", 100 );
		kstoggle[client] = true;
		return Plugin_Handled;
	}
}

public Action:Cmd_Disable( client, args )
{
	if (IsValidClient(client))
	{
		SetEntProp( client, Prop_Send, "m_iKillStreak", 0);
		kstoggle[client] = false;
		return Plugin_Handled;
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client))
	{
		if (kstoggle[client])
		{
			SetEntProp( client, Prop_Send, "m_iKillStreak", 100);
		}
		else
		{
			SetEntProp( client, Prop_Send, "m_iKillStreak", 0);
		}
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

public OnClientDisconnect(client)
{
	kstoggle[client] = false;
}