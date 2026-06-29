#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <gift>
#include <tf2attributes>

#define PLUGIN_VERSION "2.0"
#define TotalAbilities 20
#define TotalGood 10
#define TotalBad 10

#define COLOR_NORMAL		{255,255,255,255}
#define COLOR_BLACK		{200,200,200,192}
#define COLOR_INVIS		{255,255,255,0}
#define COLOR_FROZEN		{64,224,208,50}
#define COLOR_WHITE		{255,255,255,255}
#define COLOR_GREY		{128,128,128,255}
#define COLOR_RED			{255,75,75,255}
#define COLOR_BLUE		{75,75,255,255}
#define COLOR_GREEN		{0,255,0,255}

#define SLOT_PRIMARY 0
#define SLOT_SECONDARY 1
#define SLOT_MELEE 2

new Handle:cVersion = INVALID_HANDLE;
new Handle:gTimer[TotalAbilities][MAXPLAYERS+1];

new Handle:cToxicRadius = INVALID_HANDLE;
new Handle:cToxicDamage = INVALID_HANDLE;
new Handle:cGravity = INVALID_HANDLE;
new Handle:cSpeed = INVALID_HANDLE;
new Handle:cJump = INVALID_HANDLE;
new Handle:cSnail = INVALID_HANDLE;

new Float:g_ToxicRadius;
new Float:g_ToxicDamage;
new Float:g_Gravity;
new Float:g_Speed;
new Float:g_Jump;
new Float:g_Snail;

new g_Active[MAXPLAYERS+1];
new Float:g_CountTimer[MAXPLAYERS+1];
new Float:g_DrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};
new UserMsg:g_FadeUserMsgId;

enum {
	Disabled = 0,
	Godmode,
	Toxic,
	Gravity,
	Swimming,
	Bumper,
	Scary,
	Knockers,
	Incendiary,
	Speed,
	Jump,
	Freeze,
	Taunt,
	Blind,
	OneHP,
	Explode,
	Nostalgia,
	Drug,
	BrainDead,
	Melee,
	Snail
};

public Plugin:myinfo = {
	name = "[GiftMod] Gift Abilities",
	author = "Tak (chaosxk)",
	description = "Core function of GiftMod abilities.",
	version = PLUGIN_VERSION,
};

public OnPluginStart() {
	cVersion = CreateConVar("gift_abilities_version", PLUGIN_VERSION, "Gift Abilities Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cToxicRadius = CreateConVar("gift_toxic_radius", "275.0", "How big of a radius should toxic affect other players?");
	cToxicDamage = CreateConVar("gift_toxic_damage", "900.0", "How much damage should toxic do?");
	cGravity = CreateConVar("gift_gravity_multiplier", "0.1", "How much gravity?");
	cSpeed = CreateConVar("gift_speed_value", "520", "How fast should player with speed run?");
	cJump = CreateConVar("gift_jump_multiplier", "2.0", "How much higher can player jump?");
	cSnail = CreateConVar("gift_snail_value", "100", "How slow should player be?");
	
	HookConVarChange(cVersion, cVarChange);
	HookConVarChange(cToxicRadius, cVarChange);
	HookConVarChange(cToxicDamage, cVarChange);
	HookConVarChange(cGravity, cVarChange);
	HookConVarChange(cSpeed, cVarChange);
	HookConVarChange(cJump, cVarChange);
	HookConVarChange(cSnail, cVarChange);
	
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	
	g_FadeUserMsgId = GetUserMessageId("Fade");
	
	AutoExecConfig(true, "gift_abilities");
}

public OnPluginEnd() {
	for(new client = 0; client < MaxClients+1; client++) {
		RemoveEffects(client);
	}
}

public OnMapStart() {
	PrecacheKart();
}

public OnMapEnd() {
	for(new client = 0; client < MaxClients+1; client++) {
		RemoveEffects(client);
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	CreateNative("Gift_TotalGood", Native_TotalGood);
	CreateNative("Gift_TotalBad", Native_TotalBad);
	CreateNative("Gift_Remove", Native_Remove);
	CreateNative("Gift_Active", Native_Active);
	CreateNative("Gift_Godmode", Native_Godmode);
	CreateNative("Gift_Toxic", Native_Toxic);
	CreateNative("Gift_Gravity", Native_Gravity);
	CreateNative("Gift_Swimming", Native_Swimming);
	CreateNative("Gift_Bumper", Native_Bumper);
	CreateNative("Gift_Scary", Native_Scary);
	CreateNative("Gift_Knockers", Native_Knockers);
	CreateNative("Gift_Incendiary", Native_Incendiary);
	CreateNative("Gift_Speed", Native_Speed);
	CreateNative("Gift_Jump", Native_Jump);
	CreateNative("Gift_Freeze", Native_Freeze);
	CreateNative("Gift_Taunt", Native_Taunt);
	CreateNative("Gift_Blind", Native_Blind);
	CreateNative("Gift_OneHP", Native_OneHP);
	CreateNative("Gift_Explode", Native_Explode);
	CreateNative("Gift_Nostalgia", Native_Nostalgia);
	CreateNative("Gift_Drug", Native_Drug);
	CreateNative("Gift_BrainDead", Native_BrainDead);
	CreateNative("Gift_Melee", Native_Melee);
	CreateNative("Gift_Snail", Native_Snail);
	RegPluginLibrary("gift_abilities");
	return APLRes_Success; 
}

public OnConfigsExecuted() {
	g_ToxicRadius = GetConVarFloat(cToxicRadius);
	g_ToxicDamage = GetConVarFloat(cToxicDamage);
	g_Gravity = GetConVarFloat(cGravity);
	g_Speed = GetConVarFloat(cSpeed);
	g_Jump = GetConVarFloat(cJump);
	g_Snail = GetConVarFloat(cSnail);
	for(new client = 1; client <= MaxClients; client++) {
		if(IsValidClient(client)) {
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnClientPutInSever(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client) {
	RemoveEffects(client);
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public cVarChange(Handle:convar, String:oldValue[], String:newValue[]) {
	if(StrEqual(oldValue, newValue, true)) {
		return;
	}
	new Float:iNewValue = StringToFloat(newValue);
	if(convar == cVersion) {
		SetConVarString(cVersion, PLUGIN_VERSION);
	}
	else if(convar == cToxicRadius) {
		g_ToxicRadius = iNewValue;
	}
	else if(convar == cToxicDamage) {
		g_ToxicDamage = iNewValue;
	}
	else if(convar == cGravity) {
		g_Gravity = iNewValue;
	}
	else if(convar == cSpeed) {
		g_Speed = iNewValue;
	}
	else if(convar == cJump) {
		g_Jump = iNewValue;
	}
	else if(convar == cSnail) {
		g_Snail = iNewValue;
	}
}

public Action:OnRoundEnd(Handle:event, String:name[], bool:dontBroadcast) {
	for(new client = 0; client < MaxClients+1; client++) {
		RemoveEffects(client);
	}
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(victim)) return Plugin_Continue;
	RemoveEffects(victim);
	return Plugin_Continue;
}

public Native_TotalGood(Handle:plugin, numparams) {
	return TotalGood;
}

public Native_TotalBad(Handle:plugin, numparams) {
	return TotalBad;
}

public Native_Remove(Handle:plugin, numparams) {
	new client = GetNativeCell(1);
	if(IsValidClient(client)) {
		RemoveEffects(client);
	}
}

public Native_Active(Handle:plugin, numparams) {
	new client = GetNativeCell(1);
	if(!IsValidClient(client)) return true;
	if(g_Active[client] != Disabled) return true;
	return false;
}

public Native_Godmode(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Godmode;
		TF2_AddCondition(client, TFCond:5, duration);
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		gTimer[0][client] = CreateTimer(duration, Godmode_Timer, GetClientUserId(client));
		return true;
	}
	return false;
}

public Action:Godmode_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		TF2_RemoveCondition(client, TFCond:5);
		gTimer[0][client] = INVALID_HANDLE;
	}
}

public Native_Toxic(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Toxic;
		ColorizePlayer(client, COLOR_GREEN);
		g_CountTimer[client] = duration;
		gTimer[1][client] = CreateTimer(1.0, Toxic_Timer, GetClientUserId(client), TIMER_REPEAT);
	}
}

public Action:Toxic_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		if(g_CountTimer[client] == 0) {
			g_Active[client] = Disabled;
			ColorizePlayer(client, COLOR_NORMAL);
			gTimer[1][client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
		new clientTeam = GetClientTeam(client);
		for(new victim = 1; victim <= MaxClients; victim++) {
			if(IsValidClient(victim) && client != victim && clientTeam != GetClientTeam(victim)) {
				if(!TF2_IsPlayerInCondition(victim, TFCond_Ubercharged) && g_Active[victim] != Godmode) {
					decl Float:cpos[3], Float:vpos[3];
					GetClientAbsOrigin(client, cpos);
					GetClientAbsOrigin(victim, vpos);
					new Float:Distance = GetVectorDistance(cpos, vpos);
					if(Distance <= g_ToxicRadius) {
						SDKHooks_TakeDamage(victim, 0, client, g_ToxicDamage, DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH|DMG_ALWAYSGIB);
					}
				}
			}
		}
	}
	g_CountTimer[client]--;
	return Plugin_Continue;
}

public Native_Gravity(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Gravity;
		SetEntityGravity(client, g_Gravity);
		gTimer[2][client] = CreateTimer(duration, Gravity_Timer, GetClientUserId(client));
	}
}

public Action:Gravity_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		SetEntityGravity(client, 1.0);
		gTimer[2][client] = INVALID_HANDLE;
	}
}

public Native_Swimming(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Swimming;
		TF2_AddCondition(client, TFCond:86, duration);
		gTimer[3][client] = CreateTimer(duration, Swimming_Timer, GetClientUserId(client));
	}
}

public Action:Swimming_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		TF2_RemoveCondition(client, TFCond:86);
		gTimer[3][client] = INVALID_HANDLE;
	}
}

public Native_Bumper(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Bumper;
		TF2_AddCondition(client, TFCond:82, duration);
		gTimer[4][client] = CreateTimer(duration, Bumper_Timer, GetClientUserId(client));
	}
}

public Action:Bumper_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		TF2_RemoveCondition(client, TFCond:82);
		gTimer[4][client] = INVALID_HANDLE;
	}
}

public Native_Scary(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Scary;
		gTimer[5][client] = CreateTimer(duration, Scary_Timer, GetClientUserId(client));
	}
}

public Action:Scary_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		gTimer[5][client] = INVALID_HANDLE;
	}
}

public Native_Knockers(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Knockers;
		gTimer[6][client] = CreateTimer(duration, Knockers_Timer, GetClientUserId(client));
	}
}

public Action:Knockers_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		gTimer[6][client] = INVALID_HANDLE;
	}
}

public Native_Incendiary(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Incendiary;
		gTimer[7][client] = CreateTimer(duration, Incendiary_Timer, GetClientUserId(client));
	}
}

public Action:Incendiary_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		gTimer[7][client] = INVALID_HANDLE;
	}
}

public Native_Speed(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Speed;
		new Float:m_Speed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
		AddAttribute(client, "move speed bonus", g_Speed/m_Speed);
		TF2_AddCondition(client, TFCond:32, 0.01);
		new ent = AttachParticle(client, GetClientTeam(client) == _:TFTeam_Blue ? "scout_dodge_blue" : "scout_dodge_red", 75.0);
		new Handle:pack;
		gTimer[8][client] = CreateDataTimer(duration, Speed_Timer, pack);
		WritePackCell(pack, GetClientUserId(client));
		WritePackCell(pack, EntIndexToEntRef(ent));
		SetThirdPerson(client, true);
	}
}

public Action:Speed_Timer(Handle:timer, Handle:pack) {
	if(pack != INVALID_HANDLE) {
		ResetPack(pack);
		new client = GetClientOfUserId(ReadPackCell(pack));
		new ent = EntRefToEntIndex(ReadPackCell(pack));
		if(IsValidClient(client)) {
			g_Active[client] = Disabled;
			RemoveAttribute(client, "move speed bonus");
			TF2_AddCondition(client, TFCond:32, 0.01);
			if(IsValidEntity(ent)) {
				AcceptEntityInput(ent, "Kill");
			}
			SetThirdPerson(client, false);
			gTimer[8][client] = INVALID_HANDLE;
		}
	}
}

public Native_Jump(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Jump;
		AddAttribute(client, "increased jump height", g_Jump);
		gTimer[9][client] = CreateTimer(duration, Jump_Timer, GetClientUserId(client));
	}
}

public Action:Jump_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		RemoveAttribute(client, "increased jump height");
		gTimer[9][client] = INVALID_HANDLE;
	}
}

public Native_Freeze(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Freeze;
		SetEntityMoveType(client, MOVETYPE_NONE);
		ColorizePlayer(client, COLOR_INVIS);
		new ent = CreateRagdoll(client);
		if(IsValidEntity(ent)) {
			SetClientViewEntity(client, ent);
			SetThirdPerson(client, true);
		}
		new Handle:pack;
		gTimer[10][client] = CreateDataTimer(duration, Freeze_Timer, pack);
		WritePackCell(pack, GetClientUserId(client));
		WritePackCell(pack, EntIndexToEntRef(ent));
	}
}

public Action:Freeze_Timer(Handle:timer, Handle:pack) {
	if(pack != INVALID_HANDLE) {
		ResetPack(pack);
		new client = GetClientOfUserId(ReadPackCell(pack));
		new ent = EntRefToEntIndex(ReadPackCell(pack));
		if(IsValidClient(client)) {
			g_Active[client] = Disabled;
			SetClientViewEntity(client, client);
			SetEntityMoveType(client, MOVETYPE_WALK);
			ColorizePlayer(client, COLOR_NORMAL);
			SetThirdPerson(client, false);
			if(IsValidEntity(ent)) {
				AcceptEntityInput(ent, "kill");
			}
			gTimer[10][client] = INVALID_HANDLE;
		}
	}
}
		
public Native_Taunt(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Taunt;
		g_CountTimer[client] = duration;
		gTimer[11][client] = CreateTimer(1.0, Taunt_Timer, GetClientUserId(client), TIMER_REPEAT);
	}
}

public Action:Taunt_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		if(g_CountTimer[client] == 0) {
			g_Active[client] = Disabled;
			gTimer[11][client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
		FakeClientCommand(client, "taunt");
		g_CountTimer[client]--;
	}
	return Plugin_Continue;
}

public Native_Blind(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Blind;
		BlindPlayer(client, 255);
		gTimer[12][client] = CreateTimer(duration, Blind_Timer, GetClientUserId(client));
	}
}

public Action:Blind_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		BlindPlayer(client, 0);
		gTimer[12][client] = INVALID_HANDLE;
	}
}

public Native_OneHP(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		//Timer 13 unused for consistency
		SetEntProp(client, Prop_Send, "m_iHealth", 1);
	}
}

public Native_Explode(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		//Timer 14 unused for consistency
		FakeClientCommand(client, "explode");
	}
}

public Native_Nostalgia(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Nostalgia;
		SetOverlay("debug/yuv", client);
		gTimer[15][client] = CreateTimer(duration, Nostalgia_Timer, GetClientUserId(client));
	}
}

public Action:Nostalgia_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		RemoveOverlay(client);
		gTimer[15][client] = INVALID_HANDLE;
	}
}

public Native_Drug(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Drug;
		g_CountTimer[client] = duration;
		gTimer[16][client] = CreateTimer(1.0, Drug_Timer, GetClientUserId(client), TIMER_REPEAT);
	}
}

public Action:Drug_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		if(g_CountTimer[client] == 0) {
			g_Active[client] = Disabled;
			DrugPlayer(client, false);
			gTimer[16][client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
		DrugPlayer(client, true);
		g_CountTimer[client]--;
	}
	return Plugin_Continue;
}

public Native_BrainDead(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = BrainDead;
		TF2_StunPlayer(client, duration, 0.0, TF_STUNFLAGS_NORMALBONK, 0);
		TF2_AddCondition(client, TFCond:50, duration);
		gTimer[17][client] = CreateTimer(duration, BrainDead_Timer, GetClientUserId(client));
	}
}

public Action:BrainDead_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		TF2_RemoveCondition(client, TFCond:50);
		gTimer[17][client] = INVALID_HANDLE;
	}
}

public Native_Melee(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		//Timer 18 unused for consistency
		StripWeapons(client);
	}
}

public Native_Snail(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new Float:duration = GetNativeCell(2);
	if(IsValidClient(client)) {
		g_Active[client] = Snail;
		new Float:m_Speed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
		AddAttribute(client, "move speed bonus", g_Snail/m_Speed);
		TF2_AddCondition(client, TFCond:32, 0.01);
		SetThirdPerson(client, true);
		gTimer[19][client] = CreateTimer(duration, Snail_Timer, GetClientUserId(client));
	}
}

public Action:Snail_Timer(Handle:timer, any:UserId) {
	new client = GetClientOfUserId(UserId);
	if(IsValidClient(client)) {
		g_Active[client] = Disabled;
		RemoveAttribute(client, "move speed bonus");
		TF2_AddCondition(client, TFCond:32, 0.01);
		SetThirdPerson(client, false);
		gTimer[19][client] = INVALID_HANDLE;
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if(IsValidClient(attacker) && IsValidClient(victim)) {
		if(g_Active[attacker] == Scary) {
			if(attacker != victim) {
				TF2_StunPlayer(victim, 1.0, 0.0, TF_STUNFLAGS_GHOSTSCARE, 0);
			}
		}
		else if(g_Active[attacker] == Knockers) {
			new Float:aang[3], Float:vvel[3], Float:pvec[3];
			GetClientAbsAngles(attacker, aang);
			GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vvel);
			
			if (attacker == victim) {
				vvel[2] += 1000.0;
			} 
			else {
				GetAngleVectors(aang, pvec, NULL_VECTOR, NULL_VECTOR);
				vvel[0] += pvec[0] * 300.0;
				vvel[1] += pvec[1] * 300.0;
				vvel[2] = 500.0;
			}
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vvel);
		}
		else if(g_Active[attacker] == Incendiary) {
			if(attacker != victim) {
				TF2_IgnitePlayer(victim, attacker);
			}
		}
	}
}

public RemoveEffects(client) {
	if(g_Active[client] != Disabled) {
		switch(g_Active[client]) {
			case Godmode: {
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				TF2_RemoveCondition(client, TFCond:5);
				ClearTimer(gTimer[0][client]);
			}
			case Toxic: {
				SetEntityRenderColor(client, 255, 255, 255, _);
				ClearTimer(gTimer[1][client]);
			}
			case Gravity: {
				SetEntityGravity(client, 1.0);
				ClearTimer(gTimer[2][client]);
			}
			case Swimming: {
				TF2_RemoveCondition(client, TFCond:86);
				ClearTimer(gTimer[3][client]);
			}
			case Bumper: {
				TF2_RemoveCondition(client, TFCond:82);
				ClearTimer(gTimer[4][client]);
			}
			case Scary: {
				ClearTimer(gTimer[5][client]);
			}
			case Knockers: {
				ClearTimer(gTimer[6][client]);
			}
			case Incendiary: {
				ClearTimer(gTimer[7][client]);
			}
			case Speed: {
				RemoveAttribute(client, "move speed bonus");
				TF2_AddCondition(client, TFCond:32, 0.01);
				SetThirdPerson(client, false);
				new ent = -1;
				while((ent = FindEntityByClassname(ent, "info_particle_system")) != -1) {
					if(IsValidEntity(ent)) {
						decl String:name[32];
						decl String:target[32];
						GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));  
						Format(target, sizeof(target),"giftparticle%i%i", ent, client);
						if(StrEqual(name, target)) {
							AcceptEntityInput(ent, "kill");
						}
					}
				}
				ClearTimer(gTimer[8][client]);
			}
			case Jump: {
				RemoveAttribute(client, "increased jump height");
				ClearTimer(gTimer[9][client]);
			}
			case Freeze: {
				SetClientViewEntity(client, client);
				SetEntityMoveType(client, MOVETYPE_WALK);
				ColorizePlayer(client, COLOR_NORMAL);
				SetThirdPerson(client, false);
				new ent = -1;
				while((ent = FindEntityByClassname(ent, "tf_ragdoll")) != -1) {
					if(IsValidEntity(ent)) {
						decl String:name[32];
						decl String:target[32];
						GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));  
						Format(target, sizeof(target),"giftragdoll%i%i", ent, client);
						if(StrEqual(name, target)) {
							AcceptEntityInput(ent, "kill");
						}
					}
				}
				ClearTimer(gTimer[10][client]);
			}
			case Taunt: {
				ClearTimer(gTimer[11][client]);
			}
			case Blind: {
				BlindPlayer(client, 0);
				ClearTimer(gTimer[12][client]);
			}
			case OneHP: {
				//Do nothing - Just for consistency - Timer 13
			}
			case Explode: {
				//Do nothing - Just for consistency - Timer 14
			}
			case Nostalgia: {
				RemoveOverlay(client);
				ClearTimer(gTimer[15][client]);
			}
			case Drug: {
				DrugPlayer(client, false);
				ClearTimer(gTimer[16][client]);
			}
			case BrainDead: {
				TF2_RemoveCondition(client, TFCond:50);
				ClearTimer(gTimer[17][client]);
			}
			case Melee: {
				//Do nothing - Just for consistency - Timer 18
			}
			case Snail: {
				RemoveAttribute(client, "move speed bonus");
				TF2_AddCondition(client, TFCond:32, 0.01);
				SetThirdPerson(client, false);
				ClearTimer(gTimer[18][client]);
			}
		}
		g_Active[client] = Disabled;
	}
}

stock AddAttribute(client, String:attribute[], Float:value) {
	TF2Attrib_SetByName(client, attribute, value);
}

stock RemoveAttribute(client, String:attribute[]) {
	TF2Attrib_RemoveByName(client, attribute);
}

stock AttachParticle(entity, String:particleType[], Float:offset=0.0, bool:attach=true) {
	new particle=CreateEntityByName("info_particle_system");
	if(IsValidEntity(particle)) {
		decl String:targetName[32];
		decl String:partName[32];
		decl Float:position[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
		position[2]+=offset;
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

		Format(targetName, sizeof(targetName), "target%i", entity);
		DispatchKeyValue(entity, "targetname", targetName);
		
		Format(partName, sizeof(partName), "giftparticle%i%i", particle, entity);
		DispatchKeyValue(particle, "targetname", partName);
		DispatchKeyValue(particle, "parentname", targetName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(targetName);
		if(attach) {
			AcceptEntityInput(particle, "SetParent", particle, particle, 0);
			SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
		}
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
	return particle;
}

SetThirdPerson(client, bool:bEnabled) {
	if(bEnabled) SetVariantInt(1);
	else SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");
}

SetOverlay(String:overlay[], client) {
	ClientCommand(client, "r_screenoverlay \"%s.vtf\"", overlay);
}

RemoveOverlay(client) {
	ClientCommand(client, "r_screenoverlay \"\"");
}

CreateRagdoll(client) {
	new iRag = CreateEntityByName("tf_ragdoll");
	if(iRag > MaxClients && IsValidEntity(iRag)) {
		new Float:flPos[3];
		new Float:flAng[3];
		new Float:flVel[3];
		GetClientAbsOrigin(client, flPos);
		GetClientAbsAngles(client, flAng);
		
		TeleportEntity(iRag, flPos, flAng, flVel);
		decl String:ragName[32];
		Format(ragName, sizeof(ragName), "giftragdoll%i%i", iRag, client);
		DispatchKeyValue(iRag, "targetname", ragName);
		
		SetEntProp(iRag, Prop_Send, "m_iPlayerIndex", client);
		SetEntProp(iRag, Prop_Send, "m_bIceRagdoll", 1);
		SetEntProp(iRag, Prop_Send, "m_iTeam", GetClientTeam(client));
		SetEntProp(iRag, Prop_Send, "m_iClass", _:TF2_GetPlayerClass(client));
		SetEntProp(iRag, Prop_Send, "m_bOnGround", 1);
		
		SetEntityMoveType(iRag, MOVETYPE_NONE);
		
		DispatchSpawn(iRag);
		ActivateEntity(iRag);
		
		
		//if(flSelfDestruct > 0.0) CreateTimer(flSelfDestruct, Timer_DeleteParticle, EntIndexToEntRef(iRag));
		
		return iRag;
	}
	return 0;
}

DrugPlayer(client, bool:enabled) {
	new Float:flPos[3], Float:flAng[3];
	GetClientAbsOrigin(client, flPos);
	GetClientEyeAngles(client, flAng);
	if(enabled) {
		flAng[2] = g_DrugAngles[GetRandomInt(0, 100) % 20];
		TeleportEntity(client, flPos, flAng, NULL_VECTOR);
		new iClients[2];
		iClients[0] = client;
		new Handle:message = StartMessageEx(g_FadeUserMsgId, iClients, 1);
		BfWriteShort(message, 255);
		BfWriteShort(message, 255);
		BfWriteShort(message, (0x0002));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, 128);
		EndMessage();
	}
	else {
		flAng[2] = 0.0;			
		TeleportEntity(client, flPos, flAng, NULL_VECTOR);	
		new iClients[2];
		iClients[0] = client;
		new Handle:message = StartMessageEx(g_FadeUserMsgId, iClients, 1);
		BfWriteShort(message, 1536);
		BfWriteShort(message, 1536);
		BfWriteShort(message, (0x0001 | 0x0010));
		BfWriteByte(message, 0);
		BfWriteByte(message, 0);
		BfWriteByte(message, 0);
		BfWriteByte(message, 0);
		EndMessage();
	}
}

StripWeapons(client) {
	TF2_RemoveWeaponSlot(client, SLOT_PRIMARY);
	TF2_RemoveWeaponSlot(client, SLOT_SECONDARY);
	
	new iWeapon = GetPlayerWeaponSlot(client, SLOT_MELEE);
	if(iWeapon > MaxClients && IsValidEntity(iWeapon)) {
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);
	}
}

stock ColorizePlayer(client, iColor[4]) {
	SetEntityColor(client, iColor);
	for(new i=0; i<3; i++) {
		new iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon > MaxClients && IsValidEntity(iWeapon)) {
			SetEntityColor(iWeapon, iColor);
		}
	}
	
	decl String:strClass[20];
	for(new i=MaxClients+1; i<GetMaxEntities(); i++) {
		if(IsValidEntity(i)) {
			GetEdictClassname(i, strClass, sizeof(strClass));
			if((strncmp(strClass, "tf_wearable", 11) == 0 || strncmp(strClass, "tf_powerup", 10) == 0) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client) {
				SetEntityColor(i, iColor);
			}
		}
	}

	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
	if(iWeapon > MaxClients && IsValidEntity(iWeapon)) {
		SetEntityColor(iWeapon, iColor);
	}
}

stock SetEntityColor(iEntity, iColor[4]) {
	SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iEntity, iColor[0], iColor[1], iColor[2], iColor[3]);
}

stock BlindPlayer(client, iAmount) {
	new iTargets[2];
	iTargets[0] = client;
	g_FadeUserMsgId = GetUserMessageId("Fade");
	new Handle:message = StartMessageEx(g_FadeUserMsgId, iTargets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if(iAmount == 0) {
		BfWriteShort(message, (0x0001 | 0x0010));
	}
	else {
		BfWriteShort(message, (0x0002 | 0x0008));
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, iAmount);
	
	EndMessage();
}

public ClearTimer(&Handle:timer) {  
	if(timer != INVALID_HANDLE) {  
		KillTimer(timer);  
	}  
	timer = INVALID_HANDLE;  
} 

bool:IsValidClient( client ) {
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client)) {
		return false; 
	}
	return true; 
}  

stock PrecacheKart() {
	PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar.mdl", true);
	PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar_nolights.mdl", true);
	PrecacheModel("models/props_halloween/bumpercar_cage.mdl", true);

	PrecacheSound(")weapons/bumper_car_accelerate.wav");
	PrecacheSound(")weapons/bumper_car_decelerate.wav");
	PrecacheSound(")weapons/bumper_car_decelerate_quick.wav");
	PrecacheSound(")weapons/bumper_car_go_loop.wav");
	PrecacheSound(")weapons/bumper_car_hit_ball.wav");
	PrecacheSound(")weapons/bumper_car_hit_ghost.wav");
	PrecacheSound(")weapons/bumper_car_hit_hard.wav");
	PrecacheSound(")weapons/bumper_car_hit_into_air.wav");
	PrecacheSound(")weapons/bumper_car_jump.wav");
	PrecacheSound(")weapons/bumper_car_jump_land.wav");
	PrecacheSound(")weapons/bumper_car_screech.wav");
	PrecacheSound(")weapons/bumper_car_spawn.wav");
	PrecacheSound(")weapons/bumper_car_spawn_from_lava.wav");
	PrecacheSound(")weapons/bumper_car_speed_boost_start.wav");
	PrecacheSound(")weapons/bumper_car_speed_boost_stop.wav");

	decl String:szSnd[64];
	for(new i = 1; i <= 8; i++) {
		FormatEx(szSnd, sizeof(szSnd), "weapons/bumper_car_hit%i.wav", i);
		PrecacheSound(szSnd);
	}
}