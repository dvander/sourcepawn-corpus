#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>

new g_iOldTeam[MAXPLAYERS+1] = {0, ...};
new Float:spawnPos[MAXPLAYERS+1][3];
new Float:spawnAng[MAXPLAYERS+1][3];
new bool:IsSpectator[MAXPLAYERS+1];

public OnPluginStart()
{
	RegAdminCmd("sm_specteam", Command_KillAsASpec, ADMFLAG_ROOT);
	RegAdminCmd("sm_bringtolife", Command_RiseAgain, ADMFLAG_ROOT);
	HookEvent("player_death", Event_Death, EventHookMode_Post);
	HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);
}

public Action:Command_KillAsASpec(client, args)
{
	if(args == 1)
	{
		new String:arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		new Target = FindTarget(client, arg1, false, true);
		if(Target != 0 && IsValidClient(Target) && !IsSpectator[Target])
		{
			g_iOldTeam[Target] = GetClientTeam(Target);
			SetEntProp(Target, Prop_Send, "m_iTeamNum", 0);
			SetEntityRenderColor(Target, 90, 90, 90, 255); //Remove this if you dont want the users color to chaneg
			ReplyToCommand(client, "[SM] Made %N to play as a spectator!", Target);
			IsSpectator[Target] = true;
		}
		else
			ReplyToCommand(client, "[SM] Invalid target.");
	}
	else
	{
		ReplyToCommand(client, "[SM] sm_specteam <target>");
	}
	return Plugin_Handled;
}

public Action:Command_RiseAgain(client, args)
{
	if(args == 1)
	{
		new String:arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		new Target = FindTarget(client, arg1, false, true);
		if(Target != 0 && IsValidClient(Target) && IsSpectator[Target])
		{
			GetClientAbsOrigin(Target, spawnPos[Target]);
			GetClientAbsAngles(Target, spawnAng[Target]);
			SetEntProp(Target, Prop_Send, "m_iTeamNum", g_iOldTeam[Target]);
			SetEntityRenderColor(Target, 255, 255, 255, 255);
			TF2_RespawnPlayer(Target);
			ReplyToCommand(Target, "[SM] Forced %N back to his old team!", Target);
			TeleportEntity(client, spawnPos[client], spawnAng[client], NULL_VECTOR);
			IsSpectator[Target] = false;
		}
		else
			ReplyToCommand(client, "[SM] Invalid target.");
	}
	else
	{
		ReplyToCommand(client, "[SM] sm_bringtolife <target>");
	}
	return Plugin_Handled;
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsSpectator[client] && IsValidClient(client))
	{
		SetEntProp(client, Prop_Send, "m_iTeamNum", g_iOldTeam[client]);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		TF2_RespawnPlayer(client);
		IsSpectator[client] = false;
	}
}

public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	/*new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsSpectator[client] && IsValidClient(client))
	{
		SetEntProp(client, Prop_Send, "m_iTeamNum", g_iOldTeam[client]);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		TeleportEntity(client, spawnPos[client], spawnAng[client], NULL_VECTOR);
		IsSpectator[client] = false;
	}*/
}

public OnClientDisconnect(client)
{
	if(IsSpectator[client])
	{
		SetEntProp(client, Prop_Send, "m_iTeamNum", g_iOldTeam[client]);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		IsSpectator[client] = false;
	}
}

stock bool:IsValidClient(client) 
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}