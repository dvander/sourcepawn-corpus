#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "13.1023.0"

#define M_COLLISION_GROUP 11
#define SOLID_FLAGS 668
#define BRUSH_CLASSNAME "func_nav_avoid"

new BoxingBrush;
new SpectatorBrush;
new RedBoxer;
new BluBoxer;


new Float:BluSpawnBoxing[3] = {477.314545, -1526.343872, -181.845612};
new Float:RedSpawnBoxing[3] = {-455.159698, -1517.230103, -185.426178};
new Float:BluSpawnBoxingAngles[3] = {0.00, 180.0, 0.0};
new Float:RedSpawnBoxingAngles[3] = {0.00, 0.0, 0.0};
new Float:NoVelocity[3] = {0.0, 0.0, 0.0};

new Handle:hcvar_version = INVALID_HANDLE;
new Handle:hcvar_criticals = INVALID_HANDLE;
new bool:cvar_criticals;

new Handle:hcvar_blockweps_black = INVALID_HANDLE;
new cvar_blockweps_black[255];
new Handle:hcvar_blockweps_classes = INVALID_HANDLE;
new String:cvar_blockweps_classes[255][64];
new Handle:hcvar_blockweps_white = INVALID_HANDLE;
new cvar_blockweps_white[255];


public Plugin:myinfo =
{
	name = "Lethal-Zone.eu Boxing",
	author = "Derek D. Howard",
	description = "Various Functions for the Lethal-Zone boxing ring.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=228521"
}

public OnPluginStart() {

	hcvar_version = CreateConVar("sm_ddhoward_lethalzoneboxing_version", PLUGIN_VERSION, "Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_PLUGIN);
	SetConVarString(hcvar_version, PLUGIN_VERSION);
	HookConVarChange(hcvar_version, cvarChange);

	hcvar_criticals = CreateConVar("sm_boxing_crits", "1", "Enable crits in the boxing ring?", FCVAR_NOTIFY|FCVAR_PLUGIN);
	HookConVarChange(hcvar_criticals, cvarChange);
	hcvar_blockweps_classes = CreateConVar("sm_boxing_blockedclasses", "0", "What weapon classes to block? Enter 0 to disable, or enter a custom list seperated by commas.", FCVAR_PLUGIN);
	HookConVarChange(hcvar_blockweps_classes, cvarChange);
	hcvar_blockweps_black = CreateConVar("sm_boxing_blockedweapons", "0", "What weapon index definiteion numbers to block? Set to 0 to disable, or enter a custom list here, seperated by commas.", FCVAR_PLUGIN);
	HookConVarChange(hcvar_blockweps_black, cvarChange);
	hcvar_blockweps_white = CreateConVar("sm_boxing_whitelistedweps", "0", "What weapon index definiteion numbers to whitelist? Set to 0 to disable, or enter a custom list here, seperated by commas.", FCVAR_PLUGIN);
	HookConVarChange(hcvar_blockweps_white, cvarChange);

	HookEvent("teamplay_round_start", Round_Start);
	HookEvent("player_stunned", Stunned);

	AddMultiTargetFilter("@boxers", t_boxers, "players in the boxing ring", false);
	AddMultiTargetFilter("@redboxer", t_redboxer, "the RED player in the boxing ring", false);
	AddMultiTargetFilter("@bluboxer", t_bluboxer, "the BLU player in the boxing ring", false);

	CreateTimer(1.0, CreateBrush);
	
	for (new i=1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public Round_Start(Handle:event, const String:name[], bool:dontBroadcast) {
	CreateTimer(0.5, CreateBrush);
}

public OnConfigsExecuted() {
	cvarChange(INVALID_HANDLE, "0", "0");
}

public cvarChange(Handle:hHandle, const String:oldValue[], const String:newValue[]) {
	if (hHandle == hcvar_version || hHandle == INVALID_HANDLE) {
		SetConVarString(hcvar_version, PLUGIN_VERSION);
	}
	if (hHandle == hcvar_criticals || hHandle == INVALID_HANDLE) {
		cvar_criticals = GetConVarBool(hcvar_criticals);
	}
	if (hHandle == hcvar_blockweps_black || hHandle == INVALID_HANDLE) {
		decl String:strWeaponsBlack[255]; strWeaponsBlack[0] = '\0';
		decl String:strWeaponsBlack2[255][8];
		GetConVarString(hcvar_blockweps_black, strWeaponsBlack, sizeof(strWeaponsBlack));
		if (StrEqual(strWeaponsBlack, "0")) {
			strWeaponsBlack = "-1";
		}
		new numweps = ExplodeString(strWeaponsBlack, ",", strWeaponsBlack2, sizeof(strWeaponsBlack2), sizeof(strWeaponsBlack2[]));
		for (new i=0; i < sizeof(cvar_blockweps_black) && i < numweps; i++) {
			cvar_blockweps_black[i] = StringToInt(strWeaponsBlack2[i]);
		}
		cvar_blockweps_black[numweps] = -1;
	}
	if (hHandle == hcvar_blockweps_white || hHandle == INVALID_HANDLE) {
		decl String:strWeaponsWhite[255]; strWeaponsWhite[0] = '\0';
		decl String:strWeaponsWhite2[255][8];
		GetConVarString(hcvar_blockweps_white, strWeaponsWhite, sizeof(strWeaponsWhite));
		if (StrEqual(strWeaponsWhite, "0")) {
			strWeaponsWhite = "-1";
		}
		new numweps = ExplodeString(strWeaponsWhite, ",", strWeaponsWhite2, sizeof(strWeaponsWhite2), sizeof(strWeaponsWhite2[]));
		for (new i=0; i < sizeof(cvar_blockweps_white) && i < numweps; i++) {
			cvar_blockweps_white[i] = StringToInt(strWeaponsWhite2[i]);
		}
		cvar_blockweps_white[numweps] = -1;
	}
	if (hHandle == hcvar_blockweps_classes || hHandle == INVALID_HANDLE) {
		decl String:strWeaponsClass[256]; strWeaponsClass[0] = '\0';
		GetConVarString(hcvar_blockweps_classes, strWeaponsClass, sizeof(strWeaponsClass));
		if (StrEqual(strWeaponsClass, "0")) {
			strWeaponsClass = "-1";
		}
		new numclasses = ExplodeString(strWeaponsClass, ",", cvar_blockweps_classes, sizeof(cvar_blockweps_classes), sizeof(cvar_blockweps_classes[]));
		cvar_blockweps_classes[numclasses] = "-1";
	}
}

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnPluginEnd() {
	if (IsValidEntity(BoxingBrush)) {
		decl String:classname[32];
		GetEdictClassname(BoxingBrush, classname, sizeof(classname));
		if (StrEqual(classname, BRUSH_CLASSNAME)) {
			AcceptEntityInput(BoxingBrush, "Kill");
		}
	}
	if (IsValidEntity(SpectatorBrush)) {
		decl String:classname[32];
		GetEdictClassname(SpectatorBrush, classname, sizeof(classname));
		if (StrEqual(classname, BRUSH_CLASSNAME)) {
			AcceptEntityInput(SpectatorBrush, "Kill");
		}
	}
	RemoveMultiTargetFilter("@boxers", t_boxers);
	RemoveMultiTargetFilter("@redboxer", t_redboxer);
	RemoveMultiTargetFilter("@bluboxer", t_bluboxer);
}



public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result) {
	if (!cvar_criticals && (RedBoxer == client || BluBoxer == client)) {
		result = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if (attacker < 1 || attacker > MaxClients) {
		return Plugin_Continue;
	}
	if ((client == RedBoxer || client == BluBoxer) && attacker != RedBoxer && attacker != BluBoxer) {
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[]) {
	if(StrEqual(classname, "item_healthkit_medium", false)) {
		SDKHook(entity, SDKHook_StartTouch, OnSandvichTouch);
		SDKHook(entity, SDKHook_Touch, OnSandvichTouch);
	}
	if(StrEqual(classname, "tf_ammo_pack", false)) {
		SDKHook(entity, SDKHook_StartTouch, OnSandvichTouch);
		SDKHook(entity, SDKHook_Touch, OnSandvichTouch);
	}
}

/*///////////////////////////////////////////////////////////////////////////////////////////
Touch Events */

public Action:OnStartTouchBoxing(point, client) {
	if (!IsValidEntity(client))
		return Plugin_Continue;
	if (client < 1 && client > MaxClients)
		return Plugin_Continue;
	new team = GetClientTeam(client);
	if (team != 2 && team != 3)
		return Plugin_Continue;
	if (team == 2) {
		if (RedBoxer != 0 && RedBoxer != client) {
			TeleportEntity(client, RedSpawnBoxing, RedSpawnBoxingAngles, NoVelocity);
			PrintToChat(client, "Only 1v1 is allowed in the boxing ring.");
			return Plugin_Handled;
		}
		new weapon = GetPlayerWeaponSlot(client, 2);
		if (IsWeaponBlocked(weapon)) {
			TeleportEntity(client, RedSpawnBoxing, RedSpawnBoxingAngles, NoVelocity);
			PrintToChat(client, "That melee weapon is not allowed in the ring.");
			return Plugin_Handled;
		}
		if (RedBoxer == 0) {
			RedBoxer = client;
		}
	}
	if (team == 3) {
		if (BluBoxer != 0 && BluBoxer != client) {
			TeleportEntity(client, BluSpawnBoxing, BluSpawnBoxingAngles, NoVelocity);
			PrintToChat(client, "Only 1v1 is allowed in the boxing ring.");
			return Plugin_Handled;
		}
		new weapon = GetPlayerWeaponSlot(client, 2);
		if (IsWeaponBlocked(weapon)) {
			TeleportEntity(client, BluSpawnBoxing, BluSpawnBoxingAngles, NoVelocity);
			PrintToChat(client, "That melee weapon is not allowed in the ring.");
			return Plugin_Handled;
		}
		if (BluBoxer == 0) {
			BluBoxer = client;
		}
	}
	if (TF2_IsPlayerInCondition(client, TFCond_OnFire)) {
		TF2_RemoveCondition(client, TFCond_OnFire);
	}
	if (TF2_IsPlayerInCondition(client, TFCond_Bleeding)) {
		TF2_RemoveCondition(client, TFCond_Bleeding);
	}
	SetNoTarget(client, true);
	return Plugin_Continue;
}


public Action:OnTouchBoxing(point, client) {
	if (!IsValidEntity(client))
		return Plugin_Continue;
	if (client < 1 || client > MaxClients) {
		return Plugin_Continue;
	}
	if (TF2_IsPlayerInCondition(client, TFCond_Milked))
		TF2_RemoveCondition(client, TFCond_Milked);
	if (TF2_IsPlayerInCondition(client, TFCond_Jarated))
		TF2_RemoveCondition(client, TFCond_Jarated);

	if (TF2_IsPlayerInCondition(client, TFCond_Buffed))
		TF2_RemoveCondition(client, TFCond_Buffed);
	if (TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
		TF2_RemoveCondition(client, TFCond_DefenseBuffed);
	if (TF2_IsPlayerInCondition(client, TFCond_RegenBuffed))
		TF2_RemoveCondition(client, TFCond_RegenBuffed);

	if (TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		TF2_RemoveCondition(client, TFCond_Cloaked);
	if (TF2_IsPlayerInCondition(client, TFCond_Disguised))
		TF2_RemoveCondition(client, TFCond_Disguised);

	if (TF2_IsPlayerInCondition(client, TFCond_InHealRadius))
		TF2_RemoveCondition(client, TFCond_InHealRadius);

	if (TF2_IsPlayerInCondition(client, TFCond_CritCola))
		TF2_RemoveCondition(client, TFCond_CritCola);
	if (TF2_IsPlayerInCondition(client, TFCond_Bonked))
		TF2_RemoveCondition(client, TFCond_Bonked);
	if (TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly))
		TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
	return Plugin_Continue;
}

public Action:OnStopTouchBoxing(point, client) {
	if (!IsValidEntity(client))
		return Plugin_Continue;
	if (client < 1 || client > MaxClients)
		return Plugin_Continue;
	if (RedBoxer == client) {
		RedBoxer = 0;
		SetNoTarget(client, false);
	}
	if (BluBoxer == client) {
		BluBoxer = 0;
		SetNoTarget(client, false);
	}
	return Plugin_Continue;
}

public Action:OnStartTouchSpectatorArea(point, client) {
	if (!IsValidEntity(client))
		return Plugin_Continue;
	if (client < 1 || client > MaxClients) {
		return Plugin_Continue;
	}
	if (TF2_GetPlayerClass(client) == TFClass_Medic) {
		new primary = GetPlayerWeaponSlot(client, 0);
		new secondary = GetPlayerWeaponSlot(client, 1);
		decl String:primaryWeaponClass[64]; primaryWeaponClass[0] = '\0';
		decl String:secondaryWeaponClass[64]; secondaryWeaponClass[0] = '\0';
		if (GetEntityClassname(primary, primaryWeaponClass, sizeof(primaryWeaponClass))) {
			if (StrEqual(primaryWeaponClass, "tf_weapon_crossbow")) {
				TF2_RemoveWeaponSlot(client, 0);
				PrintToChat(client, "The Crusader's Crossbow is not allowed near the boxing arena.");
			}
		}
		if (GetEntityClassname(secondary, secondaryWeaponClass, sizeof(secondaryWeaponClass))) {
			if (StrEqual(secondaryWeaponClass, "tf_weapon_medigun")) {
				TF2_RemoveWeaponSlot(client, 1);
				PrintToChat(client, "Mediguns are not allowed near the boxing arena.");
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnSandvichTouch(point, client) {
	if (client < 1 || client > MaxClients)
		return Plugin_Continue;
	if (RedBoxer == client || BluBoxer == client)
		return Plugin_Handled;
	return Plugin_Continue;
}

stock bool:IsWeaponBlocked(weapon) {
	decl String:weaponClass[64]; weaponClass[0] = '\0';
	if (!GetEntityClassname(weapon, weaponClass, sizeof(weaponClass))) {
		return false;
	}
	new weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	new bool:blocked = false;
	for (new i = 0; i < sizeof(cvar_blockweps_classes) && !blocked && !StrEqual(cvar_blockweps_classes[i], "-1"); i++) {
		if (StrEqual(cvar_blockweps_classes[i], weaponClass)) {
			blocked = true;
		}
	}
	if (blocked) {
		for (new i = 0; i < sizeof(cvar_blockweps_white) && cvar_blockweps_white[i] != -1; i++) {
			if (cvar_blockweps_white[i] == weaponIndex) {
				return false;
			}
		}
		return true;
	} else {
		for (new i = 0; i < sizeof(cvar_blockweps_black) && cvar_blockweps_black[i] != -1; i++) {
			if (cvar_blockweps_black[i] == weaponIndex) {
				return true;
			}
		}
		return false;
	}
}

SetNoTarget(ent, bool:apply) {
	new flags;
	if (apply) {
		flags = GetEntityFlags(ent)|FL_NOTARGET;
	} else {
		flags = GetEntityFlags(ent)&~FL_NOTARGET;
	}
	SetEntityFlags(ent, flags);
}


/*///////////////////////////////////////////////////////////////////////////////////////////
Create Brushes */

public Action:CreateBrush(Handle:timer) {
	CreateBoxingBrush();
	CreateSpectatorBrush();
}

CreateBoxingBrush() {
	new Float:funcpos[3] = {-180.0, -1704.0, -440.0};
	new Float:minbounds[3] = {0.0, 0.0, 0.0};
	new Float:maxbounds[3] = {360.0, 360.0, 430.0};
	//-180 -1704 -440
	//180 -1344 -10
	
	BoxingBrush = CreateEntityByName(BRUSH_CLASSNAME);

	DispatchSpawn(BoxingBrush);
	ActivateEntity(BoxingBrush);

	TeleportEntity(BoxingBrush, funcpos, NULL_VECTOR, NULL_VECTOR);

	SetEntityModel(BoxingBrush, "models/props_gameplay/resupply_locker.mdl");

	SetEntPropVector(BoxingBrush, Prop_Send, "m_vecMins", minbounds);
	SetEntPropVector(BoxingBrush, Prop_Send, "m_vecMaxs", maxbounds);
	SetEntProp(BoxingBrush, Prop_Send, "m_CollisionGroup", M_COLLISION_GROUP);
	SetEntProp(BoxingBrush, Prop_Send, "m_usSolidFlags", SOLID_FLAGS);

	new enteffects = GetEntProp(BoxingBrush, Prop_Send, "m_fEffects");
	enteffects |= 32;
	SetEntProp(BoxingBrush, Prop_Send, "m_fEffects", enteffects); 
	
	SDKHook(BoxingBrush, SDKHook_StartTouch, OnStartTouchBoxing);
	SDKHook(BoxingBrush, SDKHook_Touch, OnTouchBoxing);
	SDKHook(BoxingBrush, SDKHook_EndTouch, OnStopTouchBoxing);
}

CreateSpectatorBrush() {
	new Float:funcpos[3] = {-1024.0, -2480.0, -448.0};
	new Float:minbounds[3] = {0.0, 0.0, 0.0};
	new Float:maxbounds[3] = {2048.0, 1912.0, 438.0};
	
	SpectatorBrush = CreateEntityByName(BRUSH_CLASSNAME);

	DispatchSpawn(SpectatorBrush);
	ActivateEntity(SpectatorBrush);

	TeleportEntity(SpectatorBrush, funcpos, NULL_VECTOR, NULL_VECTOR);

	SetEntityModel(SpectatorBrush, "models/props_gameplay/resupply_locker.mdl");

	SetEntPropVector(SpectatorBrush, Prop_Send, "m_vecMins", minbounds);
	SetEntPropVector(SpectatorBrush, Prop_Send, "m_vecMaxs", maxbounds);
	SetEntProp(SpectatorBrush, Prop_Send, "m_CollisionGroup", M_COLLISION_GROUP);
	SetEntProp(SpectatorBrush, Prop_Send, "m_usSolidFlags", SOLID_FLAGS);

	new enteffects = GetEntProp(SpectatorBrush, Prop_Send, "m_fEffects");
	enteffects |= 32;
	SetEntProp(SpectatorBrush, Prop_Send, "m_fEffects", enteffects); 
	
	SDKHook(SpectatorBrush, SDKHook_StartTouch, OnStartTouchSpectatorArea);
}


/*///////////////////////////////////////////////////////////////////////////////////////////
Multi-Target Filters */

public bool:t_boxers(const String:pattern[], Handle:clients)
{
	if (RedBoxer != 0 && IsClientInGame(RedBoxer)) {
		PushArrayCell(clients, RedBoxer);
	}
	if (BluBoxer != 0 && IsClientInGame(BluBoxer)) {
		PushArrayCell(clients, BluBoxer);
	}
	return true;
}
public bool:t_redboxer(const String:pattern[], Handle:clients)
{
	if (RedBoxer != 0 && IsClientInGame(RedBoxer)) {
		PushArrayCell(clients, RedBoxer);
	}
	return true;
}
public bool:t_bluboxer(const String:pattern[], Handle:clients)
{
	if (BluBoxer != 0 && IsClientInGame(BluBoxer)) {
		PushArrayCell(clients, BluBoxer);
	}
	return true;
}

public Stunned(Handle:event, const String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new stunner = GetClientOfUserId(GetEventInt(event, "stunner"));
	if (victim < 1 || victim > MaxClients || stunner < 1 || stunner > MaxClients)
		return;
	if (victim != RedBoxer && victim != BluBoxer)
		return;
	if (stunner == RedBoxer || stunner == BluBoxer)
		return;
	new victimUserID = GetClientUserId(victim);
	CreateTimer(0.1, RemoveStun, victimUserID);
}

public Action:RemoveStun(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if (client < 1 || client > MaxClients)
		return;
	TF2_RemoveCondition(client, TFCond_Dazed);
}