#pragma semicolon 1
#define DEBUG

#define PLUGIN_AUTHOR "hiiamu"
#define PLUGIN_VERSION "2.0.0"

#define taggingcmd "200000.0"
#define DMG_FALL (1 << 5)

#include <sourcemod>
#include <cstrike>
#include <csgocolors>
#include <clientprefs>
#include <sdkhooks>
#include <sdktools>

#define chattag "[{darkred}amuHnS{default}] "

#pragma newdecls required

#define FROST_COLOR {20,63,255,255}
#define FREEZE_COLOR {20,63,255,167}

#define SOUND_UNFREEZE "physics/glass/glass_impact_bullet4.wav"
#define SOUND_FROSTNADE_EXPLODE "ui/freeze_cam.wav"

char HITMARKER_FULL_SOUND[] = "sound/hns/hitsound.wav";
char HITMARKER_RELATIVE_SOUND[] = "*hns/hitsound.wav";
char g_szGrenadeWeaponNames[][] = {
	"weapon_flashbang",
	"weapon_molotov",
	"weapon_smokegrenade",
	"weapon_hegrenade",
	"weapon_decoy",
	"weapon_incgrenade"
};

ConVar g_cvRoundStartDelay
		 , g_cvFreezeTime
		 , g_cvTGod;

bool g_bMarked[MAXPLAYERS+1]
	 , g_bFallDamage[MAXPLAYERS+1]
	 , g_bPlayerJumped[MAXPLAYERS+1]
	 , g_bPlayerOnGround[MAXPLAYERS+1]
	 , g_bLastOnGround[MAXPLAYERS+1]
	 , g_bLocked
	 , g_bWasOnLadder[MAXPLAYERS+1]
	 , g_bOnSurf[MAXPLAYERS+1]
	 , g_bAllowUnder[MAXPLAYERS+1];

Handle g_hRoundStart[MAXPLAYERS+1] = null
		 , g_hToggleKnife = INVALID_HANDLE
		 , g_hUnFreezeCT = null;

int g_iToggleKnife[MAXPLAYERS+1]
	, g_iAssister[MAXPLAYERS+1]
	, g_iGlowSprite
	, g_iBeamSprite
	, g_iHaloSprite
	, g_aNadeList[sizeof(g_szGrenadeWeaponNames)];

float g_fLastPosition[MAXPLAYERS+1][3]
		, g_fGround[MAXPLAYERS+1]
		, g_fRoundStartDelay
		, g_fFreezeTime
		, g_fTerroristImmunity;

public Plugin myinfo = {
	name = "amuHnS",
	author = "hiiamu",
	description = "hiiamu's HnS plugin",
	version = "0.1.0",
	url = "/id/hiiamu/"
};

public void OnPluginStart() {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientConnected(i) || IsClientInGame(i))
			OnClientPutInServer(i);
	}
	//Commands Admin & Players
	RegConsoleCmd("sm_restartgame", command_restartmatch, "Restart the game so we can fix stuff or something?", ADMFLAG_ROOT);
	RegAdminCmd("sm_restartmap", Command_RestartMap, ADMFLAG_CUSTOM2, "Quick restart map");
	//Bad guys trying to kill themselfs
	AddCommandListener(command_suicide, "explode");
	AddCommandListener(command_suicide, "kill");
	//Hooks
	AddCommandListener(Listener_HandleSay, "say");
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_JoinTeam, "spectate");
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_blind", OnPlayerFlash, EventHookMode_Pre);
	//Removing tagging
	ServerCommand("sm_cvar mp_tagging_scale %s", taggingcmd);

	g_cvRoundStartDelay = CreateConVar("hns_round_start_delay", "10.0", "How long CTs are stunned and Ts dont take fall damage at start of round", FCVAR_NOTIFY, true, 0.0, true, 20.0);
	g_cvFreezeTime = CreateConVar("hns_freezetime", "2.5", "How long smoke grenades stun CTs", FCVAR_NOTIFY, true, 0.0, true, 10.0);
	g_cvTGod = CreateConVar("hns_tgod", "5.0", "How long a terrorist is immune after getting stabbed by CT", FCVAR_NOTIFY, true, 0.0, true, 15.0);

	g_fRoundStartDelay = GetConVarFloat(g_cvRoundStartDelay);
	HookConVarChange(g_cvRoundStartDelay, OnSettingChanged);
	g_fFreezeTime = GetConVarFloat(g_cvFreezeTime);
	HookConVarChange(g_cvFreezeTime, OnSettingChanged);
	g_fTerroristImmunity = GetConVarFloat(g_cvTGod);
	HookConVarChange(g_cvTGod, OnSettingChanged);

	CreateTimer(0.1, DisplayHud, _, TIMER_REPEAT);
	//commands
	RegConsoleCmd("sm_toggleknife", cmdToggleKnife);
	//Cookies
	g_hToggleKnife = RegClientCookie("OurTestCookie7", "Toggle Knife Cookie", CookieAccess_Private);
	for(int i = MaxClients; i > 0; --i) {
		if(AreClientCookiesCached(i))
			OnClientPostAdminCheck(i);
	}
}

public int OnSettingChanged(ConVar convar, char[] oldValue, char[] newValue) {
	if(convar == g_cvRoundStartDelay)
		g_fRoundStartDelay = StringToFloat(newValue);
	else if(convar == g_cvFreezeTime)
		g_fFreezeTime = StringToFloat(newValue);
	else if(convar == g_cvTGod)
		g_fTerroristImmunity = StringToFloat(newValue);
}

public void OnEntityCreated(int iEntity, const char[] sClassName) {
	if(StrEqual(sClassName, "smokegrenade_projectile")) {
		SDKHook(iEntity, SDKHook_StartTouch, StartTouch_Smoke);
		SDKHook(iEntity, SDKHook_SpawnPost, SpawnPost_Smoke);

		CreateBeamFollow(iEntity, g_iBeamSprite, FROST_COLOR);
	}
}

void FakePrecacheSound(const char[] szPath) {
	AddToStringTable(FindStringTable("soundprecache"), szPath);
}

void InitPrecache() {
	AddFileToDownloadsTable(HITMARKER_FULL_SOUND);
	FakePrecacheSound(HITMARKER_RELATIVE_SOUND);
}

public Action StartTouch_Smoke(int iEntity) {
	SetEntProp(iEntity, Prop_Data, "m_nNextThinkTick", -1);

	int iRef = EntIndexToEntRef(iEntity);
	CreateTimer(1.0, SmokeDetonate, iRef);
	return Plugin_Continue;
}

public Action SmokeDetonate(Handle hTimer, any iRef) {
	int iEntity = EntRefToEntIndex(iRef);
	if(iEntity != INVALID_ENT_REFERENCE) {
		float fSmokeCoord[3];
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fSmokeCoord);
		EmitAmbientSound(SOUND_FROSTNADE_EXPLODE, fSmokeCoord, iEntity, SNDLEVEL_NORMAL);
		//fSmokeCoord[2] += 32.0;
		int iThrower = GetEntPropEnt(iEntity, Prop_Send, "m_hThrower");
		AcceptEntityInput(iEntity, "Kill");
		int ThrowerTeam = GetClientTeam(iThrower);

		for(int client = 1; client <= MaxClients; client++) {
			if(IsValidClient(iThrower)) {
				if(iThrower && IsClientInGame(client)) {
					if(GetClientTeam(client) != ThrowerTeam) {
						float targetCoord[3];
						GetClientAbsOrigin(client, targetCoord);
						if (GetVectorDistance(fSmokeCoord, targetCoord) <= 175.0)
							Freeze(client, g_fFreezeTime, iThrower);
					}
				}
			}
		}
		TE_SetupBeamRingPoint(fSmokeCoord, 10.0, 175.0 * 2, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.3, 8.0, 0.0, FROST_COLOR, 10, 0);
		TE_SendToAll();
	}
}

public Action SpawnPost_Smoke(int iEntity) {
	SetEntProp(iEntity, Prop_Data, "m_nNextThinkTick", -1);
	SetEntityRenderColor(iEntity, 20, 200, 255, 255);

	int iRef = EntIndexToEntRef(iEntity);
	CreateTimer(1.5, SmokeDetonate, iRef);
	CreateTimer(0.5, Redo_Tick, iRef);
	CreateTimer(1.0, Redo_Tick, iRef);
	CreateTimer(1.5, Redo_Tick, iRef);
	return Plugin_Continue;
}

public Action Redo_Tick(Handle hTimer, any iRef) {
	int iEntity = EntRefToEntIndex(iRef);
	if(iEntity != INVALID_ENT_REFERENCE)
		SetEntProp(iEntity, Prop_Data, "m_nNextThinkTick", -1);
}

void OnClientPostAdminCheck(int client) {
	char sCookie[2];
	GetClientCookie(client, g_hToggleKnife, sCookie, sizeof(sCookie));
	g_iToggleKnife[client] = StringToInt(sCookie);
}

public void OnServerLoad(int client) {
	//Removing tagging
	ServerCommand("sm_cvar mp_tagging_scale %s", taggingcmd);
}

public void OnMapStart() {
	InitPrecache();
	g_iGlowSprite = PrecacheModel("sprites/blueglow1.vmt");
	g_iBeamSprite = PrecacheModel("materials/sprites/physbeam.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/halo.vmt");
	PrecacheSound(SOUND_UNFREEZE);
	PrecacheSound(SOUND_FROSTNADE_EXPLODE);
	ServerCommand("sm_cvar mp_free_armor 0");
	//Removing tagging
	ServerCommand("sm_cvar mp_tagging_scale %s", taggingcmd);
	ServerCommand("sm_cvar mp_ignore_round_conditions 1");
}

// Connection messages
public void OnClientAuthorized(int client) {
	CPrintToChatAll("%s{purple}%N{lightblue} has connected.", chattag, client);
}

public void OnClientDisconnect(int client) {
	CPrintToChatAll("%s{purple}%N{lightblue} has disconnected.", chattag, client);
}

public Action Command_JoinTeam(int client, const char[] command, int args) {
	int team = GetClientTeam(client);
	char sChosenTeam[2];
	GetCmdArg(1, sChosenTeam, sizeof(sChosenTeam));
	int chosenteam = StringToInt(sChosenTeam);
	if(chosenteam == CS_TEAM_SPECTATOR) {
		PrintToChat(client, "You are not allowed to switch teams.");
		return Plugin_Handled;
	}
	if(team == CS_TEAM_CT && chosenteam == CS_TEAM_T) {
		PrintToChat(client, "You are not allowed to switch teams.");
		return Plugin_Handled;
	}
	if(team == CS_TEAM_T && chosenteam == CS_TEAM_CT) {
		PrintToChat(client, "You are not allowed to switch teams.");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Listener_HandleSay(int client, char[] Command, int argc) {
	//Console
	if(client == 0) {
		char Buffer[10246];
		GetCmdArgString(Buffer, sizeof(Buffer));
		StripQuotes(Buffer);
		TrimString(Buffer);
		CPrintToChatAll("{red}Console {white}: {blue}%s", Buffer);
		return Plugin_Handled;
	}
	//Player
	else {
		char Buffer[10246];
		GetCmdArgString(Buffer, sizeof(Buffer));
		StripQuotes(Buffer);
		TrimString(Buffer);

		//Log hidden messages:
		if(Buffer[0] == '/' || Buffer[0] == '!') LogMessage("%N :  %s", client, Buffer);

		//Hide
		if(Buffer[0] == '!') return Plugin_Handled;
		if(Buffer[0] == '/') return Plugin_Handled;
		if(Buffer[0] == '@') return Plugin_Handled;

		//CS:GO quirk - this prevents any empty chat messages:
		if(Buffer[0] == 0 || Buffer[0] <= 0) return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action RestartMapTimer(Handle timer) {
	char MapName[64];
	GetCurrentMap(MapName, sizeof(MapName));

	ForceChangeLevel(MapName, "Map Restart to Patch Updates");
	return Plugin_Handled;
}

public Action Command_RestartMap(int Client, int Args) {
	char Timer[32];
	GetCmdArg(1, Timer, sizeof(Timer));
	float Time = StringToFloat(Timer);
	CreateTimer(Time, RestartMapTimer);

	int Time2 = RoundToFloor(Time);
	CPrintToChatAll("%s {purple}Map Restart in {a}%i{purple} seconds!", chattag, Time2);

	return Plugin_Handled;
}

public Action Timer_Greet(Handle timer, any client) {
	return Plugin_Handled;
}

public Action CS_OnTerminateRound(float & delay, CSRoundEndReason & reason) {
	if (reason == CSRoundEnd_CTWin) {
		delay = 6.0;
		for (int i = 1; i <= MaxClients; i++) {
			if (IsValidClient(i)) {
				if (GetClientTeam(i) == CS_TEAM_CT)
					CS_SwitchTeam(i, CS_TEAM_T);
				else if (GetClientTeam(i) == CS_TEAM_T)
					CS_SwitchTeam(i, CS_TEAM_CT);
			}
		}
	}

	if (reason == CSRoundEnd_Draw) {
		delay = 8.0;
		reason = CSRoundEnd_TerroristWin;
		return Plugin_Changed;
	}

	if (reason == CSRoundEnd_TerroristWin) {
		delay = 6.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) {
	if(GetClientTeam(client) == CS_TEAM_CT && g_bLocked)
		return Plugin_Handled;
	if(GetClientTeam(client) == CS_TEAM_CT) {
		if (buttons & (IN_ATTACK)) {
			int ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(ActiveWeapon)) {
				char WeaponName[64];
				GetEntityClassname(ActiveWeapon, WeaponName, sizeof(WeaponName));
				if(IsWeaponKnife(WeaponName)) {
					buttons &= ~(IN_ATTACK);
					buttons |= IN_ATTACK2;
					return Plugin_Changed;
				}
			}
		}
	}
	if(!IsFakeClient(client) && IsClientInGame(client)) {
	// some stupid shit for understab detection, see OnTakeDamage
		g_bLastOnGround[client] = g_bPlayerOnGround[client];
		float origin[3];
		GetClientAbsOrigin(client, origin);
		if((GetEntityFlags(client) & FL_ONGROUND)) {
			g_bPlayerJumped[client] = false;
			g_bPlayerOnGround[client] = true;
			g_bWasOnLadder[client] = false;
			g_bOnSurf[client] = false;
		} else
			g_bPlayerOnGround[client] = false;
		if(g_bPlayerOnGround[client])
			g_fLastPosition[client] = origin;
		if(GetEntityMoveType(client) == MOVETYPE_LADDER)
			g_bWasOnLadder[client] = true;
	//falling past jump Check
		if(origin[2] < g_fLastPosition[client][2])
			g_bAllowUnder[client] = false;
	//surf check
		float vPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", vPos);
		float vMins[3];
		GetEntPropVector(client, Prop_Send, "m_vecMins", vMins);
		float vMaxs[3];
		GetEntPropVector(client, Prop_Send, "m_vecMaxs", vMaxs);
		float vEndPos[3];
		vEndPos[0] = vPos[0];
		vEndPos[1] = vPos[1];
		vEndPos[2] = vPos[2] - FindConVar("sv_maxvelocity").FloatValue;
		TR_TraceHullFilter(vPos, vEndPos, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, TraceRayDontHitSelf, client);
		if(TR_DidHit()) {
			float vPlane[3];
			TR_GetPlaneNormal(INVALID_HANDLE, vPlane);
			if(0.7 >= vPlane[2])
				g_bOnSurf[client] = true;
			g_fGround[client] = vPlane[2];
		}
	}
	return Plugin_Continue;
}

public bool TraceRayDontHitSelf(int entity, int mask, any data) {
	return entity != data && !(0 < entity <= MaxClients);
}

public Action cmdToggleKnife(int client, int args) {
	if(client > 0 && client <= MaxClients && IsClientInGame(client)) {
		int Weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEntity(Weapon))
			return Plugin_Handled;
		g_iToggleKnife[client] = g_iToggleKnife[client] == 1 ? 0 : 1;
		if(g_iToggleKnife[client] == 1) {
			PrintToChat(client, "\x01\x01[\x0BHNS\x01] You can no longer see your knife.");
			SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		}
		else if(g_iToggleKnife[client] == 0) {
			PrintToChat(client, "\x01\x01[\x0BHNS\x01] You can now see your knife.");
			SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		}
		char sCookie[2];
		IntToString(g_iToggleKnife[client], sCookie, sizeof(sCookie));
		SetClientCookie(client, g_hToggleKnife, sCookie);
	}
	return Plugin_Handled;
}

public Action OnRoundStart(Event event, const char[] name, bool dontBrodcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bMarked[client] = false;
	g_bLocked = true;
	delete g_hUnFreezeCT;
	g_hUnFreezeCT = CreateTimer(g_fRoundStartDelay, UnFreezeCT);
}

public Action UnFreezeCT(Handle timer) {
	g_hUnFreezeCT = null;
	g_bLocked = false;

	return Plugin_Handled;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client))
		return Plugin_Continue;

	g_bFallDamage[client] = false;

	RemoveNades(client);
	g_bMarked[client] = false;
	CreateTimer(0.1, RedieKnife, client);

	delete g_hRoundStart[client];
	g_hRoundStart[client] = CreateTimer(g_fRoundStartDelay, StartRound, client);

	return Plugin_Continue;
}

public Action StartRound(Handle timer, int client) {
	g_hRoundStart[client] = null;
	g_bFallDamage[client] = true;
	if(GetClientTeam(client) == CS_TEAM_T) {
		GivePlayerItem(client, "weapon_flashbang");
		GivePlayerItem(client, "weapon_smokegrenade");
		GivePlayerItem(client, "weapon_flashbang");
	}
}

public Action RedieKnife(Handle timer, int client) {
	int Weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEntity(Weapon))
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 2));
	GivePlayerItem(client, "weapon_knife");
	if(g_iToggleKnife[client] == 1)
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	else if(g_iToggleKnife[client] == 0)
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
}

bool IsWeaponKnife(const char[] WeaponName) {
	return StrContains(WeaponName, "knife", false) != -1;
}

public void OnClientPutInServer(int client) {
	//CS_TEAM_T = 0 DMG && CS_TEAM_CT = 50 DMG
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);

	g_hRoundStart[client] = null;
}

void RemoveNades(int client) {
	while(RemoveWeaponBySlot(client, 3)){}
	for(int i = 0; i < 6; i++)
		SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, g_aNadeList[i]);
}

bool RemoveWeaponBySlot(int client, int slot) {
	int entity = GetPlayerWeaponSlot(client, slot);
	if(IsValidEdict(entity)) {
		RemovePlayerItem(client, entity);
		AcceptEntityInput(entity, "Kill");
		return true;
	}
	return false;
}

public Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup) {
	if(!g_bFallDamage[victim])
		return Plugin_Handled;

	if(g_bMarked[victim] || GetClientTeam(attacker) == CS_TEAM_T || GetClientTeam(victim) == CS_TEAM_CT)
		return Plugin_Handled;

	else {
		int HealthOffset = FindSendPropInfo("CBasePlayer", "m_iHealth");
		int HealthSet = GetClientHealth(victim) - 50;
		SetHudTextParams(-1.0, 0.32, g_fTerroristImmunity, 247, 20, 20, 255, 0, 0.1, 0.1, 0.2);
		ShowHudText(victim, -1, "-50 from %N", attacker);
		ClientCommand(attacker, "play %s", HITMARKER_RELATIVE_SOUND);
		if(HealthSet < 1)
			return Plugin_Continue;
		else {
			SetEntData(victim, HealthOffset, HealthSet);
			ImmunePlayer(victim);
			return Plugin_Handled;
		}
	}
}

public Action command_restartmatch(int client, int args) {
	ServerCommand("mp_restartgame 1");
}

public Action command_suicide(int client, char[] command, int args) {
	if (IsPlayerAlive(client)) {
		CPrintToChat(client, "%sYou can't kill yourself.", chattag);
		return Plugin_Handled;
	}
	else
		CPrintToChat(client, "%sYou're already dead, nice try...", chattag);
	return Plugin_Continue;
}

public Action OnWeaponCanUse(int client, int weapon) {
	char sWeaponName[64];
	GetEntityClassname(weapon, sWeaponName, sizeof(sWeaponName));
	if(GetClientTeam(client) == CS_TEAM_T)
		return Plugin_Continue;
	else if(GetClientTeam(client) == CS_TEAM_CT && IsWeaponGrenade(sWeaponName))
		return Plugin_Handled;
	return Plugin_Continue;
}

bool IsWeaponGrenade(const char[] sWeaponName) {
	if(StrEqual("weapon_flashbang", sWeaponName) || StrEqual("weapon_smokegrenade", sWeaponName))
		return true;
	return false;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
	if(!IsValidClient(victim))
		return Plugin_Continue;
	if(!g_bFallDamage[victim])
		return Plugin_Handled;

	// NOTE FOR ANY OF THIS TO WORK YOU HAVE TO MODIFY
	// TRACEATTACK TO NOT RETRUN PLUGIN_HANDLED ATTAKCS NEVER
	// GET HERE WITH THAT IN THE WAY

	/*
	// understab detection, only uncomment if you dare
	float HeightCheck = g_fLastPosition[victim][2] - g_fLastPosition[attacker][2];
	if(attacker != 0) {
		if(GetClientTeam(victim) != GetClientTeam(attacker) && GetClientTeam(attacker) == CS_TEAM_CT) {
			if(g_bWasOnLadder[attacker] || g_bWasOnLadder[victim])
				return Plugin_Continue;
			if(g_bOnSurf[victim] || g_bOnSurf[attacker])
				return Plugin_Continue;
			if(g_fGround[victim] == g_fGround[attacker])
				return Plugin_Continue;
			if(HeightCheck > 64.0 && HeightCheck != 72.03125) {
				CPrintToChatAll("%s %N understabbed %N", chattag, attacker, victim);
				damage = 0.0;
			}
		}
	}
	// anti damage jump, doesnt worke because how i handle the float PauseTimer, can be fixed easily
	// devs feel free to fix and use
	if (damagetype == DMG_FALL && GetClientTeam(victim) == CS_TEAM_CT) {
		float PauseTime;
		if(20.0 <= damage < 30.0)
			PauseTime = 2.0;
		else if(30.0 <= damage < 40.0)
			PauseTime = 2.25;
		else if(40.0 <= damage < 50.0)
			PauseTime = 2.5;
		else if(50 >= damage)
			PauseTime = 2.75;
		float PauseTimer = GetGameTime() + PauseTime;
		int HP = GetClientHealth(victim);
		int PostHP = HP - RoundFloat(damage);
		if(PostHP <= 0)
			return Plugin_Continue;
		if (20.0 <= damage)
			PrintToChat(victim, "You took %.0f fall damage, you can not stab for %.2f seconds.", damage, PauseTime);
		int knife = GetPlayerWeaponSlot(victim, 2);
		if(IsValidEntity(knife)) {
			SetEntPropFloat(knife, Prop_Send, "m_flNextPrimaryAttack", PauseTimer);
			SetEntPropFloat(knife, Prop_Send, "m_flNextSecondaryAttack", PauseTimer);
		}
	}*/
	return Plugin_Changed;
}

//If the Player can see the other player they can see there name/team
//Client is the player viewing, Player is the player being viewed
public Action DisplayHud(Handle timer) {
	for(int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR && IsPlayerAlive(i)) {
			int target = TraceClientViewEntity(i);
			if(target > 0 && target <= MaxClients && IsValidClient(target) && IsPlayerAlive(target)) {
				SetHudTextParams(-1.0, 0.5, 1.0, 247, 255, 20, 255, 0, 6.0, 0.1, 0.2);
				ShowHudText(i, -1, "%N", target);
			}
		}
	}
}

// make t immune to knife after getting stabbed once
public void ImmunePlayer(int client) {
	if(!IsValidClient(client))
		return;
	g_bMarked[client] = true;
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 0, 137, 182, 255);

	CreateTimer(g_fTerroristImmunity, TMR_Unmark, client);
}

public Action TMR_Unmark(Handle tmr, any client) {
	if(!IsValidClient(client))
		return Plugin_Continue;
	g_bMarked[client] = false;
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, 255);

	return Plugin_Handled;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "victim"));

	if(!client || !IsClientInGame(client) || !g_iAssister[client] || !IsClientInGame(g_iAssister[client]))
		return Plugin_Continue;

	SetEventInt(event, "assister", GetClientUserId(g_iAssister[client]));
	return Plugin_Changed;
}

stock int TraceClientViewEntity(int client) {
	float m_vecOrigin[3];
	float m_angRotation[3];

	GetClientEyePosition(client, m_vecOrigin);
	GetClientEyeAngles(client, m_angRotation);

	Handle tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
	int pEntity = -1;

	if (TR_DidHit(tr)) {
		pEntity = TR_GetEntityIndex(tr);
		CloseHandle(tr);
		return pEntity;
	}

	if(tr != INVALID_HANDLE)
		CloseHandle(tr);

	return -1;
}

public bool TRDontHitSelf(int entity, int mask, any data) {
	return (1 <= entity <= MaxClients) && (entity != data);
}

public Action OnPlayerFlash(Event event, const char[] name, bool dontBrodcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = GetClientTeam(client);
	if(team == CS_TEAM_T)
		SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
	else if(team == CS_TEAM_SPECTATOR)
		SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpah", 0.5);

	return Plugin_Continue;
}

void CreateBeamFollow(int entity, int iSprite, const int iaColor[4] = {0, 0, 0, 255}) {
	TE_SetupBeamFollow(entity, iSprite, 0, 1.5, 3.0, 3.0, 2, iaColor);
	TE_SendToAll();
}

void Freeze(int client, float Duration, int attacker) {
	if(!IsValidClient)
		return;
	if(GetClientTeam(client) != CS_TEAM_CT)
		return;
	if(!IsPlayerAlive(client))
		return;
	SetEntityMoveType(client, MOVETYPE_NONE);
	float defreezetime = GetGameTime() + Duration;
	int knife = GetPlayerWeaponSlot(client, 2);
	if(IsValidEntity(knife)) {
		SetEntPropFloat(knife, Prop_Send, "m_flNextPrimaryAttack", defreezetime);
		SetEntPropFloat(knife, Prop_Send, "m_flNextSecondaryAttack", defreezetime);
	}
	float coord[3];
	GetClientEyePosition(client, coord);
	coord[2] -= 32.0;
	CreateGlowSprite(g_iGlowSprite, coord, Duration);
	LightCreate(coord, Duration);
	char AttackerName[MAX_NAME_LENGTH];
	GetClientName(attacker, AttackerName, sizeof(AttackerName));
	CPrintToChat(client, "[{green}HnS{default}] You were frozen by %s for %.1f seconds", AttackerName, Duration);

	CreateTimer(g_fFreezeTime, SmokeUnFreeze, client);
}

public Action SmokeUnFreeze(Handle timer, int client) {
	if(IsClientInGame(client)) {
		SetEntityMoveType(client, MOVETYPE_WALK);
		float faCoord[3];
		GetClientEyePosition(client, faCoord);
		EmitAmbientSound(SOUND_UNFREEZE, faCoord, client, 55);
	}
	return Plugin_Continue;
}

void CreateGlowSprite(int iSprite, const float faCoord[3], const float fDuration) {
	TE_SetupGlowSprite(faCoord, iSprite, fDuration, 2.2, 180);
	TE_SendToAll();
}

void LightCreate(const float faCoord[3], float fDuration) {
	int iEntity = CreateEntityByName("light_dynamic");
	DispatchKeyValue(iEntity, "inner_cone", "0");
	DispatchKeyValue(iEntity, "cone", "90");
	DispatchKeyValue(iEntity, "brightness", "1");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 150.0);
	DispatchKeyValue(iEntity, "pitch", "90");
	DispatchKeyValue(iEntity, "style", "1");
	DispatchKeyValue(iEntity, "_light", "20 63 255 255");
	DispatchKeyValueFloat(iEntity, "distance", 150.0);

	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, faCoord, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "TurnOn");
	CreateTimer(fDuration, DeleteEntity, iEntity, TIMER_FLAG_NO_MAPCHANGE);
}

public Action DeleteEntity(Handle hTimer, any iEntity) {
	if(IsValidEdict(iEntity))
		AcceptEntityInput(iEntity, "kill");
}

stock bool IsValidClient(int client) {
	return (0 < client <= MaxClients) && IsClientInGame(client);
}
