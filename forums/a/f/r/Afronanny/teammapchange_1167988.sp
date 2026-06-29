#include <sourcemod>
new Handle:g_hArray;

new Handle:g_hCvarEnabled;
new bool:g_bIsEnabled = true;

public Plugin:myinfo = 
{
	name = "Teams Stay through mapchange",
	author = "Afronanny",
	description = "Name says it all",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?t=125681"
}

public OnPluginStart()
{
	g_hArray = CreateArray(2);
	g_hCvarEnabled = CreateConVar("sm_sameteams_enabled", "1", "Do teams stay through mapchange?", FCVAR_PLUGIN|FCVAR_SPONLY);
	
	HookConVarChange(g_hCvarEnabled, ConVarChanged_Enabled);
}

public OnPluginEnd()
{
	CloseHandle(g_hCvarEnabled);
}

public OnMapEnd()
{
	if (g_bIsEnabled)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				new team = GetClientTeam(i);
				new userid = GetClientUserId(i);
				new cell[2];
				cell[0] = userid;
				cell[1] = team;
				PushArrayArray(g_hArray, cell);
			}
		}
	}
}

public OnMapStart()
{
	if (g_bIsEnabled)
	{	
		CreateTimer(2.0, Timer_RevertTeams, _,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_RevertTeams(Handle:timer)
{
	new size = GetArraySize(g_hCvarEnabled);
	
	new team;
	new userid;
	new client;
	
	for (new i = 0; i < size; i++)
	{
		userid = GetArrayCell(g_hArray, i, 0);
		team = GetArrayCell(g_hArray, i, 1);
		client = GetClientOfUserId(userid);
		if (client != 0)
		{
			ChangeClientTeam(client, team);
		}
	}
	ClearArray(g_hArray);
	return Plugin_Handled;
}

public ConVarChanged_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bIsEnabled = GetConVarBool(convar);
}

