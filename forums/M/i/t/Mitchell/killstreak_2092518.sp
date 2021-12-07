#include <sourcemod>

#define PLUGIN_VERSION 			"2.0"

public Plugin:myinfo =
{
	name = "Killstreak",
	author = "Dr_Knuckles",
	description = "Enables Killstreaks",
	version = "1.0",
	url = "http://www.the-vaticancity.com"
};

new Handle:sm_killstreak_amount = INVALID_HANDLE;
new g_iLastKillStreak[MAXPLAYERS+1] = {0,...};
new g_bKSToggle[MAXPLAYERS+1] = {false,...};

public OnPluginStart()
{
	RegAdminCmd("sm_ks", Killstreak, ADMFLAG_GENERIC);
	sm_killstreak_amount = CreateConVar("sm_killstreak_amount", "10", "Default Killstreak Amount", FCVAR_PLUGIN|FCVAR_NOTIFY);
	AutoExecConfig();
	CreateConVar("sm_ks_version", PLUGIN_VERSION, "Killstreak modifier.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookEvent("player_spawn", Event_Spawn);
}

public OnPlayerPutInServer(client)
{
	g_iLastKillStreak[client] = 0;
	g_bKSToggle[client] = false;
}

public Action:Killstreak( client, args )
{
	if(client)
	{
		new iKS = 0;
		if(!g_bKSToggle[client])
		{
			if(args < 1)
			{
				iKS = GetConVarInt(sm_killstreak_amount);
				if(g_iLastKillStreak[client] == iKS) iKS = 0; //Toggles it off.
			}
			else
			{
				decl String:sArg[4];
				GetCmdArg(1, sArg, sizeof(sArg));
				iKS = StringToInt(sArg);
			}
		}
		g_bKSToggle[client] = !g_bKSToggle[client];
		if(iKS >= 0)
		{
			if(iKS > 0) ReplyToCommand(client, "[KS] Killstreak set to: %i", iKS);
			else ReplyToCommand(client, "[KS] Killstreak disabled.");
			SetEntProp( client, Prop_Send, "m_iKillStreak",  iKS);
		}
		else ReplyToCommand(client, "[KS] Killstreak must be a positive number.");
	}
	else
	{
		ReplyToCommand(client, "[KS] You must be in-game to use this command");
	}
	return Plugin_Handled;
}

public Event_Spawn(Handle:hEvent, const String:sName[], bool:bNoBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_iLastKillStreak[client] > 0) 
		{
			SetEntProp( client, Prop_Send, "m_iKillStreak",  g_iLastKillStreak[client]);
		}
	}
}
