#pragma semicolon 1
#include <sourcemod>

new	Handle:g_hTimerInterval = INVALID_HANDLE;
new Float:g_fTimerInterval;

public Plugin:myinfo =
{
	name = "Block Autosave",
	author = "k0nan",
	description = "Execute a command every X min",
	version = "1.2",
	url = "http://www.caosk-esports.com"
}

public OnPluginStart()
{
	g_hTimerInterval = CreateConVar("time_interval", "130.0", "Number of seconds used for the repeat timer (0 = disabled).", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hTimerInterval, OnCVarChange);
	g_fTimerInterval = GetConVarFloat(g_hTimerInterval);
}

public OnMapStart()
{
	if(g_fTimerInterval > 0.0)
	{
		CreateTimer(g_fTimerInterval, Timer_Callback, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_Callback(Handle:Timer)
{
	new iPlayers = 0;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			iPlayers++;
		}
	}
	
	if(iPlayers)
	{
		ServerCommand("sm_bsave");
		PrintToChatAll("\x03[BM]\x04 Blocks and Teleporters have been autosaved");
	}
}

public OnCVarChange(Handle:hCVar, const String:sOldValue[], const String:sNewValue[])
{
	if(hCVar == g_hTimerInterval)
	{
		g_fTimerInterval = StringToFloat(sNewValue);
	}
}

bool:IsValidClient(client, bool:bAllowBots = false)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots))
	{
		return false;
	}
	return true;
}