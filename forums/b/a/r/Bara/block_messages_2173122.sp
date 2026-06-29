new String:g_sCMD[][] = {"coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog", "getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition", "reportingin", "getout", "negative","enemydown"};

public OnPluginStart()
{
	HookEvent("player_team", OnPlayerTeam, EventHookMode_Pre);
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_connect", OnPlayerConnect, EventHookMode_Pre);

	for(new i; i < sizeof(g_sCMD); i++)
		AddCommandListener(Command_BlockRadio, g_sCMD[i]);
}

public OnConfigsExecuted()
{
	ServerCommand("sv_ignoregrenaderadio 1");
}

public Action:Command_BlockRadio(client, const String:command[], args) 
{
	return Plugin_Handled;
}

public Action:OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	return (Plugin_Handled);
}

public Action:OnPlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	return (Plugin_Handled);
}

public Action:OnPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	return (Plugin_Handled);
}