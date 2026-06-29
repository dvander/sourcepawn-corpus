#pragma semicolon 1

#include <sourcemod>
#include <sdktools>


public Plugin:myinfo = {

	name = "Sniper Punishment",
	author = "Madcat",
	description = "Restricts the number of times a player can fire a sniper weapon.",
	version = "0.2",
	url = "http://www.sourcemod.net/"

};

new Handle:sm_punish_awp_shots = INVALID_HANDLE;
new Handle:sm_punish_auto_shots = INVALID_HANDLE;
new Handle:sm_punish_scout_shots = INVALID_HANDLE;
new shots = 0;


public OnPluginStart() {

	sm_punish_awp_shots = CreateConVar("sm_punish_awp_shots", "3", "Sets how many AWP hits are allowed (0 - unlimited)");
	sm_punish_auto_shots = CreateConVar("sm_punish_auto_shots", "20", "Sets how many autosniper hits are allowed (0 - unlimited)");
	sm_punish_scout_shots = CreateConVar("sm_punish_scout_shots", "0", "Sets how many scout hits are allowed (0 - unlimited)");
	AutoExecConfig(true, "sniper_punish");

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);

}


/*****************************************
 * Reset the shot counter at round start *
 *****************************************/
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {

	shots = 0;

}


/**********************************************************************************
 * Someone got hurt, check who attacked and what weapon he used, punish if sniper *
 **********************************************************************************/
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {

	new cvar_awp = GetConVarInt(sm_punish_awp_shots);
	new cvar_auto = GetConVarInt(sm_punish_auto_shots);
	new cvar_scout = GetConVarInt(sm_punish_scout_shots);

	new shooter = GetEventInt(event, "attacker");
	new client = GetClientOfUserId(shooter);
	decl String:weapon[32];
	GetClientWeapon(client, weapon, sizeof(weapon));

	if (StrEqual(weapon, "weapon_awp") && cvar_awp > 0) {

		shots++;
		if (shots > cvar_awp) {
			new weaponindex = GetPlayerWeaponSlot(client, 0);
			RemovePlayerItem(client, weaponindex);
			RemoveEdict(weaponindex);
			PrintToChat(client, "Sorry, you used up all your shots. Removing weapon.");
		} else {
			PrintToChat(client, "You have %d hits with AWP left.", cvar_awp - shots);
		}

	} else if (StrEqual(weapon, "weapon_g3sg1") && cvar_auto > 0) {

		shots++;
		if (shots > cvar_auto) {
			new weaponindex = GetPlayerWeaponSlot(client, 0);
			RemovePlayerItem(client, weaponindex);
			RemoveEdict(weaponindex);
			PrintToChat(client, "Sorry, you used up all your shots. Removing weapon.");
		} else {
			PrintToChat(client, "You have %d hits with G3SG1 left.", cvar_auto - shots);
		}

	} else if (StrEqual(weapon, "weapon_sg550") && cvar_auto > 0) {

		shots++;
		if (shots > cvar_auto) {
			new weaponindex = GetPlayerWeaponSlot(client, 0);
			RemovePlayerItem(client, weaponindex);
			RemoveEdict(weaponindex);
			PrintToChat(client, "Sorry, you used up all your shots. Removing weapon.");
		} else {
			PrintToChat(client, "You have %d hits with SG550 left.", cvar_auto - shots);
		}

	} else if (StrEqual(weapon, "weapon_scout") && cvar_scout > 0) {

		shots++;
		if (shots > cvar_scout) {
			new weaponindex = GetPlayerWeaponSlot(client, 0);
			RemovePlayerItem(client, weaponindex);
			RemoveEdict(weaponindex);
			PrintToChat(client, "Sorry, you used up all your shots. Removing weapon.");
		} else {
			PrintToChat(client, "You have %d hits with SCOUT left.", cvar_scout - shots);
		}

	}

}


/******************************************
 * useful function, but not used any more *
 ******************************************
SetClientHealth(client, amount) {
	new HealthOffs = FindDataMapOffs(client, "m_iHealth");
	SetEntData(client, HealthOffs, amount, true);
}

*/
