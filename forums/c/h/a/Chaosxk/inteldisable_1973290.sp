#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"0.2.2"
new Handle:hCvarEnabled;
new Handle:hCvarMinimumPlayers;
new Handle:hCvarDisableOverride;

new iClientCount;
new iMinimumClientCount;

new bool:bIsEnabled;

public Plugin:myinfo = 
{
	name = "Disable the Intelligence",
	author = "Afronanny, fixed by tak(chaosxk)",
	description = "Disable the Intelligence until player count reaches a certain number",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=122604"
}

public OnPluginStart()
{
	
	hCvarEnabled = CreateConVar("sm_intel_enabled", "1", "Enable the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvarMinimumPlayers = CreateConVar("sm_intel_minimumplayers", "6", "Minimum amount of players before intelligence is enabled");
	hCvarDisableOverride = CreateConVar("sm_intel_disabled", "0", "Override the system and disable no matter the playercount");
	
	HookConVarChange(hCvarDisableOverride, ConVarChanged_Override);
	HookConVarChange(hCvarEnabled, ConVarChanged_Enabled);
	HookConVarChange(hCvarMinimumPlayers, ConVarChanged_MinimumClients);
	
	HookEvent("teamplay_round_start", newRound);
	
	for (new i = 0; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			if(IsClientConnected(i) && IsClientInGame(i)) {
				iClientCount++;
			}
		}
	}
	
	bIsEnabled = GetConVarBool(hCvarEnabled);
	DoMinimumClientCheck();
	AutoExecConfig(true);
}

public OnMapStart() {
	if(bIsEnabled) {
		DoMinimumClientCheck();
	}
}

public Action:newRound(Handle:event, String:name[], bool:dontBroadcast) {
	if(bIsEnabled) {
		DoMinimumClientCheck();
	}
}

public OnClientPutInServer(client) {
	if(IsValidClient(client)) {
		iClientCount++;
		if(bIsEnabled) {
			DoMinimumClientCheck();
		}
	}
}

public OnClientDisconnect(client) {
	if(IsValidClient(client)) {
		if(iClientCount > 0) {
			iClientCount--;
		}
		if(bIsEnabled) {
			DoMinimumClientCheck();
		}
	}
}

public ConVarChanged_Override(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(GetConVarBool(convar)) {
		DisableAllFlags();
		bIsEnabled = false;
	} 
	else {
		DoMinimumClientCheck();
		bIsEnabled = true;
	}
	
}

public ConVarChanged_Enabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	bIsEnabled = GetConVarBool(convar);
	if(!bIsEnabled) {
		EnableAllFlags();
	}
}

public ConVarChanged_MinimumClients(Handle:convar, const String:oldValue[], const String:newValue[]) {
	iMinimumClientCount = StringToInt(newValue);
	if(bIsEnabled) {
		DoMinimumClientCheck();
	}
}

public EnableAllFlags() {
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "item_teamflag")) != -1) {
		if(IsValidEntity(ent)) {
			AcceptEntityInput(ent, "Enable");
		}
	}
}

public DisableAllFlags() {
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "item_teamflag")) != -1) {
		if(IsValidEntity(ent)) {
			AcceptEntityInput(ent, "Disable");
		}
	}
}

public DoMinimumClientCheck() {
	if(iClientCount < iMinimumClientCount) {
		new ent = -1;
		while((ent = FindEntityByClassname(ent, "item_teamflag")) != -1) {
			if(IsValidEntity(ent)) {
				AcceptEntityInput(ent, "Disable");
			}
		}
	} 
	else {
		new ent = -1;
		while((ent = FindEntityByClassname(ent, "item_teamflag")) != -1) {
			if(IsValidEntity(ent)) {
				AcceptEntityInput(ent, "Enable");
			}
		}
	}
}

stock bool:IsValidClient(iClient, bool:bReplay = true) {
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}
