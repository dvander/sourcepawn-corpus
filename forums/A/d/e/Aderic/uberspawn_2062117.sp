#include <sourcemod>
#include <tf2>

#undef REQUIRE_PLUGIN
#include <morecolors>
#define REQUIRE_PLUGIN


#define PLUGIN_PREFIX 		"{strange}[Uberspawn]{default}"
#define PLUGIN_VERSION 		"1.0"
#define PLUGIN_TAG			"uberspawn"
#define WORLD 0

new bool:IsClientNotified[MAXPLAYERS];

new Handle:pluginVersion;	 //STRING: Version of the currently running plugin. Reflects PLUGIN_VERSION as defined.
new Handle:pluginDuration;
new Handle:pluginNotify;
new Handle:pluginMode;

public Plugin:myinfo = 
{
	name = "Uberspawn",
	author = "Aderic",
	description = "Gives spawned players TF2 styled damage resistance.",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{	
	if (GetEngineVersion() != Engine_TF2) {
		SetFailState("This plugin only supports TF2.");
	}
	
	pluginMode = CreateConVar("sm_uberspawnmode", "1", "If 0, Uberspawn is disabled. If 1, normal uber is used. If 2, hidden uber is used (flickers only when shot).", FCVAR_NONE, true, 0.0, true, 2.0);
	pluginDuration = CreateConVar("sm_uberspawnduration", "7.0", "Duration in seconds for the ubercharge.", FCVAR_NONE, true, 0.0);
	pluginNotify = CreateConVar("sm_uberspawnnotify", "1", "Notifies the client who connects that the server is running Uberspawn and that they will be protected.", FCVAR_NONE, true, 0.0, true, 1.0);
	
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);

	AutoExecConfig(true, "uberspawn");
}
// Called when config is loaded or created.
public OnConfigsExecuted() {
	// Create our version CVAR after config is executed. 
	// Seems improper to write this value to the config so that's why we do it after config.
	pluginVersion =  CreateConVar("sm_uberspawn", 	PLUGIN_VERSION, 		"Current version of the plugin. Read Only", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
	// Hook the CVAR change. && GetConVarBool(expireHandle) == true
	HookConVarChange(pluginVersion, 	OnPluginVersionChanged);
}

// Blocks changing of the plugin version.
public OnPluginVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	// If the newly set value is different from the actual version number.
	if (StrEqual(newVal, PLUGIN_VERSION, false) == false) {
		// Set it back to the way it was supposed to be.
		SetConVarString(pluginVersion, PLUGIN_VERSION);
	}
}

public Action:OnPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast) {
	new clientId = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (clientId == WORLD)
		return Plugin_Continue;
	
	IsClientNotified[clientId] = false;
	return Plugin_Continue;
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new clientId = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (clientId == WORLD)
		return Plugin_Continue;
	
	if (IsClientNotified[clientId] == false && GetConVarBool(pluginNotify) == true) {
		CPrintToChat(clientId, "%s You get {orange}%.2f{default} seconds of ubercharge every time you spawn.", PLUGIN_PREFIX, GetConVarFloat(pluginDuration));
		IsClientNotified[clientId] = true;
	}

	new ConditionID = GetConVarInt(pluginMode);
	
	if (ConditionID == 0 || GetConVarFloat(pluginDuration) <= 0.0) {
		return Plugin_Continue;
	}
	
	if (ConditionID == 1)
		ConditionID = _:TFCond_Ubercharged;
	else
		ConditionID = _:TFCond_UberchargedHidden;
	
	if (IsClientInGame(clientId)) {
		TF2_AddCondition(clientId, TFCond:ConditionID, GetConVarFloat(pluginDuration));
	}
	
	return Plugin_Continue;
}

