#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

ConVar convar_Enabled;
ConVar convar_Hud_Coords;
ConVar convar_Hud_Color;

Handle g_Hudsync;
Cookie g_Cookie_ShowTime;
bool g_ShowTime[MAXPLAYERS + 1] = {true, ...};

public Plugin myinfo = {
	name = "[ANY] Hud Time",
	author = "Drixevel",
	description = "Shows the current time of the server in the hud.",
	version = "1.0.0",
	url = "https://drixevel.dev/"
};

public void OnPluginStart() {

	LoadTranslations("common.phrases");
	LoadTranslations("hud_time.phrases");

	CreateConVar("sm_hud_time_version", "1.0.0", "Version control for this plugin.", FCVAR_DONTRECORD);
	convar_Enabled = CreateConVar("sm_hud_time_enabled", "1", "Should this plugin be enabled or disabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_Hud_Coords = CreateConVar("sm_hud_time_coords", "0.0 0.01", "What should the X and Y coordinates be?", FCVAR_NOTIFY);
	convar_Hud_Color = CreateConVar("sm_hud_time_color", "150 150 150 255", "What should the Red, Green, Blue and Alpha color values be?", FCVAR_NOTIFY);
	AutoExecConfig();

	g_Cookie_ShowTime = new Cookie("ShowHudTime", "Should the HUD time be shown?", CookieAccess_Public);
	g_Cookie_ShowTime.SetPrefabMenu(CookieMenu_OnOff_Int, "Show Hud Time", OnCookieHandler);

	RegConsoleCmd("sm_time", Command_Time, "Toggles the current time of the server in the HUD.");

	g_Hudsync = CreateHudSynchronizer();
	CreateTimer(1.0, Timer_Seconds, _, TIMER_REPEAT);

	for (int i = 1; i <= MaxClients; i++) {
		if (AreClientCookiesCached(i)) {
			OnClientCookiesCached(i);
		}
	}
}

public void OnPluginEnd() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			ClearSyncHud(i, g_Hudsync);
		}
	}
}

public Action Timer_Seconds(Handle timer) {
	if (!convar_Enabled.BoolValue) {
		return Plugin_Continue;
	}

	float coords[2]; coords = GetConVar2DVector(convar_Hud_Coords);
	int color[4]; color = GetConVarColor(convar_Hud_Color);

	SetHudTextParams(coords[0], coords[1], 1.0, color[0], color[1], color[2], color[3]);

	char s24Hour[16];
	FormatTime(s24Hour, sizeof(s24Hour), "%H");

	char s12Hour[16];
	FormatTime(s12Hour, sizeof(s12Hour), "%I");

	char sMinute[16];
	FormatTime(sMinute, sizeof(sMinute), "%M");

	char sSecond[16];
	FormatTime(sSecond, sizeof(sSecond), "%S");

	char sFormat[64];
	FormatEx(sFormat, sizeof(sFormat), "%t", "Hud time format", s24Hour, s12Hour, sMinute, sSecond);

	char sTime[32];
	FormatTime(sTime, sizeof(sTime), sFormat);

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && g_ShowTime[i]) {
			ShowSyncHudText(i, g_Hudsync, sTime);
		}
	}

	return Plugin_Continue;
}

public void OnCookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen) {
	if (action == CookieMenuAction_SelectOption) {
		OnClientCookiesCached(client);
	}
}

public void OnClientCookiesCached(int client) {
	char sValue[8];
	g_Cookie_ShowTime.Get(client, sValue, sizeof(sValue));

	if (strlen(sValue) == 0) {
		g_ShowTime[client] = true;
		g_Cookie_ShowTime.Set(client, "1");
	} else {
		g_ShowTime[client] = view_as<bool>((StringToInt(sValue)));
	}
}

public void OnClientDisconnect_Post(int client) {
	g_ShowTime[client] = true;
}

public Action Command_Time(int client, int args) {
	if (!convar_Enabled.BoolValue) {
		return Plugin_Continue;
	}

	if (client < 1) {
		ReplyToCommand(client, "[SM] %T", "Command is in-game only", client);
		return Plugin_Handled;
	}

	g_ShowTime[client] = !g_ShowTime[client];
	g_Cookie_ShowTime.Set(client, g_ShowTime[client] ? "1" : "0");
	PrintToChat(client, "[SM] %T", "Toggle hud time", client, g_ShowTime[client] ? "on" : "off");

	return Plugin_Handled;
}

float[] GetConVar2DVector(ConVar convar) {
	float vectors[2] = {0.0, 0.0};

	char sBuffer[128];
	convar.GetString(sBuffer, sizeof(sBuffer));

	if (strlen(sBuffer) == 0) {
		return vectors;
	}

	char sPart[2][12];
	int iReturned = ExplodeString(sBuffer, StrContains(sBuffer, ", ") != -1 ? ", " : " ", sPart, 2, 12);

	for (int i = 0; i < iReturned; i++) {
		vectors[i] = StringToFloat(sPart[i]);
	}

	return vectors;
}

int[] GetConVarColor(ConVar convar) {
	int colors[4] = {255, 255, 255, 255};

	char sBuffer[128];
	convar.GetString(sBuffer, sizeof(sBuffer));

	if (strlen(sBuffer) == 0) {
		return colors;
	}

	char sPart[4][6];
	int iReturned = ExplodeString(sBuffer, StrContains(sBuffer, ", ") != -1 ? ", " : " ", sPart, 4, 6);

	for (int i = 0; i < iReturned; i++) {
		colors[i] = StringToInt(sPart[i]);
	}

	return colors;
}