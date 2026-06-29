#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PL_VERSION "1.3"

public Plugin:myinfo = {
	name        = "Randomizer",
	author      = "EnigmatiK",
	description = "Sets all players to a random class and gives them random weapons.",
	version     = PL_VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?t=98127"
}

// sdkcalls
new Handle:GiveNamedItem;
new Handle:WeaponEquip;

// offsets
new m_iAmmo;

// randomization
new setclass[MAXPLAYERS + 1];
new setwep[MAXPLAYERS + 1][3];

// fixes
new ammo_count[MAXPLAYERS + 1][2];
new spy_status[MAXPLAYERS + 1];
new heal_beams[MAXPLAYERS + 1];
new healtarget[MAXPLAYERS + 1];
new infotarget[MAXPLAYERS + 1];

// cvars
new cvar_enabled;
new cvar_destroy;
new cvar_fixammo;
new cvar_fixpyro;
new cvar_fixspy;
new cvar_fixuber;

static const String:weapon_primary[10][27] = {
	"tf_weapon_scattergun",
	"tf_weapon_rocketlauncher",
	"tf_weapon_flamethrower",
	"tf_weapon_grenadelauncher",
	"tf_weapon_minigun",
	"tf_weapon_shotgun_primary",
	"tf_weapon_syringegun_medic",
	"tf_weapon_sniperrifle",
	"tf_weapon_compound_bow",	//new
	"tf_weapon_revolver"};
static const String:weapon_secondary[9][27] = {
	"tf_weapon_pistol_scout",
	"tf_weapon_shotgun_soldier",
	"tf_weapon_shotgun_pyro",
	"tf_weapon_flaregun",
	"tf_weapon_pipebomblauncher",
	"tf_weapon_shotgun_hwg",
	"tf_weapon_smg",
	"tf_weapon_pistol",
	"tf_weapon_medigun"};
static const String:weapon_tertiary[10][19] = {
	"tf_weapon_bat",
	"tf_weapon_shovel",
	"tf_weapon_fireaxe",
	"tf_weapon_bottle",
	"tf_weapon_sword",		//new
	"tf_weapon_fists",
	"tf_weapon_wrench",
	"tf_weapon_bonesaw",
	"tf_weapon_club",
	"tf_weapon_knife"};

new Handle:max_ammo;

public OnPluginStart() {
	
	
	decl String:hostname[255], String:ip[32], String:port[8];
	GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));	
	GetConVarString(FindConVar("ip"), ip, sizeof(ip));
	GetConVarString(FindConVar("hostport"), port, sizeof(port));
	
	//if( StrContains(hostname, "Randomi", false) == -1)
	//	SetFailState("Randomizer ftw [%s] [%s]", hostname, ip);
	
	
	/*************
	 * SDK Calls *
	 *************/
	new Handle:conf = LoadGameConfigFile("sdktools.games/game.tf");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "GiveNamedItem");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	//PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
	GiveNamedItem = EndPrepSDKCall();
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	WeaponEquip = EndPrepSDKCall();
	CloseHandle(conf);

	/***********
	 * ConVars *
	 ***********/
	CreateConVar("rnd_version", PL_VERSION, "Version of Randomizer for TF2.", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_PLUGIN);
	new Handle:cv_enabled = CreateConVar("rnd_enabled", "1", "Enables/disables forcing random class and giving random weapons.", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 1.0);
	new Handle:cv_destroy = CreateConVar("rnd_destroy_buildings", "1", "Destroys Engineer buildings when a player respawns as a different class.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	new Handle:cv_fixammo = CreateConVar("rnd_fix_ammo", "1", "Emulates proper ammo handling.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	new Handle:cv_fixpyro = CreateConVar("rnd_fix_pyro", "1", "Properly limits the Pyro's speed when scoped or spun down.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	new Handle:cv_fixspy  = CreateConVar("rnd_fix_spy", "2", "0 = don't check, 1 = force undisguise on non-melee attacks, 2 = force undisguise on all attacks", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	new Handle:cv_fixuber = CreateConVar("rnd_fix_uber", "1", "Emulates Übercharges for non-Medic classes with the Medigun.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(cv_enabled, cvhook_enabled);
	HookConVarChange(cv_destroy, cvhook_destroy);
	HookConVarChange(cv_fixammo, cvhook_fixammo);
	HookConVarChange(cv_fixpyro, cvhook_fixpyro);
	HookConVarChange(cv_fixspy,  cvhook_fixspy);
	HookConVarChange(cv_fixuber, cvhook_fixuber);
	cvar_enabled = GetConVarBool(cv_enabled);
	cvar_destroy = GetConVarBool(cv_destroy);
	cvar_fixammo = GetConVarBool(cv_fixammo);
	cvar_fixpyro = GetConVarBool(cv_fixpyro);
	cvar_fixspy = GetConVarInt(cv_fixspy);
	cvar_fixuber = GetConVarBool(cv_fixuber);

	/************************
	 * Event & Entity Hooks *
	 ************************/
	HookEvent("player_spawn", player_spawn);
	HookEvent("player_death", player_death);
	HookEvent("teamplay_round_win", round_win, EventHookMode_PostNoCopy);

	/******************
	 * Max Ammo Count *
	 ******************/
	max_ammo = CreateTrie();
	// Scout
	SetTrieValue(max_ammo, "tf_weapon_scattergun", 32);
	SetTrieValue(max_ammo, "tf_weapon_pistol_scout", 36);
	// Soldier
	SetTrieValue(max_ammo, "tf_weapon_rocketlauncher", 16);
	SetTrieValue(max_ammo, "tf_weapon_shotgun_soldier", 32);
	// Pyro
	SetTrieValue(max_ammo, "tf_weapon_flamethrower", 200);
	SetTrieValue(max_ammo, "tf_weapon_shotgun_pyro", 32);
	SetTrieValue(max_ammo, "tf_weapon_flaregun", 16);
	// Demoman
	SetTrieValue(max_ammo, "tf_weapon_grenadelauncher", 16);
	SetTrieValue(max_ammo, "tf_weapon_pipebomblauncher", 24);
	// Heavy
	SetTrieValue(max_ammo, "tf_weapon_minigun", 200);
	SetTrieValue(max_ammo, "tf_weapon_shotgun_hwg", 32);
	// Engineer
	SetTrieValue(max_ammo, "tf_weapon_shotgun_primary", 32);
	SetTrieValue(max_ammo, "tf_weapon_pistol", 200);
	// Medic
	SetTrieValue(max_ammo, "tf_weapon_syringegun_medic", 150);
	// Sniper
	SetTrieValue(max_ammo, "tf_weapon_sniperrifle", 25);
	SetTrieValue(max_ammo, "tf_weapon_compound_bow", 12);
	SetTrieValue(max_ammo, "tf_weapon_smg", 75);
	// Spy
	SetTrieValue(max_ammo, "tf_weapon_revolver", 24);

	/********
	 * Vars *
	 ********/
	m_iAmmo = FindSendPropInfo("CTFPlayer", "m_iAmmo");
}

public cvhook_enabled(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_enabled = GetConVarBool(cvar); }
public cvhook_destroy(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_destroy = GetConVarBool(cvar); }
public cvhook_fixammo(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_fixammo = GetConVarBool(cvar); }
public cvhook_fixpyro(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_fixpyro = GetConVarBool(cvar); }
public cvhook_fixspy (Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_fixspy  = GetConVarBool(cvar); }
public cvhook_fixuber(Handle:cvar, const String:oldVal[], const String:newVal[]) { cvar_fixuber = GetConVarBool(cvar); }

public OnClientPutInServer(client) {
	setclass[client] = GetRandomInt(1, 9);
	setwep[client][0] = -2;
}

public OnClientDisconnect(client) {
	if (heal_beams[client]) {
		if (IsValidEntity(heal_beams[client])) AcceptEntityInput(heal_beams[client], "Kill");
		if (IsValidEntity(infotarget[client])) AcceptEntityInput(infotarget[client], "Kill");
		heal_beams[client] = 0;
		infotarget[client] = 0;
	}
}

public OnMapStart() {
	for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) OnClientPutInServer(i);
	CreateTimer(0.1, timer_checkplayers, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	PrecacheSound("player/invulnerable_off.wav", true);
	PrecacheSound("player/invulnerable_on.wav", true);
}

public player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	// Error-checking
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return;
	if (!IsPlayerAlive(client)) return;
	new TFClassType:cur = TF2_GetPlayerClass(client);
	if (cur == TFClass_Unknown) return;
	// Randomize if necessary.
	if (setwep[client][0] == -2) {
		if (cvar_enabled) {
			setwep[client][0] = GetRandomInt(-1 * isDefault(client, 0), sizeof(weapon_primary) - 1);
			setwep[client][1] = GetRandomInt(-1 * isDefault(client, 1), sizeof(weapon_secondary) - 1);
			setwep[client][2] = GetRandomInt(-1 * isDefault(client, 2), sizeof(weapon_tertiary) - 1);
		} else {
			setclass[client] = _:cur;
			setwep[client] = {-1, -1, -1};
		}
	}
	// Check class and weapons.
	if (cur != TFClassType:setclass[client]) {
		if (cvar_destroy && cur == TFClass_Engineer) {
			decl String:classname[32];
			new MaxEntities = GetMaxEntities();
			for (new i = MaxClients + 1; i <= MaxEntities; i++) {
				if (IsValidEdict(i)) {
					GetEdictClassname(i, classname, sizeof(classname));
					if (StrEqual(classname, "obj_dispenser")
					|| StrEqual(classname, "obj_sentrygun")
					|| StrEqual(classname, "obj_teleporter_entrace")
					|| StrEqual(classname, "obj_teleporter_exit")) {
						if (GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client) {
							SetVariantInt(9001);
							AcceptEntityInput(i, "RemoveHealth");
						}
					}
				}
			}
		}
		TF2_SetPlayerClass(client, TFClassType:setclass[client], false, true);
		TF2_RespawnPlayer(client);
	} else {
		spy_status[client] = (cur == TFClass_Spy);
		givePlayerWeapons(client);
		ammo_count[client][0] = 1000;
		ammo_count[client][1] = 1000;
	}
}

public player_death(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!(GetEventInt(event, "death_flags") & 32)) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (attacker && attacker != client) OnClientPutInServer(client);
	}
}

public round_win(Handle:event, const String:name[], bool:dontBroadcast) {
	for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) OnClientPutInServer(i);
}

public Action:timer_checkplayers(Handle:timer) {
	// Simply cap ammo if Randomizer isn't enabled.
	if (!cvar_enabled) {
		decl max, slot, String:name[64];
		for (new i = 1; i <= MaxClients; i++) {
			slot = GetPlayerWeaponSlot(i, 0);
			if (slot != -1) {
				GetEdictClassname(slot, name, sizeof(name));
				if (GetTrieValue(max_ammo, name, max)) {
					if (GetEntData(i, m_iAmmo + 4) > max)
						SetEntData(i, m_iAmmo + 4, max);
				}
			}
			slot = GetPlayerWeaponSlot(i, 1);
			if (slot != -1) {
				GetEdictClassname(GetPlayerWeaponSlot(i, 1), name, sizeof(name));
				if (GetTrieValue(max_ammo, name, max)) {
					if (GetEntData(i, m_iAmmo + 8) > max)
						SetEntData(i, m_iAmmo + 8, max);
				}
			}
		}
		return;
	}

	// Step 1: KILL ALL THE RAZORBACKS!
	decl String:name[64];
	for (new i = MaxClients + 1; i < GetMaxEntities(); i++) {
		if (IsValidEdict(i)) {
			GetEdictClassname(i, name, sizeof(name));
			if (StrEqual(name, "tf_wearable_item") && GetEntProp(i, Prop_Send, "m_iEntityLevel") == 10) RemoveEdict(i); // MUAHAHAHA.
		}
	}
	// Step 2: Calm down, then check all the players.
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i) && setwep[i][0] > -2) {
			// Check for unassigned (default) weapons.
			new bad = false, pri = setwep[i][0], sec = setwep[i][1], mel = setwep[i][2];
			if (pri > -1) bad = !isWeaponEquipped(i, 0, weapon_primary[pri]);
			if (sec > -1 && !bad) bad = !isWeaponEquipped(i, 1, weapon_secondary[sec]);
			if (mel > -1 && !bad) bad = !isWeaponEquipped(i, 2, weapon_tertiary[mel]);
			if (bad) {
				givePlayerWeapons(i);
			} else {
				// Cap ammo.
				new max = -1, slot;
				slot = GetPlayerWeaponSlot(i, 0);
				if (slot != -1) {
					GetEdictClassname(slot, name, sizeof(name));
					if (GetTrieValue(max_ammo, name, max)) {
						if (GetEntData(i, m_iAmmo + 4) > max)
							SetEntData(i, m_iAmmo + 4, max);
					}
				}
				slot = GetPlayerWeaponSlot(i, 1);
				if (slot != -1) {
					GetEdictClassname(GetPlayerWeaponSlot(i, 1), name, sizeof(name));
					if (GetTrieValue(max_ammo, name, max)) {
						if (GetEntData(i, m_iAmmo + 8) > max)
							SetEntData(i, m_iAmmo + 8, max);
					}
				}
			}
		}
	}
}

public bool:CheckWeapon(wpn){
	//PrintToServer("%i", wpn);
	if(wpn < MAXPLAYERS || !IsValidEntity(wpn)) return false;
	new idx = GetEntProp(wpn, Prop_Send, "m_iItemDefinitionIndex");
	return !(idx == 159 || idx == 42 || idx == 154 || idx == 127 || idx == 128 || idx == 133 || idx == 129);
}

public givePlayerWeapons(client) {
	decl String:name[32];
	new slot, wpn, pri = setwep[client][0], sec = setwep[client][1], mel = setwep[client][2];
	// primary
	if (pri > -1) {
		slot = GetPlayerWeaponSlot(client, 0);
		if (slot > -1) GetEdictClassname(slot, name, sizeof(name));
		if (slot == -1 || !StrEqual(name, weapon_primary[pri])) {
			TF2_RemoveWeaponSlot(client, 0);
			wpn = SDKCall(GiveNamedItem, client, weapon_primary[pri], 0);
			while(!CheckWeapon(wpn)){
				AcceptEntityInput(wpn, "kill");
				setwep[client][0] = pri = GetRandomInt(-1 * isDefault(client, 0), sizeof(weapon_primary) - 1);
				wpn = SDKCall(GiveNamedItem, client, weapon_primary[pri], 0);				
			}
			SDKCall(WeaponEquip, client, wpn);
		}
	}
	// secondary
	if (sec > -1) {
		slot = GetPlayerWeaponSlot(client, 1);
		if (slot > -1) GetEdictClassname(slot, name, sizeof(name));
		if (slot == -1 || !StrEqual(name, weapon_secondary[sec])) {
			TF2_RemoveWeaponSlot(client, 1);
			wpn = SDKCall(GiveNamedItem, client, weapon_secondary[sec], 0, 0);			
			while(!CheckWeapon(wpn)){
				AcceptEntityInput(wpn, "kill");
				setwep[client][1] = sec = GetRandomInt(-1 * isDefault(client, 1), sizeof(weapon_secondary) - 1);
				TF2_RemoveWeaponSlot(client, 1);
				wpn = SDKCall(GiveNamedItem, client, weapon_secondary[sec], 0, 0);			
			}
			SDKCall(WeaponEquip, client, wpn);
		}
	}
	// melee
	if (mel > -1) {
		TF2_RemoveWeaponSlot(client, 2);
		wpn = SDKCall(GiveNamedItem, client, weapon_tertiary[mel], 0, 0);	
		while(!CheckWeapon(wpn)){
			AcceptEntityInput(wpn, "kill");
			setwep[client][2] = mel = GetRandomInt(-1 * isDefault(client, 2), sizeof(weapon_tertiary) - 1);
			TF2_RemoveWeaponSlot(client, 2);
			wpn = SDKCall(GiveNamedItem, client, weapon_tertiary[mel], 0, 0);	
		}
		
		SDKCall(WeaponEquip, client, wpn);
	}
}

isDefault(client, slot) {
	new wepslot = GetPlayerWeaponSlot(client, slot);
	if (wepslot == -1) return true; // gets rid of Razorback
	//if (GetEntProp(wepslot, Prop_Send, "m_iEntityLevel") > 1) return false;
	decl String:weapon[27];
	GetEdictClassname(wepslot, weapon, sizeof(weapon));
	if (slot == 0) for (new i = 0; i < sizeof(weapon_primary); i++) if (StrEqual(weapon, weapon_primary[i])) return true;
	if (slot == 1) for (new i = 0; i < sizeof(weapon_secondary); i++) if (StrEqual(weapon, weapon_secondary[i])) return true;
	if (slot == 2) for (new i = 0; i < sizeof(weapon_tertiary); i++) if (StrEqual(weapon, weapon_tertiary[i])) return true;
	return false;
}

isWeaponEquipped(client, slot, const String:name[]) {
	new ent = GetPlayerWeaponSlot(client, slot);
	if (ent == -1) return false;
	decl String:weapon[32];
	GetEdictClassname(ent, weapon, sizeof(weapon));
	return StrEqual(name, weapon);
}

//

/*
RefillAmmo(client, Float:amount) {
	decl slot, ammo, max, String:name[64];
	slot = GetPlayerWeaponSlot(client, 0);
	if (slot != -1) {
		GetEdictClassname(slot, name, sizeof(name));
		if (GetTrieValue(max_ammo, name, max)) {
			ammo = GetEntData(client, m_iAmmo + 4) - RoundToFloor(amount * 1000);
			ammo += RoundToFloor(max * amount);
			if (ammo > max) ammo = max;
			SetEntData(client, m_iAmmo + 4, ammo);
		}
	}
	slot = GetPlayerWeaponSlot(client, 1);
	if (slot != -1) {
		GetEdictClassname(slot, name, sizeof(name));
		if (GetTrieValue(max_ammo, name, max)) {
			ammo = GetEntData(client, m_iAmmo + 8) - RoundToFloor(amount * 1000);
			ammo += RoundToFloor(max * amount);
			if (ammo > max) ammo = max;
			SetEntData(client, m_iAmmo + 8, ammo);
		}
	}
}

public touch_ammo_small(const String:output[], caller, activator, Float:delay) {
	if (activator && activator <= MaxClients) RefillAmmo(activator, 0.201);
}

public touch_ammo_medium(const String:output[], caller, activator, Float:delay) {
	if (activator && activator <= MaxClients) RefillAmmo(activator, 0.5);
}
*/



/*****************
 * OnGameFrame() *
 *****************/
public OnGameFrame() {
	if (!(cvar_fixammo || cvar_fixpyro || cvar_fixspy || cvar_fixuber)) return;
	decl ammo0old, ammo0new, ammo1old, ammo1new, max;
	decl cond, status, String:weapon[64]; // Spy
	decl Float:speed; // Pyro
	decl slot, target, oldtarget; // Medigun
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			cond = GetEntProp(i, Prop_Send, "m_nPlayerCond");
			// Fix ammo
			if (cvar_fixammo) {
				ammo0old = ammo_count[i][0];
				ammo0new = GetEntData(i, m_iAmmo + 4);
				ammo1old = ammo_count[i][1];
				ammo1new = GetEntData(i, m_iAmmo + 8);
				// fix primary
				if (ammo0new > ammo0old) {
					slot = GetPlayerWeaponSlot(i, 0);
					if (slot != -1) {
						GetEdictClassname(slot, weapon, sizeof(weapon));
						if (GetTrieValue(max_ammo, weapon, max)) {
							//PrintToServer("1) %s  2) %i  3) %i  4) %i  5) %i  6) %i", weapon, ammo0old, ammo0new, ammo1old, ammo1new, max);
							ammo0new = ammo0old + RoundToFloor(max * float(ammo0new - ammo0old) / 1000);
							if (ammo0new > max) ammo0new = max;
							SetEntData(i, m_iAmmo + 4, ammo0new);
						}
					}
				}
				// fix secondary
				if (ammo1new > ammo1old) {
					slot = GetPlayerWeaponSlot(i, 1);
					if (slot != -1) {
						GetEdictClassname(slot, weapon, sizeof(weapon));
						if (GetTrieValue(max_ammo, weapon, max)) {
							ammo1new = ammo1old + RoundToFloor(max * float(ammo1new - ammo1old) / 1000);
							if (ammo1new > max) ammo1new = max;
							SetEntData(i, m_iAmmo + 8, ammo1new);
						}
					}
				}
				ammo_count[i][0] = ammo0new;
				ammo_count[i][1] = ammo1new;
			}
			// Fix Spy disguise
			if (cvar_fixspy) {
				if ((status = spy_status[i])) {
					if (spy_status[i] == 1 && (cond & 12) && (GetClientButtons(i) & IN_ATTACK)) { // Attacking?
						if (cvar_fixspy == 1) {
							GetClientWeapon(i, weapon, sizeof(weapon));
							if (StrEqual(weapon, "tf_weapon_flamethrower")
								|| StrEqual(weapon, "tf_weapon_grenadelauncher")
								|| StrEqual(weapon, "tf_weapon_pipebomblauncher")) TF2_RemovePlayerDisguise(i); //TF2_DisguisePlayer(i, TFTeam:GetClientTeam(i), TFClass_Spy);
						} else {
							TF2_RemovePlayerDisguise(i); //TF2_DisguisePlayer(i, TFTeam:GetClientTeam(i), TFClass_Spy);
						}
					}
					if (status == 1) {
						if (cond & 16) spy_status[i] = 2;
					} else if (status == 2 && !(cond & 16)) {
						CreateTimer(2.0, timer_uncloak, i);
						spy_status[i] = 3;
					}
				}
			}
			// Fix Pyro minigun
			if (cvar_fixpyro) {
				if (TF2_GetPlayerClass(i) == TFClass_Pyro) {
					speed = GetEntPropFloat(i, Prop_Send, "m_flMaxspeed");
					if ((cond & 3) && speed != 80.0) {
						SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 80.0);
					} else if (!(cond & 3) && speed && speed != 300.0) {
						SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 300.0);
					}
				}
			}
			// Fix Ubercharge
			if (cvar_fixuber) {
				if (setclass[i] != _:TFClass_Medic) { // Not set to Medic.
					slot = GetPlayerWeaponSlot(i, 1);
					if (slot != -1) { // Have a secondary weapon.
						GetEdictClassname(slot, weapon, sizeof(weapon));
						if (StrEqual(weapon, "tf_weapon_medigun")) { // It's a medigun.
							// 1: Fix medigun beam.
							target = GetEntPropEnt(slot, Prop_Send, "m_hHealingTarget");
							oldtarget = healtarget[i];
							if (target != oldtarget) {
								if (heal_beams[i]) {
									if (IsValidEntity(heal_beams[i])) AcceptEntityInput(heal_beams[i], "Kill");
									if (IsValidEntity(infotarget[i])) AcceptEntityInput(infotarget[i], "Kill");
									heal_beams[i] = 0;
									infotarget[i] = 0;
								}
								healtarget[i] = target;
								if (target != -1) {
									new particle = CreateEntityByName("info_particle_system");
									if (IsValidEdict(particle)) {
										heal_beams[i] = particle;
										// weapon targetname (start)
										decl String:targetname[9];
										FormatEx(targetname, sizeof(targetname), "wpn%i", slot);
										DispatchKeyValue(slot, "targetname", targetname);
										// player targetname
										decl String:playertarget[9];
										FormatEx(playertarget, sizeof(playertarget), "player%i", target);
										DispatchKeyValue(target, "targetname", playertarget);
										// info_target on player (end)
										new info_target = CreateEntityByName("info_particle_system");
										decl String:controlpoint[9], Float:pos[3];
										FormatEx(controlpoint, sizeof(controlpoint), "target%i", target);
										DispatchKeyValue(info_target, "targetname", controlpoint);
										GetClientAbsOrigin(target, pos);
										pos[2] += 48.0;
										TeleportEntity(info_target, pos, NULL_VECTOR, NULL_VECTOR);
										SetVariantString(playertarget);
										AcceptEntityInput(info_target, "SetParent");
										infotarget[i] = info_target;
										// set particle stuff
										decl String:effect_name[19];
										FormatEx(effect_name, sizeof(effect_name), "medicgun_beam_%s", (GetClientTeam(i) == 2) ? "red" : "blue");
										DispatchKeyValue(particle, "parentname", targetname);
										DispatchKeyValue(particle, "effect_name", effect_name);
										DispatchKeyValue(particle, "cpoint1", controlpoint);
										DispatchSpawn(particle);
										SetVariantString(targetname);
										AcceptEntityInput(particle, "SetParent");
										SetVariantString("muzzle");
										AcceptEntityInput(particle, "SetParentAttachment");
										ActivateEntity(particle);
										AcceptEntityInput(particle, "Start");
									}
								}
							}
							// 2: Fix ubercharges.
							if (GetEntProp(slot, Prop_Send, "m_bChargeRelease")) { // Charge was activated.
								GetClientWeapon(i, weapon, sizeof(weapon));
								if (StrEqual(weapon, "tf_weapon_medigun")) {
									// uber effect
									if (TF2_GetPlayerClass(i) != TFClass_Medic) {
										TF2_SetPlayerClass(i, TFClass_Medic, _, false);
										TF2_Ubercharge(i, true);
									}
									// fix charge level
									new Float:charge = GetEntPropFloat(slot, Prop_Send, "m_flChargeLevel") - 0.001875;
									if (charge <= 0.0) {
										SetEntProp(slot, Prop_Send, "m_bChargeRelease", false);
										charge = 0.0;
									}
									SetEntPropFloat(slot, Prop_Send, "m_flChargeLevel", charge);
								} else if (TF2_GetPlayerClass(i) == TFClass_Medic) {
									TF2_SetPlayerClass(i, TFClassType:setclass[i], _, false);
									TF2_Ubercharge(i, false);
								}
							} else if (TF2_GetPlayerClass(i) == TFClass_Medic) {
								TF2_SetPlayerClass(i, TFClassType:setclass[i], _, false);
								TF2_Ubercharge(i, false);
							}
						}
					}
				}
			}
		}
	}
}

public Action:timer_uncloak(Handle:event, any:client) {
	spy_status[client] = 1;
}

TF2_Ubercharge(client, enable) {
	if (enable) {
		EmitSoundToClient(client, "player/invulnerable_on.wav");
		TF2_AddCond(client, 5);
	} else {
		EmitSoundToClient(client, "player/invulnerable_off.wav");
		TF2_RemoveCond(client, 5);
	}
}



stock TF2_AddCond(client, cond) {
	new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
	if (!enabled) {
		SetConVarFlags(cvar, flags & ~(FCVAR_NOTIFY | FCVAR_REPLICATED));
		SetConVarBool(cvar, true);
	}
	FakeClientCommand(client, "addcond %i", cond);
	if (!enabled) {
		SetConVarBool(cvar, false);
		SetConVarFlags(cvar, flags);
	}
}

stock TF2_RemoveCond(client, cond) {
	new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
	if (!enabled) {
		SetConVarFlags(cvar, flags & ~(FCVAR_NOTIFY | FCVAR_REPLICATED));
		SetConVarBool(cvar, true);
	}
	FakeClientCommand(client, "removecond %i", cond);
	if (!enabled) {
		SetConVarBool(cvar, false);
		SetConVarFlags(cvar, flags);
	}
}

/*
TF2_AddCond(client, cond) {
	new flags = GetCommandFlags("addcond");
	SetCommandFlags("addcond", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "addcond %d", cond);
	SetCommandFlags("addcond", flags);
}

TF2_RemoveCond(client, cond) {
	new flags = GetCommandFlags("removecond");
	SetCommandFlags("removecond", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "removecond %d", cond);
	SetCommandFlags("removecond", flags);
}
*/



/********************
 * Mersenne Twister *
 ********************/
new mt_array[624];
new mt_index;

stock mt_srand(seed) {
	mt_array[0] = seed;
	for (new i = 1; i < 624; i++) mt_array[i] = ((mt_array[i - 1] ^ (mt_array[i - 1] >> 30)) * 0x6C078965 + 1) & 0xFFFFFFFF;
}

stock mt_rand(min, max) {
	new Float:num = _mt_getNext() / float(0x7FFFFFFF);
	return (RoundToNearest(num * (max - min) + min));
}

stock _mt_getNext() {
	if (!mt_index) _mt_generate();
	new y = mt_array[mt_index];
	y ^= (y >> 11);
	y ^= (y << 7) & 0x9D2C5680;
	y ^= (y << 15) & 0xEFC60000;
	y ^= (y >> 18);
	mt_index = (mt_index + 1) % 624;
	return y;
}

stock _mt_generate() {
	for (new i = 0; i < 623; i++) {
		new y = (mt_array[i] & 0x80000000) + ((mt_array[i + 1] % 624) & 0x7FFFFFFF);
		mt_array[i] = mt_array[(i + 397) % 624] ^ (y >> 1);
		if (y % 2) mt_array[i] ^= 0x9908B0DF;
	}
}
