#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
	name = "One-Shot Defib",
	author = "Oshroth",
	description = "Survivors only get one chance with a defib before its useless.",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public OnPluginStart() {
	decl String:game[12];
	
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1) SetFailState("One-Shot Defib will only work with Left 4 Dead 2!");
	
	HookEvent("defibrillator_used_fail", Event_UsedDefib);
	HookEvent("defibrillator_interrupted", Event_UsedDefib);
	
	CreateConVar("sm_osdefib_version", PLUGIN_VERSION, "One-Shot Defib version.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
}

public Action:Event_UsedDefib(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new entity;
	decl String:EdictName[128];
	
	if(client <= 0) {
		return Plugin_Continue;
	}
	
	entity = GetPlayerWeaponSlot(client, 3);
	if(entity > -1) {
		GetEdictClassname(entity, EdictName, sizeof(EdictName));
		if(StrContains(EdictName, "defibrillator", false) != -1) {
			RemovePlayerItem(client, entity);
			PrintHintTextToAll("%N's Defib ran out of power and became useless.", client);
		}
	}
	
	return Plugin_Continue;
}
