
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <colorlib>

#define FFADE_IN			0x0001		// Just here so we don't pass 0 into the function
#define FFADE_OUT			0x0002		// Fade out (not in)
#define FFADE_MODULATE		0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE			0x0010		// Purges all other fades, replacing them with this one

enum struct ConVarlist {
	bool iAfkKillEnable
	bool bPingCheckEnable;
	bool bAntiCampEnable;
	bool bPingFlagEnable;
	bool bAntiCampFlagEnable;
	bool bAntiCampInSpeed
	bool bAntiCampMatchmaking;
	bool bAntiCampUncheckKnife;
	int iAfkFlag;
	int iPingFlag;
	int iAntiCampFlag;
	int iAfkKickMin;
	int iPingChecks;
	int iPingMaxPing;
	int iAfkFlagEnable;
	int iAntiCampMinHealth;
	int iAntiCampPunishment;
	int iAntiCampSlapHealth;
	float fAfkMove;
	float fAfkKick;
	float fCalcTime;
	float fCalcTimeWarn;
	float fAfkOriginThreshold;
	float fAntiCampRadius;
	float fAntiCampInterval;
	char szSoundWarn[PLATFORM_MAX_PATH];
	char szTag[PLATFORM_MAX_PATH];
}
ConVarlist g_aConVarlist;

enum struct PlayerChecks_s {
	int iPingClient;
	int iPingCheckFail;
	float fOldAngles[3]; // Roll, Yaw, Pitch
	float fOldPos[3]; // X, Y, Z
	float fAfkCheckTime;
	float fAntiCampCheckTime;
}
PlayerChecks_s g_aPlayerCheks[MAXPLAYERS + 1];

enum struct OtherVals {
	int m_hActiveWeapon;
	bool bSwapCampTeam;
	bool bMapHasBombTarget;
	bool bMapHasRescueZone;
}
OtherVals g_aOtherVals;

public Plugin myinfo =  {
	name = "Player checker afk/ping/camp (mmcs.pro)",
	author = "SAZONISCHE",
	description = "",
	version = "3.5",
	url = "mmcs.pro",
};

public void OnPluginStart() {
	EngineVersion iEngineVersion = GetEngineVersion();
	switch (iEngineVersion) {
		case Engine_CSGO: LogMessage("Player checker Init CS:GO");
		case Engine_CSS: LogMessage("Player checker Init CSS");
		case Engine_SourceSDK2006: LogMessage("Player checker Init SourceSDK2006");
		default: SetFailState("This plugin is for CSGO/CSS only.");
	}

	g_aOtherVals.m_hActiveWeapon = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon")
	if (g_aOtherVals.m_hActiveWeapon == -1)
		SetFailState("Failed to obtain offset: \"m_hActiveWeapon\"!");

	ConVar CVAR;
	(CVAR = CreateConVar("sm_pc_check_interval", "5.0", "After how many seconds to check afk/png/camp the player.", FCVAR_NOTIFY, true, 0.0)).AddChangeHook(CVarChange_CalcTime);
	CVarChange_CalcTime(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_warn_interval", "15.0", "Time to show warining message.", FCVAR_NOTIFY, true, 0.0)).AddChangeHook(CVarChange_CalcTimeWarn);
	CVarChange_CalcTimeWarn(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_warn_sound", "ui/menu_invalid.wav", "User warn sound", FCVAR_NOTIFY)).AddChangeHook(CVarChange_SoundWarn);
	CVarChange_SoundWarn(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_plugin_tag", "[{lightgreen}Player Checker{default}] ", "Plugin tag", FCVAR_NOTIFY)).AddChangeHook(CVarChange_Tag);
	CVarChange_Tag(CVAR, NULL_STRING, NULL_STRING);

	(CVAR = CreateConVar("sm_pc_afk_move_interval", "40.0", "After how many seconds to move spec the player.", FCVAR_NOTIFY, true, 0.0)).AddChangeHook(CVarChange_AfkMove);
	CVarChange_AfkMove(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_afk_origin_threshold", "40.0", "The distance (units) that the player must go to remove checks.", FCVAR_NOTIFY, true, 0.0)).AddChangeHook(CVarChange_AfkOriginThreshold);
	CVarChange_AfkOriginThreshold(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_afk_kick_interval", "290.0", "After how many seconds to delete the player.", FCVAR_NOTIFY, true, 0.0)).AddChangeHook(CVarChange_AfkKick);
	CVarChange_AfkKick(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_afk_kick_min_players", "10", "Minimum number of players to kick.", FCVAR_NOTIFY, true, 0.0)).AddChangeHook(CVarChange_AfkKickMin);
	CVarChange_AfkKickMin(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_afk_immune_enable", "2", "Immunity afk: 1 kick, 2 move and kick. Set 0 to disable.", FCVAR_NOTIFY, true, 0.0, true, 2.0)).AddChangeHook(CVarChange_AfkFlagEnable);
	CVarChange_AfkFlagEnable(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_afk_force_kill", "0", "Kill all afk: 1, Only last player kill: 0.", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChange_AfkKillEnable);
	CVarChange_AfkKillEnable(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_afk_immune_flag", "p", "Flag for afk immunity (example: 'pza')", FCVAR_NOTIFY)).AddChangeHook(CVarChange_AfkFlag);
	CVarChange_AfkFlag(CVAR, NULL_STRING, NULL_STRING);

	(CVAR = CreateConVar("sm_pc_ping_check_enable", "1", "Set 0 to disable ping check.", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChange_PingCheckEnable);
	CVarChange_PingCheckEnable(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_ping_max_ping", "150", "Max ping allowed.", FCVAR_NOTIFY, true, 0.0)).AddChangeHook(CVarChange_PingMaxPing);
	CVarChange_PingMaxPing(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_ping_max_checks", "10", "Number of max checks ping after kick.", FCVAR_NOTIFY, true, 0.0)).AddChangeHook(CVarChange_PingChecks);
	CVarChange_PingChecks(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_ping_immune_enable", "1", "Set 0 to disable immunity ping.", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChange_PingFlagEnable);
	CVarChange_PingFlagEnable(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_ping_immune_flag", "p", "Flag for ping immunity (example: 'pza')", FCVAR_NOTIFY)).AddChangeHook(CVarChange_PingFlag);
	CVarChange_PingFlag(CVAR, NULL_STRING, NULL_STRING);

	(CVAR = CreateConVar("sm_pc_anticamp_enable", "1", "Set 0 to disable anticamp.", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChange_AntiCampEnable);
	CVarChange_AntiCampEnable(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_anticamp_radius", "130.0", "The distance (units) to check for camping.", FCVAR_NOTIFY, true, 0.0)).AddChangeHook(CVarChange_AntiCampRadius);
	CVarChange_AntiCampRadius(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_anticamp_interval", "30.0", "The amount of times a suspected camper is checked for", FCVAR_NOTIFY, true, 2.0)).AddChangeHook(CVarChange_AntiCampInterval);
	CVarChange_AntiCampInterval(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_anticamp_minhealth", "10", "The amount of health that should not be penalized. Set to 0 to ignore the parameter.", FCVAR_NOTIFY, true, 0.0, true, 100.0)).AddChangeHook(CVarChange_AntiCampMinHealth);
	CVarChange_AntiCampMinHealth(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_anticamp_punishment_type", "0", "The camp punishment type. (0 = Fade, 1 = Kill, 2 = Slap)", FCVAR_NOTIFY, true, 0.0, true, 2.0)).AddChangeHook(CVarChange_AntiCampPunishment);
	CVarChange_AntiCampPunishment(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_anticamp_immune_enable", "1", "Set 0 to disable immunity anticamp.", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChange_AntiCampFlagEnable);
	CVarChange_AntiCampFlagEnable(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_anticamp_immune_flag", "p", "Flag for anticamp immunity (example: 'pza')", FCVAR_NOTIFY)).AddChangeHook(CVarChange_AntiCampFlag);
	CVarChange_AntiCampFlag(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_anticamp_in_speed", "0", "Set 0 to disable check shift.", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChange_AntiCampInSpeed);
	CVarChange_AntiCampInSpeed(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_anticamp_matchmaking", "1", "Set 0 to enable checks of all commands permanently.", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChange_AntiCampMatchmaking);
	CVarChange_AntiCampMatchmaking(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_anticamp_check_knife", "1", "Set it to 0 to disable checking the knife in the player hands.", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChange_AntiCampUncheckKnife);
	CVarChange_AntiCampUncheckKnife(CVAR, NULL_STRING, NULL_STRING);
	(CVAR = CreateConVar("sm_pc_anticamp_slaphealth", "5", "How much damage to inflict when punishing through a slap. Set to 0 to ignore the parameter.", FCVAR_NOTIFY, true, 0.0, true, 1000.0)).AddChangeHook(CVarChange_AntiCampSlapHealth);
	CVarChange_AntiCampSlapHealth(CVAR, NULL_STRING, NULL_STRING);

	LoadTranslations("player_checker.phrases");
	AutoExecConfig(true, "player_checker");

	HookEvent("player_spawn", Event_PlayerSpawn);
	if(iEngineVersion == Engine_CSGO)
		HookEvent("player_spawned", Event_PlayerSpawn); // warmup fix
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("bomb_planted",  Event_BombPlanted);
}

public void CVarChange_CalcTime(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.fCalcTime = convar.FloatValue;}
public void CVarChange_CalcTimeWarn(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.fCalcTimeWarn = convar.FloatValue;}
public void CVarChange_SoundWarn(ConVar convar, const char[] oldValue, const char[] newValue) {convar.GetString(g_aConVarlist.szSoundWarn, sizeof(g_aConVarlist.szSoundWarn));}
public void CVarChange_Tag(ConVar convar, const char[] oldValue, const char[] newValue) {convar.GetString(g_aConVarlist.szTag, sizeof(g_aConVarlist.szTag));}

public void CVarChange_AfkMove(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.fAfkMove = convar.FloatValue;}
public void CVarChange_AfkOriginThreshold(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.fAfkOriginThreshold = convar.FloatValue;}
public void CVarChange_AfkKick(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.fAfkKick = convar.FloatValue;}
public void CVarChange_AfkKickMin(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.iAfkKickMin = convar.IntValue;}
public void CVarChange_AfkFlagEnable(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.iAfkFlagEnable = convar.IntValue;}
public void CVarChange_AfkKillEnable(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.iAfkKillEnable = convar.BoolValue;}
public void CVarChange_AfkFlag(ConVar convar, const char[] oldValue, const char[] newValue) {char szBuff[16]; convar.GetString(szBuff, sizeof(szBuff)); g_aConVarlist.iAfkFlag = ReadFlagString(szBuff);}

public void CVarChange_PingCheckEnable(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.bPingCheckEnable = convar.BoolValue;}
public void CVarChange_PingMaxPing(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.iPingMaxPing = convar.IntValue;}
public void CVarChange_PingChecks(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.iPingChecks = convar.IntValue;}
public void CVarChange_PingFlagEnable(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.bPingFlagEnable = convar.BoolValue;}
public void CVarChange_PingFlag(ConVar convar, const char[] oldValue, const char[] newValue) {char szBuff[16]; convar.GetString(szBuff, sizeof(szBuff)); g_aConVarlist.iPingFlag = ReadFlagString(szBuff);}

public void CVarChange_AntiCampEnable(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.bAntiCampEnable = convar.BoolValue;}
public void CVarChange_AntiCampRadius(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.fAntiCampRadius = convar.FloatValue;}
public void CVarChange_AntiCampInterval(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.fAntiCampInterval = convar.FloatValue;}
public void CVarChange_AntiCampMinHealth(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.iAntiCampMinHealth = convar.IntValue;}
public void CVarChange_AntiCampPunishment(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.iAntiCampPunishment = convar.IntValue;}
public void CVarChange_AntiCampFlagEnable(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.bAntiCampFlagEnable = convar.BoolValue;}
public void CVarChange_AntiCampFlag(ConVar convar, const char[] oldValue, const char[] newValue) {char szBuff[16]; convar.GetString(szBuff, sizeof(szBuff)); g_aConVarlist.iAntiCampFlag = ReadFlagString(szBuff);}
public void CVarChange_AntiCampInSpeed(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.bAntiCampInSpeed = convar.BoolValue;}
public void CVarChange_AntiCampMatchmaking(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.bAntiCampMatchmaking = convar.BoolValue;}
public void CVarChange_AntiCampUncheckKnife(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.bAntiCampUncheckKnife = convar.BoolValue;}
public void CVarChange_AntiCampSlapHealth(ConVar convar, const char[] oldValue, const char[] newValue) {g_aConVarlist.iAntiCampSlapHealth = convar.IntValue;}

public void OnMapStart() {
	PrepareSound(g_aConVarlist.szSoundWarn);
	CreateTimer(g_aConVarlist.fCalcTime, TimerCheckAfk, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	g_aOtherVals.bMapHasBombTarget = view_as<bool>(GameRules_GetProp("m_bMapHasBombTarget"));
	g_aOtherVals.bMapHasRescueZone = view_as<bool>(GameRules_GetProp("m_bMapHasRescueZone"));
}

public void OnClientPostAdminCheck(int client) {
	if(IsValidClient(client)) {
		g_aPlayerCheks[client].iPingClient = g_aPlayerCheks[client].iPingCheckFail = 0;
		g_aPlayerCheks[client].fAfkCheckTime = g_aPlayerCheks[client].fAntiCampCheckTime = 0.0;
	}
}

public void Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast) {
	int client 	= GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
		g_aPlayerCheks[client].fAfkCheckTime = g_aPlayerCheks[client].fAntiCampCheckTime = 0.0;
}

public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client) && IsPlayerAlive(client))
		CreateTimer(0.100, SpawnTimerInfo, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action SpawnTimerInfo(Handle timer, any client) {
	if(IsValidClient(client) && IsPlayerAlive(client)) {
		GetClientEyeAngles(client, g_aPlayerCheks[client].fOldAngles);
		GetClientAbsOrigin(client, g_aPlayerCheks[client].fOldPos);
		g_aPlayerCheks[client].fAntiCampCheckTime = 0.0;
	}
}

public void Event_BombPlanted(Handle event, const char[] name, bool dontBroadcast) {
	g_aOtherVals.bSwapCampTeam = true;
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast) {
	RequestFrame(RoundStartPost);

	if(g_aOtherVals.bMapHasBombTarget) 
		g_aOtherVals.bSwapCampTeam = false;
	else if(g_aOtherVals.bMapHasRescueZone)
		g_aOtherVals.bSwapCampTeam = true;
	else 
		g_aConVarlist.bAntiCampMatchmaking = false;
}

void RoundStartPost() {
	for(int client = 1; client <= MaxClients; client++) {
		if(IsValidClient(client) && IsPlayerAlive(client)) {
			GetClientEyeAngles(client, g_aPlayerCheks[client].fOldAngles);
			GetClientAbsOrigin(client, g_aPlayerCheks[client].fOldPos);
			g_aPlayerCheks[client].fAntiCampCheckTime = 0.0;
		}
	}
}

public Action TimerCheckAfk(Handle timer, any data) {
	float fGetAngles[3], fGetPos[3], fAfkCalcTime, fAntiCampCalcTime; int iClientButtons; bool iFakeAnglesGet;

	for (int client = 1; client <= MaxClients; client++) {
		if (IsValidClient(client)) {
			if (IsPlayerAlive(client) && !(GetEntityFlags(client) & FL_FROZEN) && (GetEntityFlags(client) & FL_ONGROUND) && !GameRules_GetProp("m_bFreezePeriod")) {
				fGetAngles = g_aPlayerCheks[client].fOldAngles;
				fGetPos = g_aPlayerCheks[client].fOldPos;

				GetClientEyeAngles(client, g_aPlayerCheks[client].fOldAngles);
				GetClientAbsOrigin(client, g_aPlayerCheks[client].fOldPos);

				iClientButtons = GetClientButtons(client)
				iFakeAnglesGet = (g_aPlayerCheks[client].fOldAngles[0] == fGetAngles[0] && g_aPlayerCheks[client].fOldAngles[1] == fGetAngles[1]) || (iClientButtons & (IN_LEFT|IN_RIGHT) != 0);
				if (iFakeAnglesGet && (GetVectorDistance(g_aPlayerCheks[client].fOldPos, fGetPos) < g_aConVarlist.fAfkOriginThreshold) && (g_aConVarlist.iAfkFlagEnable != 2 || !(GetUserFlagBits(client) & g_aConVarlist.iAfkFlag))) {
					g_aPlayerCheks[client].fAfkCheckTime += g_aConVarlist.fCalcTime;
					fAfkCalcTime = g_aConVarlist.fAfkMove - g_aPlayerCheks[client].fAfkCheckTime;
					if(fAfkCalcTime <= g_aConVarlist.fCalcTimeWarn) {
						if(g_aPlayerCheks[client].fAfkCheckTime >= g_aConVarlist.fAfkMove) {
							CPrintToChatAll("%s%t", g_aConVarlist.szTag, "AFK Announce Spec", client);
							if(g_aConVarlist.iAfkKillEnable || GetPlayerCountEx(client, true, true, true) == 1)
								FakeClientCommand(client, "explode"); // round end fix
							ChangeClientTeam(client, CS_TEAM_SPECTATOR);
						} else {
							CPrintToChat(client, "%s%t", g_aConVarlist.szTag, "AFK Warning Spec", fAfkCalcTime);
							EmitSoundToClient(client, g_aConVarlist.szSoundWarn, SOUND_FROM_PLAYER, SNDCHAN_BODY, 0, SND_NOFLAGS, 1.0, 100, _, NULL_VECTOR, NULL_VECTOR, true);
							g_aPlayerCheks[client].fAntiCampCheckTime = 0.0;
						}
					}
				} else {
					g_aPlayerCheks[client].fAfkCheckTime = 0.0;
				}

				if (g_aConVarlist.bAntiCampEnable && g_aPlayerCheks[client].fAfkCheckTime == 0.0 && (!g_aConVarlist.bAntiCampInSpeed || !(iClientButtons & IN_SPEED)) && (!g_aConVarlist.bAntiCampFlagEnable || !(GetUserFlagBits(client) & g_aConVarlist.iAntiCampFlag)) && (!g_aConVarlist.bAntiCampMatchmaking || (GetClientTeam(client) == (g_aOtherVals.bSwapCampTeam ? CS_TEAM_CT : CS_TEAM_T)))) {
					int iActWeapon;
					if ((GetVectorDistance(g_aPlayerCheks[client].fOldPos, fGetPos) < g_aConVarlist.fAntiCampRadius) && (!g_aConVarlist.bAntiCampUncheckKnife || (IsValidEntity(iActWeapon = GetEntDataEnt2(client, g_aOtherVals.m_hActiveWeapon)) && !IsWeaponKnife(iActWeapon)))) {
						g_aPlayerCheks[client].fAntiCampCheckTime += g_aConVarlist.fCalcTime;
						fAntiCampCalcTime = g_aConVarlist.fAntiCampInterval - g_aPlayerCheks[client].fAntiCampCheckTime;
						if(fAntiCampCalcTime <= g_aConVarlist.fCalcTimeWarn) {
							if(g_aPlayerCheks[client].fAntiCampCheckTime >= g_aConVarlist.fAntiCampInterval) {
								if(GetClientHealth(client) >= g_aConVarlist.iAntiCampMinHealth) {
									switch(g_aConVarlist.iAntiCampPunishment) {
										case 0: {
											Client_ScreenFade(client, RoundToFloor(g_aConVarlist.fCalcTime*1000), FFADE_IN, 0, 66, 105, 158, 210);
											CPrintToChat(client, "%s%t", g_aConVarlist.szTag, "CAMP Fade Punished Message", g_aConVarlist.fAntiCampRadius);
										}
										case 1:	ForcePlayerSuicide(client);
										case 2:	SlapPlayer(client, g_aConVarlist.iAntiCampSlapHealth, true);
									}
								}
							} else {
								CPrintToChat(client, "%s%t", g_aConVarlist.szTag, "CAMP Warning Message", fAntiCampCalcTime);
								EmitSoundToClient(client, g_aConVarlist.szSoundWarn, SOUND_FROM_PLAYER, SNDCHAN_BODY, 0, SND_NOFLAGS, 1.0, 100, _, NULL_VECTOR, NULL_VECTOR, true);
							}
						}
					} else {
						g_aPlayerCheks[client].fAntiCampCheckTime = 0.0;
					}
				}

			} else if (GetClientTeam(client) <= CS_TEAM_SPECTATOR && (!g_aConVarlist.iAfkFlagEnable || !(GetUserFlagBits(client) & g_aConVarlist.iAfkFlag)) && GetPlayerCountEx(client, false, false, false) >= g_aConVarlist.iAfkKickMin) {
				g_aPlayerCheks[client].fAfkCheckTime += g_aConVarlist.fCalcTime;
				fAfkCalcTime = g_aConVarlist.fAfkKick - g_aPlayerCheks[client].fAfkCheckTime;
				if(fAfkCalcTime <= g_aConVarlist.fCalcTimeWarn) {
					if(g_aPlayerCheks[client].fAfkCheckTime >= g_aConVarlist.fAfkKick) {
						CPrintToChatAll("%s%t", g_aConVarlist.szTag, "AFK Announce Kick", client);
						KickClientEx(client, "%t", "AFK Message Kick");
					} else {
						CPrintToChat(client, "%s%t", g_aConVarlist.szTag, "AFK Warning Kick", fAfkCalcTime);
						EmitSoundToClient(client, g_aConVarlist.szSoundWarn, SOUND_FROM_PLAYER, SNDCHAN_BODY, 0, SND_NOFLAGS, 1.0, 100, _, NULL_VECTOR, NULL_VECTOR, true);
					}
				}
			}

			if(g_aConVarlist.bPingCheckEnable && (!g_aConVarlist.bPingFlagEnable || !(GetUserFlagBits(client) & g_aConVarlist.iPingFlag))) {
				float fLatency = GetClientAvgLatency(client, NetFlow_Outgoing), fTickRate = GetTickInterval();
				char sClientCmdRate[4];
				GetClientInfo(client, "cl_cmdrate", sClientCmdRate, sizeof(sClientCmdRate));
				int iCmdRate = StringToInt(sClientCmdRate);

				if(iCmdRate < 20)
					iCmdRate = 20;

				fLatency -= ((0.5/iCmdRate) + (fTickRate * 1.0));
				fLatency -= (fTickRate * 0.5);
				fLatency *= 1000.0;
				g_aPlayerCheks[client].iPingClient = RoundToZero(fLatency);
				if(g_aPlayerCheks[client].iPingClient > g_aConVarlist.iPingMaxPing) {
					g_aPlayerCheks[client].iPingCheckFail++;
					if(g_aPlayerCheks[client].iPingCheckFail >= g_aConVarlist.iPingChecks) {
						CPrintToChatAll("%s%t", g_aConVarlist.szTag, "PING Announce Kick", client, g_aPlayerCheks[client].iPingClient, g_aConVarlist.iPingMaxPing);
						KickClientEx(client, "%t", "PING Message Kick", g_aPlayerCheks[client].iPingClient, g_aConVarlist.iPingMaxPing);
					}
				} else {
					if(g_aPlayerCheks[client].iPingCheckFail > 0)
						g_aPlayerCheks[client].iPingCheckFail--;
				}
			}
		}
	}
}

stock int GetPlayerCountEx(int client, bool AliveOnly, bool teamOnly, bool noSpectators) {
	int players;
	for(int i = 1, t = !client ? 0 : GetClientTeam(client); i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i) && (!AliveOnly || IsPlayerAlive(i))) {
			if(teamOnly) {
				if(GetClientTeam(i) == t) players++;
			}
			else if(!noSpectators || GetClientTeam(i) > CS_TEAM_SPECTATOR) players++;
		}
	return players;
}

stock void PrepareSound(const char[] szSound) {
	if(szSound[0]) {
		char buffer[PLATFORM_MAX_PATH];
		Format(buffer, sizeof(buffer), "sound*/%s", szSound[1]);
		if(FileExists(buffer))
			AddFileToDownloadsTable(buffer);

		AddToStringTable(FindStringTable("soundprecache"), szSound);
	}
}

stock bool IsValidClient(int client) {
	return 0 < client && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}

stock bool IsWeaponKnife(int iWeapon) {
	char sClass[8];
	GetEntityNetClass(iWeapon, sClass, sizeof(sClass));
	return strncmp(sClass, "CKnife", 6) == 0;
}

stock bool Client_ScreenFade(int client, int duration, int mode, int holdtime=-1, int r=0, int g=0, int b=0, int a=255, bool reliable=true) {
	Handle userMessage = StartMessageOne("Fade", client, (reliable?USERMSG_RELIABLE:0));

	if (userMessage == INVALID_HANDLE)
		return false;

	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) {
		int color[4]; color[0] = r; color[1] = g; color[2] = b; color[3] = a;
		PbSetInt(userMessage,   "duration",   duration);
		PbSetInt(userMessage,   "hold_time",  holdtime);
		PbSetInt(userMessage,   "flags",      mode);
		PbSetColor(userMessage, "clr",        color);
	} else {
		BfWriteShort(userMessage,	duration);	// Fade duration
		BfWriteShort(userMessage,	holdtime);	// Fade hold time
		BfWriteShort(userMessage,	mode);		// What to do
		BfWriteByte(userMessage,	r);			// Color R
		BfWriteByte(userMessage,	g);			// Color G
		BfWriteByte(userMessage,	b);			// Color B
		BfWriteByte(userMessage,	a);			// Color Alpha
	}
	EndMessage();
	return true;
}