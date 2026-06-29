#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <morecolors>

#define PLUGIN_VERSION 		"2.0"		   						// Our console friendly prefix.
#define PLUGIN_PREFIX 		"{strange}[Setup Build]{default}" 	// Our chat friendly prefix.

new initialMetalPerHitVal; 		// Some servers (like mine) modify this value. Instead of resetting to 25, let's reset to whatever the server WAS running at.

new bool:setupBuildEnabled = false;
new Handle:CVAR_pluginVersion;

new Handle:CVAR_fastBuild;
new Handle:CVAR_cheapObjects;
new Handle:CVAR_metalPerHit;

public Plugin:myinfo = 
{
	name = "Setup Build",
	author = "Aderic",
	description = "Allows MVM-like building during setup time.",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	if (GetEngineVersion() != Engine_TF2) {
		PrintToServer("Sorry! This plugin only works for TF2.");
		SetFailState("Incompatible game engine. Requires TF2.");
	}
	
	HookEvent("teamplay_round_active", 		OnSetupStart);
	HookEvent("teamplay_setup_finished", 		OnSetupEnd);
	
	CVAR_pluginVersion = CreateConVar("setupbuild_version", 	PLUGIN_VERSION, 		"Current version of the plugin. Read Only", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
	CVAR_metalPerHit = FindConVar("tf_obj_upgrade_per_hit");
	CVAR_fastBuild = FindConVar("tf_fastbuild");
	CVAR_cheapObjects = FindConVar("tf_cheapobjects");
	
	initialMetalPerHitVal = GetConVarInt(CVAR_metalPerHit); // Grab the metal per hit CVAR that the server was using.
	HookConVarChange(CVAR_pluginVersion, 	OnPluginVersionChanged);
	LoadTranslations("setupbuild.phrases");
}

// Blocks changing of the plugin version.
public OnPluginVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	// If the newly set value is different from the actual version number.
	if (StrEqual(newVal, PLUGIN_VERSION, false) == false) {
		// Set it back to the way it was supposed to be.
		SetConVarString(CVAR_pluginVersion, PLUGIN_VERSION);
	}
}

// Set everything to fast build when setup starts.
public Action:OnSetupStart(Handle:event, const String:name[], bool:dontBroadcast) {
	if (GameRules_GetProp("m_bInSetup") == _:true) {
		// If the game reports that it is in setup, and there does happen to be a setup timer running go ahead and enable Setup Build.
		if (timerRunning() == true) {
			EnableSetupBuild();
			for (new client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client) && IsFakeClient(client) == false) {
					CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "setupbuild_started", client);
				}
			}
		}
		else {
			CreateTimer(1.0, SetupWatcher, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	return Plugin_Continue;
}
// Set everything to fast build when setup starts.
public Action:OnSetupEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	if (setupBuildEnabled == true) {
		DisableSetupBuild();
		for (new client = 1; client <= MaxClients; client++) {
			if (IsClientInGame(client) && IsFakeClient(client) == false && TF2_GetPlayerClass(client) == TFClass_Engineer) {
				CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "setupbuild_ended", client);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:SetupWatcher(Handle:timer) {
	if (GameRules_GetProp("m_bInSetup") != _:true) {
		if (setupBuildEnabled == true) {
			DisableSetupBuild();
			for (new client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client) && IsFakeClient(client) == false && TF2_GetPlayerClass(client) == TFClass_Engineer) {
					CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "setupbuild_ended", client);
				}
			}
		}
		//return Plugin_Stop;
	}
	else {
		if (setupBuildEnabled == false && timerRunning() == true) {
			EnableSetupBuild();
			// Notify EVERYONE that setup build is active. (To encourage more engineers)
			for (new client = 1; client <= MaxClients; client++) {
				if (IsClientInGame(client) && IsFakeClient(client) == false) {
					CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "setupbuild_started", client);
				}
			}
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

public OnMapEnd() {
	DisableSetupBuild();
}

EnableSetupBuild() {
	setupBuildEnabled = true;
	// Enable free building.
	SetConVarBool(CVAR_cheapObjects, true);
	// Enable fast building.
	SetConVarBool(CVAR_fastBuild, true);		
	// 200 metal per hit = full level per hit.
	SetConVarInt(CVAR_metalPerHit, 200);
}

DisableSetupBuild() {
	setupBuildEnabled = false;
	// Disable free building.
	SetConVarBool(CVAR_cheapObjects, false);
	// Disable fast building.
	SetConVarBool(CVAR_fastBuild, false);
	// Reset metal per hit, to the value initially found when the plugin started up.
	SetConVarInt(CVAR_metalPerHit, initialMetalPerHitVal);
}

bool:timerRunning() {
	new roundTimer = -1;
	
	while (roundTimer > -2) {
		roundTimer = FindEntityByClassname(roundTimer, "team_round_timer");
		
		// Our safety mechanism.
		if (roundTimer == -1) {
			roundTimer = -2;
			break;
		}
		
		if (GetEntProp(roundTimer, Prop_Data, "m_bIsDisabled") == 0)
			return true;
	}	
	
	return false;
}