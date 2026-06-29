#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.2.4"
#define PLUGIN_NAME			"cge_l4d2_autohelp"

public Plugin myinfo =
{
	name = "[L4D2] AutoHelp",
	author = "chinagreenelvis, JustMe",
	description = "Survivors help themselves from incapacitation, ledge grabs, and special infected attacks.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=170454"
}

#define CVAR_FLAGS			FCVAR_NOTIFY

#define TEAM_SURVIVORS		2
#define TEAM_INFECTED		3

#define INCAP_NONE			0
#define INCAP_DOWN			1
#define INCAP_LEDGE			2

#define HOLD_NONE			0
#define HOLD_GRAB			1
#define HOLD_POUNCE			2
#define HOLD_RIDE			3
#define HOLD_PUMMEL			4

#define STATE_NONE			0
#define STATE_SELFREVIVE	1
#define STATE_REVIVE		2
#define STATE_OK			3

#define ZOMBIE_SMOKER		1
#define ZOMBIE_HUNTER		3
#define ZOMBIE_JOCKEY		5
#define ZOMBIE_CHARGER		6

ConVar g_hCvarMPGameMode;
ConVar g_hCvarAllow, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
ConVar g_hCvarBots;
ConVar g_hCvarIncap, g_hCvarIncapDelay, g_hCvarIncapDuration, g_hCvarIncapHealth;
ConVar g_hCvarLedge, g_hCvarLedgeDelay, g_hCvarLedgeDuration;
ConVar g_hCvarSpecials, g_hCvarSpecialsDelay, g_hCvarSpecialsDuration, g_hCvarSmokerDrag;

bool	g_bCvarAllow, g_bCvarBots;
bool	g_bCvarIncap, g_bCvarLedge, g_bCvarSpecials;
int		g_iCvarIncapDelay, g_iCvarIncapDuration, g_iCvarIncapHealth;
int		g_iCvarLedgeDelay, g_iCvarLedgeDuration;
int		g_iCvarSpecialsDelay, g_iCvarSpecialsDuration, g_iCvarSmokerDrag;

bool	g_bMapStarted;
int		g_iCurrentMode;

Handle	g_hDelayTimer[MAXPLAYERS+1];
Handle	g_hReviveTimer[MAXPLAYERS+1];
Handle	g_hSlapTimer[MAXPLAYERS+1];

int		g_iHelpState[MAXPLAYERS+1];
int		g_iIncapType[MAXPLAYERS+1];
int		g_iHoldType[MAXPLAYERS+1];
int		g_iAttacker[MAXPLAYERS+1];
int		g_iReviveHealth[MAXPLAYERS+1];
int		g_iHeartSound[MAXPLAYERS+1];

float	g_fHelpStartTime[MAXPLAYERS+1];
float	g_fSelfReviveDuration[MAXPLAYERS+1];

public void OnPluginStart()
{
	g_hCvarAllow =		CreateConVar("autohelp_allow",		"1",	"0=Plugin off, 1=Plugin on.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarModes =		CreateConVar("autohelp_modes",		"",		"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS);
	g_hCvarModesOff =	CreateConVar("autohelp_modes_off",	"",		"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS);
	g_hCvarModesTog =	CreateConVar("autohelp_modes_tog",	"0",	"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS);
	CreateConVar(						"autohelp_version",	PLUGIN_VERSION, "AutoHelp plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarBots =				CreateConVar("autohelp_bots",					"1",	"Allow AutoHelp for survivor bots? 0=No, 1=Yes.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarIncap =				CreateConVar("autohelp_incap",					"1",	"Allow AutoHelp for incapacitation? 0=No, 1=Yes.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarIncapDelay =			CreateConVar("autohelp_incap_delay",			"3",	"AutoHelp delay for incapacitation.", CVAR_FLAGS, true, 0.0);
	g_hCvarIncapDuration =		CreateConVar("autohelp_incap_duration",			"4",	"AutoHelp duration for incapacitation (setting higher than 5 will disable animation).", CVAR_FLAGS, true, 0.0);
	g_hCvarIncapHealth =		CreateConVar("autohelp_incap_health",			"30",	"Health buffer after AutoHelp from incapacitation.", CVAR_FLAGS, true, 1.0);
	g_hCvarLedge =				CreateConVar("autohelp_ledge",					"1",	"Allow AutoHelp for ledge grabs? 0=No, 1=Yes.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarLedgeDelay =			CreateConVar("autohelp_ledge_delay",			"3",	"AutoHelp delay for ledge grabs.", CVAR_FLAGS, true, 0.0);
	g_hCvarLedgeDuration =		CreateConVar("autohelp_ledge_duration",			"4",	"AutoHelp duration for ledge grabs (setting lower than 4 causes animation issues, higher than 5 disables animation).", CVAR_FLAGS, true, 0.0);
	g_hCvarSpecials =			CreateConVar("autohelp_specials",				"1",	"Allow AutoHelp for special infected holds? 0=No, 1=Yes.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarSpecialsDelay =		CreateConVar("autohelp_specials_delay",			"3",	"AutoHelp delay for special infected holds.", CVAR_FLAGS, true, 0.0);
	g_hCvarSpecialsDuration =	CreateConVar("autohelp_specials_duration",		"4",	"AutoHelp duration for special infected holds.", CVAR_FLAGS, true, 0.0);
	g_hCvarSmokerDrag =			CreateConVar("autohelp_specials_smoker_drag",	"10",	"Maximum time a survivor can be dragged before AutoHelp kicks in.", CVAR_FLAGS, true, 0.0);

	AutoExecConfig(true, PLUGIN_NAME);

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);

	g_hCvarBots.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarIncap.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarIncapDelay.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarIncapDuration.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarIncapHealth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLedge.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLedgeDelay.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLedgeDuration.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpecials.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpecialsDelay.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpecialsDuration.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSmokerDrag.AddChangeHook(ConVarChanged_Cvars);

	GetCvars();
}

public void OnPluginEnd()
{
	ResetPlugin();
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarBots				= g_hCvarBots.BoolValue;
	g_bCvarIncap			= g_hCvarIncap.BoolValue;
	g_iCvarIncapDelay		= g_hCvarIncapDelay.IntValue;
	g_iCvarIncapDuration	= g_hCvarIncapDuration.IntValue;
	g_iCvarIncapHealth		= g_hCvarIncapHealth.IntValue;
	g_bCvarLedge			= g_hCvarLedge.BoolValue;
	g_iCvarLedgeDelay		= g_hCvarLedgeDelay.IntValue;
	g_iCvarLedgeDuration	= g_hCvarLedgeDuration.IntValue;
	g_bCvarSpecials			= g_hCvarSpecials.BoolValue;
	g_iCvarSpecialsDelay	= g_hCvarSpecialsDelay.IntValue;
	g_iCvarSpecialsDuration	= g_hCvarSpecialsDuration.IntValue;
	g_iCvarSmokerDrag		= g_hCvarSmokerDrag.IntValue;
}

void IsAllowed()
{
	GetCvars();
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if (g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true)
	{
		g_bCvarAllow = true;
		HookEvents();
	}
	else if (g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false))
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvents();
	}
}

bool IsAllowedGameMode()
{
	if (g_hCvarMPGameMode == null) return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if (iCvarModesTog != 0)
	{
		if (g_bMapStarted == false) return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if (IsValidEntity(entity))
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop",		OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival",	OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus",		OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge",	OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if (IsValidEntity(entity))
				RemoveEdict(entity);
		}

		if (g_iCurrentMode == 0) return false;
		if (!(iCvarModesTog & g_iCurrentMode)) return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if (sGameModes[0])
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) == -1) return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if (sGameModes[0])
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) != -1) return false;
	}

	return true;
}

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if      (strcmp(output, "OnCoop") == 0)		g_iCurrentMode = 1;
	else if (strcmp(output, "OnSurvival") == 0)	g_iCurrentMode = 2;
	else if (strcmp(output, "OnVersus") == 0)	g_iCurrentMode = 4;
	else if (strcmp(output, "OnScavenge") == 0)	g_iCurrentMode = 8;
}

public void OnMapStart()
{
	g_bMapStarted = true;
	PrecacheSound("player/heartbeatloop.wav", true);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void HookEvents()
{
	HookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("player_first_spawn",		Event_PlayerFirstSpawn);
	HookEvent("player_spawn",			Event_PlayerSpawn);
	HookEvent("player_team",			Event_PlayerTeam);
	HookEvent("player_hurt",			Event_PlayerHurt);
	HookEvent("player_death",			Event_PlayerDeath);
	HookEvent("player_incapacitated",	Event_PlayerIncapacitated);
	HookEvent("player_ledge_grab",		Event_PlayerLedgeGrab);
	HookEvent("lunge_pounce",			Event_LungePounce);
	HookEvent("pounce_stopped",			Event_PounceStopped);
	HookEvent("tongue_grab",			Event_TongueGrab);
	HookEvent("choke_start",			Event_ChokeStart);
	HookEvent("tongue_release",			Event_TongueRelease);
	HookEvent("jockey_ride",			Event_JockeyRide);
	HookEvent("jockey_ride_end",		Event_JockeyRideEnd);
	HookEvent("charger_pummel_start",	Event_ChargerPummelStart);
	HookEvent("charger_pummel_end",		Event_ChargerPummelEnd);
	HookEvent("survivor_rescued",		Event_SurvivorRescued);
	HookEvent("revive_begin",			Event_ReviveBegin);
	HookEvent("revive_end",				Event_ReviveEnd);
	HookEvent("revive_success",			Event_ReviveSuccess);
	HookEvent("heal_success",			Event_HealSuccess);
}

void UnhookEvents()
{
	UnhookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
	UnhookEvent("player_first_spawn",	Event_PlayerFirstSpawn);
	UnhookEvent("player_spawn",			Event_PlayerSpawn);
	UnhookEvent("player_team",			Event_PlayerTeam);
	UnhookEvent("player_hurt",			Event_PlayerHurt);
	UnhookEvent("player_death",			Event_PlayerDeath);
	UnhookEvent("player_incapacitated",	Event_PlayerIncapacitated);
	UnhookEvent("player_ledge_grab",	Event_PlayerLedgeGrab);
	UnhookEvent("lunge_pounce",			Event_LungePounce);
	UnhookEvent("pounce_stopped",		Event_PounceStopped);
	UnhookEvent("tongue_grab",			Event_TongueGrab);
	UnhookEvent("choke_start",			Event_ChokeStart);
	UnhookEvent("tongue_release",		Event_TongueRelease);
	UnhookEvent("jockey_ride",			Event_JockeyRide);
	UnhookEvent("jockey_ride_end",		Event_JockeyRideEnd);
	UnhookEvent("charger_pummel_start",	Event_ChargerPummelStart);
	UnhookEvent("charger_pummel_end",	Event_ChargerPummelEnd);
	UnhookEvent("survivor_rescued",		Event_SurvivorRescued);
	UnhookEvent("revive_begin",			Event_ReviveBegin);
	UnhookEvent("revive_end",			Event_ReviveEnd);
	UnhookEvent("revive_success",		Event_ReviveSuccess);
	UnhookEvent("heal_success",			Event_HealSuccess);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

void Event_PlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS)
	{
		ResetClient(client);
		GetHealth(client);
	}
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS)
	{
		ResetClient(client);
		GetHealth(client);
	}
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS)
		GetHealth(client);
}

void Event_TongueGrab(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCvarSpecials) return;

	int victim =   GetClientOfUserId(event.GetInt("victim"));
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !attacker) return;

	g_iAttacker[victim] =			attacker;
	g_iHoldType[victim] =			HOLD_GRAB;
	g_iHelpState[victim] =			STATE_NONE;
	g_fSelfReviveDuration[victim] =	float(g_iCvarSpecialsDuration);

	delete g_hDelayTimer[victim];
	g_hDelayTimer[victim] = CreateTimer(float(g_iCvarSmokerDrag), Timer_Delay, victim, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_ChokeStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCvarSpecials) return;

	int victim =   GetClientOfUserId(event.GetInt("victim"));
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !attacker) return;

	g_iAttacker[victim] =			attacker;
	g_iHoldType[victim] =			HOLD_GRAB;
	g_iHelpState[victim] =			STATE_NONE;
	g_fSelfReviveDuration[victim] =	float(g_iCvarSpecialsDuration);

	delete g_hDelayTimer[victim];
	float fDelay = (g_hReviveTimer[victim] != null) ? 0.1 : float(g_iCvarSpecialsDelay);
	g_hDelayTimer[victim] = CreateTimer(fDelay, Timer_Delay, victim, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_TongueRelease(Event event, const char[] name, bool dontBroadcast)
{
	int victim =   GetClientOfUserId(event.GetInt("victim"));
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !attacker) return;

	if (g_iAttacker[victim] == attacker) g_iAttacker[victim] = 0;
	g_iHoldType[victim] = HOLD_NONE;

	delete g_hDelayTimer[victim];
	g_hDelayTimer[victim] = CreateTimer(float(g_iCvarIncapDelay), Timer_Delay, victim, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_LungePounce(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCvarSpecials) return;

	int victim =   GetClientOfUserId(event.GetInt("victim"));
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !attacker) return;

	g_iAttacker[victim] =			attacker;
	g_iHoldType[victim] =			HOLD_POUNCE;
	g_iHelpState[victim] =			STATE_NONE;
	g_fSelfReviveDuration[victim] =	float(g_iCvarSpecialsDuration);

	delete g_hDelayTimer[victim];
	g_hDelayTimer[victim] = CreateTimer(float(g_iCvarSpecialsDelay), Timer_Delay, victim, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_PounceStopped(Event event, const char[] name, bool dontBroadcast)
{
	int victim =   GetClientOfUserId(event.GetInt("victim"));
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !attacker) return;

	if (g_iAttacker[victim] == attacker) g_iAttacker[victim] = 0;
	g_iHoldType[victim] = HOLD_NONE;

	delete g_hDelayTimer[victim];
	g_hDelayTimer[victim] = CreateTimer(float(g_iCvarIncapDelay), Timer_Delay, victim, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCvarSpecials) return;

	int victim =   GetClientOfUserId(event.GetInt("victim"));
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !attacker) return;

	g_iAttacker[victim] =			attacker;
	g_iHoldType[victim] =			HOLD_RIDE;
	g_iHelpState[victim] =			STATE_NONE;
	g_fSelfReviveDuration[victim] =	float(g_iCvarSpecialsDuration);

	delete g_hDelayTimer[victim];
	g_hDelayTimer[victim] = CreateTimer(float(g_iCvarSpecialsDelay), Timer_Delay, victim, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_JockeyRideEnd(Event event, const char[] name, bool dontBroadcast)
{
	int victim =   GetClientOfUserId(event.GetInt("victim"));
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !attacker) return;

	if (g_iAttacker[victim] == attacker) g_iAttacker[victim] = 0;
	g_iHoldType[victim] = HOLD_NONE;

	delete g_hDelayTimer[victim];
	g_hDelayTimer[victim] = CreateTimer(float(g_iCvarIncapDelay), Timer_Delay, victim, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_ChargerPummelStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCvarSpecials) return;

	int victim =   GetClientOfUserId(event.GetInt("victim"));
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !attacker) return;

	g_iAttacker[victim] =			attacker;
	g_iHoldType[victim] =			HOLD_PUMMEL;
	g_iHelpState[victim] =			STATE_NONE;
	g_fSelfReviveDuration[victim] =	float(g_iCvarSpecialsDuration);

	delete g_hDelayTimer[victim];
	g_hDelayTimer[victim] = CreateTimer(float(g_iCvarSpecialsDelay), Timer_Delay, victim, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_ChargerPummelEnd(Event event, const char[] name, bool dontBroadcast)
{
	int victim =   GetClientOfUserId(event.GetInt("victim"));
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !attacker) return;

	if (g_iAttacker[victim] == attacker) g_iAttacker[victim] = 0;
	g_iHoldType[victim] = HOLD_NONE;

	delete g_hDelayTimer[victim];
	g_hDelayTimer[victim] = CreateTimer(float(g_iCvarIncapDelay), Timer_Delay, victim, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || GetClientTeam(victim) == TEAM_INFECTED) return;

	g_iIncapType[victim] =				INCAP_DOWN;
	g_iHelpState[victim] =				STATE_NONE;
	g_fSelfReviveDuration[victim] =		float(g_iCvarIncapDuration);

	delete g_hReviveTimer[victim];
	delete g_hDelayTimer[victim];
	g_hDelayTimer[victim] = CreateTimer(float(g_iCvarIncapDelay), Timer_Delay, victim, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_PlayerLedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!victim) return;

	g_iIncapType[victim] =				INCAP_LEDGE;
	g_iHelpState[victim] =				STATE_NONE;
	g_fSelfReviveDuration[victim] =		float(g_iCvarLedgeDuration);

	delete g_hDelayTimer[victim];
	g_hDelayTimer[victim] = CreateTimer(float(g_iCvarLedgeDelay), Timer_Delay, victim, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client =		GetClientOfUserId(event.GetInt("userid"));
	int attacker =		GetClientOfUserId(event.GetInt("attacker"));
	int damagetype =	event.GetInt("type");

	if (!client || !IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVORS) return;

	if (!GetEntProp(client, Prop_Send, "m_isHangingFromLedge") && !GetEntProp(client, Prop_Send, "m_isIncapacitated"))
		GetHealth(client);

	if (g_iHelpState[client] == STATE_SELFREVIVE || g_iHelpState[client] == STATE_NONE)
	{
		if (damagetype != 131072 && !g_iAttacker[client] && (!attacker || GetClientTeam(attacker) != TEAM_SURVIVORS))
		{
			if (g_iIncapType[client] == INCAP_DOWN || g_iIncapType[client] == INCAP_LEDGE)
			{
				if (g_iHelpState[client] == STATE_SELFREVIVE)
				{
					SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
					SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
					if (g_fSelfReviveDuration[client] <= 5.0)
						SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
					g_iHelpState[client] = STATE_NONE;
				}
				RestartTimer(client);
			}
		}
	}

	if (g_iHelpState[client] == STATE_REVIVE && damagetype == 131072)
		g_iHelpState[client] = STATE_NONE;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client) return;
	StopBeat(client);
	ResetClient(client);
}

void Event_SurvivorRescued(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (!client) return;
	StopBeat(client);
	ResetClient(client);
	GetHealth(client);
}

void Event_ReviveBegin(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (!client) return;

	g_iHelpState[client] = STATE_REVIVE;
	delete g_hDelayTimer[client];
	delete g_hReviveTimer[client];
}

void Event_ReviveEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (!client) return;

	g_iHelpState[client] = STATE_NONE;
	RestartTimer(client);
}

void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (!client) return;

	g_iIncapType[client] =	INCAP_NONE;
	g_iHoldType[client] =	HOLD_NONE;
	g_iHelpState[client] =	STATE_OK;
	delete g_hReviveTimer[client];

	if (IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS)
		GetHealth(client);
}

void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (!client) return;
	StopBeat(client);
	GetHealth(client);
}

Action Timer_Delay(Handle timer, any client)
{
	g_hDelayTimer[client] = null;

	if (!client) return Plugin_Continue;

	if (!g_bCvarBots && IsFakeClient(client) && !GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return Plugin_Continue;

	if (g_iHelpState[client] != STATE_NONE) return Plugin_Continue;

	bool bIncapOk = (g_iIncapType[client] == INCAP_DOWN  && g_bCvarIncap);
	bool bLedgeOk = (g_iIncapType[client] == INCAP_LEDGE && g_bCvarLedge);
	bool bHoldOk  = (g_bCvarSpecials && (
					  g_iHoldType[client] == HOLD_GRAB   ||
					  g_iHoldType[client] == HOLD_POUNCE ||
					  g_iHoldType[client] == HOLD_RIDE   ||
					  g_iHoldType[client] == HOLD_PUMMEL));

	if (bIncapOk || bLedgeOk || bHoldOk)
	{
		delete g_hReviveTimer[client];
		g_hReviveTimer[client] = CreateTimer(0.1, Timer_SelfRevive, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

Action Timer_SelfRevive(Handle timer, any client)
{
	if (!IsClientInGame(client))
	{
		g_hReviveTimer[client] = null;
		return Plugin_Stop;
	}

	bool bIncapState = (g_iIncapType[client] == INCAP_DOWN || g_iIncapType[client] == INCAP_LEDGE);
	bool bHoldState  = (g_iAttacker[client] && IsClientInGame(g_iAttacker[client]) && IsPlayerAlive(g_iAttacker[client]));

	if (!IsPlayerAlive(client) || g_iHelpState[client] == STATE_OK || (!bIncapState && !bHoldState))
	{
		if (g_iHelpState[client] == STATE_SELFREVIVE)
		{
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
		}
		g_iHelpState[client] =	STATE_OK;
		g_iIncapType[client] =	INCAP_NONE;
		g_hReviveTimer[client] = null;
		return Plugin_Stop;
	}

	float fTime = GetEngineTime();

	if (g_iHelpState[client] == STATE_NONE)
	{
		g_fHelpStartTime[client] = fTime;

		if (g_iIncapType[client] == INCAP_DOWN && !g_iAttacker[client])
		{
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", g_fSelfReviveDuration[client]);
		}
		if (bIncapState && !g_iAttacker[client] && g_fSelfReviveDuration[client] <= 5.0)
			SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);

		g_iHelpState[client] = STATE_SELFREVIVE;
	}

	if (g_iHelpState[client] == STATE_SELFREVIVE)
	{
		if (fTime - g_fHelpStartTime[client] >= g_fSelfReviveDuration[client])
		{
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
			SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
			g_iHelpState[client] = STATE_OK;

			g_hReviveTimer[client] = null;
			SelfRevive(client);
			return Plugin_Stop;
		}
	}

	if (g_iHelpState[client] == STATE_REVIVE)
	{
		g_hReviveTimer[client] = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

Action Timer_GetHealth(Handle timer, any client)
{
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVORS)
		return Plugin_Continue;

	if (!GetEntProp(client, Prop_Send, "m_isHangingFromLedge") && !GetEntProp(client, Prop_Send, "m_isIncapacitated"))
	{
		int iHealth = GetClientHealth(client);
		if (!iHealth) iHealth = 100;

		int iReviveHealth = iHealth - (g_iCvarLedgeDelay + g_iCvarLedgeDuration);
		if (iReviveHealth < 1) iReviveHealth = 1;
		g_iReviveHealth[client] = iReviveHealth;
	}

	return Plugin_Continue;
}

Action Timer_RestoreState(Handle timer, any client)
{
	if (client) SetEntProp(client, Prop_Send, "m_lifeState", 0);
	return Plugin_Continue;
}

Action Timer_SlapPlayer(Handle timer, any client)
{
	if (client) SlapPlayer(client, 0, false);
	return Plugin_Continue;
}

Action Timer_StopSlap(Handle timer, any client)
{
	if (client) delete g_hSlapTimer[client];
	return Plugin_Continue;
}

void ResetPlugin()
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			ResetClient(i);
}

void ResetClient(int client)
{
	g_iHelpState[client] =		STATE_OK;
	g_iIncapType[client] =		INCAP_NONE;
	g_iHoldType[client] =		HOLD_NONE;
	g_iAttacker[client] =		0;
	g_fHelpStartTime[client] =	0.0;

	delete g_hDelayTimer[client];
	delete g_hReviveTimer[client];
}

void RestartTimer(int client)
{
	if (!client) return;

	delete g_hDelayTimer[client];
	delete g_hReviveTimer[client];

	if (g_iIncapType[client] == INCAP_LEDGE)
		g_hDelayTimer[client] = CreateTimer(float(g_iCvarLedgeDelay), Timer_Delay, client, TIMER_FLAG_NO_MAPCHANGE);
	else if (g_iIncapType[client] == INCAP_DOWN)
		g_hDelayTimer[client] = CreateTimer(float(g_iCvarIncapDelay), Timer_Delay, client, TIMER_FLAG_NO_MAPCHANGE);
}

void SelfRevive(int client)
{
	if (!client) return;
	if (g_iAttacker[client])
	{
		KnockAttacker(client);
		g_iAttacker[client] = 0;
	}
	Revive(client);
}

void KnockAttacker(int client)
{
	if (!client) return;

	int attacker = g_iAttacker[client];
	if (!IsClientInGame(attacker) || !IsPlayerAlive(attacker)) return;

	int iClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");

	if (iClass == ZOMBIE_SMOKER)
	{
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
		CreateTimer(0.1, Timer_RestoreState, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (iClass == ZOMBIE_HUNTER)
	{
		CallOnPounceEnd(client);
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
		delete g_hSlapTimer[attacker];
		g_hSlapTimer[attacker] = CreateTimer(0.1, Timer_SlapPlayer, attacker, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.6, Timer_StopSlap, attacker, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.5, Timer_RestoreState, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (iClass == ZOMBIE_JOCKEY)
	{
		FakeClientCommand(attacker, "dismount");
	}
	else if (iClass == ZOMBIE_CHARGER)
	{
		CallOnPummelEnded(client);
		if (!GetEntProp(client, Prop_Send, "m_isIncapacitated"))
		{
			SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
			SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
		}
		delete g_hSlapTimer[attacker];
		g_hSlapTimer[attacker] = CreateTimer(0.5, Timer_SlapPlayer, attacker, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(2.0, Timer_StopSlap, attacker, TIMER_FLAG_NO_MAPCHANGE);
		delete g_hSlapTimer[client];
		g_hSlapTimer[client] = CreateTimer(0.5, Timer_SlapPlayer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(2.0, Timer_StopSlap, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void Revive(int client)
{
	if (!client) return;

	if (g_iIncapType[client] == INCAP_DOWN || g_iIncapType[client] == INCAP_LEDGE)
	{
		if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
		{
			int iReviveCount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
			HealthCheat(client);
			SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
			SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
			SetEntProp(client, Prop_Send, "m_reviveOwner", 0);
			SetEntityHealth(client, g_iReviveHealth[client]);
			SetEntProp(client, Prop_Send, "m_currentReviveCount", iReviveCount);
		}
		else
		{
			int iReviveCount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
			HealthCheat(client);
			SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
			SetEntityHealth(client, 1);
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(g_iCvarIncapHealth));
			SetEntProp(client, Prop_Send, "m_reviveOwner", 0);
			SetEntProp(client, Prop_Send, "m_currentReviveCount", iReviveCount + 1);

			ConVar hMaxIncap = FindConVar("survivor_max_incapacitated_count");
			if (hMaxIncap != null && GetEntProp(client, Prop_Send, "m_currentReviveCount") == hMaxIncap.IntValue)
			{
				SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
				EmitSoundToClient(client, "player/heartbeatloop.wav");
				g_iHeartSound[client] = 1;
			}
		}
	}

	g_iIncapType[client] = INCAP_NONE;
	g_iHoldType[client] =  HOLD_NONE;
	GetHealth(client);
}

void GetHealth(int client)
{
	if (client && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS)
		CreateTimer(0.1, Timer_GetHealth, client, TIMER_FLAG_NO_MAPCHANGE);
}

void StopBeat(int client)
{
	if (client && g_iHeartSound[client])
	{
		StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
		g_iHeartSound[client] = 0;
	}
}

void HealthCheat(int client)
{
	if (!client) return;
	int iUserFlags = GetUserFlagBits(client);
	int iCmdFlags =  GetCommandFlags("give");
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags("give", iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give health");
	SetCommandFlags("give", iCmdFlags);
	SetUserFlagBits(client, iUserFlags);
}

void CallOnPummelEnded(int client)
{
	if (!client) return;
	static Handle hOnPummelEnded = null;
	if (hOnPummelEnded == null)
	{
		GameData hConf = new GameData(PLUGIN_NAME);
		if (!hConf) { SetFailState("Failed to load gamedata: %s", PLUGIN_NAME); return; }
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
		hOnPummelEnded = EndPrepSDKCall();
		delete hConf;
		if (!hOnPummelEnded) { SetFailState("Can't get CTerrorPlayer::OnPummelEnded SDKCall!"); return; }
	}
	SDKCall(hOnPummelEnded, client, true, -1);
}

void CallOnPounceEnd(int client)
{
	if (!client) return;
	static Handle hOnPounceEnd = null;
	if (hOnPounceEnd == null)
	{
		GameData hConf = new GameData(PLUGIN_NAME);
		if (!hConf) { SetFailState("Failed to load gamedata: %s", PLUGIN_NAME); return; }
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTerrorPlayer::OnPounceEnd");
		hOnPounceEnd = EndPrepSDKCall();
		delete hConf;
		if (!hOnPounceEnd) { SetFailState("Can't get CTerrorPlayer::OnPounceEnd SDKCall!"); return; }
	}
	SDKCall(hOnPounceEnd, client);
}

public void OnClientDisconnect(int client)
{
	StopBeat(client);
	ResetClient(client);
}
