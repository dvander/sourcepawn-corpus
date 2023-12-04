#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define INCAP_NONE 0
#define INCAP 1
#define INCAP_LEDGE	6

#define STATE_NONE 0
#define STATE_SELFREVIVE 1
#define STATE_REVIVE 2
#define STATE_OK 3
#define STATE_ATTACKED 4

#define PLUGIN_NAME_TECH "autohelp"
#define PLUGIN_NAME_SHORT "AutoHelp"

static Handle DelayTimer[MAXPLAYERS+1];
static Handle ReviveTimer[MAXPLAYERS+1];

static int HelpState[MAXPLAYERS+1];
static int IncapType[MAXPLAYERS+1];
static int Attacker[MAXPLAYERS+1];

static float HelpStartTime[MAXPLAYERS+1];
static float SelfReviveDuration[MAXPLAYERS+1];

static ConVar AutoHelp_Bots, AutoHelp_Players, AutoHelp_Ledge, AutoHelp_Ledge_Delay, AutoHelp_Ledge_Duration;
bool g_bAutoHelp_Bots, g_bAutoHelp_Players;
bool g_bAutoHelp_Ledge;
float g_fAutoHelp_Ledge_Delay, g_fAutoHelp_Ledge_Duration;



static int HeartSound[MAXPLAYERS+1];

public void OnPluginStart()
{
	static char cmd_str[64];
	static char desc_str[128];
	Format(cmd_str, sizeof(cmd_str), "%s_bots", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Allow %s for survivor bots? 0 - No. 1 - Yes.", PLUGIN_NAME_SHORT);
	AutoHelp_Bots = CreateConVar(cmd_str, "1", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);
	AutoHelp_Bots.AddChangeHook(CC_AH_Bots);
	
	Format(cmd_str, sizeof(cmd_str), "%s_players", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Allow %s for survivor players? 0 - No. 1 - Yes.", PLUGIN_NAME_SHORT);
	AutoHelp_Players = CreateConVar(cmd_str, "1", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);
	AutoHelp_Players.AddChangeHook(CC_AH_Players);
	
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
	
	
	AutoExecConfig(true, "cge_l4d2_autohelp");
	SetCvars();
	

	HookEvent("player_ledge_grab", Event_PlayerLedgeGrab);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
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

void CC_AH_Ledge(ConVar convar, const char[] oldValue, const char[] newValue)				{ g_bAutoHelp_Ledge =					convar.BoolValue;		}
void CC_AH_Ledge_Delay(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_fAutoHelp_Ledge_Delay =			convar.FloatValue;	}
void CC_AH_Ledge_Duration(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fAutoHelp_Ledge_Duration =			convar.FloatValue;	}


void SetCvars()
{
	CC_AH_Bots(AutoHelp_Bots, "", "");
	CC_AH_Players(AutoHelp_Players, "", "");

	CC_AH_Ledge(AutoHelp_Ledge, "", "");
	CC_AH_Ledge_Delay(AutoHelp_Ledge_Delay, "", "");
	CC_AH_Ledge_Duration(AutoHelp_Ledge_Duration, "", "");
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

public void OnClientDisconnect(int client)
{
	HelpState[client] = STATE_OK;
	IncapType[client] = INCAP_NONE;
	Attacker[client] = 0;
	HelpStartTime[client] = 0.0;
	if (ReviveTimer[client] != null)
	{
		KillTimer(ReviveTimer[client]);
		ReviveTimer[client] = null;
	}
	DelayTimer[client] = null;
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

void Event_PlayerLedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(victim)) return;
	
	IncapType[victim] = INCAP_LEDGE;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = g_fAutoHelp_Ledge_Duration;
	if (DelayTimer[victim] == null)
		DelayTimer[victim] = CreateTimer(g_fAutoHelp_Ledge_Delay, Timer_Delay, GetClientUserId(victim));	
}

Action Timer_Delay(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	DelayTimer[client] = null;
	
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
	
	if ((HelpState[client] == STATE_NONE) && ((IncapType[client] == INCAP_LEDGE && g_bAutoHelp_Ledge)))
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
	(IncapType[client] == INCAP_LEDGE || 
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

					if (IncapType[client] == INCAP_LEDGE && (!Attacker[client] && SelfReviveDuration[client] <= 5))
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
		if (DelayTimer[client] == null)
			DelayTimer[client] = CreateTimer(g_fAutoHelp_Ledge_Delay, Timer_Delay, GetClientUserId(client));
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
		ReviveTimer[client] = null;
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
	int client = GetClientOfUserId(GetEventInt(event, "subject"));
	HelpState[client] = STATE_REVIVE;
	DelayTimer[client] = null;
	ReviveTimer[client] = null;
}

void Event_ReviveEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "subject"));
	HelpState[client] = STATE_NONE;
	RestartTimer(client);
}

void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
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

void SelfRevive(int client)
{
	if (!IsValidClient(client)) return;

	Revive(client);
}

void Revive(int client)
{
	if (IncapType[client] == INCAP_LEDGE)
	{
		if (IsIncapacitated(client, 1))
		{
			VScriptCheat(client);
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

bool IsGameSurvivor(int client)
{ return (GetClientTeam(client) == 2); }


bool IsTeamGameSurvivor(int team)
{ return (team == 2); }

bool IsIncapacitated(int client, int hanging = 2)
{
	bool isIncap = view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
	bool isHanging = view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge"));
	
	switch (hanging)
	{
		case 2:
			return (isIncap);
		case 1:
			return (isIncap && isHanging);
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