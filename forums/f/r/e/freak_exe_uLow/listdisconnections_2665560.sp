#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
    name = "Disconnections list",
    author = "Ilusion9",
    description = "Informations about the last disconnected players.",
    version = "2.0",
    url = "https://github.com/Ilusion9/"
};

enum struct PlayerInfo
{
	char steam[64];
	char name[64];
	int time;
}

ArrayList g_List_Players;
ConVar g_Cvar_ListSize;

public void OnPluginStart()
{
	g_List_Players = new ArrayList(sizeof(PlayerInfo));
	g_Cvar_ListSize = CreateConVar("sm_listdc_size", "10", _, 0, true, 1.0);

	HookEvent("player_disconnect", Event_PlayerDisconnect);
	RegConsoleCmd("sm_listdc", Command_ListDisconnections);
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) 
{	
	PlayerInfo info;
	event.GetString("networkid", info.steam, sizeof(PlayerInfo::steam));
	
	if (StrEqual(info.steam, "BOT", false)) {
		return;
	}
	
	event.GetString("name", info.name, sizeof(PlayerInfo::name));
	info.time = GetTime();
	
	if (g_List_Players.Length)
	{
		g_List_Players.ShiftUp(0);
		g_List_Players.SetArray(0, info);
		
		if (g_List_Players.Length > g_Cvar_ListSize.IntValue) {
			g_List_Players.Resize(g_Cvar_ListSize.IntValue);
		}
	}
	else {
		g_List_Players.PushArray(info);
	}
}

public Action Command_ListDisconnections(int client, int args)
{
	char time[64];
	PlayerInfo info;

	PrintToConsole(client, "Disconnections list");
	PrintToConsole(client, "-------------------------");
	
	for (int i = 0; i < g_List_Players.Length; i++)
	{
		g_List_Players.GetArray(i, info);
		
		FormatTimeDuration(time, sizeof(time), GetTime() - info.time);
		PrintToConsole(client, "%02d. %s \"%s\" - %s ago", i + 1, info.steam, info.name, time);
	}
	
	return Plugin_Handled;
}

int FormatTimeDuration(char[] buffer, int maxlen, int time)
{
	int days = time / 86400;
	int hours = (time / 3600) % 24;
	int minutes = (time / 60) % 60;

	if (days) {
		return Format(buffer, maxlen, "%dd %dh %dm", days, hours, minutes);		
	}

	if (hours) {
		return Format(buffer, maxlen, "%dh %dm", hours, minutes);		
	}
	
	if (minutes) {
		return Format(buffer, maxlen, "%dm", minutes);		
	}
	
	return Format(buffer, maxlen, "%ds", time % 60);		
}
