#pragma semicolon 1
#pragma newdecls required

#include <clientprefs>

static const float
	// Position of fist HUD panel:
	POS1_X	= 0.0,		// 0.0 - 1.0 left to right or -1.0  for center
	POS1_Y	= 0.0,		// 0.0 - 1.0 top to bottom or -1.0  for center
	// Position of second HUD panel:
	POS2_X	= -1.0,		// 0.0 - 1.0 left to right or -1.0  for center
	POS2_Y	= 0.075,	// 0.0 - 1.0 top to bottom or -1.0 for center
	UPDATE	= 1.0;		// Update HUDs every x seconds

enum
{
	ClrRed1,
	ClrGreen1,
	ClrBlue1,

	ClrRed2,
	ClrGreen2,
	ClrBlue2,

	ClrTotal
};

public Plugin myinfo = 
{
	name		= "HUDv2",
	author		= "xSLOW (rewritten by Grey83)",
	description	= "Server Hud",
	version		= "1.4.1"
}

Handle
	hCookies,
	hHUD1,
	hHUD2;
bool
	bShow[MAXPLAYERS+1];
int
	iSlots,
	iColor[ClrTotal];
char
	sMsg[3][32];


public void OnPluginStart()
{
	hHUD1 = CreateHudSynchronizer();
	hHUD2 = CreateHudSynchronizer();

	hCookies = RegClientCookie("HudCookie_V2", "HudCookie_V2", CookieAccess_Protected);
	SetCookieMenuItem(Cookie_HUD, 0, "Server Hud");

	ConVar cvar;
	cvar = CreateConVar("sm_hud_message1", "MESSAGE 1", "Top-Left first message", FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_Msg1);
	UpdateMsg(cvar, 0);

	cvar = CreateConVar("sm_hud_message2", "MESSAGE 2", "Top-Left second message", FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_Msg2);
	UpdateMsg(cvar, 1);

	cvar = CreateConVar("sm_hud_message3", "[ MESSAGE 3 ]", "Top-Mid third message", FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_Msg3);
	UpdateMsg(cvar, 2);

	cvar = CreateConVar("sm_hud_slots", "32", "Number of server's slots", FCVAR_NOTIFY, true, _, true, (MaxClients + 0.0));
	cvar.AddChangeHook(CVarChanged_Slots);
	iSlots = cvar.IntValue;

	cvar = CreateConVar("sm_hud1_rgb", "230,057,0", "RGB of the fist text. You can get more colors from https://www.hexcolortool.com/", FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_Color1);
	UpdateColor(cvar, ClrRed1);

	cvar = CreateConVar("sm_hud2_rgb", "230,057,0", "RGB of the second text. You can get more colors from https://www.hexcolortool.com/", FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_Color2);
	UpdateColor(cvar, ClrRed2);

	AutoExecConfig(true, "HUDv2");

	CreateTimer(UPDATE, Timer_HUD, _, TIMER_REPEAT);

	RegConsoleCmd("hud", Command_hud);
}

public void CVarChanged_Msg1(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	UpdateMsg(cvar, 0);
}

public void CVarChanged_Msg2(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	UpdateMsg(cvar, 1);
}

public void CVarChanged_Msg3(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	UpdateMsg(cvar, 2);
}

stock void UpdateMsg(ConVar cvar, int type)
{
	cvar.GetString(sMsg[type], sizeof(sMsg[]));
}

public void CVarChanged_Slots(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iSlots = cvar.IntValue;
}

public void CVarChanged_Color1(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	UpdateColor(cvar, ClrRed1);
}

public void CVarChanged_Color2(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	UpdateColor(cvar, ClrRed2);
}

stock void UpdateColor(ConVar cvar, int fist)
{
	char buffer[16], buffer2[3][4];
	cvar.GetString(buffer, sizeof(buffer));
	ExplodeString(buffer, ",", buffer2, sizeof(buffer2), sizeof(buffer2[]));
	for(int i = fist, end = fist + 3; i < end; i++) iColor[i] = StringToInt(buffer2[i]);
}

public void Cookie_HUD(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if(action == CookieMenuAction_DisplayOption)
		Format(buffer, maxlen, "Server Hud: %s", bShow[client] ? "☑" : "☐");
	else if(action == CookieMenuAction_SelectOption)
	{
		ToggleHUDSetings(client);
		ShowCookieMenu(client);
	}
}

public void OnClientPutInServer(int client)
{
	bool bSourceTV = IsClientSourceTV(client);
	bShow[client] = !IsFakeClient(client) || bSourceTV;
	if(!bShow[client] || bSourceTV)
		return;

	char buffer[4];
	GetClientCookie(client, hCookies, buffer, sizeof(buffer));
	bShow[client] = buffer[0] != '0';
}

public Action Command_hud(int client, int args) 
{
	ToggleHUDSetings(client);
}

stock void ToggleHUDSetings(int client)
{
	if((bShow[client] = !bShow[client]))
	{
		PrintToChat(client, " ★ \x04HUD is now on");
		SetClientCookie(client, hCookies, "1");
	}
	else
	{
		PrintToChat(client, " ★ \x02HUD is now off");
		SetClientCookie(client, hCookies, "0");
	}
}

public Action Timer_HUD(Handle timer)
{
	int i, clients, iTimeleft;
	for(i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) ++clients;
	if(!clients)
		return Plugin_Continue;

	static char left[16], current[16], buffer[1024];
	GetMapTimeLeft(iTimeleft);
	if(iTimeleft < 1)
		FormatEx(left, sizeof(left), "Last Round");
	else FormatTime(left, sizeof(left), "%M:%S", iTimeleft);

	FormatTime(current, sizeof(current), "%H:%M:%S", GetTime());
	FormatEx(buffer, sizeof(buffer),"%s\n%s\nPlayers: %d/%d\nTimeleft: %s\nClock: %s", sMsg[0], sMsg[1], clients, iSlots, left, current);

	SetHudTextParams(POS1_X, POS1_Y, UPDATE, iColor[ClrRed1], iColor[ClrGreen1], iColor[ClrBlue1], 255, 0, 0.0, 0.0, 0.0);
	for(i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && bShow[i]) ShowSyncHudText(i, hHUD1, buffer);

	SetHudTextParams(POS2_X, POS2_Y, UPDATE, iColor[ClrRed2], iColor[ClrGreen2], iColor[ClrBlue2], 255, 0, 0.0, 0.0, 0.0);
	for(i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && bShow[i]) ShowSyncHudText(i, hHUD2, sMsg[2]);

	return Plugin_Continue;
}