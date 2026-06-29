#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:cvarCheatCheck;
new Handle:cvarCheatAction;
new Handle:cvarCheatBanTime;

#define PLUGIN_VERSION "1.01"

public Plugin:myinfo = {
	name = "SGTLS Cheat Check",
	author = "Sense",
	description = "Plugin to check for class cheaters",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart() {

	cvarCheatCheck = CreateConVar("sm_sgtls_cc_cheatcheck", "1", "Check for cheaters 0=disable 1=enable (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarCheatAction = CreateConVar("sm_sgtls_cc_ban", "1", "Ban Cheaters 0=disabled 1=ban (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarCheatBanTime = CreateConVar("sm_sgtls_cc_bantime", "0", "Ban Time in Minutes (0=Forever) (Def 0)", FCVAR_PLUGIN, true, 0.0);

	AutoExecConfig(true, "plugin.sgtls.cheat");
	if (GetConVarInt(cvarCheatCheck) == 1) {
		HookEvent("player_spawn", event_SpawnCheatCheck);
	}

}

public event_SpawnCheatCheck(Handle:event, const String:name[], bool:dontBroadcast) {

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new userid = GetEventInt(event, "userid");
	new m_iClassId = FindSendPropOffs("CPlayerResource", "m_iClassId");
	new ClientOffset = m_iClassId + (client * 4);
	new PlayerClass = GetEntData(46, ClientOffset);
	decl String:SteamId[256];
	GetClientAuthString(client, SteamId, sizeof(SteamId));
	decl String:PlayerName[256];
	GetClientName(client, PlayerName, sizeof(PlayerName));
	
	if (PlayerClass == 8) { 
		if (GetConVarInt(cvarCheatAction) == 0) { LogMessage("[SGTLS Cheater Detected] Name: %s -- Steamid: %s -- Using Class 8 -- Action: None", PlayerName, SteamId); }
		if (GetConVarInt(cvarCheatAction) == 1) {
			LogMessage("[SGTLS Cheater Detected] Name: %s -- Steamid: %s -- Using Class 8 -- Action: Ban", PlayerName, SteamId);
			ServerCommand("sm_ban \"#%i\" %i \"Exploiting SGTLS Bug\"", userid, GetConVarInt(cvarCheatBanTime));
		}
	}
	
	if (PlayerClass == 4) { 
		if (GetConVarInt(cvarCheatAction) == 0) { LogMessage("[SGTLS Cheater Detected] Name: %s -- Steamid: %s -- Using Class 4 -- Action: None", PlayerName, SteamId); }
		if (GetConVarInt(cvarCheatAction) == 1) {
			LogMessage("[SGTLS Cheater Detected] Name: %s -- Steamid: %s -- Using Class 4 -- Action: Ban", PlayerName, SteamId);
			ServerCommand("sm_ban \"#%i\" %i \"Exploiting SGTLS Bug\"", userid, GetConVarInt(cvarCheatBanTime));
		}
	}

}