#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION	"0.2.3"

ConVar CvarEnabled, CvarMinimumPlayers, CvarDisableOverride;

int ClientCount, MinimumClientCount;

bool bIsEnabled;

public Plugin myinfo = {
	name = "Disable the Intelligence",
	author = "Afronanny, fixed by tak(chaosxk), Updated syntax by Tk /id/Teamkiller324",
	description = "Disable the Intelligence until player count reaches a certain number",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=122604"
}

public void OnPluginStart() {
	CvarEnabled			= CreateConVar("sm_intel_enabled",			"1", "Enable the plugin", _, true, 0.0, true, 1.0);
	CvarMinimumPlayers	= CreateConVar("sm_intel_minimumplayers",	"6", "Minimum amount of players before intelligence is enabled");
	CvarDisableOverride	= CreateConVar("sm_intel_disabled",			"0", "Override the system and disable no matter the playercount");
	
	HookConVarChange(CvarDisableOverride,	ConVarChanged_Override);
	HookConVarChange(CvarEnabled,			ConVarChanged_Enabled);
	HookConVarChange(CvarMinimumPlayers,	ConVarChanged_MinimumClients);
	
	HookEvent("teamplay_round_start",		newRound);
	
	for (int i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(IsClientConnected(i) && IsClientInGame(i)) ClientCount++;
		}
	}
	
	bIsEnabled = GetConVarBool(CvarEnabled);
	DoMinimumClientCheck();
	AutoExecConfig(true, "inteldisable");
}

public void OnMapStart() {
	if(bIsEnabled)
		DoMinimumClientCheck();
}

public Action newRound(Event event, char[] name, bool dontBroadcast) {
	if(bIsEnabled)
		DoMinimumClientCheck();
}

public void OnClientPutInServer(int client) {
	if(IsValidClient(client)) {
		ClientCount++;
		if(bIsEnabled)
			DoMinimumClientCheck();
	}
}

public void OnClientDisconnect(int client) {
	if(IsValidClient(client)) {
		if(ClientCount > 0)
			ClientCount--;
			
		if(bIsEnabled)
			DoMinimumClientCheck();
	}
}

public void ConVarChanged_Override(ConVar convar, const char[] oldValue, const char[] newValue) {
	if(GetConVarBool(convar)) {
		DisableAllFlags();
		bIsEnabled = false;
	}
	else {
		DoMinimumClientCheck();
		bIsEnabled = true;
	}
}

public void ConVarChanged_Enabled(ConVar convar, const char[] oldValue, const char[] newValue) {
	bIsEnabled = GetConVarBool(convar);
	if(!bIsEnabled)
		EnableAllFlags();
}

public void ConVarChanged_MinimumClients(ConVar convar, const char[] oldValue, const char[] newValue) {
	MinimumClientCount = StringToInt(newValue);
	if(bIsEnabled)
		DoMinimumClientCheck();
}

public void EnableAllFlags() {
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "item_teamflag")) != -1)
	{
		if(IsValidEntity(ent))
			AcceptEntityInput(ent, "Enable");
	}
}

public void DisableAllFlags() {
	int ent = -1;
	while((ent = FindEntityByClassname(ent, "item_teamflag")) != -1)
	{
		if(IsValidEntity(ent))
			AcceptEntityInput(ent, "Disable");
	}
}

public void DoMinimumClientCheck() {
	int ent = -1;
	if(ClientCount < MinimumClientCount) {
		while((ent = FindEntityByClassname(ent, "item_teamflag")) != -1) {
			if(IsValidEntity(ent))
				AcceptEntityInput(ent, "Disable");
		}
	} 
	else {
		while((ent = FindEntityByClassname(ent, "item_teamflag")) != -1) {
			if(IsValidEntity(ent)) {
				AcceptEntityInput(ent, "Enable");
			}
		}
	}
}

stock bool IsValidClient(int client, bool Replay = true) {
	if(client <= 0 || client > MaxClients)
		return false;
	if(!IsClientInGame(client))
		return false;
	if(Replay && (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;
	return true;
}
