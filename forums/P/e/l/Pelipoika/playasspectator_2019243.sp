#include <sourcemod>
//#include <tf2
//#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>

new g_iOldTeam[MAXPLAYERS+1] = {0, ...};
new bool:IsSpectator[MAXPLAYERS+1];

public OnPluginStart()
{
	RegAdminCmd("sm_specteam", Command_KillAsASpec, ADMFLAG_GENERIC);
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}

public Action:Command_KillAsASpec(client, args)
{
	if(args == 1)
	{
		new String:arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		new Target = FindTarget(client, arg1, false, true);
		if(Target != 0 && IsValidClient(Target))
		{
			g_iOldTeam[Target] = GetClientTeam(Target);
			IsSpectator[Target] = true;
			SetEntProp(Target, Prop_Send, "m_iTeamNum", 0);
		}
	}
	return Plugin_Handled;
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsSpectator[client] && IsValidClient(client))
	{
		IsSpectator[client] = false;
		SetEntProp(client, Prop_Send, "m_iTeamNum", g_iOldTeam[client]);
	}
}

public OnClientDisconnect(client)
{
	if(IsSpectator[client])
	{
		IsSpectator[client] = false;
		SetEntProp(client, Prop_Send, "m_iTeamNum", g_iOldTeam[client]);
	}
}

stock bool:IsValidClient(client) 
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}