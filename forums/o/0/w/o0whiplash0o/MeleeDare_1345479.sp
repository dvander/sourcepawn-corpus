#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define CLASS_SCOUT 1 
#define CLASS_SOLDIER 2
#define CLASS_PYRO 3
#define CLASS_DEMOMAN 4
#define CLASS_HEAVY 5
#define CLASS_ENGINEER 6
#define CLASS_MEDIC 7
#define CLASS_SNIPER 8
#define CLASS_SPY 9

#define PLUGIN_VERSION "0.2"

public Plugin:myinfo = {
	name = "Melee Dare",
	author = "EnigmatiK",
	description = "Plays meleedare sounds.",
	version = PLUGIN_VERSION,
	url = "http://theme.freehostia.com/"
}

new Float:arr_lastDare[MAXPLAYERS + 1];
new arr_playerClass[MAXPLAYERS + 1];
new arr_weaponNotMelee[MAXPLAYERS + 1];

public OnPluginStart() {
	SetConVarString(CreateConVar("meleedare_version", PLUGIN_VERSION, "Version of the TF2 Melee Dare plugin.", FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_REPLICATED), PLUGIN_VERSION);
	HookEvent("player_spawn", player_spawn);
}

public player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	switch (TF2_GetPlayerClass(client)) {
		case (TFClass_Scout): arr_playerClass[client] = CLASS_SCOUT;
		case (TFClass_Soldier): arr_playerClass[client] = CLASS_SOLDIER;
		case (TFClass_Pyro): arr_playerClass[client] = CLASS_PYRO;
		case (TFClass_DemoMan): arr_playerClass[client] = CLASS_DEMOMAN;
		case (TFClass_Heavy): arr_playerClass[client] = CLASS_HEAVY;
		case (TFClass_Engineer): arr_playerClass[client] = CLASS_ENGINEER;
		case (TFClass_Medic): arr_playerClass[client] = CLASS_MEDIC;
		case (TFClass_Sniper): arr_playerClass[client] = CLASS_SNIPER;
		case (TFClass_Spy): arr_playerClass[client] = CLASS_SPY;
		default: arr_playerClass[client] = 0;
	}
}

public OnGameFrame() {
	decl String:weapon[20], String:melee[20];
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		if (!arr_playerClass[i] || GetGameTime() < arr_lastDare[i] + 5.0) continue;
		new slot = GetPlayerWeaponSlot(i, 2);
		if (slot == -1) continue;
		GetEdictClassname(slot, melee, sizeof(melee));
		GetClientWeapon(i, weapon, sizeof(weapon));
		if (StrEqual(weapon, melee)) {
			if (arr_weaponNotMelee[i]) {
				arr_weaponNotMelee[i] = false;
				new team = GetClientTeam(i);
				// vector stuff
				decl Float:pos_i[3], Float:pos_j[3];
				decl Float:vec_i[3], Float:vec_j[3];
				GetClientEyePosition(i, pos_i);
				GetClientEyeAngles(i, vec_i);
				GetAngleVectors(vec_i, vec_i, NULL_VECTOR, NULL_VECTOR);
				// * Check for enemies in FOV * //
				for (new j = 1; j <= MaxClients; j++) {
					// in game? alive? on different team?
					if (IsClientInGame(j) && IsPlayerAlive(j) && GetClientTeam(j) != team) {
						//if (!(GetEntProp(j, Prop_Send, "m_nPlayerCond") & 16) && TF2_
						if (TF2_GetPlayerClass(j) == TFClass_Spy){//if he's a spy...
							continue; // POOT SPY CHECKS HERE
						}
						// get enemy vector
						GetClientEyePosition(j, pos_j);
						MakeVectorFromPoints(pos_i, pos_j, vec_j);
						// is he close to me?
						if (GetVectorLength(vec_j, true) > 1048576.0) continue;
						// am I looking at him?
						NormalizeVector(vec_j, vec_j);
						if (GetVectorDotProduct(vec_i, vec_j) < 0.7) continue;
						// is he looking at me? (sneaky sneaky)
						//GetClientEyeAngles(j, vec_j);
						//GetAngleVectors(vec_j, vec_j, NULL_VECTOR, NULL_VECTOR);
						//if (GetVectorDotProduct(vec_i, vec_j) > -0.7) continue;
						// do it
						arr_lastDare[i] = GetGameTime();
						playMeleeDare(i);
						break;
					}
				}
			}
		} else {
			if (!arr_weaponNotMelee[i]) arr_weaponNotMelee[i] = true;
		}
	}
}

playMeleeDare(client) {
	decl String:path[32];
	switch (arr_playerClass[client]) {
		case (CLASS_SCOUT):    FormatEx(path, sizeof(path), "vo/scout_meleedare%02d.wav", GetRandomInt(1, 6));
		case (CLASS_SOLDIER):  FormatEx(path, sizeof(path), "vo/soldier_PickAxeTaunt%02d.wav", GetRandomInt(1, 5));
		case (CLASS_PYRO):     FormatEx(path, sizeof(path), "vo/pyro_autodejectedtie01.wav");
		case (CLASS_DEMOMAN): 
			switch (GetRandomInt(0, 1)) {
				case 0: FormatEx(path, sizeof(path), "vo/demoman_eyelandertaunt%02d.wav", GetRandomInt(1, 2));
				case 1: FormatEx(path, sizeof(path), "vo/demoman_autocappedintelligence02.wav");
			}
		case (CLASS_HEAVY):    FormatEx(path, sizeof(path), "vo/heavy_meleedare%02d.wav", GetRandomInt(1, 13));
		case (CLASS_ENGINEER): FormatEx(path, sizeof(path), "vo/engineer_meleedare%02d.wav", GetRandomInt(1, 3));
		case (CLASS_MEDIC):
			switch (GetRandomInt(0, 2)) {
				case 0: FormatEx(path, sizeof(path), "vo/medic_autocappedcontrolpoint03.wav");
				case 1: FormatEx(path, sizeof(path), "vo/medic_autodejectedtie02.wav");
				case 2: FormatEx(path, sizeof(path), "vo/medic_specialcompleted02.wav");
			}
		case (CLASS_SNIPER):   FormatEx(path, sizeof(path), "vo/sniper_meleedare%02d.wav", GetRandomInt(1, 9));
		case (CLASS_SPY):      FormatEx(path, sizeof(path), "vo/spy_meleedare%02d.wav", GetRandomInt(1, 2));
	}
	if (!strlen(path)) return; // hmm. (client must be invalid!)
	PrecacheSound(path);
	EmitSoundToAll(path, client, SNDCHAN_VOICE);
}
