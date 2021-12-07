#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Brrdy"
#define PLUGIN_VERSION "1.0.3"

ConVar cPrefix;
ConVar g_cPluginEnabled;

bool g_bPluginEnabled;

char g_szTag[64];

#include <sourcemod>

public Plugin myinfo = {
	name = "[ANY] FakeVAC",
	author = PLUGIN_AUTHOR,
	description = "Fake VAC Ban",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=259350"
};

public void OnPluginStart(){
	RegConsoleCmd("sm_fv", Cmd_FV);
	
	cPrefix = CreateConVar("sm_fakevac_prefix", "[VAC]", "Chat prefix for plugin usage.");
	g_cPluginEnabled = CreateConVar("sm_fakevac_enabled", "1", "Enable or Disable plugin features", 0, true, 0.0, true, 1.0);
	CreateConVar("sm_fakevac_version", PLUGIN_VERSION);
	
	AutoExecConfig(true, "sm_fakevac", "Brrdy");
	
	g_cPluginEnabled.AddChangeHook(OnConVarChanged);
	
	LoadTranslations("common.phrases");
}

public void OnConfigsExecuted(){
	cPrefix.GetString(g_szTag, sizeof(g_szTag));
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue){
	g_bPluginEnabled = g_cPluginEnabled.BoolValue;
}

public Action Cmd_FV(int client, int args){
	if (!g_bPluginEnabled){
		return Plugin_Stop;
	}
	
	if (IsValidClient(client)){
		char szArg[32];
		GetCmdArg(1, szArg, sizeof(szArg));
		
		if (args < 1){
			PrintToChat(client, " \x10%s\x01 Usage: sm_fv \x04<client>\x01.", g_szTag);
			return Plugin_Handled;
		}
		
		int iTarget = FindTarget(client, szArg, true, true);
		if (iTarget != 1){
			PrintToChatAll(" \x07%N has been permanently banned from official CS:GO servers.", iTarget);
			KickClient(iTarget, "Your account is currently untrusted.");
		}
		
	} else {
		PrintToChat(client, " \x10%s\x01 You do not have access to this command.", g_szTag);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

stock bool IsValidClient(int client){
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC));
}