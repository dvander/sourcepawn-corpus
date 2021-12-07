#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "KilleR_gamea / xoxo^^"
#define PLUGIN_VERSION "2.2"

Handle g_hNoSpreadTimer = INVALID_HANDLE;

ConVar cPrefix;
ConVar g_cPluginEnabled;

bool g_bPluginEnabled;

ConVar g_cTimeToNoSpread;
float g_fTimeToNoSpread;

char g_szTag[64];

#include <sourcemod>

public Plugin myinfo = {
	name = "[CS:GO/CS:S?] NoSpread Timer",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "https://suicidee.cf/"
};

public void OnPluginStart(){
	EngineVersion g_evGame = GetEngineVersion();
	if (g_evGame != Engine_CSGO){
		SetFailState("This plugin is for CSGO only.");
	}
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	cPrefix = CreateConVar("sm_nospread_prefix", "[NoSpread]", "Prefix for NoSpread Timer.");
	g_cTimeToNoSpread = CreateConVar("sm_nospread_ttns", "60.0", "Time for enabling nospread. (Default: 60.0)");
	g_cPluginEnabled = CreateConVar("sm_nospread_enabled", "1", "Enable or Disable all features of the plugin.", 0, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "sm_nospread", "SuicidE");
	
	g_cTimeToNoSpread.AddChangeHook(OnConVarChanged);
	g_cPluginEnabled.AddChangeHook(OnConVarChanged);
}

public void OnConfigsExecuted(){
	cPrefix.GetString(g_szTag, sizeof(g_szTag));
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue){
	g_fTimeToNoSpread = g_cTimeToNoSpread.FloatValue;
	g_bPluginEnabled = g_cPluginEnabled.BoolValue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
	if (!g_bPluginEnabled){
		return;
	}
	
	PrintToChatAll(" \x05%s\x01 In \x04%d\x01 seconds the \x04NoSpread\x01 will be \x04enabled\x01.", g_szTag, RoundToFloor(g_fTimeToNoSpread));
	g_hNoSpreadTimer = CreateTimer(g_fTimeToNoSpread, Timer_NoSpread);
}

public Action Timer_NoSpread(Handle timer){
	ServerCommand("weapon_accuracy_nospread 1");
	PrintToChatAll(" \x05%s\x01 NoSpread \x04Enabled\x01.", g_szTag);
	
	for (int i = 1; i <= MaxClients; i++){
		if (IsClientInGame(i)){
			SetHudTextParams(-1.0, 0.1, 7.0, 0, 255, 150, 255, 2, 6.0, 0.1, 0.2);
			ShowHudText(i, 5, "NoSpread Enabled!");
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
	if (!g_bPluginEnabled){
		return;
	}
	
	ServerCommand("weapon_accuracy_nospread 0");
	PrintToChatAll(" \x05%s\x01 NoSpread \x0FDisabled\x01.", g_szTag);
	
	for (int i = 1; i <= MaxClients; i++){
		if (IsClientInGame(i)){
			SetHudTextParams(-1.0, 0.1, 7.0, 0, 255, 150, 255, 2, 6.0, 0.1, 0.2);
			ShowHudText(i, 5, "NoSpread Disabled");
		}
	}
	
	if (g_hNoSpreadTimer != null){
		KillTimer(g_hNoSpreadTimer);
		g_hNoSpreadTimer = null;
	}
}