#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "[L4D2] AutoHelp"
#define PLUGIN_AUTHOR "chinagreenelvis, Shadowysn"
#define PLUGIN_DESC "Survivors help themselves from incapacitation, ledge grabs, and special infected attacks."
#define PLUGIN_VERSION "1.2.5b"
#define PLUGIN_URL "https://forums.alliedmods.net/showpost.php?p=2760053&postcount=53"
#define PLUGIN_NAME_SHORT "AutoHelp"
#define PLUGIN_NAME_TECH "autohelp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
	return APLRes_SilentFailure;
}

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

#define INCAP_NONE 0
#define INCAP 1
#define INCAP_GRAB 2
#define INCAP_POUNCE 3
#define INCAP_RIDE 4
#define INCAP_PUMMEL 5
#define INCAP_LEDGE	6

#define STATE_NONE 0
#define STATE_SELFREVIVE 1
#define STATE_REVIVE 2
#define STATE_OK 3
#define STATE_ATTACKED 4

//#define SMOKER 1
#define HUNTER 3
//#define JOCKEY 5
#define CHARGER 6
//#define TANK 8

static Handle DelayTimer[MAXPLAYERS+1];
static Handle ReviveTimer[MAXPLAYERS+1];
static Handle TimerSlapPlayer[MAXPLAYERS+1];

static int HelpState[MAXPLAYERS+1];
static int IncapType[MAXPLAYERS+1];
static int Attacker[MAXPLAYERS+1];

static float HelpStartTime[MAXPLAYERS+1];
static float SelfReviveDuration[MAXPLAYERS+1];

static ConVar AutoHelp_Bots, AutoHelp_Players,
AutoHelp_Incap, AutoHelp_Incap_Delay, AutoHelp_Incap_Duration, AutoHelp_Incap_Health,
AutoHelp_Ledge, AutoHelp_Ledge_Delay, AutoHelp_Ledge_Duration,
AutoHelp_Specials, AutoHelp_Specials_Delay, AutoHelp_Specials_Duration, AutoHelp_Specials_Smoker_Drag;
bool g_bAutoHelp_Bots, g_bAutoHelp_Players, g_bAutoHelp_Incap;
float g_fAutoHelp_Incap_Delay, g_fAutoHelp_Incap_Duration, g_fAutoHelp_Incap_Health;
bool g_bAutoHelp_Ledge;
float g_fAutoHelp_Ledge_Delay, g_fAutoHelp_Ledge_Duration;
bool g_bAutoHelp_Specials;
float g_fAutoHelp_Specials_Delay, g_fAutoHelp_Specials_Duration, g_fAutoHelp_Specials_Smoker_Drag;

//static ConVar incap_count = null;
//static ConVar z_charge_interval = null;

static int HeartSound[MAXPLAYERS+1];

public void OnPluginStart()
{
	//incap_count = FindConVar("survivor_max_incapacitated_count");
	//z_charge_interval = FindConVar("z_charge_interval");
	
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "%s_version", PLUGIN_NAME_TECH);
	static char desc_str[128];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "%s_bots", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Allow %s for survivor bots? 0 - No. 1 - Yes.", PLUGIN_NAME_SHORT);
	AutoHelp_Bots = CreateConVar(cmd_str, "1", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);
	AutoHelp_Bots.AddChangeHook(CC_AH_Bots);
	
	Format(cmd_str, sizeof(cmd_str), "%s_players", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Allow %s for survivor players? 0 - No. 1 - Yes.", PLUGIN_NAME_SHORT);
	AutoHelp_Players = CreateConVar(cmd_str, "1", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);
	AutoHelp_Players.AddChangeHook(CC_AH_Players);
	
	Format(cmd_str, sizeof(cmd_str), "%s_incap", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Allow %s for incapacitation? 0 - No. 1 - Yes.", PLUGIN_NAME_SHORT);
	AutoHelp_Incap = CreateConVar(cmd_str, "0", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);
	AutoHelp_Incap.AddChangeHook(CC_AH_Incap);
	
	Format(cmd_str, sizeof(cmd_str), "%s_incap_delay", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "%s delay for incapacitation", PLUGIN_NAME_SHORT);
	AutoHelp_Incap_Delay = CreateConVar(cmd_str, "3", desc_str, FCVAR_NONE);
	AutoHelp_Incap_Delay.AddChangeHook(CC_AH_Incap_Delay);
	
	Format(cmd_str, sizeof(cmd_str), "%s_incap_duration", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "%s duration for incapacitation (setting higher than 5 will disable animation)", PLUGIN_NAME_SHORT);
	AutoHelp_Incap_Duration = CreateConVar(cmd_str, "4", desc_str, FCVAR_NONE);
	AutoHelp_Incap_Duration.AddChangeHook(CC_AH_Incap_Duration);
	
	Format(cmd_str, sizeof(cmd_str), "%s_incap_health", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Health buffer after %s from incapacitation", PLUGIN_NAME_SHORT);
	AutoHelp_Incap_Health = CreateConVar(cmd_str, "30", desc_str, FCVAR_NONE);
	AutoHelp_Incap_Health.AddChangeHook(CC_AH_Incap_Health);
	
	Format(cmd_str, sizeof(cmd_str), "%s_ledge", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Allow %s for ledge grabs? 0 - No. 1 - Yes.", PLUGIN_NAME_SHORT);
	AutoHelp_Ledge = CreateConVar(cmd_str, "1", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);		
	AutoHelp_Ledge.AddChangeHook(CC_AH_Ledge);
	
	Format(cmd_str, sizeof(cmd_str), "%s_ledge_delay", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "%s delay for ledge grabs", PLUGIN_NAME_SHORT);
	AutoHelp_Ledge_Delay = CreateConVar(cmd_str, "10", desc_str, FCVAR_NONE);
	AutoHelp_Ledge_Delay.AddChangeHook(CC_AH_Ledge_Delay);
	
	Format(cmd_str, sizeof(cmd_str), "%s_ledge_duration", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "%s duration for ledge grabs (setting lower than 4 will cause animation issues, higher than 5 will disable the animation)", PLUGIN_NAME_SHORT);
	AutoHelp_Ledge_Duration = CreateConVar(cmd_str, "4", desc_str, FCVAR_NONE);
	AutoHelp_Ledge_Duration.AddChangeHook(CC_AH_Ledge_Duration);
	
	Format(cmd_str, sizeof(cmd_str), "%s_specials", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Allow %s for special infected holds? 0 - No. 1 - Yes.", PLUGIN_NAME_SHORT);
	AutoHelp_Specials = CreateConVar(cmd_str, "0", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);
	AutoHelp_Specials.AddChangeHook(CC_AH_Specials);
	
	Format(cmd_str, sizeof(cmd_str), "%s_specials_delay", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "%s delay for special infected holds", PLUGIN_NAME_SHORT);
	AutoHelp_Specials_Delay = CreateConVar(cmd_str, "3", desc_str, FCVAR_NONE);
	AutoHelp_Specials_Delay.AddChangeHook(CC_AH_Specials_Delay);
	
	Format(cmd_str, sizeof(cmd_str), "%s_specials_duration", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "%s duration for special infected holds", PLUGIN_NAME_SHORT);
	AutoHelp_Specials_Duration = CreateConVar(cmd_str, "4", desc_str, FCVAR_NONE);
	AutoHelp_Specials_Duration.AddChangeHook(CC_AH_Specials_Duration);
	
	Format(cmd_str, sizeof(cmd_str), "%s_specials_smoker_drag", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Maximum time a survivor can be dragged before %s kicks in", PLUGIN_NAME_SHORT);
	AutoHelp_Specials_Smoker_Drag = CreateConVar(cmd_str, "10", desc_str, FCVAR_NONE);
	AutoHelp_Specials_Smoker_Drag.AddChangeHook(CC_AH_Specials_Smoker_Drag);
	
	AutoExecConfig(true, "cge_l4d2_autohelp");
	SetCvars();
	
	//HookEvent("round_start", Event_RoundStart);
	HookEvent("lunge_pounce", Event_LungePounce);
	HookEvent("pounce_stopped", Event_PounceStopped);
	HookEvent("tongue_grab", Event_TongueGrab);
	HookEvent("choke_start", Event_ChokeStart);
	HookEvent("tongue_release", Event_TongueRelease);
	HookEvent("jockey_ride", Event_JockeyRide);
	HookEvent("jockey_ride_end", Event_JockeyRideEnd);
	HookEvent("charger_pummel_start", Event_ChargerPummelStart);
	HookEvent("charger_pummel_end", Event_ChargerPummelEnd);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	//HookEvent("player_incapacitated_start", Event_PlayerIncapacitatedStart);
	HookEvent("player_ledge_grab", Event_PlayerLedgeGrab);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	//HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("survivor_rescued", Event_SurvivorRescued);
	HookEvent("revive_begin", Event_ReviveBegin);
	HookEvent("revive_end", Event_ReviveEnd);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("heal_success", Event_HealSuccess);
}

void CC_AH_Bots(ConVar convar, const char[] oldValue, const char[] newValue)				{ g_bAutoHelp_Bots =					convar.BoolValue;		}
void CC_AH_Players(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_bAutoHelp_Players =				convar.BoolValue;		}
void CC_AH_Incap(ConVar convar, const char[] oldValue, const char[] newValue)				{ g_bAutoHelp_Incap =					convar.BoolValue;		}
void CC_AH_Incap_Delay(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_fAutoHelp_Incap_Delay =			convar.FloatValue;	}
void CC_AH_Incap_Duration(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fAutoHelp_Incap_Duration =			convar.FloatValue;	}
void CC_AH_Incap_Health(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fAutoHelp_Incap_Health =			convar.FloatValue;	}
void CC_AH_Ledge(ConVar convar, const char[] oldValue, const char[] newValue)				{ g_bAutoHelp_Ledge =					convar.BoolValue;		}
void CC_AH_Ledge_Delay(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_fAutoHelp_Ledge_Delay =			convar.FloatValue;	}
void CC_AH_Ledge_Duration(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fAutoHelp_Ledge_Duration =			convar.FloatValue;	}
void CC_AH_Specials(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_bAutoHelp_Specials =				convar.BoolValue;		}
void CC_AH_Specials_Delay(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fAutoHelp_Specials_Delay =			convar.FloatValue;	}
void CC_AH_Specials_Duration(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_fAutoHelp_Specials_Duration =		convar.FloatValue;	}
void CC_AH_Specials_Smoker_Drag(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_fAutoHelp_Specials_Smoker_Drag =	convar.FloatValue;	}
void SetCvars()
{
	CC_AH_Bots(AutoHelp_Bots, "", "");
	CC_AH_Players(AutoHelp_Players, "", "");
	CC_AH_Incap(AutoHelp_Incap, "", "");
	CC_AH_Incap_Delay(AutoHelp_Incap_Delay, "", "");
	CC_AH_Incap_Duration(AutoHelp_Incap_Duration, "", "");
	CC_AH_Incap_Health(AutoHelp_Incap_Health, "", "");
	CC_AH_Ledge(AutoHelp_Ledge, "", "");
	CC_AH_Ledge_Delay(AutoHelp_Ledge_Delay, "", "");
	CC_AH_Ledge_Duration(AutoHelp_Ledge_Duration, "", "");
	CC_AH_Specials(AutoHelp_Specials, "", "");
	CC_AH_Specials_Delay(AutoHelp_Specials_Delay, "", "");
	CC_AH_Specials_Duration(AutoHelp_Specials_Duration, "", "");
	CC_AH_Specials_Smoker_Drag(AutoHelp_Specials_Smoker_Drag, "", "");
}

public void OnMapStart()
{
	kill_timer();
	PrecacheSound("player/heartbeatloop.wav", true);
}

void kill_timer()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (DelayTimer[i] != null)
		{
			KillTimer(DelayTimer[i]);
			DelayTimer[i] = null;
		}
		else if (ReviveTimer[i] != null)
		{
			KillTimer(ReviveTimer[i]);
			ReviveTimer[i] = null;
		}
	}
}

void kill_client_timer(int client)
{
	if (DelayTimer[client] != null)
	{
		KillTimer(DelayTimer[client]);
		DelayTimer[client] = null;
	}
	else if (ReviveTimer[client] != null)
	{
		KillTimer(ReviveTimer[client]);
		ReviveTimer[client] = null;
	}
}

public void OnClientDisconnect(int client)
{
	HelpState[client] = STATE_OK;
	IncapType[client] = INCAP_NONE;
	Attacker[client] = 0;
	HelpStartTime[client] = 0.0;
	kill_client_timer(client);
	HeartSound[client] = 0;
}

void Event_PlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client) || !IsGameSurvivor(client)) return;

	HelpState[client] = STATE_OK;
	IncapType[client] = INCAP_NONE;
	Attacker[client] = 0;
	HelpStartTime[client] = 0.0;
	if (ReviveTimer[client] != null)
	{
		KillTimer(ReviveTimer[client]);
	}
	ReviveTimer[client] = null;
	DelayTimer[client] = null;
	HeartSound[client] = 0;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int team = GetClientOfUserId(GetEventInt(event, "team"));
	if (!IsValidClient(client) || !IsTeamGameSurvivor(team)) return;
	
	HelpState[client] = STATE_OK;
	IncapType[client] = INCAP_NONE;
	Attacker[client] = 0;
	HelpStartTime[client] = 0.0;
	if (ReviveTimer[client] != null)
	{
		KillTimer(ReviveTimer[client]);
	}
	ReviveTimer[client] = null;
	DelayTimer[client] = null;
	HeartSound[client] = 0;
}

/*void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client) || !IsGameSurvivor(client)) return;
	
	GetHealth(client);
}*/

void Event_TongueGrab(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(victim)) return;
	if (!IsValidClient(attacker)) return;
	
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_GRAB;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = g_fAutoHelp_Specials_Duration;
	DelayTimer[victim] = CreateTimer(g_fAutoHelp_Specials_Smoker_Drag, Timer_Delay, GetClientUserId(victim));
}

void Event_ChokeStart(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(victim)) return;
	if (!IsValidClient(attacker)) return;
	
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_GRAB;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = g_fAutoHelp_Specials_Duration;
	if (ReviveTimer[victim])
	{
		ReviveTimer[victim] = null;
		DelayTimer[victim] = CreateTimer(0.1, Timer_Delay, GetClientUserId(victim));
	}
	else
	{
		DelayTimer[victim] = CreateTimer(g_fAutoHelp_Specials_Delay, Timer_Delay, GetClientUserId(victim));
	}
}


void Event_TongueRelease(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(victim)) return;
	if (!IsValidClient(attacker)) return;
	
	if (Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}
}

void Event_LungePounce(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(victim)) return;
	if (!IsValidClient(attacker)) return;
	
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_POUNCE;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = g_fAutoHelp_Specials_Duration;
	DelayTimer[victim] = CreateTimer(g_fAutoHelp_Specials_Delay, Timer_Delay, GetClientUserId(victim));	 
}

void Event_PounceStopped(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(victim)) return;
	if (!IsValidClient(attacker)) return;
	
	if (Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}
}

void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(victim)) return;
	if (!IsValidClient(attacker)) return;
	
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_RIDE;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = g_fAutoHelp_Specials_Duration;
	DelayTimer[victim] = CreateTimer(g_fAutoHelp_Specials_Delay, Timer_Delay, GetClientUserId(victim));	
}

void Event_JockeyRideEnd(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(victim)) return;
	if (!IsValidClient(attacker)) return;
	
	if (Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}
}

void Event_ChargerPummelStart(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(victim)) return;
	if (!IsValidClient(attacker)) return;
	
	Attacker[victim] = attacker;
	if (IsIncapacitated(victim))
	{
		IncapType[victim] = INCAP;
	}
	else
	{
		IncapType[victim] = INCAP_PUMMEL;
	}
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = g_fAutoHelp_Specials_Duration;
	DelayTimer[victim] = CreateTimer(g_fAutoHelp_Specials_Delay, Timer_Delay, GetClientUserId(victim));	
}

void Event_ChargerPummelEnd(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(victim)) return;
	if (!IsValidClient(attacker)) return;
	
	if (Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}
}

// void Event_PlayerIncapacitatedStart(Event event, const char[] name, bool dontBroadcast)
// {
// 	//Just in case.
// }

void Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(victim)) return;
	if (!IsGameSurvivor(victim)) return; // tank check is redundant Marttt, all infected can't get incapped anyway
	
	IncapType[victim] = INCAP;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = g_fAutoHelp_Incap_Duration;
	ReviveTimer[victim] = null;
	DelayTimer[victim] = CreateTimer(g_fAutoHelp_Incap_Delay, Timer_Delay, GetClientUserId(victim));	
}

void Event_PlayerLedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(victim)) return;
	
	IncapType[victim] = INCAP_LEDGE;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = g_fAutoHelp_Ledge_Duration;
	DelayTimer[victim] = CreateTimer(g_fAutoHelp_Ledge_Delay, Timer_Delay, GetClientUserId(victim));	
}

Action Timer_Delay(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	DelayTimer[client] = null;
	
	//PrintToChatAll("Timer_Delay");
	if (!IsValidClient(client)) return Plugin_Continue;

	int spec_cl = 0;
	if (HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		spec_cl = GetEntProp(client, Prop_Send, "m_humanSpectatorUserID");
	
	if (
	(!g_bAutoHelp_Bots && IsFakeClient(client) && spec_cl <= 0)
	||
	(!g_bAutoHelp_Players && (!IsFakeClient(client) || spec_cl > 0))
	)
	{
		return Plugin_Continue;
	}
	
	if ((HelpState[client] == STATE_NONE) && 
	(
	(IncapType[client] == INCAP && g_bAutoHelp_Incap) || 
	(IncapType[client] == INCAP_LEDGE && g_bAutoHelp_Ledge) || 
	((IncapType[client] == INCAP_GRAB || 
	IncapType[client] == INCAP_POUNCE || 
	IncapType[client] == INCAP_RIDE || 
	IncapType[client] == INCAP_PUMMEL) && g_bAutoHelp_Specials)))
	{
		if (ReviveTimer[client] == null)
			ReviveTimer[client] = CreateTimer(0.1, Timer_SelfRevive, GetClientUserId(client), TIMER_REPEAT);
	}
	return Plugin_Continue;
}

Action Timer_SelfRevive(Handle timer, int client)
{
	client = GetClientOfUserId(client);

	//PrintToChatAll("Timer_SelfRevive");
	if (!IsValidClient(client))
	{
		ReviveTimer[client] = null;
		return Plugin_Stop;
	}

	if (IsPlayerAlive(client) && HelpState[client] != STATE_OK && 
	((IncapType[client] == INCAP || 
	IncapType[client] == INCAP_LEDGE) || 
	(Attacker[client] && IsClientInGame(Attacker[client]) && IsPlayerAlive(Attacker[client]))))
	{
		bool caseDone = false;
		
		float time = GetGameTime();
		switch (HelpState[client]) // Shadowysn: I don't trust the switch case on SourcePawn, it does not have working break
		{
			case (STATE_NONE):
			{
				if (!caseDone)
				{
					HelpStartTime[client] = time;
					if (IncapType[client] == INCAP && !Attacker[client])
					{
						SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
						SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", SelfReviveDuration[client]);
					}
					if ((IncapType[client] == INCAP || IncapType[client] == INCAP_LEDGE) && (!Attacker[client] && SelfReviveDuration[client] <= 5))
					{
						SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
					}
					HelpState[client] = STATE_SELFREVIVE;
				}
				caseDone = true;
			}
			case (STATE_SELFREVIVE):
			{
				if (!caseDone)
				{
					/*if (time - HelpStartTime[client] < SelfReviveDuration[client])
					{
						PrintToChatAll("%f  %f", time - HelpStartTime[client], SelfReviveDuration[client]);
					}*/
					if (time - HelpStartTime[client] >= SelfReviveDuration[client])
					{
						SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
						SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
						SetEntProp(client, Prop_Send, "m_reviveOwner", -1);
						HelpState[client] = STATE_OK;
						SelfRevive(client);
					}
				}
				caseDone = true;
			}
			case (STATE_REVIVE):
			{
				ReviveTimer[client] = null;
				return Plugin_Stop;
			}
		}
	}
	else
	{
		if (HelpState[client] == STATE_SELFREVIVE)
		{
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
		}
		HelpState[client] = STATE_OK;
		IncapType[client] = INCAP_NONE;
		ReviveTimer[client] = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int damagetype = GetEventInt(event, "type");
	if (!IsValidClient(client) || !IsGameSurvivor(client)) return;
	
	if (
	(HelpState[client] == STATE_SELFREVIVE || HelpState[client] == STATE_NONE)
	&&
	(damagetype != 131072 && !Attacker[client] && (!attacker || (attacker && !IsGameSurvivor(attacker))))
	&&
	(IncapType[client] == INCAP || IncapType[client] == INCAP_LEDGE)
	)
	{
		if (HelpState[client] == STATE_SELFREVIVE)
		{
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
			if (SelfReviveDuration[client] <= 5)
			{
				SetEntProp(client, Prop_Send, "m_reviveOwner", -1);
			}
			HelpState[client] = STATE_NONE;
		}
		RestartTimer(client);
	}
	else if (HelpState[client] == STATE_REVIVE && damagetype == 131072)
	{
		HelpState[client] = STATE_NONE;
	}
}

void RestartTimer(int client)
{
	if (!IsValidClient(client)) return;
	
	if (DelayTimer[client] != null)
	{
		KillTimer(DelayTimer[client]);
		DelayTimer[client] = null;
	}
	if (ReviveTimer[client] != null)
	{
		KillTimer(ReviveTimer[client]);
		ReviveTimer[client] = null;
	}
	if (IncapType[client] == INCAP_LEDGE)
	{
		DelayTimer[client] = CreateTimer(g_fAutoHelp_Ledge_Delay, Timer_Delay, GetClientUserId(client));
	}
	else if (IncapType[client] == INCAP)
	{
		DelayTimer[client] = CreateTimer(g_fAutoHelp_Incap_Delay, Timer_Delay, GetClientUserId(client));
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	Attacker[client] = 0;
	IncapType[client] = INCAP_NONE;
	HelpState[client] = STATE_OK;
	DelayTimer[client] = null;
	if (ReviveTimer[client] != null)
	{
		KillTimer(ReviveTimer[client]);
	}
	StopBeat(client);
}

void Event_SurvivorRescued(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "subject"));
	Attacker[client] = 0;
	IncapType[client] = INCAP_NONE;
	HelpState[client] = STATE_OK;
	DelayTimer[client] = null;
	ReviveTimer[client] = null;
	StopBeat(client);
}

void Event_ReviveBegin(Event event, const char[] name, bool dontBroadcast)
{
	//PrintToChatAll("Event_ReviveBegin");
	int client = GetClientOfUserId(GetEventInt(event, "subject"));
	HelpState[client] = STATE_REVIVE;
	DelayTimer[client] = null;
	ReviveTimer[client] = null;
}

void Event_ReviveEnd(Event event, const char[] name, bool dontBroadcast)
{
	//PrintToChatAll("Event_ReviveEnd");
	int client = GetClientOfUserId(GetEventInt(event, "subject"));
	HelpState[client] = STATE_NONE;
	RestartTimer(client);
}

void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	//PrintToChatAll("Event_ReviveSuccess");
	int client = GetClientOfUserId(GetEventInt(event, "subject"));
	IncapType[client] = INCAP_NONE;
	HelpState[client] = STATE_OK;
	ReviveTimer[client] = null;
}

void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "subject"));
	StopBeat(client);
}

/*void GetHealth(int client)
{
	if (!IsValidClient(client) || !IsGameSurvivor(client)) return;
	
	CreateTimer(0.1, Timer_GetHealth, GetClientUserId(client));
}

Action Timer_GetHealth(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	
	if (!IsValidClient(client) || !IsGameSurvivor(client) || !IsIncapacitated(client, 1)) return;
	
	int health = GetClientHealth(client);
	if (!health)
	{ health = 100; }
	int delay = RoundFloat(g_fAutoHelp_Ledge_Delay);
	int duration = RoundFloat(g_fAutoHelp_Ledge_Duration);
	int revivehealth = health - (delay + duration);
	if (revivehealth < 1)
	{ revivehealth = 1; }
	ReviveHealth[client] = revivehealth;
}*/

void SelfRevive(int client)
{
	if (!IsValidClient(client)) return;
	
	int attacker = Attacker[client];
	if (IsValidClient(attacker, false) && IsPlayerAlive(attacker))
	// Using IsValidClient(attacker) fucks up all proceeding code of this in game
	{
		KnockAttacker(client, attacker);
	}
	Attacker[client] = 0;
	Revive(client);
}

void KnockAttacker(int client, int attacker)
{
	SetVariantString("self.Stagger(self.GetOrigin())");
	AcceptEntityInput(attacker, "RunScriptCode");
	SetDTCountdownTimer(attacker, "m_staggerTimer", 0.01);
	
	int class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
	switch (class)
	{
		case (HUNTER):
		{
			TimerSlapPlayer[attacker] = CreateTimer(0.1, Timer_SlapPlayer, GetClientUserId(attacker), TIMER_REPEAT);
			CreateTimer(0.6, Timer_StopSlap, GetClientUserId(attacker));
			return;
		}
		case (CHARGER):
		{
			TimerSlapPlayer[attacker] = CreateTimer(0.5, Timer_SlapPlayer, GetClientUserId(attacker), TIMER_REPEAT);
			CreateTimer(2.0, Timer_StopSlap, GetClientUserId(attacker));
			TimerSlapPlayer[client] = CreateTimer(0.5, Timer_SlapPlayer, GetClientUserId(client), TIMER_REPEAT);
			CreateTimer(2.0, Timer_StopSlap, GetClientUserId(client));
			return;
		}
	}
}

void SetDTCountdownTimer(int entity, const char[] timer_str, float duration)
{
	SetEntDataFloat(entity, (FindSendPropInfo("CTerrorPlayer", timer_str)+4), duration, true);
	SetEntDataFloat(entity, (FindSendPropInfo("CTerrorPlayer", timer_str)+8), GetGameTime()+duration, true);
}

/*void ExecuteCommand(int client, const char[] strCommand)
{
	if (!IsValidClient(client)) return;

	SetCommandFlags(strCommand, GetCommandFlags(strCommand) & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s", strCommand);
	SetCommandFlags(strCommand, GetCommandFlags(strCommand));
}*/

Action Timer_SlapPlayer(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if (!IsValidClient(client)) return Plugin_Continue;
	
	SlapPlayer(client, 0, false);
	return Plugin_Continue;
}

Action Timer_StopSlap(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if (!IsValidClient(client)) return Plugin_Continue;
	
	if (TimerSlapPlayer[client] != null)
	{
		KillTimer(TimerSlapPlayer[client]);
		TimerSlapPlayer[client] = null;
	}
	return Plugin_Continue;
}

void Revive(int client)
{
	if (IncapType[client] == INCAP || IncapType[client] == INCAP_LEDGE)
	{
		if (IsIncapacitated(client, 1))
		{
			//int revivecount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
			VScriptCheat(client);
			/*SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
			SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
			SetEntProp(client, Prop_Send, "m_reviveOwner", 0);
			SetEntityHealth(client, ReviveHealth[client]);
			SetEntProp(client, Prop_Send, "m_currentReviveCount", revivecount);*/
		}
		else
		{ 
			//int revivecount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
			VScriptCheat(client);
			//SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
			//SetEntProp(client, Prop_Send, "m_reviveOwner", 0);
			//SetEntityHealth(client, 1);
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", g_fAutoHelp_Incap_Health);
			/*SetEntProp(client, Prop_Send, "m_currentReviveCount", (revivecount + 1));
			if (GetEntProp(client, Prop_Send, "m_currentReviveCount") == GetConVarInt(incap_count))
			{
				SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
				EmitSoundToClient(client, "player/heartbeatloop.wav");
				HeartSound[client] = 1;
			}*/
		}
	}
	IncapType[client] = INCAP_NONE;
}

void VScriptCheat(int client)
{
	SetVariantString("self.ReviveFromIncap()");
	AcceptEntityInput(client, "RunScriptCode");
	CreateTimer(0.4, Timer_PainSnd, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_PainSnd(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if (!IsValidClient(client)) return Plugin_Continue;
	
	AcceptEntityInput(client, "CancelCurrentScene");
	
	AcceptEntityInput(client, "ClearContext");
	
	SetVariantString("PainLevel:Minor:0.1");
	AcceptEntityInput(client, "AddContext");
	SetVariantString("Pain");
	AcceptEntityInput(client, "SpeakResponseConcept");
	return Plugin_Continue;
}

void StopBeat(int client)
{
	if (!IsValidClient(client)) return;
	
	if (HeartSound[client])
	{
		StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
		HeartSound[client] = 0;
	}
}
/*
int GetInfectedAbility(int client)
{
	if (!IsInfected(client)) return -1;
	
	int ability_ent = -1;
	if (HasEntProp(client, Prop_Send, "m_customAbility"))
	{
		ability_ent = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	}
	return ability_ent;
}
*/
/*bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }

bool IsSurvivor(int client)
{ return (GetClientTeam(client) == 2 || GetClientTeam(client) == 4); }*/

bool IsGameSurvivor(int client)
{ return (GetClientTeam(client) == 2); }

//bool IsInfected(int client)
//{ return (GetClientTeam(client) == 3); }

bool IsTeamGameSurvivor(int team)
{ return (team == 2); }

bool IsIncapacitated(int client, int hanging = 2)
{
	bool isIncap = view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
	bool isHanging = view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge"));
	
	switch (hanging)
	{
		// if hanging is 2, don't care about hanging
		case 2:
			return (isIncap);
		// if 1, check for hanging too
		case 1:
			return (isIncap && isHanging);
		// otherwise, must just be incapped to return true
		case 0:
			return (isIncap && !isHanging);
	}
	return false;
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}