/*
*	Regenerative Healing
*	Copyright (C) 2023 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"1.12"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Regenerative Healing
*	Author	:	SilverShot
*	Descrp	:	Regenerates main health over time after using Adrenaline or Pain Pills.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=319094
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.12 (19-Feb-2023)
	- Fixed healing not continuing when a bot or player takeover each other. Thanks to "Iciaria" for reporting.

1.11 (29-May-2022)
	- Added cvars "l4d_healing_health_defib" and "l4d_healing_regen_defib" to give regenerative healing after being defibrillated.
	- Changed cvar "l4d_healing_type" to accept the type of "8" to enable defibrillators healing on revive.
	- Requested by "weakestL4D2enjoyer".

1.10 (01-Sep-2021)
	- Fixed regenerative healing not working due to the last update. Thanks to "Maur0" for reporting.

1.9 (01-Sep-2021)
	- Added cvars "l4d_healing_health_adren", "l4d_healing_health_first" and "l4d_healing_health_pills" to set health rate.
	- Requested by "bald14".

1.8 (30-Sep-2020)
	- Fixed compile errors on SM 1.11.

1.7 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

1.6 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.5 (06-Feb-2019)
	- Fixed incorrect cvar change hook breaking "l4d_healing_moving" in L4D1. Thanks to "Dragokas" for reporting.

1.4 (28-Oct-2019)
	- Optimized the way cvars are read to use less CPU cycles.

1.3 (23-Oct-2019)
	- Fixed affecting temporary health while incapacitated.

1.2 (14-Oct-2019)
	- Added cvar "l4d_healing_damage" to temporarily block regenerating health when taking damage.
	- Added cvar "l4d_healing_regen_type" to set which items heal main or temp health.
	- Added cvar "l4d_healing_regenerate" to always regenerate main or temporary health.
	- Changed cvar "l4d_healing_temp" to control removing temp health. Recommended value "1, last version was "0".
	- Changed cvar "l4d_healing_type" to disable regenerating health from items.

1.1 (12-Oct-2019)
	- Added feature to regenerate health from First Aid Kits.
	- Added cvar "l4d_healing_regen_first" to set First Aid health.
	- Changed cvar "l4d_healing_type" to include First Aid.

1.0 (10-Oct-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarDamage, g_hCvarHealth, g_hCvarHealthA, g_hCvarHealthD, g_hCvarHealthF, g_hCvarHealthP, g_hCvarMax, g_hCvarMoving, g_hCvarRegenA, g_hCvarRegenD, g_hCvarRegenF, g_hCvarRegenP, g_hCvarRegenT, g_hCvarAlways, g_hCvarTemp, g_hCvarTime, g_hCvarType, g_hDecayDecay; //g_hDecayAdren, g_hDecayPills;
float g_fCvarDamage, g_fCvarMoving, g_fCvarRegenA, g_fCvarRegenD, g_fCvarRegenF, g_fCvarRegenP, g_fCvarTime, g_fDecayDecay;
int g_iCvarHealth, g_iCvarHealthA, g_iCvarHealthD, g_iCvarHealthF, g_iCvarHealthP, g_iCvarMax, g_iCvarRegenT, g_iCvarAlways, g_iCvarTemp, g_iCvarType;

bool g_bCvarAllow, g_bMapStarted, g_bActive, g_bLeft4Dead2;
Handle g_hTimerTempHealth, g_hTimerRegenHealth;
float g_fLastDamage[MAXPLAYERS+1];
float g_fLastHealth[MAXPLAYERS+1];
int g_iLastHealth[MAXPLAYERS+1];
ArrayList g_alDataPacks;
ArrayList g_alTimerHands;

enum
{
	TYPE_ADREN = 1,
	TYPE_PILLS,
	TYPE_FIRST,
	TYPE_MAIN,
	TYPE_TEMP,
	TYPE_DEFIB
}



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Regenerative Healing",
	author = "SilverShot",
	description = "Regenerates main health over time after using Adrenaline or Pain Pills.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=319094"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	g_bActive = late;

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow =			CreateConVar(	"l4d_healing_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_healing_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_healing_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_healing_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarDamage =			CreateConVar(	"l4d_healing_damage",			"0.0",				"0.0=Off. After taking damage wait this long before regenerating health again.", CVAR_FLAGS );
	g_hCvarHealth =			CreateConVar(	"l4d_healing_health",			"2",				"How much health to apply while the effect is active, each time the timer fires.", CVAR_FLAGS );
	g_hCvarHealthF =		CreateConVar(	"l4d_healing_health_first",		"2",				"How much health to apply while the effect is active, each time the timer fires. 0 Defaults to using l4d_healing_health cvar.", CVAR_FLAGS );
	g_hCvarHealthP =		CreateConVar(	"l4d_healing_health_pills",		"2",				"How much health to apply while the effect is active, each time the timer fires. 0 Defaults to using l4d_healing_health cvar.", CVAR_FLAGS );
	g_hCvarMax =			CreateConVar(	"l4d_healing_max",				"100",				"Maximum player health to prevent over-healing.", CVAR_FLAGS );
	g_hCvarMoving =			CreateConVar(	"l4d_healing_moving",			"0.0",				"Heal when their movement speed is slower than this. 0.0=Off. 76=Crouched. 86=Walking. 250=Running.", CVAR_FLAGS );
	if( g_bLeft4Dead2 )
	{
		g_hCvarHealthA =	CreateConVar(	"l4d_healing_health_adren",		"2",				"How much health to apply while the effect is active, each time the timer fires. 0 Defaults to using l4d_healing_health cvar.", CVAR_FLAGS );
		g_hCvarHealthD =	CreateConVar(	"l4d_healing_health_defib",		"2",				"How much health to apply while the effect is active, each time the timer fires. 0 Defaults to using l4d_healing_health cvar.", CVAR_FLAGS );
		g_hCvarRegenA =		CreateConVar(	"l4d_healing_regen_adren",		"50.0",				"Maximum health Adrenaline can regenerate (L4D2 only).", CVAR_FLAGS );
		g_hCvarRegenD =		CreateConVar(	"l4d_healing_regen_defib",		"50.0",				"Maximum health Defibrillators can regenerate after defibbing someone (L4D2 only).", CVAR_FLAGS );
	}
	g_hCvarRegenF =			CreateConVar(	"l4d_healing_regen_first",		"100.0",			"Maximum health First Aid can regenerate.", CVAR_FLAGS );
	g_hCvarRegenP =			CreateConVar(	"l4d_healing_regen_pills",		"50.0",				"Maximum health Pain Pills can regenerate.", CVAR_FLAGS );
	g_hCvarRegenT =			CreateConVar(	"l4d_healing_regen_type",		"0",				"0=Items regen main health. Regen with temp health: 1=Adrenaline (L4D2 only), 2=Pain Pills, 4=First Aid. 7=All. Add numbers together.", CVAR_FLAGS );
	g_hCvarAlways =			CreateConVar(	"l4d_healing_regenerate",		"0",				"Survivors always regenerate health. 0=Off. 1=Main health. 2=Temp health. 3=Main health and replace temp while healing.", CVAR_FLAGS );
	g_hCvarTemp =			CreateConVar(	"l4d_healing_temp",				"3",				"When allowed item types are used: 1=Remove health applied. 2=Replace temp health when healing with main health. 3=Both.", CVAR_FLAGS );
	g_hCvarTime =			CreateConVar(	"l4d_healing_time",				"0.5",				"How often to heal the player.", CVAR_FLAGS );
	g_hCvarType =			CreateConVar(	"l4d_healing_type",				"3",				"Which item to affect. 0=None, 1=Adrenaline (L4D2 only), 2=Pain Pills, 4=First Aid, 8=Defibrillator (L4D2 only), 15=All. Add numbers together.", CVAR_FLAGS );
	CreateConVar(							"l4d_healing_version",			PLUGIN_VERSION,		"Healing plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_healing");

	// g_hDecayAdren = FindConVar("adrenaline_health_buffer");
	// g_hDecayPills = FindConVar("pain_pills_health_value");
	g_hDecayDecay = FindConVar("pain_pills_decay_rate");
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarDamage.AddChangeHook(ConVarChanged_Damage);
	g_hCvarAlways.AddChangeHook(ConVarChanged_Timer);
	g_hCvarTemp.AddChangeHook(ConVarChanged_Timer);
	g_hCvarType.AddChangeHook(ConVarChanged_Type);

	g_hDecayDecay.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthF.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthP.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMax.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMoving.AddChangeHook(ConVarChanged_Cvars);
	if( g_bLeft4Dead2 )
	{
		g_hCvarHealthA.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarHealthD.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarRegenA.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarRegenD.AddChangeHook(ConVarChanged_Cvars);
	}
	g_hCvarRegenF.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRegenP.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRegenT.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTime.AddChangeHook(ConVarChanged_Cvars);

	g_alDataPacks = new ArrayList();
	g_alTimerHands = new ArrayList();

	IsAllowed();
}



// ====================================================================================================
//					HOOKS
// ====================================================================================================
void HookUnhookDamage(bool hook)
{
	static bool hooked;

	if( g_fCvarDamage == 0.0 ) hook = false;

	if( hook == true && hooked == false )
	{
		hooked = true;

		for( int i = 1; i <= MaxClients; i++ )
			if( IsClientInGame(i) )
				SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	}
	else if( hook == false && hooked == true )
	{
		hooked = false;

		for( int i = 1; i <= MaxClients; i++ )
			if( IsClientInGame(i) )
				SDKUnhook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	}
}

public void OnClientPutInServer(int client)
{
	if( g_bCvarAllow && g_fCvarDamage != 0.0 )
		SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( GetClientTeam(victim) == 2 )
	{
		g_fLastDamage[victim] = GetGameTime();
	}

	return Plugin_Continue;
}

void HookUnhookEvents(bool hook)
{
	static bool hooked;

	if( g_iCvarType == 0 ) hook = false;

	if( hook == true && hooked == false )
	{
		hooked = true;

		HookEvent("player_bot_replace",			Event_Swap_Bot);
		HookEvent("bot_player_replace",			Event_Swap_User);
		HookEvent("pills_used",					Event_PainPills);
		HookEvent("heal_success",				Event_FirstAid);
		if( g_bLeft4Dead2 )
		{
			HookEvent("adrenaline_used",		Event_Adrenaline);
			HookEvent("defibrillator_used",		Event_Defibrillator);
		}
	}
	else if( hook == false && hooked == true )
	{
		hooked = false;

		UnhookEvent("player_bot_replace",		Event_Swap_Bot);
		UnhookEvent("bot_player_replace",		Event_Swap_User);
		UnhookEvent("pills_used",				Event_PainPills);
		UnhookEvent("heal_success",				Event_FirstAid);
		if( g_bLeft4Dead2 )
		{
			UnhookEvent("adrenaline_used",		Event_Adrenaline);
			UnhookEvent("defibrillator_used",	Event_Defibrillator);
		}
	}
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Damage(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
	HookUnhookDamage(true);
}

void ConVarChanged_Type(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
	HookUnhookEvents(true);
}

void ConVarChanged_Timer(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
	TempTimerToggle(true);
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_fDecayDecay =			g_hDecayDecay.FloatValue;
	g_fCvarDamage =			g_hCvarDamage.FloatValue;
	g_iCvarHealth =			g_hCvarHealth.IntValue;
	g_iCvarHealthF =		g_hCvarHealthF.IntValue;
	g_iCvarHealthP =		g_hCvarHealthP.IntValue;
	g_iCvarMax =			g_hCvarMax.IntValue;
	g_fCvarMoving =			g_hCvarMoving.FloatValue;
	if( g_bLeft4Dead2 )
	{
		g_iCvarHealthA =	g_hCvarHealthA.IntValue;
		g_iCvarHealthD =	g_hCvarHealthD.IntValue;
		g_fCvarRegenA =		g_hCvarRegenA.FloatValue;
		g_fCvarRegenD =		g_hCvarRegenD.FloatValue;
	}
	g_fCvarRegenF =			g_hCvarRegenF.FloatValue;
	g_fCvarRegenP =			g_hCvarRegenP.FloatValue;
	g_iCvarRegenT =			g_hCvarRegenT.IntValue;
	g_iCvarAlways =			g_hCvarAlways.IntValue;
	g_iCvarTemp =			g_hCvarTemp.IntValue;
	g_fCvarTime =			g_hCvarTime.FloatValue;
	g_iCvarType =			g_hCvarType.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bActive = true;
		g_bCvarAllow = true;
		HookEvent("round_end",					Event_RoundEnd);
		HookEvent("round_start",				Event_RoundStart);

		HookUnhookDamage(true);
		HookUnhookEvents(true);
		TempTimerToggle(true);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bActive = false;
		g_bCvarAllow = false;
		UnhookEvent("round_end",				Event_RoundEnd);
		UnhookEvent("round_start",				Event_RoundStart);

		HookUnhookDamage(false);
		HookUnhookEvents(false);
		TempTimerToggle(false);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	g_bActive = false;

	ResetPacks();
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bActive = true;
	TempTimerToggle(true);

	for( int i = 0; i <= MaxClients; i++ )
		g_fLastDamage[i] = 0.0;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bActive = false;

	ResetPacks();
}

void ResetPacks()
{
	DataPack dPack;
	int length = g_alDataPacks.Length;

	for( int i = 0; i < length; i++ )
	{
		dPack = g_alDataPacks.Get(i);
		if( dPack )
		{
			KillTimer(g_alTimerHands.Get(i));
		}

		delete dPack;
	}

	g_alDataPacks.Clear();
	g_alTimerHands.Clear();
}

void Event_Defibrillator(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCvarType & (1<<3) )
	{
		int userid = event.GetInt("subject");
		int client = GetClientOfUserId(userid);
		if( client && IsClientInGame(client) )
		{
			SetupHealTimer(client, userid, TYPE_DEFIB);
		}
	}
}

void Event_Adrenaline(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCvarType & (1<<0) )
	{
		int userid = event.GetInt("userid");
		int client = GetClientOfUserId(userid);
		if( client && IsClientInGame(client) )
		{
			SetupHealTimer(client, userid, TYPE_ADREN);
		}
	}
}

void Event_PainPills(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCvarType & (1<<1) )
	{
		int userid = event.GetInt("subject");
		int client = GetClientOfUserId(userid);
		if( client && IsClientInGame(client) )
		{
			SetupHealTimer(client, userid, TYPE_PILLS);
		}
	}
}

void Event_FirstAid(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCvarType & (1<<2) )
	{
		int userid = event.GetInt("subject");
		int client = GetClientOfUserId(userid);
		if( client && IsClientInGame(client) )
		{
			SetupHealTimer(client, userid, TYPE_FIRST);
		}
	}
}

void Event_Swap_Bot(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));

	g_fLastDamage[bot] = g_fLastDamage[client];
	g_fLastHealth[bot] = g_fLastHealth[client];
	g_iLastHealth[bot] = g_iLastHealth[client];

	SwapPacks(client, bot);
}

void Event_Swap_User(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));

	g_fLastDamage[client] = g_fLastDamage[bot];
	g_fLastHealth[client] = g_fLastHealth[bot];
	g_iLastHealth[client] = g_iLastHealth[bot];

	SwapPacks(bot, client);
}

void SwapPacks(int client, int target)
{
	float healed;
	int user;
	int type;
	int userid = GetClientUserId(client);
	target = GetClientUserId(target);

	// Loop datapacks, swap userids
	DataPack dPack;
	int length = g_alDataPacks.Length;

	for( int i = 0; i < length; i++ )
	{
		dPack = g_alDataPacks.Get(i);

		dPack.Reset();
		type = dPack.ReadCell();
		user = dPack.ReadCell();

		if( user == userid )
		{
			healed = dPack.ReadFloat();

			dPack.Reset();
			dPack.WriteCell(type);
			dPack.WriteCell(target);
			dPack.WriteFloat(healed);
		}
	}
}



// ====================================================================================================
//					TEMP HEALTH TIMER + ALWAYS REGEN TIMER
// ====================================================================================================
// Need to store temp health prior to adren/pill events, which fire after temp health was added.
// To correctly remove the amount of temp health added.
void TempTimerToggle(bool enable)
{
	// Kill always regen timer
	delete g_hTimerRegenHealth;

	// Kill health store timer
	delete g_hTimerTempHealth;

	// Create timer if remove temp health option
	if( enable && g_iCvarTemp & (1<<0) )
		g_hTimerTempHealth = CreateTimer(0.1, TimerTempHealth, _, TIMER_REPEAT); // Auto stops if not enabled.

	// Create timer if always regen
	if( enable && g_iCvarAlways != 0 )
		g_hTimerRegenHealth = CreateTimer(g_fCvarTime, TimerRegenAlways, _, TIMER_REPEAT);
}

Action TimerTempHealth(Handle timer)
{
	if( g_bActive )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
			{
				g_fLastHealth[i] = GetTempHealth(i);
				g_iLastHealth[i] = GetClientHealth(i);
			}
		}
		return Plugin_Continue;
	}

	g_hTimerTempHealth = null;
	return Plugin_Stop;
}

Action TimerRegenAlways(Handle timer)
{
	if( g_bActive )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
			{
				RegenPlayer(i, g_iCvarAlways + 3);
			}
		}
		return Plugin_Continue;
	}

	g_hTimerRegenHealth = null;
	return Plugin_Stop;
}



// ====================================================================================================
//					FUNCTION
// ====================================================================================================
void SetupHealTimer(int client, int userid, int type)
{
	// Remove temp / main health that was added?
	if( g_iCvarTemp & (1<<0) )
	{
		SetTempHealth(client, g_fLastHealth[client]);

		if( type == TYPE_FIRST )
		{
			SetEntityHealth(client, g_iLastHealth[client]);
		}
	}

	// Repeat healing
	DataPack dPack = new DataPack();
	dPack.WriteCell(type);
	dPack.WriteCell(userid);
	dPack.WriteFloat(0.0);

	g_alDataPacks.Push(dPack);
	Handle timer = CreateTimer(g_fCvarTime, TimerRegenTemp, dPack, TIMER_REPEAT);
	g_alTimerHands.Push(timer);
}

Action TimerRegenTemp(Handle timer, DataPack dPack)
{
	if( g_bActive == false ) return Plugin_Stop;

	// Get vars
	dPack.Reset();
	int type = dPack.ReadCell();
	int userid = dPack.ReadCell();

	int client = GetClientOfUserId(userid);
	if( client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 )
	{
		float healed = dPack.ReadFloat();

		// Healed less than regen limiter
		float max;
		switch( type )
		{
			case TYPE_ADREN:	max = g_fCvarRegenA;
			case TYPE_PILLS:	max = g_fCvarRegenP;
			case TYPE_FIRST:	max = g_fCvarRegenF;
			case TYPE_DEFIB:	max = g_fCvarRegenD;
		}

		if( healed < max )
		{
			// Update vars
			dPack.Reset();
			dPack.WriteCell(type);
			dPack.WriteCell(userid);
			switch( type )
			{
				case TYPE_ADREN: 	dPack.WriteFloat(healed + (g_iCvarHealthA ? g_iCvarHealthA : g_iCvarHealth));
				case TYPE_FIRST: 	dPack.WriteFloat(healed + (g_iCvarHealthF ? g_iCvarHealthF : g_iCvarHealth));
				case TYPE_PILLS: 	dPack.WriteFloat(healed + (g_iCvarHealthP ? g_iCvarHealthP : g_iCvarHealth));
				case TYPE_DEFIB: 	dPack.WriteFloat(healed + (g_iCvarHealthD ? g_iCvarHealthD : g_iCvarHealth));
				default: dPack.WriteFloat(healed + g_iCvarHealth);
			}

			RegenPlayer(client, type);
			return Plugin_Continue;
		}
	}

	int index = g_alDataPacks.FindValue(dPack);
	if( index != -1 )
	{
		g_alDataPacks.Erase(index);
		g_alTimerHands.Erase(index);
	}

	return Plugin_Stop;
}

void RegenPlayer(int client, int type) // 1=Adrenaline. 2=Pills. 3=First aid. 4=Always Main. 5=Always Temp.
{
	// Don't affect incapacitated
	if( GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) )
	{
		return;
	}

	// Damage timeout?
	if( g_fCvarDamage )
	{
		if( GetGameTime() - g_fLastDamage[client] < g_fCvarDamage )
		{
			return;
		}
	}

	// Moving?
	if( g_fCvarMoving )
	{
		float vVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
		if( GetVectorLength(vVel) > g_fCvarMoving )
		{
			return;
		}
	}

	// Regen temp or main health
	bool temp;
	if( type == TYPE_TEMP || (type < TYPE_MAIN && g_iCvarRegenT & (1<<type - 1)) )
		temp = true;

	int give;
	switch( type )
	{
		case TYPE_ADREN: 	give = g_iCvarHealthA ? g_iCvarHealthA : g_iCvarHealth;
		case TYPE_FIRST: 	give = g_iCvarHealthF ? g_iCvarHealthF : g_iCvarHealth;
		case TYPE_PILLS: 	give = g_iCvarHealthP ? g_iCvarHealthP : g_iCvarHealth;
		case TYPE_DEFIB: 	give = g_iCvarHealthD ? g_iCvarHealthD : g_iCvarHealth;
		default:			give = g_iCvarHealth;
	}

	if( temp )
	{
		// TEMP
		float fHealth = GetTempHealth(client);
		if( fHealth + give > g_iCvarMax )
		{
			// Max health
			SetTempHealth(client, float(g_iCvarMax));
		}
		else
		{
			// Increase health
			SetTempHealth(client, GetTempHealth(client) + give);
		}
	}
	else
	{
		// MAIN
		int health = GetClientHealth(client);
		if( health + give > g_iCvarMax )
		{
			// Max health
			// HealPlayer(client);
			SetEntityHealth(client, g_iCvarMax);
		}
		else
		{
			// Increase health
			SetEntityHealth(client, health + give);
		}
	}

	// Replace temp health
	if( temp == false && g_iCvarTemp & (1<<1) )
	{
		float fHealth = GetTempHealth(client) - give;
		SetTempHealth(client, fHealth < 0.0 ? 0.0 : fHealth);
	}

	// Fix temp health to prevent over-healing.
	if( GetClientHealth(client) + GetTempHealth(client) > g_iCvarMax )
	{
		SetTempHealth(client, float(g_iCvarMax - GetClientHealth(client)));
	}
}

stock void HealPlayer(int client)
{
	int bits = GetUserFlagBits(client);
	int flags = GetCommandFlags("give");
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give health");
	SetUserFlagBits(client, bits);
	SetCommandFlags("give", flags);
}

float GetTempHealth(int client)
{
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_fDecayDecay;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

void SetTempHealth(int client, float fHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth );
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}