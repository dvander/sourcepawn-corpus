
/*
v 1.1.3 - fixed player glow dosen't off when player die.
		- rename some idiot var.
		- kill timer on player dead. My bad.
		- added cvar "selfstandup_clearance". Only allow incap player to get up if player at some radius range from zombie and SI. Requested by "MasterMind420".
v 1.1.2 - change some slot count value.
        - relocate notify message.
		- fixed colour not changing when selfstandup_costly > 0.
		- fixed who attack player on player dead (player self kill) to prevent zero score in versus.
		- add timer check to prevent message print twice or triple.
		- adding fix timer delay for smoker (2.0 seconds) and jockey (1.0 seconds). This 2 guys too nob.
		- fixed player not turn to black & white problem when get up by team mate.
		- fixed when self get up kick in, team mate no longer allowed to lend a hand.
		- added glow type. 0:off, 1:on green only, 2: on glow only, 3:on both.
		- fixed proper name for defibrillator in chat msg.
		- added cvar plugin on/off.
		- added var check item only will be remove if player succses break free from SI or get up sucsess.
		- fixed if break free from infected cost player noting if infected killed before timer end (if selfstandup_costly > 0).
		- fixed possibility player cheat or use point system. Example, if "selfstandup_costly > 0", player buy item after being smoke (timer check already
		  run but broken half way due to no item as an exchange but player wisht to break free using point). Fixed timer dont continue, animation glitch,
		  get up wont fire again, cause player ended up 6 feet below. (Cost me 18 hrs to fix this).
		- force fire event on hunter break free (pounce_stopped) for proper game behavior.
		- removing unnecessary event.
		- little code clean up.
v 1.1.1 - fixing error IsValidSlot. My bad.
v 1.1.0 - Added option required medkit, pills, adren, (if option 2 explo and incdn count as medkit).
        - add hint text on player required medkit etc. but player do not have it.
v 1.0.6 - reset player colour and sound heart beat on player take damage (in respond to the problem - player using other plugin to restore life).
        - Fixing invalid enttity report.
		- changed notify message.
v 1.0.5 - fixed max duration of self get up timer duration.
v 1.0.4 - u need to delete the old l4d2_selfgetup.cfg in your cfg/sourcemod dir. Plugin will create new one.
        - still have minor issue with the self get up timer duration. I decide to release because the previous release mesh up.
        - changed max duration on self get up to 4.5 to prevent glitch on restoring health (animation problem).
        - little code clean up.
        - modify some cvar.
        - fixed self get up on ledge grab. Tnanks to MasterMind420 for the tips. Note: u dont need "sm_cvar z_grab_ledges_solo 1" as i already set them.
        - fixed health on ledge grab. If u green life before ledge grab, u get green life after self get up from ledge grab.
        - hopefuly fixed bug on the black and white count. Player die before black n white state (wrong counter).
v 1.0.3 - when player try to break free from infected, the attacker die before the timer end. Fixed problem with the ladder climbing.
v 1.0.2 - comment out debug Event. my bad.
v 1.0.1 - adding url. i forget this 1.
v 1.0.0 - Official release.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1.2"

public Plugin:myinfo = 
{
	name = "[L4D, L4D2] Self Get Up",
	author = " GsiX ",
	description = "Self help from incap, ledge grabs, and break free from infected attacks",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=195623"	
}

#define SOUND_KILL1			"/weapons/knife/knife_hitwall1.wav"
#define SOUND_KILL2			"/weapons/knife/knife_deploy.wav"
#define SOUND_HEART_BEAT	"player/heartbeatloop.wav"

#define INCAP_NONE 0
#define INCAP 1
#define INCAP_LEDGE	2

#define STATE_NONE 0
#define STATE_SELFGETUP 1
#define STATE_GETUP 2
#define STATE_CALM 3
#define STATE_PASS 4

#define NONE 0
#define SMOKER 1
#define HUNTER 3
#define JOCKEY 5
#define CHARGER 6
#define TANK 8
#define RESTORE_STATE 0.1

/*-- my reference -- */
new bool:debugMSG = false;
new bool:debugEvent = false;
new bool:debugMSGTimer = false;
new bool:p_bTest = true; // in case u guys asking its here. just turn it true. This stay like this until i found fix.
/*      ----        */

new bool:EnemyScan[MAXPLAYERS+1];
new HelpState[MAXPLAYERS+1];
new ReviveHealth[MAXPLAYERS+1];
new Float:ReviveHealthBuff[MAXPLAYERS+1];
new Attacker[MAXPLAYERS+1];
new ZombieClass[MAXPLAYERS+1];
new PlayerWeaponSlot[MAXPLAYERS+1];
new idiotHelper[MAXPLAYERS+1];
new ScanNameArray[MAXPLAYERS+1];

new Float:HelpStartTime[MAXPLAYERS+1];
new Handle:selfstandup_enable = INVALID_HANDLE;
new Handle:selfstandup_hint_delay = INVALID_HANDLE;
new Handle:selfstandup_delay = INVALID_HANDLE;
new Handle:selfstandup_duration = INVALID_HANDLE;
new Handle:selfstandup_health_incap = INVALID_HANDLE;
new Handle:selfstandup_grab = INVALID_HANDLE;
new Handle:selfstandup_pounce = INVALID_HANDLE;
new Handle:selfstandup_ride = INVALID_HANDLE;
new Handle:selfstandup_pummel = INVALID_HANDLE;
new Handle:selfstandup_ledge = INVALID_HANDLE;
new Handle:selfstandup_incap = INVALID_HANDLE;
new Handle:selfstandup_kill = INVALID_HANDLE;
new Handle:selfstandup_versus = INVALID_HANDLE;
new Handle:selfstandup_bot = INVALID_HANDLE;
new Handle:selfstandup_blackwhite = INVALID_HANDLE;
new Handle:selfstandup_count_msg = INVALID_HANDLE;
new Handle:selfstandup_color = INVALID_HANDLE;
new Handle:selfstandup_costly = INVALID_HANDLE;
new Handle:selfstandup_clearance = INVALID_HANDLE;
new Handle:Timers[MAXPLAYERS+1];
new Handle:TimerSlapPlayer[MAXPLAYERS+1];
new Handle:t_NotifyCheck[MAXPLAYERS+1];
new Handle:ScanMsgInterval[MAXPLAYERS+1];
new u_NotifyCheck[MAXPLAYERS+1];
new v_NotifyCheck[MAXPLAYERS+1];
new bool:g_bAttackPred[MAXPLAYERS + 1];
new UniqAttackId[MAXPLAYERS + 1];
new Float:get_UpIncapLedge;
new GameMode;
new L4D2Version=false;

// code from panxiohai
new String:Gauge1[2] = "-";
new String:Gauge3[2] = "#";
new m ;

public OnPluginStart()
{
	CreateConVar("selfstandup_version", PLUGIN_VERSION, " ", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	selfstandup_enable = CreateConVar("selfstandup_enable", "1", "0: off,  1: on,  Plugin On/Off", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_hint_delay = CreateConVar("selfstandup_hint_delay", "1.0", "0: turn off,  1 and above: Self stand up hint delay", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_delay = CreateConVar("selfstandup_delay", "1.0", "Self stand up delay the timer to kick in", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_duration = CreateConVar("selfstandup_duration", "4.5", "Min:0, Max: 4.5, Self stand up Duration", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_health_incap = CreateConVar("selfstandup_health_incap", "40.0", "How much health after reviving from incapacitation.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_ledge = CreateConVar("selfstandup_ledge", "1", "Self stand up for ledge grabs, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);		
	selfstandup_incap = CreateConVar("selfstandup_incap", "1", "Self stand up for incapacitation, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_grab = CreateConVar("selfstandup_grab", "1", "Self stand up for smoker grab, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_pounce = CreateConVar("selfstandup_pounce", "1", "Self stand up for hunter pounce, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_ride = CreateConVar("selfstandup_ride", "1", " Self stand up for jockey ride, 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_pummel = CreateConVar("selfstandup_pummel", "1", "Self stand up for charger pummel , 0:Disable, 1:Enable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_kill = CreateConVar("selfstandup_kill", "0", "0: Do not kill special infected when breaking free; 1: Kill special infected when breaking free", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);	
	selfstandup_versus = CreateConVar("selfstandup_versus", "0", "0: Disable in versus, 1: Enable in versus", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_bot = CreateConVar("selfstandup_bot", "1", "0: Disable for bot, 1: Enable for bot", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_blackwhite = CreateConVar("selfstandup_max", "2", "value only 1 and above = max incap count to black n white (off function = 9999 or what erver)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_count_msg = CreateConVar("selfstandup_count_msg", "1", "0: Off,   1: on  notify count on chat", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_color = CreateConVar("selfstandup_color", "3", "0:off, 1:on green only, 2: on glow only, 3:on both.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_costly = CreateConVar("selfstandup_costly", "2", "0: Off,   1: on (required medkit, pill, adren.),  2: On, (Count Upgrade Explo, Incdn and defb as medkit)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	selfstandup_clearance = CreateConVar("selfstandup_clearance", "0", "0: Off,   100.0: on, max radius scan range (only allow incap player to get up if player at this range from zombie and SI)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	AutoExecConfig(true, "l4d2_selfstandup");
	GameCheck();
	
	HookEvent("lunge_pounce",				EVENT_LungePounce);
	HookEvent("pounce_stopped",				EVENT_PounceStopped);
	HookEvent("tongue_grab",				EVENT_TongueGrab);
	HookEvent("tongue_release",				EVENT_TongueRelease);
	if(L4D2Version)
	{
		HookEvent("jockey_ride",			EVENT_JockeyRide);
		HookEvent("jockey_ride_end",		EVENT_JockeyRideEnd);
		HookEvent("charger_pummel_start",	EVENT_ChargerPummelStart);
		HookEvent("charger_pummel_end",		EVENT_ChargerPummelEnd);
	}	
	HookEvent("player_incapacitated_start",	EVENT_PlayerIncapacitatedStart);
	HookEvent("player_incapacitated",		EVENT_PlayerIncapacitated);
	HookEvent("player_ledge_grab",			EVENT_PlayerLedgeGrab);
	HookEvent("player_hurt",				EVENT_PlayerHurt);
	HookEvent("player_death",				EVENT_PlayerDeath, EventHookMode_Pre);
	HookEvent("survivor_rescued",			EVENT_SurvivorRescued);
	HookEvent("revive_begin",				EVENT_ReviveBegin);
	HookEvent("revive_end",					EVENT_ReviveEnd);
	HookEvent("revive_success",				EVENT_ReviveSuccess);
	HookEvent("player_spawn",				EVENT_PlayerSpawn);
	HookEvent("round_start",				EVENT_RoundStart);
	HookEvent("heal_success",				EVENT_HealSuccess);
	HookConVarChange(selfstandup_enable,		bw_CVARChanged);
	HookConVarChange(selfstandup_versus,		bw_CVARChanged);
	HookConVarChange(selfstandup_blackwhite,	bw_CVARChanged);
	HookConVarChange(selfstandup_duration, 		bw_CVARChanged);
	HookConVarChange(selfstandup_health_incap,	bw_CVARChanged);
	UdateCvarChange();
}

GameCheck()
{
	// code from pan xiohai
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

UdateCvarChange()
{
	GameCheck();
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0))
	{
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 2);
		SetConVarInt(FindConVar("survivor_revive_duration"), 5);
		SetConVarInt(FindConVar("z_grab_ledges_solo"), 0);
		SetConVarInt(FindConVar("survivor_revive_health"), 30);
	}
	else
	{
		// we turn off the game ability to kill us so we can go sucide.
		SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 99999);
		SetConVarInt(FindConVar("survivor_revive_health"), GetConVarInt(selfstandup_health_incap));
		if(GetConVarInt(selfstandup_duration) != 0)
			SetConVarInt(FindConVar("survivor_revive_duration"), GetConVarInt(selfstandup_duration));
		if(GetConVarInt(selfstandup_ledge) != 0)
			SetConVarInt(FindConVar("z_grab_ledges_solo"), 1);
	}
}

public OnMapStart()
{
 	if(L4D2Version)	PrecacheSound(SOUND_KILL2, true);
	else PrecacheSound(SOUND_KILL1, true);
	PrecacheSound(SOUND_HEART_BEAT, true);
	UdateCvarChange();
}

public OnConfigsExecuted()
{
	UdateCvarChange();
}

public OnClientPutInServer()
{
	new victim = GetClientOfUserId(victim);
	Attacker[victim] = 0;
	HelpStartTime[victim] = 0.0;
	if(Timers[victim] != INVALID_HANDLE)
	{
		KillTimer(Timers[victim]);
	}
	Timers[victim] = INVALID_HANDLE;
}

public OnClientDisconnect()
{
	new victim = GetClientOfUserId(victim);
	Attacker[victim] = 0;
	HelpStartTime[victim] = 0.0;
	HelpState[victim] = STATE_CALM;
	if(Timers[victim] != INVALID_HANDLE)
	{
		KillTimer(Timers[victim]);
		Timers[victim] = INVALID_HANDLE;
	}
}

public bw_CVARChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UdateCvarChange();
}

public EVENT_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	for (new i = 1; i < MaxClients; i++)
	{
		if(IsValidSurvivor(i))
		{
			GetHealth(i);
			Attacker[i] = 0;
			HelpState[i] = STATE_CALM;
			idiotHelper[i] = 0;
			ZombieClass[i] = NONE;
			UniqAttackId[i] = 0;
			u_NotifyCheck[i] = 0;
			v_NotifyCheck[i] = 0;
			HelpStartTime[i] = 0.0;
			EnemyScan[i] = true;
			g_bAttackPred[i] = false;
			PlayerWeaponSlot[i] = -1;
			Timers[i] = INVALID_HANDLE;
			t_NotifyCheck[i] = INVALID_HANDLE;
			ScanMsgInterval[i] = INVALID_HANDLE;
			TimerSlapPlayer[i] = INVALID_HANDLE;
			CreateTimer(0.0, ResetReviveCount, i);
		}
	}
	if(debugEvent) PrintToChatAll("EVENT_RoundStart");
}

public EVENT_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_PlayerSpawn");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidSurvivor(victim))
	{
		GetHealth(victim);
		Attacker[victim] = 0;
		HelpState[victim] = STATE_CALM;
		idiotHelper[victim] = 0;
		ZombieClass[victim] = NONE;
		UniqAttackId[victim] = 0;
		u_NotifyCheck[victim] = 0;
		v_NotifyCheck[victim] = 0;
		HelpStartTime[victim] = 0.0;
		EnemyScan[victim] = true;
		g_bAttackPred[victim] = false;
		PlayerWeaponSlot[victim] = -1;
		Timers[victim] = INVALID_HANDLE;
		t_NotifyCheck[victim] = INVALID_HANDLE;
		ScanMsgInterval[victim] = INVALID_HANDLE;
		CreateTimer(0.1, ResetReviveCount, victim);
	}
}
// smoker
public EVENT_TongueGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_TongueGrab");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!attacker) return;
	if(IsValidSurvivor(victim))
	{
		Attacker[victim] = attacker;
		HelpState[victim] = STATE_NONE;
		ZombieClass[victim] = SMOKER;
		if(!IsValidSlot(victim) && GetConVarInt(selfstandup_costly) > 0)
		{
			if(GetConVarFloat(selfstandup_hint_delay) != 0.0)
				CreateTimer(GetConVarFloat(selfstandup_hint_delay), Timer_RequiredItemBreakDelay, victim);
			return;
		}
		if (GetConVarInt(selfstandup_grab) != 0)
		{
			CreateTimer((GetConVarFloat(selfstandup_delay) + 2.0), Timer_SelfGetUPDelay, victim);
		}
	}
}
public EVENT_TongueRelease (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_TongueRelease");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!attacker) return;
	if(IsValidSurvivor(victim))
	{
		if(IsNo_Incap(victim) || IsNo_IncapLedge(victim))
		{
			if (Attacker[victim] == attacker)
			{
				Attacker[victim] = NONE;
			}
			v_NotifyCheck[victim] = 1;
			g_bAttackPred[victim] = false;
			HelpState[victim] = STATE_GETUP;
		}
		else HelpState[victim] = STATE_NONE;
		ZombieClass[victim] = NONE;
	}
}
// hunter
public EVENT_LungePounce (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_LungePounce");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!attacker) return;
	if(IsValidSurvivor(victim))
	{
		Attacker[victim] = attacker;
		HelpState[victim] = STATE_NONE;
		ZombieClass[victim] = HUNTER;
		if(!IsValidSlot(victim) && GetConVarInt(selfstandup_costly) > 0)
		{
			if(GetConVarFloat(selfstandup_hint_delay) != 0.0)
				CreateTimer(GetConVarFloat(selfstandup_hint_delay), Timer_RequiredItemBreakDelay, victim);
			return;
		}
		if (GetConVarInt(selfstandup_pounce) != 0)
		{
			CreateTimer(GetConVarFloat(selfstandup_delay), Timer_SelfGetUPDelay, victim);
		}
	}
}
public EVENT_PounceStopped (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_PounceStopped");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));	//this one incorrect (not hunter id)
	if (!attacker) return;
	if(IsValidSurvivor(victim))
	{
		if(IsNo_Incap(victim) || IsNo_IncapLedge(victim))
		{
			if (Attacker[victim] == attacker)
			{
				Attacker[victim] = NONE;
			}
			v_NotifyCheck[victim] = 1;
			g_bAttackPred[victim] = false;
			HelpState[victim] = STATE_GETUP;
		}
		else HelpState[victim] = STATE_NONE;
		ZombieClass[victim] = NONE;
	}
}
// jockey
public EVENT_JockeyRide (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_JockeyRide");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!attacker) return;
	if(IsValidSurvivor(victim))
	{
		Attacker[victim] = attacker;
		HelpState[victim] = STATE_NONE;
		ZombieClass[victim] = JOCKEY;
		if(!IsValidSlot(victim) && GetConVarInt(selfstandup_costly) > 0)
		{
			if(GetConVarFloat(selfstandup_hint_delay) != 0.0)
				CreateTimer(GetConVarFloat(selfstandup_hint_delay), Timer_RequiredItemBreakDelay, victim);
			return;
		}
		if (GetConVarInt(selfstandup_ride) != 0)
		{
			CreateTimer((GetConVarFloat(selfstandup_delay) + 1.0), Timer_SelfGetUPDelay, victim);
		}
	}
}
public EVENT_JockeyRideEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_JockeyRideEnd");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!attacker) return;
	if(IsValidSurvivor(victim))
	{
		if(IsNo_Incap(victim) || IsNo_IncapLedge(victim))
		{
			if (Attacker[victim] == attacker)
			{
				Attacker[victim] = NONE;
			}
			v_NotifyCheck[victim] = 1;
			g_bAttackPred[victim] = false;
			HelpState[victim] = STATE_GETUP;
		}
		else HelpState[victim] = STATE_NONE;
		ZombieClass[victim] = NONE;
	}
}
// charger
public EVENT_ChargerPummelStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_ChargerPummelStart");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!attacker) return;
	if(IsValidSurvivor(victim))
	{
		Attacker[victim] = attacker;
		HelpState[victim] = STATE_NONE;
		ZombieClass[victim] = CHARGER;
		if(!IsValidSlot(victim) && GetConVarInt(selfstandup_costly) > 0)
		{
			if(GetConVarFloat(selfstandup_hint_delay) != 0.0)
				CreateTimer(GetConVarFloat(selfstandup_hint_delay), Timer_RequiredItemBreakDelay, victim);
			return;
		}
		if (GetConVarInt(selfstandup_pummel) != 0)
		{
			CreateTimer(GetConVarFloat(selfstandup_delay), Timer_SelfGetUPDelay, victim);
		}
	}
}
public EVENT_ChargerPummelEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_ChargerPummelEnd");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!attacker) return;
	if(IsValidSurvivor(victim))
	{
		if(IsNo_Incap(victim) || IsNo_IncapLedge(victim))
		{
			if (Attacker[victim] == attacker)
			{
				Attacker[victim] = NONE;
			}
			v_NotifyCheck[victim] = 1;
			g_bAttackPred[victim] = false;
			HelpState[victim] = STATE_GETUP;
		}
		else HelpState[victim] = STATE_NONE;
		ZombieClass[victim] = NONE;
	}
}
// incap start
public EVENT_PlayerIncapacitatedStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_PlayerIncapacitatedStart");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidSurvivor(victim))
	{
		if(GetEntProp(victim, Prop_Send, "m_currentReviveCount") >= GetConVarInt(selfstandup_blackwhite))
		{
			SetEntityRenderMode(victim, RENDER_TRANSCOLOR);
			SetEntityRenderColor(victim, 255, 255, 255, 255);
			SetEntProp(victim, Prop_Send, "m_iGlowType", 0);
			UniqAttackId[victim] = GetClientOfUserId(GetEventInt(event, "attacker"));
			StopBeat(victim);
			ForcePlayerSuicide(victim);
		}
	}
}
// incap
public EVENT_PlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_PlayerIncapacitated");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidSurvivor(victim))
	{
		if(Timers[victim] != INVALID_HANDLE)
			KillTimer(Timers[victim]);
		Timers[victim] = INVALID_HANDLE;
		HelpState[victim] = STATE_NONE;
		if(!IsValidSlot(victim) && GetConVarInt(selfstandup_costly) > 0)
		{
			if(GetConVarFloat(selfstandup_hint_delay) != 0.0)
				CreateTimer(GetConVarFloat(selfstandup_hint_delay), Timer_RequiredItemBreakDelay, victim);
			return;
		}
		if (GetConVarInt(selfstandup_incap) != 0)
		{
			CreateTimer(GetConVarFloat(selfstandup_delay), Timer_SelfGetUPDelay, victim);
		}
		GetHealth(victim);
	}
}
// ledge grab
public EVENT_PlayerLedgeGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_PlayerLedgeGrab");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidSurvivor(victim))
	{
		HelpState[victim] = STATE_NONE;
		if(Timers[victim] != INVALID_HANDLE)
			KillTimer(Timers[victim]);
		Timers[victim] = INVALID_HANDLE;
		if(!IsValidSlot(victim) && GetConVarInt(selfstandup_costly) > 0)
		{
			if(GetConVarFloat(selfstandup_hint_delay) != 0.0)
				CreateTimer(GetConVarFloat(selfstandup_hint_delay), Timer_RequiredItemBreakDelay, victim);
			return;
		}
		if (GetConVarInt(selfstandup_ledge) != 0)
		{
			CreateTimer(GetConVarFloat(selfstandup_delay), Timer_SelfGetUPDelay, victim);
		}
	}
}

public Action:Timer_SelfGetUPDelay(Handle:timer, any:victim)
{
	if(IsValidSurvivor(victim))
	{
		if (IsFakeClient(victim) && GetConVarInt(selfstandup_bot) == 0) return;
		get_UpIncapLedge = GetConVarFloat(selfstandup_duration);
		if(GetConVarFloat(selfstandup_hint_delay) != 0.0 && u_NotifyCheck[victim] == 0)
				CreateTimer(GetConVarFloat(selfstandup_hint_delay), Timer_HintDelay, victim);
		// dont set the timer less than 0.2 or timer "Timer_GetUp" will fail.
		Timers[victim] = CreateTimer(0.2, Timer_SelfGetUP, GetClientUserId(victim), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_HintDelay(Handle:timer, any:victim)
{
	if (IsClientInGame(victim) && IsPlayerAlive(victim))
	{
		PrintHintText(victim, "++ Hold DUCK to help yourself ++");
	}
}

public Action:Timer_RequiredItemBreakDelay(Handle:timer, any:victim)
{
	if (IsClientInGame(victim) && IsPlayerAlive(victim))
	{
		PrintHintText(victim, "-- You Dont Have Required Item --");
	}
}

public Action:Timer_SelfGetUP(Handle:timer, any:client)
{
	new victim = GetClientOfUserId(client);
	if (IsValidSurvivor(victim))
	{
		if (!IsNo_Incap(victim) && get_UpIncapLedge > 4.5) get_UpIncapLedge = 4.5;
		if (!IsNo_IncapLedge(victim) && get_UpIncapLedge > 4.0) get_UpIncapLedge = 4.0;
		
		if (HelpState[victim] != STATE_CALM && ((!IsNo_Incap(victim) || !IsNo_IncapLedge(victim)) || (ZombieClass[victim] != NONE)))
		{
			new Float:time = GetEngineTime();
			new buttons = GetClientButtons(victim);
			// duck button pressed
			if (buttons & IN_DUCK || IsFakeClient(victim))
			{
				// code from Black-Rabbit
				g_bAttackPred[victim] = true;
				// we start the engine here
				if (HelpState[victim] == STATE_NONE)
				{
					HelpStartTime[victim] = time;
					if ((!IsNo_Incap(victim) || !IsNo_IncapLedge(victim)) && ZombieClass[victim] == NONE)
					{
						SetEntPropEnt(victim, Prop_Send, "m_reviveOwner", victim);
						if(ZombieClass[victim] == NONE)	Execute_EventReviveBegin(victim);
					}
					ShowBar(victim, time - HelpStartTime[victim], get_UpIncapLedge);
					if(p_bTest) Load_Unload_ProgressBar(victim, get_UpIncapLedge);
					HelpState[victim] = STATE_SELFGETUP;
					if(debugMSG) PrintToChatAll("HelpState = STATE_NONE");
				}
				// we run the engine here
				if (HelpState[victim] == STATE_SELFGETUP)
				{
					if(GetConVarFloat(selfstandup_clearance) > 0.0)
					{
						if ((ZombieClass[victim] != NONE))
						{
							RunEngine(victim, time, get_UpIncapLedge);
						}
						else
						{
							if(ScanEnemy(victim))
							{
								RunEngine(victim, time, get_UpIncapLedge);
							}
							else
							{
								Load_Unload_ProgressBar(victim, 0.0);
								SetEntPropEnt(victim, Prop_Send, "m_reviveOwner", -1);
								if(ScanMsgInterval[victim] == INVALID_HANDLE && GetConVarFloat(selfstandup_count_msg) != 0.0)
								{
									decl String:ArrayString[32];
									new ZomName = ScanNameArray[victim];
									if(ZomName > 0 && ZomName < MaxClients)	{
										GetClientName(ZomName, ArrayString, sizeof(ArrayString));
									}
									else {
										GetEntityClassname(ZomName, ArrayString, sizeof(ArrayString));
									}
									ScanNameArray[victim] = 0;
									PrintToChat(victim, "[GET UP] You too close to %s", ArrayString);
									ScanMsgInterval[victim] = CreateTimer((GetConVarInt(selfstandup_duration) + 0.1), ScanIntMSG, victim);
								}
							}
						}
					}
					else
					{
						RunEngine(victim, time, get_UpIncapLedge);
					}
					if(debugMSG) PrintToChatAll("HelpState = STATE_SELFGETUP");
				}
				// our idiot friend or bot try to help us so stop the engine here
				if (HelpState[victim] == STATE_GETUP)
				{
					KillTimer(Timers[victim]);
					HelpState[victim] = STATE_CALM;
					g_bAttackPred[victim] = false;
					u_NotifyCheck[victim] = 0;
					Timers[victim] = INVALID_HANDLE;
					ShowBar(victim, -1.0, get_UpIncapLedge);
					CreateTimer(2.0, e_Interval_pHurt, victim);
					if(p_bTest && idiotHelper[victim] == 0) Load_Unload_ProgressBar(victim, 0.0);
					if(debugMSG) PrintToChatAll("HelpState = STATE_GETUP");
					return Plugin_Stop;
				}
				if(debugMSG) PrintToChatAll("Button DUCK pressed");
			}
			// duck button released so we reset the engine & wait for the button again
			else 
			{
				if (HelpState[victim] == STATE_SELFGETUP)
				{
					if ((!IsNo_Incap(victim) || !IsNo_IncapLedge(victim)) && ZombieClass[victim] == NONE)
					{
						SetEntPropEnt(victim, Prop_Send, "m_reviveOwner", -1);
						if(ZombieClass[victim] == NONE)	Execute_EventReviveEnd(victim);
					}
					g_bAttackPred[victim] = false;
					HelpState[victim] = STATE_NONE;
				}
				// our idiot friend or bot try to help us so stop the engine here
				else if (HelpState[victim] == STATE_GETUP)
				{
					KillTimer(Timers[victim]);
					HelpState[victim] = STATE_CALM;
					g_bAttackPred[victim] = false;
					Timers[victim] = INVALID_HANDLE;
					CreateTimer(2.0, e_Interval_pHurt, victim);
					if(debugMSG) PrintToChatAll("HelpState = STATE_GETUP");
					return Plugin_Stop;
				}
				ScanMsgInterval[victim] = INVALID_HANDLE;
				ShowBar(victim, -1.0, get_UpIncapLedge);
				if(p_bTest && idiotHelper[victim] == 0) Load_Unload_ProgressBar(victim, 0.0);
				if(debugMSG) PrintToChatAll("Button DUCK released");
			}
		}
		// player dead, gone, get up or whatever so we terminate the timer.
		else
		{
			if(Timers[victim] != INVALID_HANDLE) KillTimer(Timers[victim]);
			g_bAttackPred[victim] = false;
			Timers[victim] = INVALID_HANDLE;
			ShowBar(victim, -1.0, get_UpIncapLedge);
			CreateTimer(2.0, e_Interval_pHurt, victim);
			if(p_bTest) Load_Unload_ProgressBar(victim, 0.0);
			if(debugMSG || debugEvent) PrintToChatAll("HelpState: Timer Terminated");
			return Plugin_Stop;
		}
	}
	return Plugin_Handled;
}

public EVENT_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_PlayerHurt");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivor(victim))
	{
		GetHealth(victim);
		if(GetEntProp(victim, Prop_Send, "m_currentReviveCount") < GetConVarInt(selfstandup_blackwhite))
		{
			// in respond other plugin may mod play health, we preform this.
			StopBeat(victim);
			SetEntProp(victim, Prop_Send, "m_bIsOnThirdStrike", 0);
			if (GetConVarInt(selfstandup_color) != 0)
			{
				SetEntityRenderMode(victim, RENDER_TRANSCOLOR);
				SetEntityRenderColor(victim, 255, 255, 255, 255);
				SetEntProp(victim, Prop_Send, "m_iGlowType", 0);
			}
		}
		// incase our engine break down in the middle of some things, we restart them.
		if((!IsNo_Incap(victim) || !IsNo_IncapLedge(victim)) && (idiotHelper[victim] == 0) && (Timers[victim] == INVALID_HANDLE) && (u_NotifyCheck[victim] == 0))
		{
			if(!IsValidSlot(victim) && GetConVarInt(selfstandup_costly) > 0)
			{
				if(GetConVarFloat(selfstandup_hint_delay) != 0.0)
					CreateTimer(GetConVarFloat(selfstandup_hint_delay), Timer_RequiredItemBreakDelay, victim);
				return;
			}
			if (HelpState[victim] == STATE_SELFGETUP)
			{
				SetEntPropEnt(victim, Prop_Send, "m_reviveOwner", -1);
			}
			u_NotifyCheck[victim] = 1;
			HelpState[victim] = STATE_NONE;
			CreateTimer(GetConVarFloat(selfstandup_delay), Timer_SelfGetUPDelay, victim);
			if(!IsNo_IncapLedge(victim) && (debugMSG || debugEvent)) PrintToChatAll("Timer incap ledge restarted");
			else if(!IsNo_Incap(victim) && (debugMSG || debugEvent)) PrintToChatAll("Timer incap restarted");
		}
	}
}

public Action:EVENT_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_PlayerDeath");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return Plugin_Handled;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(victim > 0 && victim < MaxClients)
	{
		if(GetClientTeam(victim) == 2)
		{
			Attacker[victim] = 0;
			u_NotifyCheck[victim] = 0;
			v_NotifyCheck[victim] = 0;
			ZombieClass[victim] = NONE;
			HelpState[victim] = STATE_CALM;
			g_bAttackPred[victim] = false;
			t_NotifyCheck[victim] = INVALID_HANDLE;
			ScanMsgInterval[victim] = INVALID_HANDLE;
			idiotHelper[victim] = 0;
			if(UniqAttackId[victim] > 0 && UniqAttackId[victim] < MaxClients)
			{
				new anyAttacker = UniqAttackId[victim];
				SetEventInt(event, "attacker", GetClientUserId(anyAttacker));
				UniqAttackId[victim] = 0;
			}
			CreateTimer(0.0, ResetReviveCount, victim);
			if(Timers[victim] != INVALID_HANDLE)
				KillTimer(Timers[victim]);
			Timers[victim] = INVALID_HANDLE;
		}
	}
	return Plugin_Changed;
}

public EVENT_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_SurvivorRescued");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "subject"));
	if(IsValidSurvivor(victim))
	{
		Attacker[victim] = 0;
		u_NotifyCheck[victim] = 0;
		HelpState[victim] = STATE_CALM;
		GetHealth(victim);
		EnemyScan[victim] = true;
		g_bAttackPred[victim] = false;
		idiotHelper[victim] = 0;
		UniqAttackId[victim] = 0;
		PlayerWeaponSlot[victim] = 0;
		Timers[victim] = INVALID_HANDLE;
		t_NotifyCheck[victim] = INVALID_HANDLE;
		ScanMsgInterval[victim] = INVALID_HANDLE;
	}
}

public Action:EVENT_ReviveBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_ReviveBegin");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return Plugin_Handled;
	new victim = GetClientOfUserId(GetEventInt(event, "subject"));
	new helper = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidSurvivor(victim))
	{
		if(!IsNo_Incap(victim) || !IsNo_IncapLedge(victim))
		{
			// we good to go
			if (victim == helper)
			{
				HelpState[victim] = STATE_SELFGETUP;
			}
			// our idiot friend or bot try to help us, terminate our action.
			else 
			{
				HelpState[victim] = STATE_GETUP;
				idiotHelper[victim] = 1;
			}
		}
	}
	return Plugin_Changed;
}

public Action:EVENT_ReviveEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_ReviveEnd");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return Plugin_Handled;
	new victim = GetClientOfUserId(GetEventInt(event, "subject"));
	if(IsValidSurvivor(victim))
	{
		if(Timers[victim] != INVALID_HANDLE)
		{
			if (HelpState[victim] == STATE_SELFGETUP)
			{
				SetEntPropEnt(victim, Prop_Send, "m_reviveOwner", -1);
			}
		}
		else CreateTimer(GetConVarFloat(selfstandup_delay), Timer_SelfGetUPDelay, victim);
		idiotHelper[victim] = 0;
		HelpState[victim] = STATE_NONE;
	}
	return Plugin_Changed;
}

public EVENT_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_ReviveSuccess");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "subject"));
	if(IsValidSurvivor(victim))
	{
		HelpState[victim] = STATE_GETUP;
		v_NotifyCheck[victim] = 1;
		g_bAttackPred[victim] = false;
		if(idiotHelper[victim] == 1)
		{
			idiotHelper[victim] = 0;
			CreateTimer(0.1, reviveIdiotNotify, victim);
		}
	}
}

public EVENT_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(debugEvent) PrintToChatAll("EVENT_HealSuccess");
	if ((GameMode == 2 && GetConVarInt(selfstandup_versus) == 0) || (GetConVarInt(selfstandup_enable) == 0)) return;
	new victim = GetClientOfUserId(GetEventInt(event, "subject"));
	if(IsValidSurvivor(victim))
	{
		GetHealth(victim);
		CreateTimer(0.2, ResetReviveCount, victim);
		if(GetConVarFloat(selfstandup_count_msg) != 0.0)
		{
			new revivecount = GetEntProp(victim, Prop_Send, "m_currentReviveCount");
			if(!IsFakeClient(victim))
				PrintToChat(victim, "[GET UP]:  %d of %d", revivecount, GetConVarInt(selfstandup_blackwhite));
		}
	}
}
// code from Black-Rabbit
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (((buttons & IN_FORWARD) || (buttons & IN_BACK) || (buttons & IN_LEFT) || (buttons & IN_RIGHT)) && g_bAttackPred[client])
	{
		buttons &= ~IN_FORWARD;
		buttons &= ~IN_BACK;
		buttons &= ~IN_LEFT;
		buttons &= ~IN_RIGHT;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

SelfStandUp(victim)
{	
	if (IsValidZombie(Attacker[victim]))
	{
		if (GetConVarInt(selfstandup_kill) != 0) KillAttacker(victim);
		else KickHisAss(victim);
		Attacker[victim] = 0;
	}
	CreateTimer(0.1, Timer_GetUp, victim);
}

KillAttacker(victim)
{
	new attacker = Attacker[victim];
	if(IsValidZombie(attacker))
	{
		ForcePlayerSuicide(attacker);
		if(L4D2Version) EmitSoundToAll(SOUND_KILL2, victim);
		else EmitSoundToAll(SOUND_KILL1, victim);
	}
}

KickHisAss(victim)
{
	new attacker = Attacker[victim];
	if(IsValidZombie(attacker))
	{
		if (ZombieClass[victim] == SMOKER)
		{
			SetEntityMoveType(attacker, MOVETYPE_NOCLIP);	// this trick trigger the event tongue_release
			SlapPlayer(attacker, 0, false);
			CreateTimer(RESTORE_STATE, Timer_UnMuteAttacker, attacker);
			CreateTimer(0.4, Timer_SlapPlayer, attacker);
		}
		if (ZombieClass[victim] == HUNTER)
		{
			SetEntityMoveType(attacker, MOVETYPE_NOCLIP);
			Execute_EventPounceStopped(victim);				// this trick trigger the event pounce_stopped
			SlapPlayer(attacker, 0, false);
			CreateTimer(RESTORE_STATE, Timer_UnMuteAttacker, attacker);
			TimerSlapPlayer[attacker] = CreateTimer(0.4, Timer_SlapPlayer, attacker, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(3.0, Timer_StopSlap, attacker);
		}
		if (ZombieClass[victim] == JOCKEY)
		{
			CallOnJockeyRideEnd(attacker);					// this trick trigger the event jockey_ride_end
			SlapPlayer(attacker, 0, false);
			CreateTimer(0.4, Timer_SlapPlayer, attacker);
		}
		if (ZombieClass[victim] == CHARGER)
		{
			CallOnPummelEnded(victim);						// this trick trigger the event pummel_end
			SlapPlayer(attacker, 0, false);
			TimerSlapPlayer[attacker] = CreateTimer(0.5, Timer_SlapPlayer, attacker, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(3.0, Timer_StopSlap, attacker);
		}
	}
}

public Action:Timer_GetUp(Handle:timer, any:victim)
{
	if(IsValidSurvivor(victim))
	{
		if((!IsNo_IncapLedge(victim)) || (!IsNo_Incap(victim)))
		{	
			StopBeat(victim);
			new maxBandW = GetConVarInt(selfstandup_blackwhite);
			new s_RevCount = GetEntProp(victim, Prop_Send, "m_currentReviveCount");
			if(!IsNo_IncapLedge(victim))
			{
				HealthCheat(victim);
				if(debugMSG) PrintToChatAll("Incap Ledge end");
				SetEntProp(victim, Prop_Send, "m_isHangingFromLedge", 0);
			}
			if(!IsNo_Incap(victim))
			{
				if(debugMSG) PrintToChatAll("Incap end");
				HealthCheat(victim);
				s_RevCount += 1;
				SetEntProp(victim, Prop_Send, "m_isIncapacitated", 0);
			}
			SetEntProp(victim, Prop_Send, "m_reviveOwner", 0);
			if(ReviveHealthBuff[victim] != 0.0) SetEntPropFloat(victim, Prop_Send, "m_healthBuffer", (ReviveHealthBuff[victim]));
			SetEntityHealth(victim, ReviveHealth[victim]);
			if(maxBandW != 0) 
			{	
				SetEntProp(victim, Prop_Send, "m_currentReviveCount", s_RevCount);
				if (s_RevCount == maxBandW)
					CreateTimer(0.2, Timer_ThirdStrike, victim);
			}
		}
		g_bAttackPred[victim] = false;
		
		// this code dont make sense to me but actually work, stop the msg print twice or triple
		if(t_NotifyCheck[victim] == INVALID_HANDLE) 
			t_NotifyCheck[victim] = CreateTimer(0.2, reviveNotify, victim);
	}
	if(debugMSG) PrintToChatAll("Timer get UP");
}

public Action:reviveNotify(Handle:timer, any:victim)
{
	if(IsValidSurvivor(victim))
	{
		new Float:n_Msg = GetConVarFloat(selfstandup_count_msg);
		new n_Costly = GetConVarInt(selfstandup_costly);
		new maxBandW = GetConVarInt(selfstandup_blackwhite);
		new s_RevCount = GetEntProp(victim, Prop_Send, "m_currentReviveCount");
		new destroyThis = PlayerWeaponSlot[victim];
		decl String:clientName[30];
		decl String:slotName[60];
		GetClientName(victim, clientName, sizeof(clientName));
		if(IsValidSlot(victim) && n_Msg != 0.0)
		{
			GetEntityClassname(destroyThis, slotName, sizeof(slotName));
			if (StrEqual(slotName, "weapon_upgradepack_explosive", false))
				Format(slotName, sizeof(slotName), "Explosive Ammo");
			else if (StrEqual(slotName, "weapon_upgradepack_incendiary", false))
				Format(slotName, sizeof(slotName), "Incendiary Ammo");
			else if (StrEqual(slotName, "weapon_first_aid_kit", false))
				Format(slotName, sizeof(slotName), "First Aid Kit");
			else if (StrEqual(slotName, "weapon_defibrillator", false))
				Format(slotName, sizeof(slotName), "Defibrillator");
			else if (StrEqual(slotName, "weapon_pain_pills", false))
				Format(slotName, sizeof(slotName), "Pain Pills");
			else Format(slotName, sizeof(slotName), "Adrenaline");
		}
		if (s_RevCount < maxBandW)
		{
			if(n_Costly == 0 && !IsFakeClient(victim) && n_Msg != 0.0)
				PrintToChat(victim, "[GET UP]: %d of %d", s_RevCount, maxBandW);
			else 
			{
				if(IsValidSlot(victim))
				{
					if(v_NotifyCheck[victim] == 1) AcceptEntityInput(destroyThis, "kill");
					v_NotifyCheck[victim] = 0;
					if(!IsFakeClient(victim) && n_Msg != 0.0)
						PrintToChat(victim, "[GET UP]: %d of %d,  cost of %s", s_RevCount, maxBandW, slotName);
				}
			}
		}
		if (s_RevCount >= maxBandW)
		{
			if(n_Msg != 0.0) PrintToChatAll("[GET UP]: %s on last life!!", clientName);
			if(n_Costly > 0)
			{
				if(IsValidSlot(victim))
				{
					if(v_NotifyCheck[victim] == 1) AcceptEntityInput(destroyThis, "kill");
					v_NotifyCheck[victim] = 0;
				}
			}
		}
	}
	t_NotifyCheck[victim] = INVALID_HANDLE;
	if(debugEvent) PrintToChatAll("Event_CostlyGetUP");
}

public Action:reviveIdiotNotify(Handle:timer, any:victim)
{
	new maxBandW = GetConVarInt(selfstandup_blackwhite);
	new s_RevCount = GetEntProp(victim, Prop_Send, "m_currentReviveCount");
	if (s_RevCount == maxBandW)
	{
		CreateTimer(0.1, Timer_ThirdStrike, victim);
		if(GetConVarFloat(selfstandup_count_msg) != 0.0)
		{
			decl String:clientName[30];
			GetClientName(victim, clientName, sizeof(clientName));
			PrintToChatAll("[GET UP]: %s on last life!!", clientName);
		}
	}
	else
	{
		if(!IsFakeClient(victim))
			PrintToChat(victim, "[GET UP]:  %d of %d", s_RevCount, maxBandW);
	}
}

public Action:e_Interval_pHurt(Handle:timer, any:victim)
{
	if(IsValidSurvivor(victim)) u_NotifyCheck[victim] = 0;
}

public Action:ScanIntMSG(Handle:timer, any:victim)
{
	if(IsValidSurvivor(victim))
		ScanMsgInterval[victim] = INVALID_HANDLE;
}

public Action:Timer_UnMuteAttacker(Handle:timer, any:attacker)
{
	if(IsValidZombie(attacker))
	{
		SetEntityMoveType(attacker, MOVETYPE_WALK);
	}
}

public Action:Timer_SlapPlayer(Handle:timer, any:attacker)
{
	if(IsValidZombie(attacker))
	{
		SlapPlayer(attacker, 0, false);
	}
	else
	{
		if(TimerSlapPlayer[attacker] != INVALID_HANDLE)
		{
			KillTimer(TimerSlapPlayer[attacker]);
			TimerSlapPlayer[attacker] = INVALID_HANDLE;
		}
	}
}

public Action:Timer_StopSlap(Handle:timer, any:attacker)
{
	if(IsValidZombie(attacker))
	{
		if (TimerSlapPlayer[attacker] != INVALID_HANDLE)
		{
			KillTimer(TimerSlapPlayer[attacker]);
			TimerSlapPlayer[attacker] = INVALID_HANDLE;
		}
	}
}

public Action:Timer_ThirdStrike(Handle:timer, any:victim)
{
	EmitSoundToClient(victim, SOUND_HEART_BEAT);
	SetEntProp(victim, Prop_Send, "m_bIsOnThirdStrike", 1);
	new cl_Mode = GetConVarInt(selfstandup_color);
	if(cl_Mode > 0)
	{
		SetEntityRenderMode(victim, RENDER_TRANSCOLOR);
		if(cl_Mode == 1) SetEntityRenderColor(victim, 128, 255, 128, 255);
		else if(cl_Mode == 2) SetEntProp(victim, Prop_Send, "m_iGlowType", 3);
		else
		{
			SetEntityRenderColor(victim, 128, 255, 128, 255);
			SetEntProp(victim, Prop_Send, "m_iGlowType", 3);
		}
	}
}

public Action:ResetReviveCount(Handle:timer, any:victim)
{
	if(IsValidSurvivor(victim))
	{
		StopBeat(victim);
		SetEntProp(victim, Prop_Send, "m_currentReviveCount", 0);
		SetEntPropFloat(victim, Prop_Send, "m_healthBuffer", 0.0);
		SetEntProp(victim, Prop_Send, "m_bIsOnThirdStrike", 0);
		if(GetConVarInt(selfstandup_color) > 0)
		{
			SetEntityRenderMode(victim, RENDER_TRANSCOLOR);
			SetEntityRenderColor(victim, 255, 255, 255, 255);
			SetEntProp(victim, Prop_Send, "m_iGlowType", 0);
		}
	}
}

// code from panxiohai
ShowBar(victim, Float:pos, Float:max)	 
{
	if (pos < 0.0)
	{
		PrintCenterText(victim, "");
		return;
	}
	new String:ChargeBar[100];
	Format(ChargeBar, sizeof(ChargeBar), "");
 	new Float:GaugeNum = pos/max*100;
	if (GaugeNum > 100.0)
		GaugeNum = 100.0;
	if (GaugeNum<0.0)
		GaugeNum = 0.0;
 	for (m=0; m<100; m++)
		ChargeBar[m] = Gauge1[0];
	new p=RoundFloat( GaugeNum);
	if (p >= 0 && p < 100) ChargeBar[p] = Gauge3[0]; 
	PrintCenterText(victim, "                                << SELF GET UP IN PROGRESS >> %3.0f %\n<<< %s >>>",GaugeNum, ChargeBar);
}
// code from panxiohai
CallOnJockeyRideEnd(victim)
{
	new flag =  GetCommandFlags("dismount");
	SetCommandFlags("dismount", flag & ~FCVAR_CHEAT);
	FakeClientCommand(victim, "%s", "dismount");
	SetCommandFlags("dismount", flag);
}
// code from panxiohai
CallOnPummelEnded(victim)
{
	static Handle:hOnPummelEnded = INVALID_HANDLE;
	new Handle:hConf = INVALID_HANDLE;
	if (hOnPummelEnded == INVALID_HANDLE)
	{
		hConf = LoadGameConfigFile("l4d2_selfstandup");
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
	SDKCall(hOnPummelEnded, victim, true, -1);
}

GetHealth(victim)
{
	if (IsNo_Incap(victim))
	{
		new health = GetClientHealth(victim);
		ReviveHealth[victim] = health;
		ReviveHealthBuff[victim] = 0.0;
		if(debugMSG) PrintToChatAll("Health not incap");
	}
	else
	{
		if(IsNo_IncapLedge(victim))
		{
			ReviveHealth[victim] = 1;
			ReviveHealthBuff[victim] = GetConVarFloat(selfstandup_health_incap);
			if(debugMSG) PrintToChatAll("Health incap");
		}
	}
}

HealthCheat(victim)
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(victim, "give health");
	SetCommandFlags("give", flags);
}

StopBeat(victim)
{
	StopSound(victim, SNDCHAN_AUTO, SOUND_HEART_BEAT);
}

bool:IsNo_Incap(victim)
{
	// if survivor incaped return false, true otherwise.
	if (GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 1) return false;
	return true;
}

bool:IsNo_IncapLedge(victim)
{
	// if survivor ledge grab return false, true otherwise.
	if (GetEntProp(victim, Prop_Send, "m_isHangingFromLedge") == 1) return false;
	return true;
}

bool:IsValidSurvivor(victim)
{
	if (victim < 1 || victim > MaxClients) return false;
	if (!IsClientConnected(victim)) return false;
	if (!IsClientInGame(victim)) return false;
	if (!IsPlayerAlive(victim)) return false;
	if (GetClientTeam(victim) != 2) return false;
	// safety to fix the old selfrevive issue with the tank.
	if (GetEntProp(victim, Prop_Send, "m_zombieClass") == TANK) return false;
	return true;
}

bool:IsValidZombie(attacker)
{
	if (attacker < 1 || attacker > MaxClients) return false;
	if (!IsClientInGame(attacker)) return false;
	if (!IsPlayerAlive(attacker)) return false;
	if (GetClientTeam(attacker) != 3) return false;
	// safety to fix the old selfrevive issue with the tank.
	if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == TANK) return false;
	return true;
}

bool:IsValidSlot(victim)
{
	new PlayerSlot_3 = GetPlayerWeaponSlot(victim, 3);
	new PlayerSlot_4 = GetPlayerWeaponSlot(victim, 4);
	if (GetConVarInt(selfstandup_costly) == 1 && PlayerSlot_3 != -1)
	{
		decl String:playerSlotName[30];
		GetEntityClassname(PlayerSlot_3, playerSlotName, sizeof(playerSlotName));
		if (!StrEqual(playerSlotName, "weapon_first_aid_kit", false))
			PlayerSlot_3 = -1;
	}
	if ((PlayerSlot_3 != -1) || (PlayerSlot_4 != -1))
	{
		if(PlayerSlot_4 != -1)
		{
			PlayerWeaponSlot[victim] = PlayerSlot_4;
			return true;
		}
		else
		{
			PlayerWeaponSlot[victim] = PlayerSlot_3;
			return true;
		}
	}
	else
	{
		PlayerWeaponSlot[victim] = -1;
		return false;
	}
}

bool:ScanEnemy(victim)
{
	EnemyScan[victim] = true;
	if(IsValidSurvivor(victim))
	{
		new Float:l_Dist = 0.0;
		decl String:InfName[64];
		new EntCount = GetEntityCount();
		decl Float:targetPos[3], Float:playerPos[3];
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", playerPos);
		for (new i = 0; i <= EntCount; i++)
		{
			if(IsValidEntity(i))
			{
				if (i > 0 && i <= MaxClients && GetClientTeam(i) == 3)
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", targetPos);
					l_Dist = GetVectorDistance(targetPos,playerPos);
					if (l_Dist <= GetConVarFloat(selfstandup_clearance))
					{
						EnemyScan[victim] = false;
						ScanNameArray[victim] = i;
						break;
					}
				}
				else
				{
					GetEntityClassname(i, InfName, sizeof(InfName));
					if (StrEqual(InfName, "infected", false))
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", targetPos);
						l_Dist = GetVectorDistance(targetPos,playerPos);
						if (l_Dist <= GetConVarFloat(selfstandup_clearance))
						{
							EnemyScan[victim] = false;
							ScanNameArray[victim] = i;
							break;
						}
					}
				}
			}
		}
	}
	return EnemyScan[victim];
}

stock RunEngine(victim, Float:time, Float:l_Duration)
{
	if ((time - HelpStartTime[victim]) <= l_Duration)
	{
		g_bAttackPred[victim] = true;
		ShowBar(victim, time - HelpStartTime[victim], l_Duration);
		if(debugMSGTimer) PrintToChatAll("Run Time: %f  Max Time: %f", time - HelpStartTime[victim], l_Duration);
	}
	if ((time - HelpStartTime[victim]) > l_Duration)
	{
		if ((!IsNo_Incap(victim) || !IsNo_IncapLedge(victim)) && ZombieClass[victim] == NONE)
		{						
			SetEntPropEnt(victim, Prop_Send, "m_reviveOwner", -1);
		}
		SelfStandUp(victim);
		HelpState[victim] = STATE_GETUP;
		ShowBar(victim, -1.0, l_Duration);
		if(p_bTest) Load_Unload_ProgressBar(victim, 0.0);
		if(debugMSG) PrintToChatAll("HelpState = STATE_SELFGETUP engine executed");
	}
}

Execute_EventPounceStopped(victim)
{
	new Handle:event = CreateEvent("pounce_stopped");
	if (event == INVALID_HANDLE)
	{
		return;
	}
	SetEventInt(event, "userid", GetClientUserId(victim));		// Who stopped it
	SetEventInt(event, "victim", GetClientUserId(victim));		// And who was being pounced
	FireEvent(event);
}

Execute_EventReviveBegin(victim)
{
	new Handle:event = CreateEvent("revive_begin");
	if (event == INVALID_HANDLE)
	{
		return;
	}
	SetEventInt(event, "userid", GetClientUserId(victim));		//person doing the reviving
	SetEventInt(event, "subject", GetClientUserId(victim));		// person being revive
	FireEvent(event);
}

Execute_EventReviveEnd(victim)
{
	new Handle:event = CreateEvent("revive_end");
	if (event == INVALID_HANDLE)
	{
		return;
	}
	SetEventInt(event, "userid", GetClientUserId(victim));		// person doing the reviving
	SetEventInt(event, "subject", GetClientUserId(victim));		// person being revive
	FireEvent(event);
}

stock Load_Unload_ProgressBar(victim, Float:time)
{
	SetEntPropFloat(victim, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(victim, Prop_Send, "m_flProgressBarDuration", time);
}

