float g_fSeconds;
bool g_bRoundEnd;

public Plugin myinfo = 
{
	name = "Round Duration",
	author = "Platinum",
	description = "Print Current Round Duration",
	version = "1.0",
	url = "https://forums.alliedmods.net/"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);

	RegConsoleCmd("sm_duration", Duration, "Print Round Duration To Chat");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_fSeconds = GetEngineTime();
	g_bRoundEnd = false;
	return Plugin_Handled;
}

public Action Duration(int client, int args)
{
	int secDiff = RoundToFloor(GetEngineTime() - g_fSeconds);
	ReplyToCommand(client, "\x04Round Duration: \x03%i min %i sec", secDiff / 60, secDiff % 60);
	return Plugin_Handled;
}

//Printing Round Duration At The End Of The Round
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bRoundEnd) {
		int secDiff = RoundToFloor(GetEngineTime() - g_fSeconds);
		PrintToChatAll("\x04Round Duration: \x03%i min %i sec", secDiff / 60, secDiff % 60);
		g_bRoundEnd = true;
	}
	return Plugin_Handled;
}