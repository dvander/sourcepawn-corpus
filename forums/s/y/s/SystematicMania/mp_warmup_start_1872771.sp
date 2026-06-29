public OnPluginStart()
{
	AddCommandListener(mp_warmup_start, "mp_warmup_start");
}

public Action:mp_warmup_start(client, const String:command[], args)
{
	static Float:iLastLogged[MAXPLAYERS+1];
	new Float:fGameTime = GetGameTime();
	
	if (client && iLastLogged[client] < fGameTime && IsClientInGame(client))
	{
		LogToFile("mp_warmup_start_logged.txt", "\"%L\" attempted to use mp_warmup_start.", client);
		iLastLogged[client] = fGameTime + 30.0;
	}
	
	return Plugin_Handled;
}