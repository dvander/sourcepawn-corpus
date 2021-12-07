#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.4.1"

public Plugin:myinfo = 
{
	name = "[L4D, L4D2] Self Revive edited by GsiX",
	author = "chinagreenelvis (Based on the Self Help plugin by Pan Xiaohai)",
	description = "Survivors can revive themselves from incapacitation, ledge grabs, and special infected attacks",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=143073"	
}

#define SOUND_KILL1  "/weapons/knife/knife_hitwall1.wav"
#define SOUND_KILL2  "/weapons/knife/knife_deploy.wav"

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

#define SMOKER 1
#define HUNTER 3
#define JOCKEY 5
#define CHARGER 6
#define TANK 8

new Handle:Timers[MAXPLAYERS+1];
new Handle:HintTimer[MAXPLAYERS+1];
new Handle:TimerSlapPlayer[MAXPLAYERS+1];

new HelpState[MAXPLAYERS+1];
new IncapType[MAXPLAYERS+1];
new Attacker[MAXPLAYERS+1];

new Float:HelpStartTime[MAXPLAYERS+1];
new Float:SelfReviveDuration[MAXPLAYERS+1];
new ReviveHealth[MAXPLAYERS+1];
new HeartSound[MAXPLAYERS+1];

new Handle:selfrevive_hint_delay = INVALID_HANDLE;
new Handle:selfrevive_delay = INVALID_HANDLE;
new Handle:selfrevive_delay_ledge = INVALID_HANDLE;
new Handle:selfrevive_delay_incap = INVALID_HANDLE;
new Handle:selfrevive_duration = INVALID_HANDLE;
new Handle:selfrevive_duration_ledge = INVALID_HANDLE;
new Handle:selfrevive_duration_incap = INVALID_HANDLE;
new Handle:selfrevive_health_incap = INVALID_HANDLE;
//new Handle:selfrevive_health_ledge = INVALID_HANDLE;
new Handle:selfrevive_grab = INVALID_HANDLE;
new Handle:selfrevive_pounce = INVALID_HANDLE;
new Handle:selfrevive_ride = INVALID_HANDLE;
new Handle:selfrevive_pummel = INVALID_HANDLE;
new Handle:selfrevive_ledge = INVALID_HANDLE;
new Handle:selfrevive_incap = INVALID_HANDLE;
new Handle:selfrevive_kill = INVALID_HANDLE;
new Handle:selfrevive_versus = INVALID_HANDLE;
new Handle:selfrevive_bot;
new Handle:selfrevive_blackwhite;
new GameMode;
new L4D2Version=false;

public OnPluginStart()
{
	CreateConVar("selfrevive_version", PLUGIN_VERSION, " ", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	selfrevive_hint_delay = CreateConVar("selfrevive_hint_delay", "4.0", "Self revive hint delay", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfrevive_delay = CreateConVar("selfrevive_delay", "0.0", "Self revive delay", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfrevive_delay_ledge = CreateConVar("selfrevive_delay_ledge", "0.0", "Self revive delay", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfrevive_delay_incap = CreateConVar("selfrevive_delay_incap", "0.0", "Self revive delay for incapacitation", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfrevive_duration = CreateConVar("selfrevive_duration", "3.0", "Self revive selfreviveDuration[victim]", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfrevive_duration_ledge = CreateConVar("selfrevive_duration_ledge", "4.5", "Self revive duration for ledge grab, setting higher than 5 will disable animation", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfrevive_duration_incap = CreateConVar("selfrevive_duration_incap", "5.0", "Self revive duration for incapacitation, setting higher than 5 will disable animation", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	//selfrevive_health_ledge = CreateConVar("selfrevive_health_ledge", "40.0", "How much health you have after reviving yourself from a ledge grab.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);	
	selfrevive_health_incap = CreateConVar("selfrevive_health_incap", "40.0", "How much health you have after reviving yourself from incapacitation.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfrevive_ledge = CreateConVar("selfrevive_ledge", "1", "Self revive for ledge grabs, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);		
	selfrevive_incap = CreateConVar("selfrevive_incap", "1", "Self revive for incapacitation, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfrevive_grab = CreateConVar("selfrevive_grab", "1", "Self revive for smoker grab, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfrevive_pounce = CreateConVar("selfrevive_pounce", "1", "Self revive for hunter pounce, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfrevive_ride = CreateConVar("selfrevive_ride", "1", " Self revive for jockey ride, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfrevive_pummel = CreateConVar("selfrevive_pummel", "1", "Self revive for charger pummel , 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfrevive_kill = CreateConVar("selfrevive_kill", "0", "0: Do not kill special infected when breaking free; 1: Kill special infected when breaking free", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);	
	selfrevive_versus = CreateConVar("selfrevive_versus", "0", "0: Disable in versus, 1: Enable in versus", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfrevive_bot = CreateConVar("selfrevive_bot", "0", "0: Disable , 1: Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfrevive_blackwhite = CreateConVar("selfrevive_blackwhite_max", "2", "0: Disable 1: max incap count to black n white", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d2_selfrevive");
	GameCheck();
	
	HookEvent("lunge_pounce", Event_LungePounce);
	HookEvent("pounce_stopped", Event_PounceStopped);
	HookEvent("tongue_grab", Event_TongueGrab);
	HookEvent("choke_start", Event_ChokeStart);
	HookEvent("tongue_release", Event_TongueRelease);

	if(L4D2Version)
	{
		HookEvent("jockey_ride", Event_JockeyRide);
		HookEvent("jockey_ride_end", Event_JockeyRideEnd);
		HookEvent("charger_pummel_start", Event_ChargerPummelStart);
		HookEvent("charger_pummel_end", Event_ChargerPummelEnd);
	}
	
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("player_ledge_grab", Event_PlayerLedgeGrab);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("survivor_rescued", Event_SurvivorRescued);
	HookEvent("revive_begin", Event_ReviveBegin);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("revive_end", Event_ReviveEnd);
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	SetConVarInt(FindConVar("tongue_break_from_damage_amount"), 1);
	HookConVarChange(selfrevive_blackwhite, bw_CVARChanged);
	UpdateBWConVars();
}

GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
	{
		GameMode = 3;
	}
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
	{
		GameMode = 2;
	}
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
	{
		GameMode = 1;
	}
	else
	{
		GameMode = 0;
 	}
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		L4D2Version=true;
	}	
	else
	{ 
		L4D2Version=false;
	}
}

public OnMapStart()
{
 	if(L4D2Version)	
	{
		PrecacheSound(SOUND_KILL2, true);
	}
	else 
	{
		PrecacheSound(SOUND_KILL1, true);
	}
	PrecacheSound("player/heartbeatloop.wav", true);
	
	UpdateBWConVars();
}

public bw_CVARChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateBWConVars();
}

UpdateBWConVars()
{
	if(GetConVarInt(selfrevive_blackwhite) != 0)
	{
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), GetConVarInt(selfrevive_blackwhite));
	}
}

public OnClientPutInServer()
{
	new client = GetClientOfUserId(client);
	Attacker[client] = 0;
	HelpStartTime[client] = 0.0;
	Timers[client] = INVALID_HANDLE;
	HelpState[client] = STATE_OK;
	IncapType[client] = INCAP_NONE;
	HeartSound[client] = 0;
	GetHealth(client);
}

public OnConfigsExecuted()
{
	UpdateBWConVars();
}

public OnClientDisconnect()
{
	new client = GetClientOfUserId(client);
	Timers[client] = INVALID_HANDLE;
	HelpState[client] = STATE_OK;
	IncapType[client] = INCAP_NONE;
	Attacker[client] = 0;
	HelpStartTime[client] = 0.0;
	HeartSound[client] = 0;
}
// smoker
public Event_TongueGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameMode == 2 && GetConVarInt(selfrevive_versus) == 0) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_GRAB;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = GetConVarFloat(selfrevive_duration);
	if (GetConVarInt(selfrevive_grab) > 0)
	{
		//PrintToChatAll("selfrevive_grab > 0");
		CreateTimer(GetConVarFloat(selfrevive_delay), Timer_Delay, victim);	
	}
}
public Event_ChokeStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameMode == 2 && GetConVarInt(selfrevive_versus) == 0) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_GRAB;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = GetConVarFloat(selfrevive_duration);
	if (GetConVarInt(selfrevive_grab) > 0)
	{
		//PrintToChatAll("selfrevive_grab > 0");
		CreateTimer(GetConVarFloat(selfrevive_delay), Timer_Delay, victim);	
	}
}
public Event_TongueRelease (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameMode == 2 && GetConVarInt(selfrevive_versus) == 0) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if (Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}
	if (GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 0)
	{
		if(Timers[victim] != INVALID_HANDLE)
		{
			KillTimer(Timers[victim]);
		}
		if(HintTimer[victim] != INVALID_HANDLE)
		{
			KillTimer(HintTimer[victim]);
		}
		Timers[victim] = INVALID_HANDLE;
		HintTimer[victim] =  INVALID_HANDLE;
		HelpState[victim] = STATE_NONE;
		IncapType[victim] = INCAP_NONE;
	}
	CreateTimer(0.5, Timer_StopSmokerMusic, victim);
}
// hunter
public Event_LungePounce (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameMode == 2 && GetConVarInt(selfrevive_versus) == 0) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_POUNCE;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = GetConVarFloat(selfrevive_duration);
	if (GetConVarInt(selfrevive_pounce) > 0)
	{
		CreateTimer(GetConVarFloat(selfrevive_delay), Timer_Delay, victim);	
	}
}
public Event_PounceStopped (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameMode == 2 && GetConVarInt(selfrevive_versus) == 0) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if (Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}
	if (GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 0)
	{
		if(Timers[victim] != INVALID_HANDLE)
		{
			KillTimer(Timers[victim]);
		}
		if(HintTimer[victim] != INVALID_HANDLE)
		{
			KillTimer(HintTimer[victim]);
		}
		Timers[victim] = INVALID_HANDLE;
		HintTimer[victim] =  INVALID_HANDLE;
		HelpState[victim] = STATE_NONE;
		IncapType[victim] = INCAP_NONE;
	}
	CreateTimer(0.5, Timer_StopHunterMusic, victim);
}
// jokey
public Event_JockeyRide (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameMode == 2 && GetConVarInt(selfrevive_versus) == 0) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_RIDE;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = GetConVarFloat(selfrevive_duration);
	if (GetConVarInt(selfrevive_ride) > 0)
	{
		CreateTimer(GetConVarFloat(selfrevive_delay), Timer_Delay, victim);	
	} 
}
public Event_JockeyRideEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameMode == 2 && GetConVarInt(selfrevive_versus) == 0) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if (Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}
}
//charger
public Event_ChargerPummelStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameMode == 2 && GetConVarInt(selfrevive_versus) == 0) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	if (GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 1)
	{
		IncapType[victim] = INCAP;
		SelfReviveDuration[victim] = GetConVarFloat(selfrevive_duration_incap);
		if (GetConVarInt(selfrevive_incap) > 0 && GetConVarInt(selfrevive_pummel) > 0)
		{
			CreateTimer(GetConVarFloat(selfrevive_delay_incap), Timer_Delay, victim);	
		}
	}
	if (GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 0)
	{
		IncapType[victim] = INCAP_PUMMEL;
		SelfReviveDuration[victim] = GetConVarFloat(selfrevive_duration);
		if (GetConVarInt(selfrevive_pummel) > 0)
		{
			CreateTimer(GetConVarFloat(selfrevive_delay), Timer_Delay, victim);	
		}
	}
	HelpState[victim] = STATE_NONE;
}
public Event_ChargerPummelEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameMode == 2 && GetConVarInt(selfrevive_versus) == 0) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if (Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
	}
	if (GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 0)
	{
		if(Timers[victim] != INVALID_HANDLE)
		{
			KillTimer(Timers[victim]);
		}
		if(HintTimer[victim] != INVALID_HANDLE)
		{
			KillTimer(HintTimer[victim]);
		}
		Timers[victim] = INVALID_HANDLE;
		HintTimer[victim] =  INVALID_HANDLE;
		HelpState[victim] = STATE_NONE;
		IncapType[victim] = INCAP_NONE;
	}
	CreateTimer(0.5, Timer_StopChargerMusic, victim);
}
// Incapacitated
public Event_PlayerIncapacitated (Handle:event, const String:name[], bool:dontBroadcast)
{
	UpdateBWConVars();
	if (GameMode == 2 && GetConVarInt(selfrevive_versus) == 0) return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	IncapType[victim] = INCAP;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = GetConVarFloat(selfrevive_duration_incap);
	if (GetConVarInt(selfrevive_incap) > 0)
	{
		CreateTimer(GetConVarFloat(selfrevive_delay_incap), Timer_Delay, victim);	
	}
}
// ledge grab
public Event_PlayerLedgeGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameMode == 2 && GetConVarInt(selfrevive_versus) == 0) return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	IncapType[victim] = INCAP_LEDGE;
	HelpState[victim] = STATE_NONE;
	SelfReviveDuration[victim] = GetConVarFloat(selfrevive_duration_ledge);
	if (GetConVarInt(selfrevive_incap) > 0)
	{
		CreateTimer(GetConVarFloat(selfrevive_delay_ledge), Timer_Delay, victim);	
	}
}

public Action:Timer_Delay(Handle:timer, any:client)
{
	//PrintToChatAll("Timer_Delay");
	if (IncapType[client] == INCAP && GetConVarInt(selfrevive_incap) == 0)
	{
		HelpState[client] = STATE_OK;
		Timers[client] = INVALID_HANDLE;
		return;
	}
	else if (IncapType[client] == INCAP_LEDGE && GetConVarInt(selfrevive_ledge) == 0)
	{
		HelpState[client] = STATE_OK;
		Timers[client] = INVALID_HANDLE;
		return;
	}
	else if (IncapType[client] == INCAP_GRAB && GetConVarInt(selfrevive_grab) == 0)
	{
		HelpState[client] = STATE_OK;
		Timers[client] = INVALID_HANDLE;
		return;
	}
	else if (IncapType[client] == INCAP_POUNCE && GetConVarInt(selfrevive_pounce) == 0)
	{
		HelpState[client] = STATE_OK;
		Timers[client] = INVALID_HANDLE;
		return;
	}
	else if (IncapType[client] == INCAP_RIDE && GetConVarInt(selfrevive_ride) == 0)
	{
		HelpState[client] = STATE_OK;
		Timers[client] = INVALID_HANDLE;
		return;
	}
	else if (IncapType[client] == INCAP_PUMMEL && GetConVarInt(selfrevive_pummel) == 0)
	{
		HelpState[client] = STATE_OK;
		Timers[client] = INVALID_HANDLE;
		return;
	}
	else
	{
		HelpState[client] = STATE_NONE;
		HintTimer[client] = CreateTimer(GetConVarFloat(selfrevive_hint_delay), Timer_HintDelay, client);
		Timers[client] = CreateTimer(0.2, Timer_SelfRevive, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_HintDelay(Handle:timer, any:client)
{
	//PrintToChatAll("Timer_HintDelay");
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			PrintHintText(client, "       \x03Hold \x04DUCK\x03 to help yourself!");
			HintTimer[client] = INVALID_HANDLE;
		}
		else
		{
			HintTimer[client] = INVALID_HANDLE;
		}
	}
}

public Action:Timer_SelfRevive(Handle:timer, any:client)
{
	//PrintToChatAll("Timer_SelfRevive");
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		if (IsPlayerAlive(client) && HelpState[client] != STATE_OK && ((IncapType[client] == INCAP || IncapType[client] == INCAP_LEDGE) || (Attacker[client] && IsClientInGame(Attacker[client]) && IsPlayerAlive(Attacker[client]))))
		{
			//PrintToChatAll("Can SelfRevive");
			new Float:time = GetEngineTime();
			new buttons = GetClientButtons(client);
			if (buttons & IN_DUCK || IsFakeClient(client))
			{
				if(IsFakeClient(client) && GetConVarInt(selfrevive_bot) == 0) return Plugin_Stop;
				
				if (HelpState[client] != STATE_REVIVE)
				{
					if (HelpState[client] == STATE_NONE)
					{
						if (HintTimer[client] != INVALID_HANDLE)
						{
							if (HintTimer[client])
							{
								KillTimer(HintTimer[client]);
							}
							HintTimer[client] = INVALID_HANDLE;
						}
						HelpStartTime[client] = time;
						if (L4D2Version)
						{
							if ((IncapType[client] == INCAP || IncapType[client] == INCAP_LEDGE) && (!Attacker[client] && SelfReviveDuration[client] <= 5.0))
							{
								SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
								SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", SelfReviveDuration[client]);
								SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
							}
							else
							{
								SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
								SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", SelfReviveDuration[client]);
							}
						}
						else
						{
							ShowBar(client,"Self Help", time - HelpStartTime[client], SelfReviveDuration[client]);
						}
					}
					if (time - HelpStartTime[client] < SelfReviveDuration[client])
					{
						HelpState[client] = STATE_SELFREVIVE;
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
			}
			else 
			{
				if (HelpState[client] == STATE_SELFREVIVE)
				{
					if (L4D2Version)
					{
						if ((IncapType[client] == INCAP || IncapType[client] == INCAP_LEDGE) && (!Attacker[client] || SelfReviveDuration[client] <= 5.0))
						{
							SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
							SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
							SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
							HelpState[client] = STATE_NONE;
						}
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
							SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
							HelpState[client] = STATE_NONE;
						}
					}
					else
					{
						ShowBar(client, "Self Help", 0.0, SelfReviveDuration[client]);
						HelpState[client] = STATE_NONE;
					}
					if (HintTimer[client] == INVALID_HANDLE)
					{
						HintTimer[client] = CreateTimer(GetConVarFloat(selfrevive_hint_delay), Timer_HintDelay, client);
					}
				}
				if (HelpState[client] == STATE_REVIVE)
				{
					if (time - HelpStartTime[client] > GetConVarFloat(FindConVar("survivor_revive_duration")))
					{
						HelpState[client] = STATE_NONE;
						if (HintTimer[client] == INVALID_HANDLE)
						{
							HintTimer[client] = CreateTimer(GetConVarFloat(selfrevive_hint_delay), Timer_HintDelay, client);
						}
					}
				}
			}
		}
		else
		{
			if (HelpState[client] == STATE_SELFREVIVE)
			{
				if (L4D2Version)
				{
					SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
					SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
				}
				else
				{
					ShowBar(client, "Self Help", 0.0, SelfReviveDuration[client]);
				}
			}
			HelpState[client] = STATE_OK;
			if (HintTimer[client] != INVALID_HANDLE)
			{
				if (HintTimer[client])
				{
					KillTimer(HintTimer[client]);
				}
				HintTimer[client] = INVALID_HANDLE;
			}
			Timers[client] = INVALID_HANDLE;
			//PrintToChatAll("Client Not in Game or Client Not Alive");
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
		if (HelpState[client] == STATE_SELFREVIVE)
		{
			if (damagetype != 131072 && !Attacker[client] && (!attacker || (attacker && GetClientTeam(attacker) != 2)))
			{
				if ((IncapType[client] == INCAP || IncapType[client] == INCAP_LEDGE) && (SelfReviveDuration[client] <= 5.0))
				{
					SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
					SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
					SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
					HelpState[client] = STATE_NONE;
				}
				else
				{
					//SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
					//SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
					//HelpState[client] = STATE_NONE;
				}
			}
		}
		if (HelpState[client] == STATE_REVIVE)
		{
			if (damagetype == 131072)
			{
				HelpState[client] = STATE_NONE;
				if (HintTimer[client] == INVALID_HANDLE)
				{
					HintTimer[client] = CreateTimer(GetConVarFloat(selfrevive_hint_delay), Timer_HintDelay, client);
				}
			}
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	Attacker[client] = 0;
	HelpState[client] = STATE_OK;
	IncapType[client] = INCAP_NONE;
	if(HintTimer[client] != INVALID_HANDLE)
	{
		KillTimer(HintTimer[client]);
		HintTimer[client] = INVALID_HANDLE;
	}
}

public Event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	GetHealth(client);
	CreateTimer(0.1, Timer_StopBeat, client);
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
			HeartSound[client] = 0;
			GetHealth(client);
		}
	}
}

public Event_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	Attacker[client] = 0;
	HelpState[client] = STATE_OK;
	IncapType[client] = INCAP_NONE;
	GetHealth(client);
	CreateTimer(0.1, Timer_StopBeat, client);
}

public Event_ReviveBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	new Float:time = GetEngineTime();
	HelpStartTime[client] = time;
	HelpState[client] = STATE_REVIVE;
	if(HintTimer[client] != INVALID_HANDLE)
	{
		KillTimer(HintTimer[client]);
		HintTimer[client] = INVALID_HANDLE;
	}
}

public Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	HelpState[client] = STATE_OK;
	IncapType[client] = INCAP_NONE;
	if (HintTimer[client] != INVALID_HANDLE)
	{
		KillTimer(HintTimer[client]);
		HintTimer[client] = INVALID_HANDLE;
	}
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		GetHealth(client);
	}
}
public Event_ReviveEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	new Float:time = GetEngineTime();
	if ((GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 1) || (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1))
	{
		HelpStartTime[client] = time;
		HelpState[client] = STATE_REVIVE;
		if(HintTimer[client] != INVALID_HANDLE)
		{
			KillTimer(HintTimer[client]);
			HintTimer[client] = INVALID_HANDLE;
		}
	}
}
SelfRevive(client)
{	
	if (Attacker[client])
	{
		if (GetConVarInt(selfrevive_kill) > 0) 
		{
			KillAttacker(client);
		}
		else
		{
			KnockAttacker(client);
		}
		Attacker[client] = 0;
	}
	Revive(client);
}

KillAttacker(client)
{
	new attacker = Attacker[client];
	if (IsClientInGame(attacker) && IsPlayerAlive(attacker) && GetEntProp(attacker, Prop_Send, "m_zombieClass") != TANK)
	{
		ForcePlayerSuicide(attacker);
		if(L4D2Version)
		{
			EmitSoundToAll(SOUND_KILL2, client);
		}
		else 
		{
			EmitSoundToAll(SOUND_KILL1, client);
		}
	}
}

KnockAttacker(client)
{
	new attacker = Attacker[client];
	if (IsClientInGame(attacker) && IsPlayerAlive(attacker))
	{
		if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == SMOKER)
		{
			SetEntPropEnt(attacker, Prop_Send, "m_tongueVictim", -1); 
			SetEntPropEnt(attacker, Prop_Send, "m_dragTarget", -1);
			SetEntProp(client, Prop_Send, "m_reachedTongueOwner", 0);
			SetEntProp(client, Prop_Send, "m_tongueOwner", 0); 
			SetEntProp(client, Prop_Send, "m_isHangingFromTongue", 0); 
			SetEntProp(client, Prop_Send, "m_isProneTongueDrag", 0);
			new weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 999.0);
			SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", 9999.0);
			
			CreateTimer(0.5, Timer_StopSmokerMusic, client);
			
			TimerSlapPlayer[attacker] = CreateTimer(0.2, Timer_SlapPlayer, attacker, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(2.0, Timer_StopSlap, attacker);
			CreateTimer(6.0, Timer_RestoreAttack, attacker);
		}
		if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == HUNTER)
		{
			SetEntPropEnt(attacker, Prop_Send, "m_pounceVictim", -1);
			SetEntPropEnt(client, Prop_Send, "m_pounceAttacker", -1);
			new weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 999.0);
			SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", 9999.0);
			CreateTimer(0.5, Timer_StopHunterMusic, client);
			
			TimerSlapPlayer[attacker] = CreateTimer(0.2, Timer_SlapPlayer, attacker, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(2.0, Timer_StopSlap, attacker);
			CreateTimer(6.0, Timer_RestoreAttack, attacker);
		}
		if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == JOCKEY)
		{
			ExecuteCommand(attacker, "dismount");
			new weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 999.0);
			SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", 9999.0);
			TimerSlapPlayer[attacker] = CreateTimer(0.2, Timer_SlapPlayer, attacker, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(2.0, Timer_StopSlap, attacker);
			CreateTimer(6.0, Timer_RestoreAttack, attacker);
		}
		if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == CHARGER)
		{
			SetEntPropEnt(client, Prop_Send, "m_pummelAttacker", -1);
			SetEntPropEnt(client, Prop_Send, "m_carryAttacker", -1);
			SetEntProp(client, Prop_Send, "m_nForceBone", 1);
			SetEntProp(client, Prop_Send, "m_fFlags", 129);
			SetEntProp(client, Prop_Send, "movetype", 2);
			SetEntProp(client, Prop_Send, "m_iPlayerState", 0);
			SetEntPropEnt(attacker, Prop_Send, "m_hGroundEntity", -1);
			SetEntPropEnt(attacker, Prop_Send, "m_pummelVictim", -1);
			SetEntPropEnt(attacker, Prop_Send, "m_carryVictim", -1);
			SetEntProp(attacker, Prop_Send, "m_nForceBone", 0);
			SetEntProp(attacker, Prop_Send, "movetype", 11);
			SetEntProp(attacker, Prop_Send, "m_scrimmageType", 0);
			SetEntProp(attacker, Prop_Send, "m_bAutoAimTarget", 0);
			if (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 0)
			{
				SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
				SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
			}
			new weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 999.0);
			SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", 999.0);
			CreateTimer(0.5, Timer_StopChargerMusic, client);
			
			TimerSlapPlayer[attacker] = CreateTimer(0.5, Timer_SlapPlayer, attacker, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(5.0, Timer_StopSlap, attacker);
			CreateTimer(6.0, Timer_RestoreAttack, attacker);
		}
	}
}

ExecuteCommand(Client, String:strCommand[])
{
	SetCommandFlags(strCommand, GetCommandFlags(strCommand) & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s", strCommand);
	SetCommandFlags(strCommand, GetCommandFlags(strCommand));
}

public Action:Timer_GetHealth(Handle:timer, any:client)
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
			new delay = GetConVarInt(selfrevive_delay_ledge);
			new duration = GetConVarInt(selfrevive_duration_ledge);
			new revivehealth = health - (delay + duration);
			if (revivehealth < 1)
			{
				revivehealth = 1;
			}
			ReviveHealth[client] = revivehealth;
			
			if (GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike") == 0)
			{
				StopBeat(client);
			}
		}
	}
}

public Action:Timer_SlapPlayer(Handle:timer, any:client)
{
	if(z_IsValidClient(client))
	{
		SlapPlayer(client, 0, false);
	}
}

public Action:Timer_StopSlap(Handle:timer, any:client)
{
	if (TimerSlapPlayer[client] != INVALID_HANDLE)
	{
		KillTimer(TimerSlapPlayer[client]);
		TimerSlapPlayer[client] = INVALID_HANDLE;
	}
}
public Action:Timer_RestoreAttack(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 4.0);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 4.0);
	}
}
public Action:Timer_StopSmokerMusic(Handle:timer, any:client)
{
	StopSmokerSounds(client);
}
public Action:Timer_StopHunterMusic(Handle:timer, any:client)
{
	StopHunterSounds(client);
}
public Action:Timer_StopChargerMusic(Handle:timer, any:client)
{
	StopChargerSounds(client);
}
public Action:Timer_StopBeat(Handle:timer, any:client)
{
	StopBeat(client);
}
public Action:Timer_ForceAttackerSuicide(Handle:timer, any:client)
{
	//PrintToChatAll("ForceAttackerSuicide");
	new attacker = Attacker[client];
	if (IsClientInGame(attacker) && IsPlayerAlive(attacker))
	{
		ForcePlayerSuicide(attacker);
		Revive(client);
	}
}

Revive(client)
{
	//PrintToChatAll("Revive");
	if (IncapType[client] == INCAP || IncapType[client] == INCAP_LEDGE && GetEntProp(client, Prop_Send, "m_zombieClass") != TANK)
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
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(GetConVarInt(selfrevive_health_incap)));
			SetEntProp(client, Prop_Send, "m_reviveOwner", 0);
			SetEntProp(client, Prop_Send, "m_currentReviveCount", (revivecount + 1));
			
			if(GetConVarInt(selfrevive_blackwhite) != 0 )
			{
				if (GetEntProp(client, Prop_Send, "m_currentReviveCount") >= GetConVarInt(selfrevive_blackwhite))
				{
					SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
					EmitSoundToClient(client, "player/heartbeatloop.wav");
					SetEntityRenderColor(client, 0, 255, 0, 255);
					HeartSound[client] = 1;
				}
			}
		}
		
	}
	IncapType[client] = INCAP_NONE;
	GetHealth(client);
}

ShowBar(client, String:msg[], Float:pos, Float:max)	 
{
	new String:Gauge1[2] = "-";
	new String:Gauge3[2] = "#";
	new i ;
	new String:ChargeBar[100];
	Format(ChargeBar, sizeof(ChargeBar), "");
 
	new Float:GaugeNum = pos/max*100;
	if (GaugeNum > 100.0)
		GaugeNum = 100.0;
	if (GaugeNum<0.0)
		GaugeNum = 0.0;
 	for (i=0; i<100; i++)
		ChargeBar[i] = Gauge1[0];
	new p=RoundFloat( GaugeNum);
	 
	if (p >= 0 && p < 100) ChargeBar[p] = Gauge3[0]; 
	PrintCenterText(client, "%s  %3.0f %\n<< %s >>", msg, GaugeNum, ChargeBar);
}

stock StopSmokerSounds(client)
{
	ClientCommand(client, "music_dynamic_stop_playing Event.SmokerChoke");
	ClientCommand(client, "music_dynamic_stop_playing Event.SmokerChokeHit");
	ClientCommand(client, "music_dynamic_stop_playing Event.SmokerDrag");
	ClientCommand(client, "music_dynamic_stop_playing Event.SmokerDragHit");
}
stock StopHunterSounds(client)
{
	ClientCommand(client, "music_dynamic_stop_playing Event.HunterPounce");
	ClientCommand(client, "music_dynamic_stop_playing Event.HunterHit");
}
stock StopChargerSounds(client)
{
	ClientCommand(client, "music_dynamic_stop_playing Event.ChargerSmash");
	ClientCommand(client, "music_dynamic_stop_playing Event.ChargerHit");
	ClientCommand(client, "music_dynamic_stop_playing Event.ChargerSlam");
	ClientCommand(client, "music_dynamic_stop_playing Event.ChargerSlamHit");
}

HealthCheat(client)
{
	new userflags = GetUserFlagBits(client);
	new cmdflags = GetCommandFlags("give");
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags("give", cmdflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give health");
	SetCommandFlags("give", cmdflags);
	SetUserFlagBits(client, userflags);
}

StopBeat(client)
{
	if (HeartSound[client])
	{
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
		StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
		ClientCommand(client, "music_dynamic_stop_playing Player.Heartbeat");
		SetEntityRenderColor(client, 255, 255, 255, 255);
		HeartSound[client] = 0;
	}
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

stock bool:z_IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	return true;
}


