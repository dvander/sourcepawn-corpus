#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.2.3"

public Plugin:myinfo = 
{
	name = "[L4D2] AutoHelp",
	author = "chinagreenelvis",
	description = "Survivors help themselves from incapacitation, ledge grabs, and special infected attacks.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"	
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

#define SMOKER 1
#define HUNTER 3
#define JOCKEY 5
#define CHARGER 6
#define TANK 8

new Handle:DelayTimer[MAXPLAYERS+1];
new Handle:ReviveTimer[MAXPLAYERS+1];
new Handle:TimerSlapPlayer[MAXPLAYERS+1];

new HelpState[MAXPLAYERS+1];
new IncapType[MAXPLAYERS+1];
new Attacker[MAXPLAYERS+1];

new Float:HelpStartTime[MAXPLAYERS+1];
new Float:SelfReviveDuration[MAXPLAYERS+1];
new ReviveHealth[MAXPLAYERS+1];

new Handle:autohelp_bots = INVALID_HANDLE;
new Handle:autohelp_incap = INVALID_HANDLE;
new Handle:autohelp_incap_delay = INVALID_HANDLE;
new Handle:autohelp_incap_duration = INVALID_HANDLE;
new Handle:autohelp_incap_health = INVALID_HANDLE;
new Handle:autohelp_ledge = INVALID_HANDLE;
new Handle:autohelp_ledge_delay = INVALID_HANDLE;
new Handle:autohelp_ledge_duration = INVALID_HANDLE;
new Handle:autohelp_specials = INVALID_HANDLE;
new Handle:autohelp_specials_delay = INVALID_HANDLE;
new Handle:autohelp_specials_duration = INVALID_HANDLE;
new Handle:autohelp_specials_smoker_drag = INVALID_HANDLE;

new HeartSound[MAXPLAYERS+1];

public OnPluginStart()
{
	CreateConVar("autohelp_version", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	
	autohelp_bots = CreateConVar("autohelp_bots", "1", "Allow AutoHelp for survivor bots? 0:No, 1:Yes", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	autohelp_incap = CreateConVar("autohelp_incap", "1", "Allow AutoHelp for incapacitation? 0:No, 1:Yes", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	autohelp_incap_delay = CreateConVar("autohelp_incap_delay", "3", "AutoHelp delay for incapacitation", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	autohelp_incap_duration = CreateConVar("autohelp_incap_duration", "4", "AutoHelp duration for incapacitation (setting higher than 5 will disable animation)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	autohelp_incap_health = CreateConVar("autohelp_incap_health", "30", "Health buffer after AutoHelp from incapacitation", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	autohelp_ledge = CreateConVar("autohelp_ledge", "1", "Allow AutoHelp for ledge grabs? 0:No, 1:Yes", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);		
	autohelp_ledge_delay = CreateConVar("autohelp_ledge_delay", "3", "AutoHelp delay for ledge grabs", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	autohelp_ledge_duration = CreateConVar("autohelp_ledge_duration", "4", "AutoHelp duration for ledge grabs (setting lower than 4 will cause animation issues, higher than 5 will disable the animation)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	autohelp_specials = CreateConVar("autohelp_specials", "1", "Allow AutoHelp for special infected holds?, 0:No, 1:Yes", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	autohelp_specials_delay = CreateConVar("autohelp_specials_delay", "3", "AutoHelp delay for special infected holds", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	autohelp_specials_duration = CreateConVar("autohelp_specials_duration", "4", "AutoHelp duration for special infected holds", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	autohelp_specials_smoker_drag = CreateConVar("autohelp_specials_smoker_drag", "10", "Maximum time a survivor can be dragged before AutoHelp kicks in", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "cge_l4d2_autohelp");
	
	HookEvent("round_start", Event_RoundStart);
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
	HookEvent("player_incapacitated_start", Event_PlayerIncapacitatedStart);
	HookEvent("player_ledge_grab", Event_PlayerLedgeGrab);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("survivor_rescued", Event_SurvivorRescued);
	HookEvent("revive_begin", Event_ReviveBegin);
	HookEvent("revive_end", Event_ReviveEnd);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("heal_success", Event_HealSuccess);
}

public OnMapStart()
{
	PrecacheSound("player/heartbeatloop.wav", true);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	
}

public OnClientDisconnect()
{
	new client = GetClientOfUserId(client);
	HelpState[client] = STATE_OK;
	IncapType[client] = INCAP_NONE;
	Attacker[client] = 0;
	HelpStartTime[client] = 0.0;
	ReviveTimer[client] = INVALID_HANDLE;
	DelayTimer[client] = INVALID_HANDLE;
	HeartSound[client] = 0;
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			HelpState[client] = STATE_OK;
			IncapType[client] = INCAP_NONE;
			Attacker[client] = 0;
			HelpStartTime[client] = 0.0;
			if(ReviveTimer[client] != INVALID_HANDLE)
			{
				KillTimer(ReviveTimer[client]);
			}
			ReviveTimer[client] = INVALID_HANDLE;
			DelayTimer[client] = INVALID_HANDLE;
			HeartSound[client] = 0;
			GetHealth(client);
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientOfUserId(GetEventInt(event, "team"));
	if(client)
	{
		if (IsClientInGame(client) && team == 2)
		{
			HelpState[client] = STATE_OK;
			IncapType[client] = INCAP_NONE;
			Attacker[client] = 0;
			HelpStartTime[client] = 0.0;
			if(ReviveTimer[client] != INVALID_HANDLE)
			{
				KillTimer(ReviveTimer[client]);
			}
			ReviveTimer[client] = INVALID_HANDLE;
			DelayTimer[client] = INVALID_HANDLE;
			HeartSound[client] = 0;
			GetHealth(client);
		}
	}
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			GetHealth(client);
		}
	}
}

public Event_TongueGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_GRAB;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = float(GetConVarInt(autohelp_specials_duration));
	DelayTimer[victim] = CreateTimer(float(GetConVarInt(autohelp_specials_smoker_drag)), Timer_Delay, victim);
}

public Event_ChokeStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_GRAB;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = float(GetConVarInt(autohelp_specials_duration));
	if (ReviveTimer[victim])
	{
		ReviveTimer[victim] = INVALID_HANDLE;
		DelayTimer[victim] = CreateTimer(0.1, Timer_Delay, victim);
	}
	else
	{
		DelayTimer[victim] = CreateTimer(float(GetConVarInt(autohelp_specials_delay)), Timer_Delay, victim);
	}
}


public Event_TongueRelease (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if (Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}
}

public Event_LungePounce (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_POUNCE;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = float(GetConVarInt(autohelp_specials_duration));
	DelayTimer[victim] = CreateTimer(float(GetConVarInt(autohelp_specials_delay)), Timer_Delay, victim);	 
}

public Event_PounceStopped (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if (Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}
}

public Event_JockeyRide (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_RIDE;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = float(GetConVarInt(autohelp_specials_duration));
	DelayTimer[victim] = CreateTimer(float(GetConVarInt(autohelp_specials_delay)), Timer_Delay, victim);	
}

public Event_JockeyRideEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if (Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}
}

public Event_ChargerPummelStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	if (GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 1)
	{
		IncapType[victim] = INCAP;
	}
	if (GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 0)
	{
		IncapType[victim] = INCAP_PUMMEL;
	}
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = float(GetConVarInt(autohelp_specials_duration));
	DelayTimer[victim] = CreateTimer(float(GetConVarInt(autohelp_specials_delay)), Timer_Delay, victim);	
}

public Event_ChargerPummelEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if (Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}
}

public Event_PlayerIncapacitatedStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	//Just in case.
}

public Event_PlayerIncapacitated (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	IncapType[victim] = INCAP;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = float(GetConVarInt(autohelp_incap_duration));
	ReviveTimer[victim] = INVALID_HANDLE;
	DelayTimer[victim] = CreateTimer(float(GetConVarInt(autohelp_incap_delay)), Timer_Delay, victim);	
}

public Event_PlayerLedgeGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	IncapType[victim] = INCAP_LEDGE;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = float(GetConVarInt(autohelp_ledge_duration));
	DelayTimer[victim] = CreateTimer(float(GetConVarInt(autohelp_ledge_delay)), Timer_Delay, victim);	
}

public Action:Timer_Delay(Handle:timer, any:client)
{
	//PrintToChatAll("Timer_Delay");
	if (client)
	{
		if (GetConVarInt(autohelp_bots) == 0)
		{
			if (IsFakeClient(client))
			{
				if (GetEntProp(client, Prop_Send, "m_humanSpectatorUserID") == 0)
				{
					return;
				}
			}
		}
		if ((HelpState[client] == STATE_NONE) && ((IncapType[client] == INCAP && GetConVarInt(autohelp_incap) != 0) || (IncapType[client] == INCAP_LEDGE && GetConVarInt(autohelp_ledge) != 0) || ((IncapType[client] == INCAP_GRAB || IncapType[client] == INCAP_POUNCE || IncapType[client] == INCAP_RIDE || IncapType[client] == INCAP_PUMMEL) && GetConVarInt(autohelp_specials) != 0)))
		{
			ReviveTimer[client] = CreateTimer(0.1, Timer_SelfRevive, client, TIMER_REPEAT);
		}
	}
}

public Action:Timer_SelfRevive(Handle:timer, any:client)
{
	//PrintToChatAll("Timer_SelfRevive");
	if (IsClientInGame(client))
	{
		DelayTimer[client] = INVALID_HANDLE;
		if (IsPlayerAlive(client) && HelpState[client] != STATE_OK && ((IncapType[client] == INCAP || IncapType[client] == INCAP_LEDGE) || (Attacker[client] && IsClientInGame(Attacker[client]) && IsPlayerAlive(Attacker[client]))))
		{
			new Float:time = GetEngineTime();
			if (HelpState[client] == STATE_NONE)
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
			if (HelpState[client] == STATE_SELFREVIVE)
			{
				if (time - HelpStartTime[client] < SelfReviveDuration[client])
				{
					//PrintToChatAll("%f  %f", time - HelpStartTime[client], SelfReviveDuration[client]);
				}
				if (time - HelpStartTime[client] >= SelfReviveDuration[client])
				{
					SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
					SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
					SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
					HelpState[client] = STATE_OK;
					SelfRevive(client);
				}
			}
			if (HelpState[client] == STATE_REVIVE)
			{
				ReviveTimer[client] = INVALID_HANDLE;
				return Plugin_Stop;
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
			ReviveTimer[client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damagetype = GetEventInt(event, "type");
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 0 && GetEntProp(client, Prop_Send, "m_isIncapacitated") == 0)
		{
			GetHealth(client);
		}
		if (HelpState[client] == STATE_SELFREVIVE || HelpState[client] == STATE_NONE)
		{
			if (damagetype != 131072 && !Attacker[client] && (!attacker || (attacker && GetClientTeam(attacker) != 2)))
			{
				if (IncapType[client] == INCAP || IncapType[client] == INCAP_LEDGE)
				{
					if (HelpState[client] == STATE_SELFREVIVE)
					{
						SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
						SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
						if (SelfReviveDuration[client] <= 5)
						{
							SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
						}
						HelpState[client] = STATE_NONE;
					}
					RestartTimer(client);
				}
			}
		}
		if (HelpState[client] == STATE_REVIVE)
		{
			if (damagetype == 131072)
			{
				HelpState[client] = STATE_NONE;
			}
		}
	}
}

RestartTimer(client)
{
	if (client)
	{
		if (DelayTimer[client] != INVALID_HANDLE)
		{
			KillTimer(DelayTimer[client]);
			DelayTimer[client] = INVALID_HANDLE;
		}
		if (ReviveTimer[client] != INVALID_HANDLE)
		{
			KillTimer(ReviveTimer[client]);
			ReviveTimer[client] = INVALID_HANDLE;
		}
		if (IncapType[client] == INCAP_LEDGE)
		{
			DelayTimer[client] = CreateTimer(float(GetConVarInt(autohelp_ledge_delay)), Timer_Delay, client);
		}
		if (IncapType[client] == INCAP)
		{
			DelayTimer[client] = CreateTimer(float(GetConVarInt(autohelp_incap_delay)), Timer_Delay, client);
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	Attacker[client] = 0;
	IncapType[client] = INCAP_NONE;
	HelpState[client] = STATE_OK;
	DelayTimer[client] = INVALID_HANDLE;
	ReviveTimer[client] = INVALID_HANDLE;
	StopBeat(client);
}

public Event_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	Attacker[client] = 0;
	IncapType[client] = INCAP_NONE;
	HelpState[client] = STATE_OK;
	DelayTimer[client] = INVALID_HANDLE;
	ReviveTimer[client] = INVALID_HANDLE;
	StopBeat(client);
	GetHealth(client);
}

public Event_ReviveBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("Event_ReviveBegin");
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	HelpState[client] = STATE_REVIVE;
	DelayTimer[client] = INVALID_HANDLE;
	ReviveTimer[client] = INVALID_HANDLE;
}

public Event_ReviveEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("Event_ReviveEnd");
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	HelpState[client] = STATE_NONE;
	RestartTimer(client);
}

public Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("Event_ReviveSuccess");
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	IncapType[client] = INCAP_NONE;
	HelpState[client] = STATE_OK;
	ReviveTimer[client] = INVALID_HANDLE;
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		GetHealth(client);
	}
}

public Event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	StopBeat(client);
	GetHealth(client);
}

GetHealth(client)
{
	if (client)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			CreateTimer(0.1, Timer_GetHealth, client);
		}
	}
}

public Action:Timer_GetHealth(Handle:timer, any:client)
{
	if (client)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 0 && GetEntProp(client, Prop_Send, "m_isIncapacitated") == 0)
			{
				new health = GetClientHealth(client);
				if (!health)
				{
					health = 100;
				}
				new delay = GetConVarInt(autohelp_ledge_delay);
				new duration = GetConVarInt(autohelp_ledge_duration);
				new revivehealth = health - (delay + duration);
				if (revivehealth < 1)
				{
					revivehealth = 1;
				}
				ReviveHealth[client] = revivehealth;
			}
		}
	}
}

SelfRevive(client)
{	
	if (client)
	{
		if (Attacker[client])
		{
			KnockAttacker(client);
			Attacker[client] = 0;
		}
		Revive(client);
	}
}

KnockAttacker(client)
{
	if (client)
	{
		new attacker = Attacker[client];
		if (IsClientInGame(attacker) && IsPlayerAlive(attacker))
		{
			if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == SMOKER)
			{
				SetEntProp(client, Prop_Send, "m_lifeState", 2);
				CreateTimer(0.1, Timer_RestoreState, client);
			}
			if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == HUNTER)
			{
				CallOnPounceEnd(client);
				SetEntProp(client, Prop_Send, "m_lifeState", 2);
				TimerSlapPlayer[attacker] = CreateTimer(0.1, Timer_SlapPlayer, attacker, TIMER_REPEAT);
				CreateTimer(0.6, Timer_StopSlap, attacker);
				CreateTimer(0.5, Timer_RestoreState, client);
			}
			if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == JOCKEY)
			{
				ExecuteCommand(attacker, "dismount");
			}
			if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == CHARGER)
			{
				CallOnPummelEnded(client);
				if (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 0)
				{
					SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
					SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
				}
				TimerSlapPlayer[attacker] = CreateTimer(0.5, Timer_SlapPlayer, attacker, TIMER_REPEAT);
				CreateTimer(2.0, Timer_StopSlap, attacker);
				TimerSlapPlayer[client] = CreateTimer(0.5, Timer_SlapPlayer, client, TIMER_REPEAT);
				CreateTimer(2.0, Timer_StopSlap, client);
			}
		}
	}
}

ExecuteCommand(client, String:strCommand[])
{
	if (client)
	{
		SetCommandFlags(strCommand, GetCommandFlags(strCommand) & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s", strCommand);
		SetCommandFlags(strCommand, GetCommandFlags(strCommand));
	}
}

public Action:Timer_RestoreState(Handle:timer, any:client)
{
	if (client)
	{
		SetEntProp(client, Prop_Send, "m_lifeState", 0);
	}
}

public Action:Timer_SlapPlayer(Handle:timer, any:client)
{
	if (client)
	{
		SlapPlayer(client, 0, false);
	}
}

public Action:Timer_StopSlap(Handle:timer, any:client)
{
	if (client)
	{
		if (TimerSlapPlayer[client] != INVALID_HANDLE)
		{
			KillTimer(TimerSlapPlayer[client]);
			TimerSlapPlayer[client] = INVALID_HANDLE;
		}
	}
}

CallOnPummelEnded(client)
{
	if (client)
	{
		static Handle:hOnPummelEnded = INVALID_HANDLE;
		if (hOnPummelEnded == INVALID_HANDLE)
		{
			new Handle:hConf = INVALID_HANDLE;
			hConf = LoadGameConfigFile("cge_l4d2_autohelp");
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded");
			PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
			hOnPummelEnded = EndPrepSDKCall();
			CloseHandle(hConf);
			if (hOnPummelEnded == INVALID_HANDLE)
			{
				SetFailState("Can't get CTerrorPlayer::OnPummelEnded SDKCall!");
				return;
			}            
		}
		SDKCall(hOnPummelEnded, client, true, -1);
	}
}

CallOnPounceEnd(client)
{
    if (client)
	{
		static Handle:hOnPounceEnd = INVALID_HANDLE;
		if (hOnPounceEnd == INVALID_HANDLE){
			new Handle:hConf = INVALID_HANDLE;
			hConf = LoadGameConfigFile("cge_l4d2_autohelp");
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTerrorPlayer::OnPounceEnd");
			hOnPounceEnd = EndPrepSDKCall();
			CloseHandle(hConf);
			if (hOnPounceEnd == INVALID_HANDLE){
				SetFailState("Can't get CTerrorPlayer::OnPounceEnd SDKCall!");
				return;
			}            
		}
		SDKCall(hOnPounceEnd,client);
	}
} 

Revive(client)
{
	if (client)
	{
		//PrintToChatAll("Revive");
		if (IncapType[client] == INCAP || IncapType[client] == INCAP_LEDGE)
		{
			if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 1)
			{
				new revivecount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
				HealthCheat(client);
				SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
				SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
				SetEntProp(client, Prop_Send, "m_reviveOwner", 0);
				SetEntityHealth(client, ReviveHealth[client]);
				SetEntProp(client, Prop_Send, "m_currentReviveCount", revivecount);
			}
			else
			{ 
				new revivecount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
				HealthCheat(client);
				SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
				SetEntityHealth(client, 1);
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(GetConVarInt(autohelp_incap_health)));
				SetEntProp(client, Prop_Send, "m_reviveOwner", 0);
				SetEntProp(client, Prop_Send, "m_currentReviveCount", (revivecount + 1));
				if (GetEntProp(client, Prop_Send, "m_currentReviveCount") == GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
				{
					SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
					EmitSoundToClient(client, "player/heartbeatloop.wav");
					HeartSound[client] = 1;
				}
			}
			
		}
		IncapType[client] = INCAP_NONE;
		GetHealth(client);
	}
}

HealthCheat(client)
{
	if (client)
	{
		new userflags = GetUserFlagBits(client);
		new cmdflags = GetCommandFlags("give");
		SetUserFlagBits(client, ADMFLAG_ROOT);
		SetCommandFlags("give", cmdflags & ~FCVAR_CHEAT);
		FakeClientCommand(client,"give health");
		SetCommandFlags("give", cmdflags);
		SetUserFlagBits(client, userflags);
	}
}

StopBeat(client)
{
	if (client)
	{
		if (HeartSound[client])
		{
			StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
			HeartSound[client] = 0;
		}
	}
}
