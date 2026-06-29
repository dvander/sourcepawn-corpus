public OnPluginStart()
{
	AddCommandListener(Listener_jointeam, "jointeam");
}

public Action:Listener_jointeam(client, String:command[], args)
{
	if (!IsPlayerAlive(client) || GetClientTeam(client) != 3) return Plugin_Continue;
	new String:arg1[4];
	GetCmdArgString(arg1, sizeof(arg1));
	if (StrEqual(arg1, "red", false)) return Plugin_Stop;
	return Plugin_Continue;
}