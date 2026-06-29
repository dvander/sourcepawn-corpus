#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma tabsize 0
#pragma newdecls required

#define Debug

public Plugin myinfo = {
	name		 = "CSGO Panorama Map Change Crashe Fixer",
	author		 = "BOT Benson",
	description	 = "CSGO Panorama Map Change Crashe Fixer",
	version		 = "1.0.0.7.65536.8192.000001",
	url			 = "https://www.botbenson.com"
};

public void OnPluginStart() {
	HookEventEx("cs_win_panel_match", Event_cs_win_panel_match, EventHookMode_PostNoCopy);

	RegAdminCmd("sm_mapend", Command_MapEnd, ADMFLAG_CHANGEMAP);
	RegAdminCmd("sm_changenextmap", Command_ChangeNextMap, ADMFLAG_CHANGEMAP);
}

public void OnMapStart() {
	SetIntCvar("mp_match_end_changelevel", 0);
	SetIntCvar("mp_endmatch_votenextmap", 0);
	SetIntCvar("mp_endmatch_votenextleveltime", 0);
	SetIntCvar("mp_match_end_restart", 0);
}

public Action Command_ChangeNextMap(int client, int args) {
	char g_szMapName[PLATFORM_MAX_PATH];
	GetCmdArg(1, g_szMapName, sizeof(g_szMapName));

	switch (FindMap(g_szMapName, g_szMapName, sizeof(g_szMapName))) {
		case FindMap_Found:
			SetNextMap(g_szMapName);
		case FindMap_FuzzyMatch:
			SetNextMap(g_szMapName);
	}

	return Plugin_Handled;
}

public Action Command_MapEnd(int client, int args) {
	SetIntCvar("mp_timelimit", 0);
	SetIntCvar("mp_maxrounds", 0);
	SetIntCvar("mp_respawn_on_death_t", 0);
	SetIntCvar("mp_respawn_on_death_ct", 0);

	return Plugin_Handled;
}

public void Event_cs_win_panel_match(Event event, const char[] name, bool dontBroadcast) {
	CreateTimer(FindConVar("mp_match_restart_delay").FloatValue - 0.2, Timer_RetryPlayers, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RetryPlayers(Handle timer) {
	#if defined Debug
	PrintToServer("L [MapCrashFixer] Forcing \"retry\" to players.");
	#endif
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i))
			ClientCommand(i, "retry");
	}
}

bool SetIntCvar(char[] scvar, int value) {
	ConVar cvar = FindConVar(scvar);
	if (cvar == null)
		return false;

	cvar.SetInt(value);
	return true;
}