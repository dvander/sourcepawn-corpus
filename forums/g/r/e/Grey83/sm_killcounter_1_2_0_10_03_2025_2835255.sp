#pragma semicolon 1
#pragma newdecls required

#include <clientprefs>

static const char
	PL_NAME[]	= "[L4D] Kill Counter",
	PL_VER[]	= "1.2.0_10.03.2025 (rewritten by Grey83)",

	PREFIX[]	= "\x04Kill Counter: \x03",
	BR[]		= "-==-==-==-==-";

Handle
	g_hTimer,
	g_hCookie;
bool
	bLate,
	g_bDisplay[MAXPLAYERS+1] = {true, ...};
int
	iMode,
	g_iData[MAXPLAYERS+1][3];
float
	fInterval;

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Counts up your kills and headshots",
	author		= "NakashimaKun",
	url			= "https://steamcommunity.com/groups/grey83ds"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_killcounter_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("sm_killcounter", "1", "Determines plugin functionality. (0 = Off, 1 = All Kills, 2 = Headshots Only)", _, true, _, true, 2.0);
	cvar.AddChangeHook(CVarChange_Mode);
	iMode = cvar.IntValue;

	cvar = CreateConVar("sm_killcounter_ad_interval", "30.0", "Amount of seconds between advertisements.", _, true, 30.0);
	cvar.AddChangeHook(CVarChange_Interval);
	fInterval = cvar.FloatValue;

	cvar = CreateConVar("sm_killcounter_ff", "1", "Friendly Fire warning. 0: Off 1: On", _,true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Warning);
	CVarChange_Warning(cvar, NULL_STRING, NULL_STRING);

	AutoExecConfig(true, "Kill_Counter");

	HookEvent("player_death", Event_Death, EventHookMode_Pre);

	RegConsoleCmd("sm_counter", Cmd_Toggle);
	RegConsoleCmd("sm_kills", Cmd_Kills);
	RegConsoleCmd("sm_teamkills", Cmd_TeamKills);

	g_hCookie = RegClientCookie("Kill_Counter_Status", "Display Kill Counter", CookieAccess_Protected);
	SetCookieMenuItem(Menu_Status, 0, "Display Kill Counter");

	if(!bLate) return;

	for(int i; ++i <= MaxClients;) if(IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i)) GetClientOption(i);
}

public void CVarChange_Mode(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iMode = cvar.IntValue;
}

public void CVarChange_Interval(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CloseHandle(g_hTimer);
	OnMapStart();
}

public void CVarChange_Warning(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	static bool hooked;
	if(hooked == cvar.BoolValue)
		return;

	if(!(hooked ^= true))
		UnhookEvent("player_hurt", Event_Hurt);
	else HookEvent("player_hurt", Event_Hurt);
}

public void Event_Hurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(!attacker || IsFakeClient(attacker))
		return;

	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(!victim || victim == attacker || GetClientTeam(attacker) != GetClientTeam(victim))
		return;

	if(g_iData[attacker][2] != victim) PrintHintText(attacker, "You hit %N.", victim);
	g_iData[attacker][2] = victim;
}

public void OnMapStart()
{
	g_hTimer = CreateTimer(fInterval, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientCookiesCached(int client)
{
	if(!IsFakeClient(client)) GetClientOption(client);
}

void GetClientOption(int client)
{
	char buffer[4];
	GetClientCookie(client, g_hCookie, buffer, sizeof(buffer));
	g_bDisplay[client] = !buffer[0] || buffer[0] != '0';
}

public void OnClientDisconnect(int client)
{
	g_bDisplay[client] = true;
	g_iData[client][0] = g_iData[client][1] = g_iData[client][2] = 0;
}

public Action Timer_DisplayAds(Handle timer)
{
	PrintToChatAll("%sTo modify your settings, type \x04!counter\x03. To view your current stats, type \x04!kills\x03. And to view your team's current stats, type \x04!teamkills\x03.", PREFIX);
	return Plugin_Continue;
}

public void Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker =  GetClientOfUserId(event.GetInt("attacker"));
	if(!attacker)
		return;

	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(!victim || victim == attacker || GetClientTeam(attacker) == GetClientTeam(victim))
		return;

	bool hs = event.GetBool("headshot");
	g_iData[attacker][view_as<int>(!hs)]++;

	if(!g_bDisplay[attacker] || !iMode || (!hs && iMode == 2))
		return;

	if(hs)
	{
		if(g_iData[attacker][0] > 1)
			PrintHintText(attacker, "HEADSHOTS: %d", g_iData[attacker][0]);
		else PrintHintText(attacker, "HEADSHOT!");
	}
	else if(iMode == 1)
	{
		if(g_iData[attacker][1] > 1)
			PrintHintText(attacker, "KILLS: %d", g_iData[attacker][1]);
		else PrintHintText(attacker, "KILL!");
	}
}

public Action Cmd_Toggle(int client, int args)
{
	if(client && IsClientInGame(client) && !IsFakeClient(client)) ToggleOption(client);
	return Plugin_Handled;
}

public void Menu_Status(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			FormatEx(buffer, maxlen, "%s Kill Counter", g_bDisplay[client] ? "Disable" : "Enable");
		case CookieMenuAction_SelectOption:
		{
			ToggleOption(client);
			ShowCookieMenu(client);
		}
	}
}

void ToggleOption(int client)
{
	g_bDisplay[client] ^= true;
	SetClientCookie(client, g_hCookie, g_bDisplay[client] ? "1" : "0");
	PrintToChat(client, "%sYou've \x04%sabled\x03 kill notifications.", PREFIX, g_bDisplay[client] ? "en" : "dis");
}

public Action Cmd_Kills(int client, int args)
{
	if(!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	Panel panel = new Panel();

	char buffer[64];
	FormatEx(buffer, sizeof(buffer), "Kill Counter\n%s", BR);
	panel.SetTitle(buffer);

	FormatEx(buffer, sizeof(buffer), "Normal Kills: %d", g_iData[client][1]);
	panel.DrawText(buffer);

	FormatEx(buffer, sizeof(buffer), "With Headshot: %d", g_iData[client][0]);
	panel.DrawText(buffer);

	int g_iKills = g_iData[client][0] + g_iData[client][1], g_fPercent;
	FormatEx(buffer, sizeof(buffer), "Total: %d", g_iKills);
	panel.DrawText(buffer);

	if(g_iKills) g_fPercent = 100 * g_iData[client][0] / g_iKills;
	FormatEx(buffer, sizeof(buffer), "HS Percentage: %d %s", g_fPercent, "%");
	panel.DrawText(buffer);
	panel.DrawText(BR);

	DrawPanelItem(panel, "Close");
	DrawPanelItem(panel, "Reset Counters");
	SendPanelToClient(panel, client, Panel_Kills, 20);
	CloseHandle(panel);
	return Plugin_Handled;
}

public int Panel_Kills(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select && param == 2)
	{
		g_iData[client][0] = g_iData[client][1] = 0;
		PrintToConsole(client, "%sYour counters have been reset.", PREFIX);
	}
	return 0;
}

public Action Cmd_TeamKills(int client, int args)
{
	if(!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	int g_iTeam = GetClientTeam(client);
	if(g_iTeam >= 2)
	{
		int g_iCount, g_iArray[MAXPLAYERS], g_iTotalZombies, g_iTotalHeadshots, g_iTotalKills, g_fTotalPercent;

		for(int i; ++i <= MaxClients;) if(IsClientInGame(i) && !IsFakeClient(i) && g_iTeam == GetClientTeam(i))
		{
			g_iTotalZombies += g_iData[i][1];
			g_iTotalHeadshots += g_iData[i][0];

			g_iArray[g_iCount++] = i;
		}

		Panel panel = new Panel();

		char buffer[256];
		FormatEx(buffer, sizeof(buffer), "Team Kill Counter\n%s", BR);
		panel.SetTitle(buffer);

		FormatEx(buffer, sizeof(buffer), "Normal Kills: %d", g_iTotalZombies);
		panel.DrawText(buffer);

		FormatEx(buffer, sizeof(buffer), "With HS: %d", g_iTotalHeadshots);
		panel.DrawText(buffer);

		FormatEx(buffer, sizeof(buffer), "Total: %d", (g_iTotalKills = g_iTotalZombies + g_iTotalHeadshots));
		panel.DrawText(buffer);

		if(g_iTotalKills) g_fTotalPercent = 100 * g_iTotalHeadshots / g_iTotalKills;
		FormatEx(buffer, sizeof(buffer), "HS Percentage: %d%s", g_fTotalPercent, "%");
		panel.DrawText(buffer);

		if(g_iCount > 0)
		{
			panel.DrawText(BR);
			for(int i; i < g_iCount; i++)
			{
				FormatEx(buffer, sizeof(buffer), "%N\n%d Kills %d HS %d Total", g_iArray[i], g_iData[g_iArray[i]][1], g_iData[g_iArray[i]][0], (g_iData[g_iArray[i]][0] + g_iData[g_iArray[i]][1]));
				panel.DrawText(buffer);
			}
		}

		panel.DrawText(BR);
		panel.DrawItem("Close");

		panel.Send(client, Panel_TeamKills, 20);
		CloseHandle(panel);
	}

	return Plugin_Handled;
}

public int Panel_TeamKills(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}