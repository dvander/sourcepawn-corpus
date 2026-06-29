#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <gift>
#include <morecolors>

#define PLUGIN_VERSION 	"2.0"
#define GIFT_BOX_BLUE 	"models/items/tf_gift.mdl"
#define GIFT_BOX_RED 		"models/props_halloween/halloween_gift.mdl"
#define GIFT_CONFETTI 	"bday_confetti"
#define GIFT_SOUND 		"misc/happy_birthday.wav"
#define TotalAbilities 20

new Handle:cVersion = INVALID_HANDLE;
new Handle:cEnabled = INVALID_HANDLE;
new Handle:cDuration = INVALID_HANDLE;
new Handle:cGiftChance = INVALID_HANDLE;
new Handle:cDropChance = INVALID_HANDLE;
new Handle:cGiftDuration = INVALID_HANDLE;
new Handle:cGiftCooldown = INVALID_HANDLE;
new Handle:cGiftSuicide = INVALID_HANDLE;
new Handle:cGiftTeam = INVALID_HANDLE;
new Handle:cDisabled = INVALID_HANDLE;

new Handle:hCoolTimer[MAXPLAYERS+1];
new Handle:hDuration[MAXPLAYERS+1];
new Handle:EntityArray;

new g_Enabled;
new isRoundActive;
new isCooldown[MAXPLAYERS+1];
new g_iGoodDisabled[10];
new g_iBadDisabled[10];
new String:g_Disabled[PLATFORM_MAX_PATH];

new Float:g_Duration;
new Float:g_GiftChance;
new Float:g_DropChance;
new Float:g_GiftDuration;
new Float:g_GiftCooldown;
new g_GiftSuicide;
new g_GiftTeam;


public Plugin:myinfo = {
	name = "[GiftMod] Gift Mode",
	author = "Tak (chaosxk)",
	description = "Spawns random gift and abilities.",
	version = PLUGIN_VERSION,
};

public OnPluginStart() {
	cVersion = CreateConVar("gift_mode_version", PLUGIN_VERSION, "Gift Mode Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cEnabled = CreateConVar("gift_mode_enabled", "1", "Should this plugin be enabled?");
	cDuration = CreateConVar("gift_duration", "20.0", "How many seconds should abilities last?");
	cGiftChance = CreateConVar("gift_mode_chance", "0.50", "Chance for a good effect.");
	cDropChance = CreateConVar("gift_mode_dropchance", "0.65", "Chance for a gift to drop.");
	cGiftDuration = CreateConVar("gift_mode_duration", "10.0", "How long before gifts disappears?");
	cGiftCooldown = CreateConVar("gift_mode_cooldown", "30.0", "How long before players can see and pickup gifts.");
	cGiftSuicide = CreateConVar("gift_mode_suicide", "0", "Can people who suicide drop gifts?");
	cGiftTeam = CreateConVar("gift_mode_team", "1", "Which team can pick up gifts? 0-None|1-All|2-Red|3-Blue");
	cDisabled = CreateConVar("gift_mode_disabled", "", "Which abilities are disabled?");
	
	HookEvent("teamplay_waiting_ends", OnRoundStart, EventHookMode_Post);
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Post);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Pre);
	HookEvent("teamplay_round_stalemate", OnRoundEnd, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
	
	HookConVarChange(cVersion, cVarChange);
	HookConVarChange(cEnabled, cVarChange);
	HookConVarChange(cDuration, cVarChange);
	HookConVarChange(cGiftChance, cVarChange);
	HookConVarChange(cDropChance, cVarChange);
	HookConVarChange(cGiftDuration, cVarChange);
	HookConVarChange(cGiftCooldown, cVarChange);
	HookConVarChange(cGiftSuicide, cVarChange);
	HookConVarChange(cGiftTeam, cVarChange);
	HookConVarChange(cDisabled, cVarChange);
	
	LoadTranslations("gift.phrases");
	
	EntityArray = CreateArray();
	
	AutoExecConfig(true, "gift_mode");
}

public OnPluginEnd() {
	RemoveGift();
	for(new i = 0; i < MaxClients+1; i++) {
		ClearTimer(hCoolTimer[i]);
		ClearTimer(hDuration[i]);
		isCooldown[i] = 0;
	}
}

public OnLibraryRemoved(const String:name[]) {
	if(StrEqual(name, "gift_abilities")) {
		RemoveGift();
		for(new i = 0; i < MaxClients+1; i++) {
			ClearTimer(hCoolTimer[i]);
			ClearTimer(hDuration[i]);
			isCooldown[i] = 0;
		}
	}
}

public OnMapStart() {
	Precache();
}

public OnMapEnd() {
	RemoveGift();
	for(new i = 0; i < MaxClients+1; i++) {
		ClearTimer(hCoolTimer[i]);
		ClearTimer(hDuration[i]);
		isCooldown[i] = 0;
	}
}

public OnClientPutInServer(client) {
	isCooldown[client] = 0;
}

public OnClientDisconnect(client) {
	ClearTimer(hCoolTimer[client]);
	ClearTimer(hDuration[client]);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	CreateNative("Gift_Spawn", Native_Spawn);
	RegPluginLibrary("gift_mode");
	return APLRes_Success; 
}

public OnConfigsExecuted() {
	g_Enabled = GetConVarInt(cEnabled);
	g_Duration = GetConVarFloat(cDuration);
	g_GiftChance = GetConVarFloat(cGiftChance);
	g_DropChance = GetConVarFloat(cDropChance);
	g_GiftDuration = GetConVarFloat(cGiftDuration);
	g_GiftCooldown = GetConVarFloat(cGiftCooldown);
	g_GiftSuicide = GetConVarInt(cGiftSuicide);
	g_GiftTeam = GetConVarInt(cGiftTeam);
	GetConVarString(cDisabled, g_Disabled, sizeof(g_Disabled));
	SetupDisabledAbilities();
	isRoundActive = 1;
}

public cVarChange(Handle:convar, String:oldValue[], String:newValue[]) {
	if(StrEqual(oldValue, newValue, true)) {
		return;
	}
	new Float:iNewValue = StringToFloat(newValue);
	if(convar == cVersion) {
		SetConVarString(cVersion, PLUGIN_VERSION);
	}
	else if(convar == cEnabled) {
		g_Enabled = RoundFloat(iNewValue);
	}
	else if(convar == cDuration) {
		g_Duration = iNewValue;
	}
	else if(convar == cGiftChance) {
		g_GiftChance = iNewValue;
	}
	else if(convar == cDropChance) {
		g_DropChance = iNewValue;
	}
	else if(convar == cGiftDuration) {
		g_GiftDuration = iNewValue;
	}
	else if(convar == cGiftCooldown) {
		g_GiftCooldown = iNewValue;
	}
	else if(convar == cGiftSuicide) {
		g_GiftSuicide = RoundFloat(iNewValue);
	}
	else if(convar == cGiftTeam) {
		g_GiftTeam = RoundFloat(iNewValue);
	}
	else if(convar == cDisabled) {
		Format(g_Disabled, sizeof(g_Disabled), "%s", newValue);
		SetupDisabledAbilities();
	}
}

public Action:OnRoundStart(Handle:event, String:name[], bool:dontBroadcast) {
	isRoundActive = 1;
	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:event, String:name[], bool:dontBroadcast) {
	isRoundActive = 0;
	for(new i = 0; i < MaxClients+1; i++) {
		ClearTimer(hCoolTimer[i]);
		ClearTimer(hDuration[i]);
		isCooldown[i] = 0;
	}
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, String:name[], bool:dontBroadcast) {
	if(!g_Enabled) return Plugin_Continue;
	if(!isRoundActive) return Plugin_Continue;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(IsValidClient(victim) && IsValidClient(attacker)) {
		if(g_GiftSuicide || !g_GiftSuicide && victim != attacker) {
			if(GetRandomFloat(0.0, 1.0) <= g_DropChance) {
				decl Float:pos[3];
				GetClientAbsOrigin(victim, pos);
				SpawnGift(attacker, pos);
			}
		}
	}
	return Plugin_Continue;
}

public Native_Spawn(Handle:plugin, numparams) {
	decl Float:pos[3];
	new client = GetNativeCell(1);
	pos[0] = Float:GetNativeCell(2);
	pos[1] = Float:GetNativeCell(3);
	pos[2] = Float:GetNativeCell(4);
	new bool:success = SpawnGift(client, pos);
	if(success) return false;
	else return true;
}

bool:SpawnGift(client, Float:pos[3]) {
	if(!IsValidClient(client)) return false;
	new ent = CreateEntityByName("item_ammopack_small");
	if(IsValidEntity(ent)) {
		new TeamNum = GetClientTeam(client);
		DispatchKeyValue(ent, "powerup_model", TeamNum == _:TFTeam_Blue ? GIFT_BOX_BLUE : GIFT_BOX_RED);
		SetEntPropFloat(ent, Prop_Send, "m_flModelScale", TeamNum == _:TFTeam_Blue ? 1.0 : 0.7);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR); 
		DispatchSpawn(ent); 
		ActivateEntity(ent);
		SetEntProp(ent, Prop_Send, "m_iTeamNum", 1, 4);
		if(TE_SetupTFParticle(GIFT_CONFETTI, pos, _, _, ent, 3, 0, false)) {
			TE_SendToAll(0.0);
		}
		EmitAmbientSound(GIFT_SOUND, pos);
		SDKHook(ent, SDKHook_StartTouch, StartTouch);
		SDKHook(ent, SDKHook_SetTransmit, SetTransmit);
		PushArrayCell(EntityArray, EntIndexToEntRef(ent));
		CreateTimer(g_GiftDuration, RemoveGiftTimer, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
		return true;
	}
	return false;
}

public Action:RemoveGiftTimer(Handle:timer, any:entref) { 
	new ent = EntRefToEntIndex(entref); 
	if(IsValidEntity(ent)) {
		AcceptEntityInput(ent, "kill"); 
		new arrayIndex = FindValueInArray(EntityArray, entref);
		if(arrayIndex != -1) {
			RemoveFromArray(EntityArray, arrayIndex);
		}
	}
}

RemoveGift() {
	for(new i = 0; i < GetArraySize(EntityArray); i++) {
		new ent = EntRefToEntIndex(GetArrayCell(EntityArray, i));
		if(IsValidEntity(ent)) {
			AcceptEntityInput(ent, "kill");
		}
	}
}

public Action:StartTouch(entity, client) {
	if(!IsValidClient(client)) return Plugin_Continue;
	if(isCooldown[client]) return Plugin_Continue;
	new TeamNum = GetClientTeam(client);
	if(TeamNum == 0) return Plugin_Continue;
	if(TeamNum == 2 && g_GiftTeam == 3) return Plugin_Continue;
	if(TeamNum == 3 && g_GiftTeam == 2) return Plugin_Continue;
	if(Gift_Active(client) == false) {
		new bool:iGoodEffect;
		AcceptEntityInput(entity, "Kill");
		if(GetRandomFloat(0.0, 1.0) < g_GiftChance) {
			iGoodEffect = true;
		}
		else iGoodEffect = false;
		new iTotalGood = Gift_TotalGood();
		new iTotalBad = Gift_TotalBad();
		new iEffectNum1 = GetRandomInt(1, iTotalGood);
		new iEffectNum2 = GetRandomInt(1, iTotalBad);
		new iCount = 0;
		new iCount2 = 0;
		new iBreak = 1;
		while(iBreak) {
			if(iGoodEffect == true) {
				if(iEffectNum1 == 0) {
					if(g_iGoodDisabled[0] == 0) {
						Gift_Godmode(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum1 = 1;
					}
				}
				else if(iEffectNum1 == 1) {
					if(g_iGoodDisabled[1] == 0) {
						Gift_Toxic(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum1 = 2;
					}
				}
				else if(iEffectNum1 == 2) {
					if(g_iGoodDisabled[2] == 0) {
						Gift_Gravity(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum1 = 3;
					}
				}
				else if(iEffectNum1 == 3) {
					if(g_iGoodDisabled[3] == 0) {
						Gift_Swimming(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum1 = 4;
					}
				}
				else if(iEffectNum1 == 4) {
					if(g_iGoodDisabled[4] == 0) {
						Gift_Bumper(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum1 = 5;
					}
				}
				else if(iEffectNum1 == 5) {
					if(g_iGoodDisabled[5] == 0) {
						Gift_Scary(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum1 = 6;
					}
				}
				else if(iEffectNum1 == 6) {
					if(g_iGoodDisabled[6] == 0) {
						Gift_Knockers(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum1 = 7;
					}
				}
				else if(iEffectNum1 == 7) {
					if(g_iGoodDisabled[7] == 0) {
						Gift_Incendiary(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum1 = 8;
					}
				}
				else if(iEffectNum1 == 8) {
					if(g_iGoodDisabled[8] == 0) {
						Gift_Speed(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum1 = 9;
					}
				}
				else if(iEffectNum1 == 9) {
					if(g_iGoodDisabled[9] == 0) {
						Gift_Jump(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum1 = 0;
					}
				}
				iCount++;
				iCount2++;
				if(iCount2 == iTotalGood+iTotalBad) {
					break;
				}
				if(iCount == iTotalGood) {
					iCount = 0;
					iGoodEffect = false;
				}
				if(!iBreak) {
					SetupTranslations(client, iEffectNum1, true);
					ClearTimer(hDuration[client]);
					new Handle:pack;
					hDuration[client] = CreateDataTimer(g_Duration, DurationTimer, pack);
					WritePackCell(pack, GetClientUserId(client));
					WritePackCell(pack, iEffectNum1);
					WritePackCell(pack, true);
				}
			}
			else {
				if(iEffectNum2 == 0) {
					if(g_iBadDisabled[0] == 0) {
						Gift_Freeze(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum2 = 1;
					}
				}
				else if(iEffectNum2 == 1) {
					if(g_iBadDisabled[1] == 0) {
						Gift_Taunt(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum2 = 2;
					}
				}
				else if(iEffectNum2 == 2) {
					if(g_iBadDisabled[2] == 0) {
						Gift_Blind(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum2 = 3;
					}
				}
				else if(iEffectNum2 == 3) {
					if(g_iBadDisabled[3] == 0) {
						Gift_OneHP(client);
						iBreak = 0;
					}
					else {
						iEffectNum2 = 4;
					}
				}
				else if(iEffectNum2 == 4) {
					if(g_iBadDisabled[4] == 0) {
						Gift_Explode(client);
						iBreak = 0;
					}
					else {
						iEffectNum2 = 5;
					}
				}
				else if(iEffectNum2 == 5) {
					if(g_iBadDisabled[5] == 0) {
						Gift_Nostalgia(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum2 = 6;
					}
				}
				else if(iEffectNum2 == 6) {
					if(g_iBadDisabled[6] == 0) {
						Gift_Drug(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum2 = 7;
					}
				}
				else if(iEffectNum2 == 7) {
					if(g_iBadDisabled[7] == 0) {
						Gift_BrainDead(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum2 = 8;
					}
				}
				else if(iEffectNum2 == 8) {
					if(g_iBadDisabled[8] == 0) {
						Gift_Melee(client);
						iBreak = 0;
					}
					else {
						iEffectNum2 = 9;
					}
				}
				else if(iEffectNum2 == 9) {
					if(g_iBadDisabled[9] == 0) {
						Gift_Snail(client, g_Duration);
						iBreak = 0;
					}
					else {
						iEffectNum2 = 0;
					}
				}
				iCount++;
				iCount2++;
				if(iCount2 == iTotalGood+iTotalBad) {
					break;
				}
				if(iCount == iTotalBad) {
					iCount = 0;
					iGoodEffect = true;
				}
				if(!iBreak) {
					SetupTranslations(client, iEffectNum2, false);
					ClearTimer(hDuration[client]);
					new Handle:pack;
					hDuration[client] = CreateDataTimer(g_Duration, DurationTimer, pack);
					WritePackCell(pack, GetClientUserId(client));
					WritePackCell(pack, iEffectNum2);
					WritePackCell(pack, false);
				}
			}
		}
		if(!iBreak) {
			isCooldown[client] = 1;
			hCoolTimer[client] = CreateTimer(g_GiftCooldown+g_Duration, CooldownTimer, GetClientUserId(client));
		}
	}
	return Plugin_Continue;
}

public Action:SetTransmit(entity, client) {
	if(!IsValidClient(client)) return Plugin_Continue;
	if(isCooldown[client]) {
		return Plugin_Handled;
	}
	new TeamNum = GetClientTeam(client);
	if(g_GiftTeam == 2 && TeamNum == 3) return Plugin_Handled;
	if(g_GiftTeam == 3 && TeamNum == 2) return Plugin_Handled;
	if(g_GiftTeam == 0) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:CooldownTimer(Handle:timer, any:userId) {
	new client = GetClientOfUserId(userId);
	if(IsValidClient(client)) {
		isCooldown[client] = 0;
		hCoolTimer[client] = INVALID_HANDLE;
	}
}

public Action:DurationTimer(Handle:timer, Handle:pack) {
	if(pack != INVALID_HANDLE) {
		ResetPack(pack);
		new client = GetClientOfUserId(ReadPackCell(pack));
		new iEffectNum = ReadPackCell(pack);
		new bool:iGoodEffect = ReadPackCell(pack);
		if(IsValidClient(client)) {
			SetupEndTranslations(client, iEffectNum, bool:iGoodEffect);
			hDuration[client] = INVALID_HANDLE;
		}
	}
}

Precache() {
	PrecacheModel(GIFT_BOX_BLUE, true);
	PrecacheModel(GIFT_BOX_RED, true);
	PrecacheGeneric(GIFT_CONFETTI, true);
	PrecacheSound(GIFT_SOUND, true);
}

SetupTranslations(client, iEffectNum, bool:iGoodEffect) {
	if(iGoodEffect) {
		if(iEffectNum == 0) {
			CPrintToChat(client, "%t", "Godmode", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 1) {
			CPrintToChat(client, "%t", "Toxic", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 2) {
			CPrintToChat(client, "%t", "Gravity", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 3) {
			CPrintToChat(client, "%t", "Swimming", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 4) {
			CPrintToChat(client, "%t", "Bumper", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 5) {
			CPrintToChat(client, "%t", "Scary", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 6) {
			CPrintToChat(client, "%t", "Knockers", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 7) {
			CPrintToChat(client, "%t", "Incendiary", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 8) {
			CPrintToChat(client, "%t", "Speed", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 9) {
			CPrintToChat(client, "%t", "Jump", RoundFloat(g_Duration));
		}
	}
	else {
		if(iEffectNum == 0) {
			CPrintToChat(client, "%t", "Freeze", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 1) {
			CPrintToChat(client, "%t", "Taunt", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 2) {
			CPrintToChat(client, "%t", "Blind", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 3) {
			CPrintToChat(client, "%t", "OneHP");
		}
		else if(iEffectNum == 4) {
			CPrintToChat(client, "%t", "Explode");
		}
		else if(iEffectNum == 5) {
			CPrintToChat(client, "%t", "Nostalgia", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 6) {
			CPrintToChat(client, "%t", "Drug", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 7) {
			CPrintToChat(client, "%t", "BrainDead", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 8) {
			CPrintToChat(client, "%t", "Melee");
		}
		else if(iEffectNum == 9) {
			CPrintToChat(client, "%t", "Snail", RoundFloat(g_Duration));
		}
	}
}

SetupEndTranslations(client, iEffectNum, bool:iGoodEffect) {
	if(iGoodEffect) {
		if(iEffectNum == 0) {
			CPrintToChat(client, "%t", "Godmode_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 1) {
			CPrintToChat(client, "%t", "Toxic_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 2) {
			CPrintToChat(client, "%t", "Gravity_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 3) {
			CPrintToChat(client, "%t", "Swimming_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 4) {
			CPrintToChat(client, "%t", "Bumper_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 5) {
			CPrintToChat(client, "%t", "Scary_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 6) {
			CPrintToChat(client, "%t", "Knockers_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 7) {
			CPrintToChat(client, "%t", "Incendiary_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 8) {
			CPrintToChat(client, "%t", "Speed_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 9) {
			CPrintToChat(client, "%t", "Jump_End", RoundFloat(g_Duration));
		}
	}
	else {
		if(iEffectNum == 0) {
			CPrintToChat(client, "%t", "Freeze_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 1) {
			CPrintToChat(client, "%t", "Taunt_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 2) {
			CPrintToChat(client, "%t", "Blind_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 3) {
			//Do nothing - Just for consistency
		}
		else if(iEffectNum == 4) {
			//Do nothing - Just for consistency
		}
		else if(iEffectNum == 5) {
			CPrintToChat(client, "%t", "Nostalgia_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 6) {
			CPrintToChat(client, "%t", "Drug_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 7) {
			CPrintToChat(client, "%t", "BrainDead_End", RoundFloat(g_Duration));
		}
		else if(iEffectNum == 8) {
			//Do nothing - Just for consistency
		}
		else if(iEffectNum == 9) {
			CPrintToChat(client, "%t", "Snail_End", RoundFloat(g_Duration));
		}
	}
}

SetupDisabledAbilities() {
	decl String:sEffect[TotalAbilities][32];
	ExplodeString(g_Disabled, ",", sEffect, sizeof(sEffect), sizeof(sEffect[]));
	for(new i = 0; i < Gift_TotalGood(); i++) {
		g_iGoodDisabled[i] = 0;
	}
	for(new i = 0; i < Gift_TotalBad(); i++) {
		g_iBadDisabled[i] = 0;
	}
	for(new i = 0; i < TotalAbilities; i++) {
		if(StrEqual(sEffect[i], "godmode", false)) {
			g_iGoodDisabled[0] = 1;
		}
		else if(StrEqual(sEffect[i], "toxic", false)) {
			g_iGoodDisabled[1] = 1;
		}
		else if(StrEqual(sEffect[i], "gravity", false)) {
			g_iGoodDisabled[2] = 1;
		}
		else if(StrEqual(sEffect[i], "swimming", false)) {
			g_iGoodDisabled[3] = 1;
		}
		else if(StrEqual(sEffect[i], "bumper", false)) {
			g_iGoodDisabled[4] = 1;
		}
		else if(StrEqual(sEffect[i], "scary", false)) {
			g_iGoodDisabled[5] = 1;
		}
		else if(StrEqual(sEffect[i], "knockers", false)) {
			g_iGoodDisabled[6] = 1;
		}
		else if(StrEqual(sEffect[i], "incendiary", false)) {
			g_iGoodDisabled[7] = 1;
		}
		else if(StrEqual(sEffect[i], "speed", false)) {
			g_iGoodDisabled[8] = 1;
		}
		else if(StrEqual(sEffect[i], "jump", false)) {
			g_iGoodDisabled[9] = 1;
		}
		else if(StrEqual(sEffect[i], "freeze", false)) {
			g_iBadDisabled[0] = 1;
		}
		else if(StrEqual(sEffect[i], "taunt", false)) {
			g_iBadDisabled[1] = 1;
		}
		else if(StrEqual(sEffect[i], "blind", false)) {
			g_iBadDisabled[2] = 1;
		}
		else if(StrEqual(sEffect[i], "onehp", false)) {
			g_iBadDisabled[3] = 1;
		}
		else if(StrEqual(sEffect[i], "explode", false)) {
			g_iBadDisabled[4] = 1;
		}
		else if(StrEqual(sEffect[i], "nostalgia", false)) {
			g_iBadDisabled[5] = 1;
		}
		else if(StrEqual(sEffect[i], "drug", false)) {
			g_iBadDisabled[6] = 1;
		}
		else if(StrEqual(sEffect[i], "braindead", false)) {
			g_iBadDisabled[7] = 1;
		}
		else if(StrEqual(sEffect[i], "melee", false)) {
			g_iBadDisabled[8] = 1;
		}
		else if(StrEqual(sEffect[i], "snail", false)) {
			g_iBadDisabled[9] = 1;
		}
	}
}

bool:IsValidClient( client ) {
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client)) {
		return false; 
	}
	return true; 
}

public ClearTimer(&Handle:timer) {  
	if(timer != INVALID_HANDLE) {  
		KillTimer(timer);  
	}  
	timer = INVALID_HANDLE;  
}

stock bool:TE_SetupTFParticle(String:Name[],
            Float:origin[3] = NULL_VECTOR,
            Float:start[3] = NULL_VECTOR,
            Float:angles[3] = NULL_VECTOR,
            entindex = -1,
            attachtype = -1,
            attachpoint = -1,
            bool:resetParticles = true) {
    new tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx == INVALID_STRING_TABLE) {
        LogError("Could not find string table: ParticleEffectNames");
        return false;
    }
    // find particle index
    new String:tmp[256];
    new count = GetStringTableNumStrings(tblidx);
    new stridx = INVALID_STRING_INDEX;
    for (new i = 0; i < count; i++) {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false)) {
            stridx = i;
            break;
        }
    }
    if(stridx == INVALID_STRING_INDEX) {
        LogError("Could not find particle: %s", Name);
        return false;
    }
    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if(entindex != -1) TE_WriteNum("entindex", entindex);
    if(attachtype != -1) TE_WriteNum("m_iAttachType", attachtype);
    if(attachpoint != -1) TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);
    return true;
}