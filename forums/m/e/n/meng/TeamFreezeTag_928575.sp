#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define VERSION "3.1.7"
#define FREEZE_SOUND "physics/glass/glass_impact_bullet4.wav"
#define NADE_SOUND "weapons/debris3.wav"
#define BEACON_SOUND "buttons/blip1.wav"

new bool:g_bEnabled;
new UserMsg:g_umTextMsg;
new bool:g_bFrozen[MAXPLAYERS+1];
new Handle:g_hFrozenTimer[MAXPLAYERS+1];
new Handle:g_hBeaconTimer[MAXPLAYERS+1];
new g_iClientScore[MAXPLAYERS+1];
new g_iClientLevel[MAXPLAYERS+1];
new g_iClientThaws[MAXPLAYERS+1];
new g_iTotalTs;
new g_iFrozenTs;
new g_iTotalCts;
new g_iFrozenCts;
new Handle:g_hScoreTimer;
new Handle:g_CVarLevel1;
new g_iLevel1;
new Handle:g_CVarLevel2;
new g_iLevel2;
new Handle:g_CVarLevel3;
new g_iLevel3;
new Handle:g_CVarUFTime;
new Float:g_fUFTime;
new Handle:g_CVarThawsPerNade;
new g_iThawsPerNade;
new Handle:g_CVarMaxNades;
new g_iMaxNades;
new g_offsetOwnerEntity;
new g_offsetHealth;
new g_offsetAmmo;
new g_offsetVelocity0;
new g_offsetVelocity1;
new g_offsetBaseVelocity;
new const g_iBlueColor[4] = {75, 75, 255, 255};
new g_BeamSprite;
new g_HaloSprite;
new g_GlowSprite;
new bool:g_bGameOver;

public Plugin:myinfo = {

	name = "freezetag",
	author = "meng",
	version = VERSION,
	description = "friendly game of tag",
	url = ""
};

public OnPluginStart() {

	CreateConVar("teamfreezetag_version", VERSION, "Team Freeze Tag Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CVarUFTime = CreateConVar("freezetag_auto_unfreeze", "15", "Time in seconds a player is automatically unfrozen. 0 to disable.", _, true, 0.0, true, 60.0);
	g_CVarThawsPerNade = CreateConVar("freezetag_thaws_per_freeze_nade", "1", "Thaws needed to gain a freeze nade.", _, true, 1.0, true, 99.0);
	g_CVarMaxNades = CreateConVar("freezetag_max_freeze_nades", "3", "Max # of freeze nades a player can have. Players with the max # keep 1 when they are frozen.", _, true, 1.0, true, 99.0);
	g_CVarLevel1 = CreateConVar("freezetag_level_1", "10", "Score needed to reach level 1.", _, true, 1.0, true, 99.0);
	g_CVarLevel2 = CreateConVar("freezetag_level_2", "20", "Score needed to reach level 2.", _, true, 1.0, true, 99.0);
	g_CVarLevel3 = CreateConVar("freezetag_level_3", "30", "Score needed to reach level 3.", _, true, 1.0, true, 99.0);
	AutoExecConfig(true, "teamfreezetag");
	g_fUFTime = GetConVarFloat(g_CVarUFTime);
	HookConVarChange(g_CVarUFTime, CVarChange);
	g_iThawsPerNade = GetConVarInt(g_CVarThawsPerNade);
	HookConVarChange(g_CVarThawsPerNade, CVarChange);
	g_iMaxNades = GetConVarInt(g_CVarMaxNades);
	HookConVarChange(g_CVarMaxNades, CVarChange);
	g_iLevel1 = GetConVarInt(g_CVarLevel1);
	HookConVarChange(g_CVarLevel1, CVarChange);
	g_iLevel2 = GetConVarInt(g_CVarLevel2);
	HookConVarChange(g_CVarLevel2, CVarChange);
	g_iLevel3 = GetConVarInt(g_CVarLevel3);
	HookConVarChange(g_CVarLevel3, CVarChange);
	g_offsetOwnerEntity = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	g_offsetHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
	g_offsetAmmo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	g_offsetVelocity0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	g_offsetVelocity1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	g_offsetBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	g_umTextMsg = GetUserMessageId("TextMsg");
	HookUserMessage(g_umTextMsg, UserMessageHook, true);
	AddNormalSoundHook(NormalSHook:SoundsHook);
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("player_hurt", EventPlayerHurt);
	HookEvent("player_jump", EventPlayerJump, EventHookMode_Pre);
	HookEvent("hegrenade_detonate", EventHD);
	HookEvent("player_death", EventPlayerDeath);
	//AddCommandListener(CmdDrop, "drop");
	RegAdminCmd("sm_freezetag", CmdFreezeTag, ADMFLAG_RCON);
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {

	if (convar == g_CVarUFTime)
		g_fUFTime = StringToFloat(newValue);
	else if (convar == g_CVarThawsPerNade)
		g_iThawsPerNade = StringToInt(newValue);
	else if (convar == g_CVarMaxNades)
		g_iMaxNades = StringToInt(newValue);
	else if (convar == g_CVarLevel1)
		g_iLevel1 = StringToInt(newValue);
	else if (convar == g_CVarLevel2)
		g_iLevel2 = StringToInt(newValue);
	else if (convar == g_CVarLevel3)
		g_iLevel3 = StringToInt(newValue);
}

public OnMapStart() {

	if (g_bEnabled) {
		new maxent = GetMaxEntities(), String:sClassname[64];
		for (new i = MaxClients; i < maxent; i++)
			if (IsValidEdict(i) && 
			IsValidEntity(i) &&
			GetEdictClassname(i, sClassname, sizeof(sClassname)) &&
			((StrContains(sClassname, "func_bomb_target") != -1) ||
			(StrContains(sClassname, "func_hostage_rescue") != -1) ||
			(StrContains(sClassname, "func_buyzone") != -1)))
				AcceptEntityInput(i,"Disable");
	}
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_GlowSprite = PrecacheModel("sprites/blueglow2.vmt");
	PrecacheSound(FREEZE_SOUND);
	PrecacheSound(NADE_SOUND);
	PrecacheSound(BEACON_SOUND);
}

public Action:FrozenGoods(Handle:timer) {

	PrintHintTextToAll("Frozen Players: T- %i/%i CT- %i/%i", g_iFrozenTs, g_iTotalTs, g_iFrozenCts, g_iTotalCts);
}

public OnClientDisconnect(client) {

	if (g_bEnabled) {
		if (g_hFrozenTimer[client] != INVALID_HANDLE) {
			KillTimer(g_hFrozenTimer[client]);
			g_hFrozenTimer[client] = INVALID_HANDLE;
		}
		if (g_hBeaconTimer[client] != INVALID_HANDLE) {
			KillTimer(g_hBeaconTimer[client]);
			g_hBeaconTimer[client] = INVALID_HANDLE;
		}
		g_iClientScore[client] = 0;
		g_iClientLevel[client] = 0;
		g_iClientThaws[client] = 0;
		CheckFrozen();
	}
}
/*
public Action:CmdDrop(client, const String:command[], argc) {

	if (g_bEnabled)
		return Plugin_Handled;
	return Plugin_Continue;
}
*/
public Action:CmdFreezeTag(client, args) {

	if (args != 1) {
		ReplyToCommand(client, "[SM] Usage: sm_freezetag <1/0>");
		return Plugin_Handled;
	}
	new String:sArg[8];
	GetCmdArg(1, sArg, sizeof(sArg));
	if (StringToInt(sArg) == 1) {
		if (!g_bEnabled) {
			g_bEnabled = true;
			if (g_hScoreTimer == INVALID_HANDLE)
				g_hScoreTimer = CreateTimer(1.0, FrozenGoods, _, TIMER_REPEAT);
			new maxent = GetMaxEntities(), String:sClassname[64];
			for (new i = MaxClients; i < maxent; i++)
				if (IsValidEdict(i) && 
				IsValidEntity(i) &&
				GetEdictClassname(i, sClassname, sizeof(sClassname)) &&
				((StrContains(sClassname, "func_bomb_target") != -1) ||
				(StrContains(sClassname, "func_hostage_rescue") != -1) ||
				(StrContains(sClassname, "func_buyzone") != -1)))
					AcceptEntityInput(i,"Disable");
			ServerCommand("mp_restartgame 1");
		}
	}
	else if (g_bEnabled) {
		g_bEnabled = false;
		if (g_hScoreTimer != INVALID_HANDLE) {
			KillTimer(g_hScoreTimer);
			g_hScoreTimer = INVALID_HANDLE;
		}
		for (new i = 1; i <= MaxClients; i++) {
			if (g_hFrozenTimer[i] != INVALID_HANDLE) {
				KillTimer(g_hFrozenTimer[i]);
				g_hFrozenTimer[i] = INVALID_HANDLE;
			}
			if (g_hBeaconTimer[i] != INVALID_HANDLE) {
				KillTimer(g_hBeaconTimer[i]);
				g_hBeaconTimer[i] = INVALID_HANDLE;
			}
		}
		new maxent = GetMaxEntities(), String:sClassname[64];
		for (new i = MaxClients; i < maxent; i++)
			if (IsValidEdict(i) &&
			IsValidEntity(i) &&
			GetEdictClassname(i, sClassname, sizeof(sClassname)) &&
			((StrContains(sClassname, "func_bomb_target") != -1) || 
			(StrContains(sClassname, "func_hostage_rescue") != -1) ||
			(StrContains(sClassname, "func_buyzone") != -1)))
				AcceptEntityInput(i,"Enable");
		ServerCommand("mp_restartgame 1");
	}
	return Plugin_Handled;
}

Setup(client) {

	g_bFrozen[client] = false;
	SetEntData(client, g_offsetHealth, 10000484); // looks like 100 in-game. thx exvel.
	SetEntityRenderColor(client, 255, 255, 255, 255);
	if (g_iClientScore[client] < 0) {
		g_iClientScore[client] = 0;
		SetEntProp(client, Prop_Data, "m_iFrags", 0);
	}
	else
		SetEntProp(client, Prop_Data, "m_iFrags", g_iClientScore[client]);
	new pistol;
	if ((pistol = GetPlayerWeaponSlot(client, 1)) != -1) {  
		RemovePlayerItem(client, pistol);
		RemoveEdict(pistol);
	}
	FakeClientCommand(client, "use weapon_knife");
	switch (g_iClientLevel[client]) {
		case 0:
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		case 1:
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.1);
		case 2:
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.14);
		case 3:
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.18);
	}
}

Freeze(client) {

	g_bFrozen[client] = true;
	new index;
	if ((index = GetPlayerWeaponSlot(client, 2)) != -1) {  
		RemovePlayerItem(client, index);
		RemoveEdict(index);
	}
	new nadeCount = GetEntData(client, g_offsetAmmo+(11*4));
	if (nadeCount == g_iMaxNades)
		SetEntData(client, g_offsetAmmo+(11*4), 1);
	else if ((index = GetPlayerWeaponSlot(client, 3)) != -1) {  
		RemovePlayerItem(client, index);
		RemoveEdict(index);
		SetEntData(client, g_offsetAmmo+(11*4), 0);
	}
	decl Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(FREEZE_SOUND, vec, _, _, _, 0.4);
	SetEntityGravity(client, 1.0);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
	SetEntityRenderColor(client, 0, 112, 160, 112);
	if (g_fUFTime > 0.0)
		g_hFrozenTimer[client] = CreateTimer(g_fUFTime, TimerThaw, client);
	g_hBeaconTimer[client] = CreateTimer(1.0, BeaconGlow, client, TIMER_REPEAT);
	CheckFrozen();
}

UnFreeze(client) {

	g_bFrozen[client] = false;
	if (g_hFrozenTimer[client] != INVALID_HANDLE) {
		KillTimer(g_hFrozenTimer[client]);
		g_hFrozenTimer[client] = INVALID_HANDLE;
	}
	if (g_hBeaconTimer[client] != INVALID_HANDLE) {
		KillTimer(g_hBeaconTimer[client]);
		g_hBeaconTimer[client] = INVALID_HANDLE;
	}
	GivePlayerItem(client, "weapon_knife");
	decl Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound("physics/glass/glass_impact_bullet4.wav", vec, _, _, _, 0.3);
	switch (g_iClientLevel[client]) {
		case 0:
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		case 1:
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.1);
		case 2:
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.14);
		case 3:
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.18);
	}
	SetEntityRenderColor(client, 255, 255, 255, 255);
	CheckFrozen();
}

public Action:TimerThaw(Handle:timer, any:client) {

	g_hFrozenTimer[client] = INVALID_HANDLE;
	if (IsClientInGame(client) && IsPlayerAlive(client) && g_bFrozen[client])
		UnFreeze(client);
}

public Action:BeaconGlow(Handle:timer, any:client) {

	if (IsClientInGame(client) && IsPlayerAlive(client) && g_bFrozen[client]) {
		static Float:vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 47.1;
		TE_SetupGlowSprite(vec, g_GlowSprite, 1.0, 1.3, 500);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 37.7, 377.7, g_BeamSprite, g_HaloSprite, 0, 15, 0.7, 5.0, 0.0, g_iBlueColor, 10, 0);
		TE_SendToAll();
		EmitAmbientSound(BEACON_SOUND, vec, client, SNDLEVEL_RAIDSIREN, _, 0.4);
		return Plugin_Continue;
	}
	g_hBeaconTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public EventHD(Handle:event, const String:name[],bool:dontBroadcast) {

	if (g_bEnabled) {
		decl Float:vec[3];
		vec[0] = GetEventFloat(event,"x");
		vec[1] = GetEventFloat(event,"y");
		vec[2] = GetEventFloat(event,"z");
		TE_SetupGlowSprite(vec, g_GlowSprite, 0.85, 4.4, 500);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 300.0, 10.0,  g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, g_iBlueColor, 8, 0);
		TE_SendToAll();
		EmitAmbientSound(NADE_SOUND, vec, _, SNDLEVEL_RAIDSIREN, _, 0.9);
	}
}

public EventRoundStart(Handle:event,const String:name[],bool:dontBroadcast) {

	if (g_bEnabled) {
		g_bGameOver = false;
		PrintToChatAll("\x04Team FreezeTag Enabled! \x03Freeze All Enemies To Win The Round!!!");
		new maxEntities = GetMaxEntities();
		decl String:sClassname[64];
		for (new i = MaxClients; i < maxEntities; i++)
			if (IsValidEdict(i) &&
			IsValidEntity(i) &&
			GetEdictClassname(i, sClassname, sizeof(sClassname)) &&
			(StrContains(sClassname, "item_") != -1 || StrContains(sClassname, "weapon_") != -1) &&  
			GetEntDataEnt2(i, g_offsetOwnerEntity) == -1)
				RemoveEdict(i);
		CheckFrozen();
	}
}

public EventPlayerSpawn(Handle:event, const String:name[],bool:dontBroadcast) {

	if (g_bEnabled) {
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (GetClientTeam(client) > 1)
			Setup(client);
	}
}

public EventPlayerJump(Handle:event,const String:name[],bool:dontBroadcast) {

	if (g_bEnabled) {
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		switch (g_iClientLevel[client]) {
			case 1: {
				SetEntityGravity(client, 0.9);
				decl Float:vec[3];
				vec[0] = GetEntDataFloat(client, g_offsetVelocity0)*0.1/2.0;
				vec[1] = GetEntDataFloat(client, g_offsetVelocity1)*0.1/2.0;
				vec[2] = 0.8*50.0;
				SetEntDataVector(client, g_offsetBaseVelocity, vec, true);
			}
			case 2: {
				SetEntityGravity(client, 0.8);
				decl Float:vec[3];
				vec[0] = GetEntDataFloat(client, g_offsetVelocity0)*0.16/2.0;
				vec[1] = GetEntDataFloat(client, g_offsetVelocity1)*0.16/2.0;
				vec[2] = 1.0*50.0;
				SetEntDataVector(client, g_offsetBaseVelocity, vec, true);
			}
			case 3: {
				SetEntityGravity(client, 0.7);
				decl Float:vec[3];
				vec[0] = GetEntDataFloat(client, g_offsetVelocity0)*0.22/2.0;
				vec[1] = GetEntDataFloat(client, g_offsetVelocity1)*0.22/2.0;
				vec[2] = 1.2*50.0;
				SetEntDataVector(client, g_offsetBaseVelocity, vec, true);
			}
		}
	}
}

public EventPlayerHurt(Handle:event, const String:name[],bool:dontBroadcast) {

	if (g_bEnabled) {
		new victim = GetClientOfUserId(GetEventInt(event,"userid"));
		new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
		new damage = GetEventInt(event, "dmg_health");
		static String:sWeapon[32];
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
		SetEntData(victim, g_offsetHealth, 10000484);
		if (attacker != 0) {
			new victimTeam = GetClientTeam(victim);
			new attackerTeam = GetClientTeam(attacker);
			if (!g_bFrozen[victim] && (victimTeam != attackerTeam) && (damage > 35)) {
				Freeze(victim);
				ClientLevelCheck(victim, g_iClientScore[victim] > 0 ? --g_iClientScore[victim] : 0);
				switch (ClientLevelCheck(attacker, ++g_iClientScore[attacker])) {
					case 1: {
						SetEntPropFloat(attacker, Prop_Data, "m_flLaggedMovementValue", 1.1);
						PrintToChatAll("\x03%N \x04has reached Level 1!", attacker);
					}
					case 2: {
						SetEntPropFloat(attacker, Prop_Data, "m_flLaggedMovementValue", 1.14);
						PrintToChatAll("\x03%N \x04has reached Level 2!", attacker);
					}
					case 3: {
						SetEntPropFloat(attacker, Prop_Data, "m_flLaggedMovementValue", 1.18);
						PrintToChatAll("\x03%N \x04has reached Level 3!", attacker);
					}
				}
			}
			else if (g_bFrozen[victim] && (victimTeam == attackerTeam)) {
				if (!StrEqual(sWeapon, "hegrenade")) {
					UnFreeze(victim);
					if (++g_iClientThaws[attacker] >= g_iThawsPerNade) {
						new nadeCount = GetEntData(attacker, g_offsetAmmo+(11*4));
						if (GetPlayerWeaponSlot(attacker, 3) == -1)
							GivePlayerItem(attacker, "weapon_hegrenade");
						if (nadeCount < g_iMaxNades)
							SetEntData(attacker, g_offsetAmmo+(11*4), nadeCount+1);
						g_iClientThaws[attacker] = 0;
					}
				}
				else if (victim == attacker) {
					UnFreeze(victim);
					return;
				}
				switch (ClientLevelCheck(attacker, ++g_iClientScore[attacker])) {
					case 1: {
						SetEntPropFloat(attacker, Prop_Data, "m_flLaggedMovementValue", 1.1);
						PrintToChatAll("\x03%N \x04has reached Level 1!", attacker);
					}
					case 2: {
						SetEntPropFloat(attacker, Prop_Data, "m_flLaggedMovementValue", 1.14);
						PrintToChatAll("\x03%N \x04has reached Level 2!", attacker);
					}
					case 3: {
						SetEntPropFloat(attacker, Prop_Data, "m_flLaggedMovementValue", 1.18);
						PrintToChatAll("\x03%N \x04has reached Level 3!", attacker);
					}
				}
			}
		}
	}
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast) {

	if (g_bEnabled) {
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (g_hFrozenTimer[client] != INVALID_HANDLE) {
			KillTimer(g_hFrozenTimer[client]);
			g_hFrozenTimer[client] = INVALID_HANDLE;
		}
		Dissolve(client);
		CheckFrozen();
	}
}

public Action:UserMessageHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) {

	if (g_bEnabled) {
		decl String:message[256];
		BfReadString(bf, message, sizeof(message));
		if (StrContains(message, "teammate_attack") != -1)
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:SoundsHook(clients[64],&numClients,String:sample[PLATFORM_MAX_PATH],&entity,&channel,&Float:volume,&level,&pitch,&flags) {

	if (g_bEnabled) {
		if ((StrContains(sample, "hegrenade/explode") != -1) ||
		(StrContains(sample, "player/death") != -1))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

Dissolve(client) {

	if (!IsValidEntity(client) || IsPlayerAlive(client))
		return;
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll<0)
		return;
	new String:dname[32], String:dtype[32];
	Format(dname, sizeof(dname), "dis_%d", client);
	Format(dtype, sizeof(dtype), "%d", 2);
	new ent = CreateEntityByName("env_entity_dissolver");
	if (ent != -1) {
		DispatchKeyValue(ragdoll, "targetname", dname);
		DispatchKeyValue(ent, "dissolvetype", dtype);
		DispatchKeyValue(ent, "target", dname);
		AcceptEntityInput(ent, "Dissolve");
		AcceptEntityInput(ent, "kill");
	}
}

ClientLevelCheck(client, clientScore) {

	SetEntProp(client, Prop_Data, "m_iFrags", clientScore);
	if (clientScore < g_iLevel1) {
		g_iClientLevel[client] = 0;
		return 0;
	}
	if (clientScore < g_iLevel2) {
		g_iClientLevel[client] = 1;
		if (clientScore == g_iLevel1)
			return 1;
		return 0;
	}
	if (clientScore < g_iLevel3) {
		g_iClientLevel[client] = 2;
		if (clientScore == g_iLevel2)
			return 2;
		return 0;
	}
	g_iClientLevel[client] = 3;
	if (clientScore == g_iLevel3)
		return 3;
	return 0;
}

CheckFrozen() {

	g_iTotalTs = 0;
	g_iFrozenTs = 0;
	g_iTotalCts = 0;
	g_iFrozenCts = 0;
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			switch (GetClientTeam(i)) {
				case 2: {
				g_iTotalTs++;
				if (g_bFrozen[i])
					g_iFrozenTs++;
				}
				case 3: {
				g_iTotalCts++;
				if (g_bFrozen[i])
					g_iFrozenCts++;
				}
			}
		}
	}
	if (!g_bGameOver)
		WinCheck();
}

WinCheck() {

	if (g_iTotalTs <= g_iFrozenTs) {
		g_bGameOver = true;
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && IsPlayerAlive(i)) {
				switch (GetClientTeam(i)) {
					case 2:
						ForcePlayerSuicide(i);
					case 3:
						if (g_bFrozen[i])
							UnFreeze(i);
				}
			}
		}
		PrintToChatAll("\x03All \x04Terrorists \x03Have Been \x04Frozen!!!");
	}
	else if (g_iTotalCts <= g_iFrozenCts) {
		g_bGameOver = true;
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && IsPlayerAlive(i)) {
				switch (GetClientTeam(i)) {
					case 2:
						if (g_bFrozen[i])
							UnFreeze(i);
					case 3:
						ForcePlayerSuicide(i);
				}
			}
		}
		PrintToChatAll("\x03All \x04Counter-Terrorists \x03Have Been \x04Frozen!!!");
	}
}