/**
 * vim: set ts=4 :
 * =============================================================================
 * Zombie Character Select 0.9.6-L4D2 by XBetaAlpha
 *
 * Allows a player on the infected team to change their infected class.
 * Complete rewrite based on the Infected Character Select idea by Crimson_Fox.
 *
 * SourceMod (C)2004-2016 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_NAME		"Zombie Character Select"
#define PLUGIN_AUTHOR		"XBetaAlpha"
#define PLUGIN_DESC		"Allows infected team players to change their class in ghost mode. (Versus Only)"
#define PLUGIN_VERSION		"0.9.6"
#define PLUGIN_URL		"http://dev.andrewx.net/sm/zcs"
#define PLUGIN_FILENAME	"l4d2_zcs"
#define PLUGIN_TRANSLATION_FILENAME	"l4d2_zcs.phrases"

#define CVAR_FLAGS FCVAR_NOTIFY

#define ZC_SMOKER		1
#define ZC_BOOMER		2
#define ZC_HUNTER		3
#define ZC_SPITTER		4
#define ZC_JOCKEY		5
#define ZC_CHARGER		6
#define ZC_WITCH		7
#define ZC_TANK			8
#define ZC_NOTINFECTED		9
#define ZC_TOTAL		7
#define ZC_LIMITSIZE		ZC_TOTAL + 1
#define ZC_INDEXSIZE		ZC_TOTAL + 3
#define ZC_TIMEROFFSET		0.8
#define ZC_TIMERDEATHCHECK	0.01
#define ZC_TIMERAFTERTANK	0.01
#define	ZC_TIMERCHECKGHOST	0.1

#define PLAYER_ADMFLAG_SIZE	8
#define PLAYER_HUD_DELAY	1
#define PLAYER_KEY_DELAY	2.5
#define PLAYER_LOCK_DELAY	2.5

#define CVAR_DIRECTOR_ALLOW_IB	"director_allow_infected_bots"
#define CVAR_Z_VS_SMOKER_LIMIT	"z_versus_smoker_limit"
#define CVAR_Z_VS_BOOMER_LIMIT	"z_versus_boomer_limit"
#define CVAR_Z_VS_HUNTER_LIMIT	"z_versus_hunter_limit"
#define CVAR_Z_VS_SPITTER_LIMIT	"z_versus_spitter_limit"
#define CVAR_Z_VS_JOCKEY_LIMIT	"z_versus_jockey_limit"
#define CVAR_Z_VS_CHARGER_LIMIT	"z_versus_charger_limit"

#define TEAM_SPECTATORS		1
#define TEAM_SURVIVORS		2
#define TEAM_INFECTED		3

#define TEAM_CLASS(%1)		(%1 == 1 ? "Smoker" : (%1 == 2 ? "Boomer" : (%1 == 3 ? "Hunter" :(%1 == 4 ? "Spitter" : (%1 == 5 ? "Jockey" : (%1 == 6 ? "Charger" : (%1 == 7 ? "Witch" : (%1 == 8 ? "Tank" : "None"))))))))
#define SELECT_KEY(%1)		(%1 == 1 ? IN_ATTACK2 : (%1 == 2 ? IN_RELOAD : (%1 == 3 ? IN_ZOOM : 0)))
#define PLAYER_KEYS(%1)		(%1 == 1 ? "MELEE" : (%1 == 2 ? "RELOAD" : (%1 == 3 ? "ZOOM" : "None")))

Handle g_hSetClass		= null;
Handle g_hCreateAbility	= null;
GameData g_hGameConf	= null;

ConVar g_hEnable;
ConVar g_hEnableVIB;
ConVar g_hDebug;
ConVar g_hRespectLimits;
ConVar g_hShowHudPanel;
ConVar g_hCountFakeBots;
ConVar g_hAllowFinaleSwitch;
ConVar g_hAllowLastClass;
ConVar g_hAllowLastOnLimit;
ConVar g_hAllowClassSwitch;
ConVar g_hAllowCullSwitch;
ConVar g_hAllowSpawnSwitch;
ConVar g_hAccessLevel;
ConVar g_hSelectKey;
ConVar g_hNotifyKey;
ConVar g_hNotifyKeyVerbose;
ConVar g_hNotifyClass;
ConVar g_hNotifyLock;
ConVar g_hSelectDelay;
ConVar g_hCooldownEnable;
ConVar g_hCooldownSmoker;
ConVar g_hCooldownBoomer;
ConVar g_hCooldownHunter;
ConVar g_hCooldownSpitter;
ConVar g_hCooldownJockey;
ConVar g_hCooldownCharger;
ConVar g_hLockDelay;
ConVar g_hSmokerLimit;
ConVar g_hBoomerLimit;
ConVar g_hHunterLimit;
ConVar g_hSpitterLimit;
ConVar g_hJockeyLimit;
ConVar g_hChargerLimit;

Handle g_hLockTimer[MAXPLAYERS + 1]	= {null,...};
Handle g_hAllowClassTimer[ZC_INDEXSIZE]	= {null,...};
Handle g_hSpawnGhostTimer[MAXPLAYERS + 1] = {null,...};

char g_sAccessLevel[PLAYER_ADMFLAG_SIZE];

bool g_bIsHoldingMelee[MAXPLAYERS + 1]	= {false,...};
bool g_bIsChanging[MAXPLAYERS + 1]	= {false,...};
bool g_bSwitchLock[MAXPLAYERS + 1]	= {false,...};
bool g_bHasMaterialised[MAXPLAYERS + 1]	= {false,...};
bool g_bHasSpawned[MAXPLAYERS + 1]	= {false,...};
bool g_bUserFlagsCheck[MAXPLAYERS + 1]	= {false,...};
bool g_bEnable		= false;
bool g_bDebug		= false;
bool g_bRespectLimits	= false;
bool g_bShowHudPanel	= false;
bool g_bCountFakeBots	= false;
bool g_bAllowFinaleSwitch	= false;
bool g_bAllowLastClass	= false;
bool g_bAllowLastOnLimit	= false;
bool g_bAllowClassSwitch	= false;
bool g_bAllowCullSwitch	= false;
bool g_bAllowSpawnSwitch	= false;
bool g_bCooldownEnable	= false;
bool g_bNotifyKey		= false;
bool g_bNotifyKeyVerbose	= false;
bool g_bNotifyClass		= false;
bool g_bNotifyLock		= false;
bool g_bSwitchDisabled	= false;
bool g_bRoundStart		= false;
bool g_bRoundEnd		= false;
bool g_bLeftSafeRoom	= false;
bool g_bHookedEvents	= false;

int g_iSmokerLimit		= -1;
int g_iBoomerLimit		= -1;
int g_iHunterLimit		= -1;
int g_iSpitterLimit		= -1;
int g_iJockeyLimit		= -1;
int g_iChargerLimit		= -1;
int g_iSelectKey		= 0;
int g_oAbility			= 0;

float g_fLockDelay          = 0.0;
float g_fSelectDelay		= 0.0;
float g_fCooldownSmoker		= 0.0;
float g_fCooldownBoomer		= 0.0;
float g_fCooldownHunter		= 0.0;
float g_fCooldownSpitter	= 0.0;
float g_fCooldownJockey		= 0.0;
float g_fCooldownCharger	= 0.0;
float g_fClassDelay[ZC_INDEXSIZE] = {0.0,...};

int g_iNotifyKeyVerbose[MAXPLAYERS + 1] = {0,...};
int g_iLastClass[MAXPLAYERS+1]	  = {0,...};
int g_iNextClass[MAXPLAYERS+1]	  = {0,...};
int g_iSLastClass[MAXPLAYERS+1]	  = {0,...};
int g_iZVLimits[ZC_LIMITSIZE]		  = {0,...};
int g_iAllowClass[ZC_INDEXSIZE] 	  = {1,...};
int g_iHudCooldown[ZC_INDEXSIZE]	  = {0,...};

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[+] APL2: Error: Plugin supports Left 4 Dead 2 only, exiting.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	Sub_HookGameData(PLUGIN_FILENAME);

	CreateConVar("zcs_version", PLUGIN_VERSION, "Zombie Character Select version.", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);

	g_hEnable		= CreateConVar("zcs_enable", "1", "Enable/Disable Zombie Character Select plugin.", CVAR_FLAGS);
	g_hEnableVIB		= CreateConVar("zcs_enable_vib", "1", "Enable/Disable Valve Infected Bots.", CVAR_FLAGS);
	g_hDebug		= CreateConVar("zcs_debug", "0", "Enable Zombie Character Select debug log.", CVAR_FLAGS);
	g_hRespectLimits	= CreateConVar("zcs_respect_limits", "1", "Respect server configured z_versus limits.", CVAR_FLAGS);
	g_hShowHudPanel		= CreateConVar("zcs_show_hud_panel", "0", "Display infected class limits panel.", CVAR_FLAGS);
	g_hCountFakeBots	= CreateConVar("zcs_count_fake_bots", "0", "Include fake infected bots in limits.", CVAR_FLAGS);
	g_hAllowFinaleSwitch	= CreateConVar("zcs_allow_finale_switch", "1", "Allow infected class switch at finale stages.", CVAR_FLAGS);
	g_hAllowLastClass	= CreateConVar("zcs_allow_last_class", "0", "Allow player to select previous infected class.", CVAR_FLAGS);
	g_hAllowLastOnLimit	= CreateConVar("zcs_allow_last_on_limit", "0", "Allow player to select previous infected class when limits are up.", CVAR_FLAGS);
	g_hAllowClassSwitch	= CreateConVar("zcs_allow_class_switch", "1", "Allow player to change their infected class.", CVAR_FLAGS);
	g_hAllowCullSwitch	= CreateConVar("zcs_allow_cull_switch", "0", "Allow player to select class when out of range of survivors.", CVAR_FLAGS);
	g_hAllowSpawnSwitch	= CreateConVar("zcs_allow_spawn_switch", "0", "Allow player to select class after returning to ghost from spawn.", CVAR_FLAGS);
	g_hAccessLevel		= CreateConVar("zcs_access_level", "-1", "Access level required to change class. (Up to 8 flags (Admin already allowed), -1=Disable - All Users Allowed)", CVAR_FLAGS);
	g_hSelectKey		= CreateConVar("zcs_select_key", "1", "Key binding for infected class selection. (1=MELEE, 2=RELOAD, 3=ZOOM)", CVAR_FLAGS, true, 1.0, true, 3.0);
	g_hSelectDelay		= CreateConVar("zcs_select_delay", "0.5", "Infected class switch delay in (s).", CVAR_FLAGS, true, 0.1, true, 10.0);
	g_hNotifyKey		= CreateConVar("zcs_notify_key", "1", "Broadcast infected class selection key binding to players.", CVAR_FLAGS);
	g_hNotifyKeyVerbose	= CreateConVar("zcs_notify_key_verbose", "0", "Notify key verbosity. (0=Notify first time ghost, 1=Notify every time ghost)", CVAR_FLAGS);
	g_hNotifyClass		= CreateConVar("zcs_notify_class", "1", "Broadcast class & limit status messages to players.", CVAR_FLAGS);
	g_hNotifyLock		= CreateConVar("zcs_notify_lock", "1", "Broadcast lock timer status messages to players.", CVAR_FLAGS);
	g_hCooldownEnable	= CreateConVar("zcs_cooldown_enable", "0", "Enable infected class restriction timer after player death. (0=Disable timer)", CVAR_FLAGS);
	g_hCooldownSmoker	= CreateConVar("zcs_cooldown_smoker", "-1", "Time before smoker class is allowed after player death in (s). (-1=Use Director, 0=No delay, 1-60=Delay)", CVAR_FLAGS, true, -1.0, true, 60.0);
	g_hCooldownBoomer	= CreateConVar("zcs_cooldown_boomer", "-1", "Time before boomer class is allowed after player death in (s). (-1=Use Director, 0=No delay, 1-60=Delay)", CVAR_FLAGS, true, -1.0, true, 60.0);
	g_hCooldownHunter	= CreateConVar("zcs_cooldown_hunter", "-1", "Time before hunter class is allowed after player death in (s). (-1=Use Director, 0=No delay, 1-60=Delay)", CVAR_FLAGS, true, -1.0, true, 60.0);
	g_hCooldownSpitter	= CreateConVar("zcs_cooldown_spitter", "-1", "Time before spitter class is allowed after player death in (s). (-1=Use Director, 0=No delay, 1-60=Delay)", CVAR_FLAGS, true, -1.0, true, 60.0);
	g_hCooldownJockey	= CreateConVar("zcs_cooldown_jockey", "-1", "Time before jockey class is allowed after player death in (s). (-1=Use Director, 0=No delay, 1-60=Delay)", CVAR_FLAGS, true, -1.0, true, 60.0);
	g_hCooldownCharger	= CreateConVar("zcs_cooldown_charger", "-1", "Time before charger class is allowed after player death in (s). (-1=Use Director, 0=No delay, 1-60=Delay)", CVAR_FLAGS, true, -1.0, true, 60.0);
	g_hLockDelay		= CreateConVar("zcs_lock_delay", "0", "Time before infected class switching is locked in (s). (0=Disable lock)", CVAR_FLAGS, true, 0.0, true, 600.0);
	g_hSmokerLimit		= CreateConVar("zcs_smoker_limit", "-1", "How many Smokers allowed. (-1=Use Server, 0=None Allowed, 1-10=Limit)", CVAR_FLAGS, true, -1.0, true, 10.0);
	g_hBoomerLimit		= CreateConVar("zcs_boomer_limit", "-1", "How many Boomers allowed. (-1=Use Server, 0=None Allowed, 1-10=Limit)", CVAR_FLAGS, true, -1.0, true, 10.0);
	g_hHunterLimit		= CreateConVar("zcs_hunter_limit", "-1", "How many Hunters allowed. (-1=Use Server, 0=None Allowed, 1-10=Limit)", CVAR_FLAGS, true, -1.0, true, 10.0);
	g_hSpitterLimit		= CreateConVar("zcs_spitter_limit", "-1", "How many Spitters allowed. (-1=Use Server, 0=None Allowed, 1-10=Limit)", CVAR_FLAGS, true, -1.0, true, 10.0);
	g_hJockeyLimit		= CreateConVar("zcs_jockey_limit", "-1", "How many Jockeys allowed. (-1=Use Server, 0=None Allowed, 1-10=Limit)", CVAR_FLAGS, true, -1.0, true, 10.0);
	g_hChargerLimit		= CreateConVar("zcs_charger_limit", "-1", "How many Chargers allowed. (-1=Use Server, 0=None Allowed, 1-10=Limit)", CVAR_FLAGS, true, -1.0, true, 10.0);

	AutoExecConfig(true, PLUGIN_FILENAME);
	LoadTranslations(PLUGIN_TRANSLATION_FILENAME);

	g_hEnable.AddChangeHook(Sub_ConVarsChanged);
	g_hEnableVIB.AddChangeHook(Sub_ConVarsChanged);
	g_hDebug.AddChangeHook(Sub_ConVarsChanged);
	g_hRespectLimits.AddChangeHook(Sub_ConVarsChanged);
	g_hShowHudPanel.AddChangeHook(Sub_ConVarsChanged);
	g_hCountFakeBots.AddChangeHook(Sub_ConVarsChanged);
	g_hAllowFinaleSwitch.AddChangeHook(Sub_ConVarsChanged);
	g_hAllowLastClass.AddChangeHook(Sub_ConVarsChanged);
	g_hAllowLastOnLimit.AddChangeHook(Sub_ConVarsChanged);
	g_hAllowClassSwitch.AddChangeHook(Sub_ConVarsChanged);
	g_hAllowCullSwitch.AddChangeHook(Sub_ConVarsChanged);
	g_hAllowSpawnSwitch.AddChangeHook(Sub_ConVarsChanged);
	g_hAccessLevel.AddChangeHook(Sub_ConVarsChanged);
	g_hSelectKey.AddChangeHook(Sub_ConVarsChanged);
	g_hSelectDelay.AddChangeHook(Sub_ConVarsChanged);
	g_hNotifyKey.AddChangeHook(Sub_ConVarsChanged);
	g_hNotifyKeyVerbose.AddChangeHook(Sub_ConVarsChanged);
	g_hNotifyClass.AddChangeHook(Sub_ConVarsChanged);
	g_hNotifyLock.AddChangeHook(Sub_ConVarsChanged);
	g_hCooldownEnable.AddChangeHook(Sub_ConVarsChanged);
	g_hCooldownSmoker.AddChangeHook(Sub_ConVarsChanged);
	g_hCooldownBoomer.AddChangeHook(Sub_ConVarsChanged);
	g_hCooldownHunter.AddChangeHook(Sub_ConVarsChanged);
	g_hCooldownSpitter.AddChangeHook(Sub_ConVarsChanged);
	g_hCooldownJockey.AddChangeHook(Sub_ConVarsChanged);
	g_hCooldownCharger.AddChangeHook(Sub_ConVarsChanged);
	g_hLockDelay.AddChangeHook(Sub_ConVarsChanged);
	g_hSmokerLimit.AddChangeHook(Sub_ConVarsChanged);
	g_hBoomerLimit.AddChangeHook(Sub_ConVarsChanged);
	g_hHunterLimit.AddChangeHook(Sub_ConVarsChanged);
	g_hSpitterLimit.AddChangeHook(Sub_ConVarsChanged);
	g_hJockeyLimit.AddChangeHook(Sub_ConVarsChanged);
	g_hChargerLimit.AddChangeHook(Sub_ConVarsChanged);

	FindConVar(CVAR_Z_VS_SMOKER_LIMIT).AddChangeHook(Sub_ConVarsChanged);
	FindConVar(CVAR_Z_VS_BOOMER_LIMIT).AddChangeHook(Sub_ConVarsChanged);
	FindConVar(CVAR_Z_VS_HUNTER_LIMIT).AddChangeHook(Sub_ConVarsChanged);
	FindConVar(CVAR_Z_VS_SPITTER_LIMIT).AddChangeHook(Sub_ConVarsChanged);
	FindConVar(CVAR_Z_VS_JOCKEY_LIMIT).AddChangeHook(Sub_ConVarsChanged);
	FindConVar(CVAR_Z_VS_CHARGER_LIMIT).AddChangeHook(Sub_ConVarsChanged);
}

public void OnConfigsExecuted()
{
	Sub_ReloadConVars();
	Sub_ReloadLimits();
	Sub_CheckEventHooks();
}

public void OnClientDisconnect(int Client)
{
	if (Client > 0 && !IsFakeClient(Client))
	{
		Sub_ClearClassLock(Client);
		Sub_ClearSpawnGhostTimer(Client);

		g_bHasMaterialised[Client] = false;
		g_bHasSpawned[Client] = false;
		g_bUserFlagsCheck[Client] = false;
	}
}

public void OnClientPostAdminCheck(int Client)
{
	if (Client > 0 && !IsFakeClient(Client))
	{
		g_iNotifyKeyVerbose[Client] = 0;

		if (StrEqual(g_sAccessLevel, "-1"))
		{
			g_bUserFlagsCheck[Client] = false;
		}
		else
		{
			if ((GetUserFlagBits(Client) & ADMFLAG_ROOT) || (GetUserFlagBits(Client) & ReadFlagString(g_sAccessLevel)))
			{
				g_bUserFlagsCheck[Client] = false;
			}
			else
			{
				g_bUserFlagsCheck[Client] = true;
			}
		}
	}
}

Action Event_RoundStart(Event hEvent, const char[] name, bool dontBroadcast)
{
	if (g_bRoundStart)
		return Plugin_Continue;

	g_bRoundStart = true;
	g_bRoundEnd = false;
	g_bSwitchDisabled = false;
	g_bLeftSafeRoom = false;

	Sub_InitArrays();

	if (g_bShowHudPanel)
		CreateTimer(float(PLAYER_HUD_DELAY), Timer_ShowHud, _, TIMER_REPEAT);

	return Plugin_Continue;
}

Action Event_RoundEnd(Event hEvent, const char[] name, bool dontBroadcast)
{
	if (g_bRoundEnd)
		return Plugin_Continue;

	g_bRoundStart = false;
	g_bRoundEnd = true;
	g_bSwitchDisabled = true;
	g_bLeftSafeRoom = false;

	return Plugin_Continue;
}

Action Event_FinaleStart(Event hEvent, const char[] name, bool dontBroadcast)
{
    if (!g_bAllowFinaleSwitch)
        g_bSwitchDisabled = true;
    else
        g_bSwitchDisabled = false;

    return Plugin_Continue;
}

Action Event_PlayerTeam(Event hEvent, const char[] name, bool dontBroadcast)
{
	int Client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (Client == 0 || !IsClientInGame(Client))
		return Plugin_Continue;

	int NewTeam = hEvent.GetInt("team");
	int OldTeam = hEvent.GetInt("oldteam");

	if (OldTeam == TEAM_INFECTED)
	{
		Sub_ClearClassLock(Client);
		Sub_ClearSpawnGhostTimer(Client);
		g_iNotifyKeyVerbose[Client] = 0;
	}

	if (NewTeam == TEAM_INFECTED)
	{
		Sub_ClearClassLock(Client);
		g_bHasMaterialised[Client] = false;
		g_bHasSpawned[Client] = false;

		CreateTimer(ZC_TIMERCHECKGHOST, Timer_CheckPlayerGhostDelayed, Client, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

Action Event_PlayerSpawn(Event hEvent, const char[] name, bool dontBroadcast)
{
	int Client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (Client == 0 || !IsClientInGame(Client) || IsFakeClient(Client) || GetClientTeam(Client) != TEAM_INFECTED)
		return Plugin_Continue;

	if (!g_bHasSpawned[Client])
		Sub_ClearSpawnGhostTimer(Client);

	if (g_bLeftSafeRoom)
	{
		Sub_ClearClassLock(Client);

		if (!g_bAllowSpawnSwitch)
			g_bHasMaterialised[Client] = true;
		else
			g_bHasMaterialised[Client] = false;
	}

	g_bHasSpawned[Client] = true;

	return Plugin_Continue;
}

Action Event_PlayerDeath(Event hEvent, const char[] name, bool dontBroadcast)
{
	int Client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (g_bRoundEnd || Client == 0 || !IsClientInGame(Client) || IsFakeClient(Client) || GetClientTeam(Client) != TEAM_INFECTED)
		return Plugin_Continue;

	if (g_bCooldownEnable && g_bRespectLimits)
	{
		if (!Sub_IsPlayerGhost(Client))
		{
			int ZClass = GetEntProp(Client, Prop_Send, "m_zombieClass");
			if ((ZClass >= ZC_SMOKER) && (ZClass <= ZC_CHARGER))
			{
				if (g_iAllowClass[ZClass] != 0 && g_hAllowClassTimer[ZClass] == null)
				{
					if (g_fClassDelay[ZClass] == -1 || g_fClassDelay[ZClass] > 0)
						g_iAllowClass[ZClass] = 0;
					else
						g_iAllowClass[ZClass] = 1;

					Sub_DebugPrint("[+] E_PD: (%N) Class (%s) is %s. (g_iAllowClass=%i)", Client, TEAM_CLASS(ZClass), g_iAllowClass[ZClass] == 0 ? "cooling down" : "bypassed", g_iAllowClass[ZClass]);
				}
			}
		}
	}

	if (Sub_IsPlayerGhost(Client))
		Sub_ClearClassLock(Client);

	g_bHasMaterialised[Client] = false;
	g_bHasSpawned[Client] = false;

	return Plugin_Continue;
}

Action Event_GhostSpawnTime(Event hEvent, const char[] name, bool dontBroadcast)
{
	int Client = GetClientOfUserId(hEvent.GetInt("userid"));

	if (g_bRoundEnd || Client == 0 || !IsClientInGame(Client) || IsFakeClient(Client))
		return Plugin_Continue;

	if (IsPlayerAlive(Client))
		return Plugin_Continue;

	Sub_ClearClassLock(Client);
	float SpawnTime = hEvent.GetFloat("spawntime");

	if (g_hSpawnGhostTimer[Client] == null)
	{
		g_hSpawnGhostTimer[Client] = CreateTimer(SpawnTime - ZC_TIMEROFFSET, Timer_SpawnGhostClass, Client, TIMER_FLAG_NO_MAPCHANGE);
		Sub_DebugPrint("[+] E_GST: (%N) Will spawn as a ghost in %0.fs.", Client, SpawnTime);
	}

	if (g_bCooldownEnable && g_bRespectLimits)
	{
		int ZClass = GetEntProp(Client, Prop_Send, "m_zombieClass");
		if ((ZClass >= ZC_SMOKER) && (ZClass <= ZC_CHARGER))
		{
			if (g_iAllowClass[ZClass] != 1 && g_hAllowClassTimer[ZClass] == null)
			{
				if (g_fClassDelay[ZClass] > 0)
					SpawnTime = g_fClassDelay[ZClass];

				g_iHudCooldown[ZClass] = 1;
				Sub_DebugPrint("[+] E_GST: (%N) Class (%s) will be released in %.0fs. (g_iAllowClass=0)", Client, TEAM_CLASS(ZClass), SpawnTime);
				g_hAllowClassTimer[ZClass] = CreateTimer(SpawnTime, Timer_ReleaseClass, ZClass, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}

	g_bHasMaterialised[Client] = false;
	g_bHasSpawned[Client] = false;

	return Plugin_Continue;
}

Action Event_PlayerLeftStartArea(Event hEvent, const char[] name, bool dontBroadcast)
{
	if (g_bLeftSafeRoom || g_bRoundEnd)
		return Plugin_Continue;

	g_bLeftSafeRoom = true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED)
			Sub_CheckClassLock(i);
	}
	return Plugin_Continue;
}

Action Event_DoorOpen(Event hEvent, const char[] name, bool dontBroadcast)
{
	if (g_bLeftSafeRoom || g_bRoundEnd)
        return Plugin_Continue;

	if (!hEvent.GetBool("checkpoint"))
		return Plugin_Continue;

	g_bLeftSafeRoom = true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED)
			Sub_CheckClassLock(i);
	}
	return Plugin_Continue;
}

Action Event_TankFrustrated(Event hEvent, const char[] name, bool dontBroadcast)
{
	if (g_bRoundEnd)
		return Plugin_Continue;

	int Client = GetClientOfUserId(hEvent.GetInt("userid"));
	Sub_DebugPrint("[+] E_TF: Tank is frustrated. Switching player (%N) back to special infected.", Client);
	g_bHasMaterialised[Client] = false;
	g_bHasSpawned[Client] = false;
	g_hSpawnGhostTimer[Client] = CreateTimer(ZC_TIMERAFTERTANK, Timer_SpawnGhostClass, Client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int Client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!g_bEnable || Client == 0 || !IsClientInGame(Client) || IsFakeClient(Client))
		return Plugin_Continue;

	if (Sub_IsPlayerGhost(Client) && !Sub_IsPlayerCulling(Client) && g_bAllowClassSwitch)
	{
		if (!g_bSwitchDisabled && !g_bSwitchLock[Client] && !g_bHasMaterialised[Client])
		{
			if (buttons & SELECT_KEY(g_iSelectKey))
			{
				if (!g_bIsHoldingMelee[Client] && !g_bIsChanging[Client])
				{
					g_bIsHoldingMelee[Client] = true;
					g_bIsChanging[Client] = true;

					if (g_bUserFlagsCheck[Client])
						Sub_DebugPrint("[+] OPRC: (%N) does not have the necessary access level to change class.", Client);
					else
						Sub_DetermineClass(Client, GetEntProp(Client, Prop_Send, "m_zombieClass"));

					CreateTimer(g_fSelectDelay, Timer_DelayChange, Client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			else
				g_bIsHoldingMelee[Client] = false;
		}
	}

	if (buttons & IN_ATTACK && Sub_IsPlayerGhost(Client))
		CreateTimer(1.0, Timer_SelectDelay, Client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

Action Timer_SelectDelay(Handle hTimer, any Client)
{
	if (!IsClientInGame(Client) || IsFakeClient(Client))
		return Plugin_Stop;

	if (!Sub_IsPlayerGhost(Client))
	{
		g_iLastClass[Client] = GetEntProp(Client, Prop_Send, "m_zombieClass");
		g_iSLastClass[Client] = g_iLastClass[Client];
	}
	return Plugin_Stop;
}

Action Timer_NotifyKey(Handle hTimer, any Client)
{
	if (IsClientInGame(Client) && !IsFakeClient(Client) && GetClientTeam(Client) == TEAM_INFECTED)
	{
		if (g_bNotifyKey && !g_bUserFlagsCheck[Client])
			CPrintToChat(Client, "%t", "PLAYER_NOTIFY_KEY", PLAYER_KEYS(g_iSelectKey));
	}
	return Plugin_Stop;
}

Action Timer_NotifyLock(Handle hTimer, any Client)
{
	if (IsClientInGame(Client) && !IsFakeClient(Client) && GetClientTeam(Client) == TEAM_INFECTED)
	{
		if (g_bNotifyLock && !g_bUserFlagsCheck[Client])
			CPrintToChat(Client, "%t", "PLAYER_NOTIFY_LOCK", g_fLockDelay);
	}
	return Plugin_Stop;
}

Action Timer_DelayChange(Handle hTimer, any Client)
{
	g_bIsChanging[Client] = false;
	return Plugin_Stop;
}

Action Timer_CheckPlayerGhostDelayed(Handle hTimer, any Client)
{
	if (Client > 0 && IsClientInGame(Client) && !IsFakeClient(Client) && Sub_IsPlayerGhost(Client))
	{
		Sub_CheckClassLock(Client);
		Sub_DetermineClass(Client, GetEntProp(Client, Prop_Send, "m_zombieClass"));

		if (g_bNotifyKey)
		{
			CreateTimer(PLAYER_KEY_DELAY, Timer_NotifyKey, Client, TIMER_FLAG_NO_MAPCHANGE);
			g_iNotifyKeyVerbose[Client] = 1;
		}
	}
	return Plugin_Stop;
}

Action Timer_ReleaseClass(Handle hTimer, any ZClass)
{
	if (g_iAllowClass[ZClass] != 1)
	{
		g_iAllowClass[ZClass] = 1;
		g_iHudCooldown[ZClass] = 0;
		Sub_DebugPrint("[+] T_RC: Class (%s) is now released. (g_iAllowClass=1)", TEAM_CLASS(ZClass));
		g_hAllowClassTimer[ZClass] = null;
	}
	return Plugin_Stop;
}

Action Timer_SpawnGhostClass(Handle hTimer, any Client)
{
	g_hSpawnGhostTimer[Client] = null;

	if (g_bRoundEnd || Client == 0 || !IsClientInGame(Client) || Sub_IsTank(Client) || IsFakeClient(Client) || GetClientTeam(Client) != TEAM_INFECTED)
		return Plugin_Stop;

	if (!IsPlayerAlive(Client))
	{
		Sub_DebugPrint("[+] T_SGC: (%N) Waiting for player to become alive.", Client);
		CreateTimer(ZC_TIMERDEATHCHECK, Timer_SpawnGhostClass, Client, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}

	if (!Sub_IsPlayerGhost(Client))
		return Plugin_Continue;

	Sub_CheckClassLock(Client);

	int ZClass = GetEntProp(Client, Prop_Send, "m_zombieClass");

	if (!g_bRespectLimits)
	{
		if (ZClass == g_iLastClass[Client])
			Sub_DetermineClass(Client, ZClass);
	}
	else
		Sub_DetermineClass(Client, ZClass);

	if (g_bNotifyKey && g_bNotifyKeyVerbose)
	{
		CreateTimer(PLAYER_KEY_DELAY, Timer_NotifyKey, Client, TIMER_FLAG_NO_MAPCHANGE);
		g_iNotifyKeyVerbose[Client] = 0;
	}
	else
	{
		if (g_bNotifyKey && !g_bNotifyKeyVerbose)
		{
			if (g_iNotifyKeyVerbose[Client] != 1)
			{
				CreateTimer(PLAYER_KEY_DELAY, Timer_NotifyKey, Client, TIMER_FLAG_NO_MAPCHANGE);
				g_iNotifyKeyVerbose[Client] = 1;
			}
		}
	}

	Sub_DebugPrint("[+] T_SGC: Current Entity Count: %d (Total: %d)", GetEntityCount(), GetMaxEntities());

	return Plugin_Stop;
}

Action Timer_SwitchLock(Handle hTimer, any Client)
{
	if (Client == 0 || !IsClientInGame(Client) || IsFakeClient(Client) || GetClientTeam(Client) != TEAM_INFECTED)
		return Plugin_Stop;

	if (g_fLockDelay > 0 && g_bLeftSafeRoom && !Sub_IsTank(Client) && g_bAllowClassSwitch)
	{
		if (Sub_IsPlayerGhost(Client))
		{
			if (g_bNotifyLock)
				CPrintToChat(Client, "%t", "PLAYER_SWITCH_LOCK", g_fLockDelay);

			g_bSwitchLock[Client] = true;
		}
	}
	return Plugin_Stop;
}

Action Timer_ShowHud(Handle hTimer)
{
	if (g_bRoundEnd)
		return Plugin_Stop;

	Hud_ShowLimits();

	return Plugin_Continue;
}

stock void Sub_ClearSpawnGhostTimer(any Client)
{
	if (g_hSpawnGhostTimer[Client] != null)
	{
		delete g_hSpawnGhostTimer[Client];
		Sub_DebugPrint("[+] S_CSGT: (%N) Clearing spawn ghost timer.", Client);
	}
}

stock void Sub_ClearClassLock(any Client)
{
	if (g_fLockDelay > 0 && g_bLeftSafeRoom)
	{
		if (g_hLockTimer[Client] != null)
		{
			if (!g_bSwitchLock[Client] && !IsFakeClient(Client))
				delete g_hLockTimer[Client];

			g_bSwitchLock[Client] = false;
			Sub_DebugPrint("[+] S_CCL: (%N) Clearing lock timer (%.0fs).", Client, g_fLockDelay);
		}
	}
}

stock void Sub_CheckClassLock(any Client)
{
	if (g_fLockDelay > 0 && g_bLeftSafeRoom && !Sub_IsTank(Client) && IsPlayerAlive(Client) && g_bAllowClassSwitch)
	{
		if (g_hLockTimer[Client] == null)
		{
			Sub_DebugPrint("[+] S_CCL: (%N) Creating lock timer (%.0fs).", Client, g_fLockDelay);
			CreateTimer(PLAYER_LOCK_DELAY, Timer_NotifyLock, Client, TIMER_FLAG_NO_MAPCHANGE);
			g_hLockTimer[Client] = CreateTimer(g_fLockDelay, Timer_SwitchLock, Client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

stock void Sub_InitArrays()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iNextClass[i] = 0;
		g_iLastClass[i] = 0;
		g_iSLastClass[i] = 0;
		g_bSwitchLock[i] = false;
		g_bIsHoldingMelee[i] = false;
		g_bIsChanging[i] = false;
		g_bHasMaterialised[i] = false;
		g_bHasSpawned[i] = false;
		g_hLockTimer[i] = null;
		g_hSpawnGhostTimer[i] = null;
		g_iNotifyKeyVerbose[i] = 0;
	}

	if (g_bCooldownEnable)
	{
		for (int i = 1; i <= ZC_TOTAL; i++)
		{
			g_hAllowClassTimer[i] = null;
			g_iAllowClass[i] = 1;
			g_iHudCooldown[i] = 0;
		}
	}
}

stock void Sub_CheckEventHooks()
{
	if (g_bEnable)
	{
		if (!g_bHookedEvents)
		{
			HookEvent("round_start", Event_RoundStart);
			HookEvent("round_end", Event_RoundEnd);
			HookEvent("mission_lost", Event_RoundEnd);
			HookEvent("finale_win", Event_RoundEnd);
			HookEvent("finale_start", Event_FinaleStart);
			HookEvent("player_team", Event_PlayerTeam);
			HookEvent("ghost_spawn_time", Event_GhostSpawnTime);
			HookEvent("player_left_start_area", Event_PlayerLeftStartArea);
			HookEvent("player_death", Event_PlayerDeath);
			HookEvent("player_spawn", Event_PlayerSpawn);
			HookEvent("door_open", Event_DoorOpen);
			HookEvent("tank_frustrated", Event_TankFrustrated);

			g_bHookedEvents = true;
			Sub_DebugPrint("[+] S_CEH: Hooked all events (Plugin Enabled).");
		}
	}
	else if (!g_bEnable)
	{
		if (g_bHookedEvents)
		{
			UnhookEvent("round_start", Event_RoundStart);
			UnhookEvent("round_end", Event_RoundEnd);
			UnhookEvent("mission_lost", Event_RoundEnd);
			UnhookEvent("finale_win", Event_RoundEnd);
			UnhookEvent("finale_start", Event_FinaleStart);
			UnhookEvent("player_team", Event_PlayerTeam);
			UnhookEvent("ghost_spawn_time", Event_GhostSpawnTime);
			UnhookEvent("player_left_start_area", Event_PlayerLeftStartArea);
			UnhookEvent("player_death", Event_PlayerDeath);
			UnhookEvent("player_spawn", Event_PlayerSpawn);
			UnhookEvent("door_open", Event_DoorOpen);
			UnhookEvent("tank_frustrated", Event_TankFrustrated);

			g_bHookedEvents = false;
			Sub_DebugPrint("[+] S_CEH: Unhooked all events (Plugin Disabled).");
		}
	}
}

stock void Sub_ReloadConVars()
{
	g_bEnable = g_hEnable.BoolValue;
	g_bDebug = g_hDebug.BoolValue;
	g_bRespectLimits = g_hRespectLimits.BoolValue;
	g_bShowHudPanel = g_hShowHudPanel.BoolValue;
	g_bCountFakeBots = g_hCountFakeBots.BoolValue;
	g_bAllowFinaleSwitch = g_hAllowFinaleSwitch.BoolValue;
	g_bAllowLastClass = g_hAllowLastClass.BoolValue;
	g_bAllowLastOnLimit = g_hAllowLastOnLimit.BoolValue;
	g_bAllowClassSwitch = g_hAllowClassSwitch.BoolValue;
	g_bAllowCullSwitch = g_hAllowCullSwitch.BoolValue;
	g_bAllowSpawnSwitch = g_hAllowSpawnSwitch.BoolValue;
	g_hAccessLevel.GetString(g_sAccessLevel, sizeof(g_sAccessLevel));
	g_iSelectKey = g_hSelectKey.IntValue;
	g_bNotifyKey = g_hNotifyKey.BoolValue;
	g_bNotifyKeyVerbose = g_hNotifyKeyVerbose.BoolValue;
	g_bNotifyClass = g_hNotifyClass.BoolValue;
	g_bNotifyLock = g_hNotifyLock.BoolValue;
	g_fSelectDelay = g_hSelectDelay.FloatValue;
	g_bCooldownEnable = g_hCooldownEnable.BoolValue;
	g_fCooldownSmoker = g_hCooldownSmoker.FloatValue;
	g_fCooldownBoomer = g_hCooldownBoomer.FloatValue;
	g_fCooldownHunter = g_hCooldownHunter.FloatValue;
	g_fCooldownSpitter = g_hCooldownSpitter.FloatValue;
	g_fCooldownJockey = g_hCooldownJockey.FloatValue;
	g_fCooldownCharger = g_hCooldownCharger.FloatValue;
	g_fLockDelay = g_hLockDelay.FloatValue;
	g_iSmokerLimit = g_hSmokerLimit.IntValue;
	g_iBoomerLimit = g_hBoomerLimit.IntValue;
	g_iHunterLimit = g_hHunterLimit.IntValue;
	g_iSpitterLimit = g_hSpitterLimit.IntValue;
	g_iJockeyLimit = g_hJockeyLimit.IntValue;
	g_iChargerLimit = g_hChargerLimit.IntValue;

	if (g_hEnableVIB.BoolValue)
		FindConVar(CVAR_DIRECTOR_ALLOW_IB).SetInt(1, false, false);
	else
		FindConVar(CVAR_DIRECTOR_ALLOW_IB).SetInt(0, false, false);
}

stock void Sub_ReloadLimits()
{
	for (int i = 1; i <= ZC_TOTAL; i++)
	{
		g_iZVLimits[i] = 0;
		g_fClassDelay[i] = 0.0;
	}

	g_iZVLimits[ZC_SMOKER] = g_iSmokerLimit != -1 ? g_iSmokerLimit : FindConVar(CVAR_Z_VS_SMOKER_LIMIT).IntValue;
	g_iZVLimits[ZC_BOOMER] = g_iBoomerLimit != -1 ? g_iBoomerLimit : FindConVar(CVAR_Z_VS_BOOMER_LIMIT).IntValue;
	g_iZVLimits[ZC_HUNTER] = g_iHunterLimit != -1 ? g_iHunterLimit : FindConVar(CVAR_Z_VS_HUNTER_LIMIT).IntValue;
	g_iZVLimits[ZC_SPITTER] = g_iSpitterLimit != -1 ? g_iSpitterLimit : FindConVar(CVAR_Z_VS_SPITTER_LIMIT).IntValue;
	g_iZVLimits[ZC_JOCKEY] = g_iJockeyLimit != -1 ? g_iJockeyLimit : FindConVar(CVAR_Z_VS_JOCKEY_LIMIT).IntValue;
	g_iZVLimits[ZC_CHARGER] = g_iChargerLimit != -1 ? g_iChargerLimit : FindConVar(CVAR_Z_VS_CHARGER_LIMIT).IntValue;

	for (int i = ZC_SMOKER; i <= ZC_CHARGER; i++)
	{
		g_iZVLimits[ZC_TOTAL] += g_iZVLimits[i];
	}

	g_fClassDelay[ZC_SMOKER] = g_fCooldownSmoker;
	g_fClassDelay[ZC_BOOMER] = g_fCooldownBoomer;
	g_fClassDelay[ZC_HUNTER] = g_fCooldownHunter;
	g_fClassDelay[ZC_SPITTER] = g_fCooldownSpitter;
	g_fClassDelay[ZC_JOCKEY] = g_fCooldownJockey;
	g_fClassDelay[ZC_CHARGER] = g_fCooldownCharger;
}

stock void Sub_HookGameData(char[] GameDataFile)
{
	g_hGameConf = new GameData(GameDataFile);
	if (g_hGameConf != null)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "SetClass");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSetClass = EndPrepSDKCall();

		if (g_hSetClass == null)
			SetFailState("[+] S_HGD: Error: Unable to find SetClass signature.");

		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CreateAbility");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hCreateAbility = EndPrepSDKCall();

		if (g_hCreateAbility == null)
			SetFailState("[+] S_HGD: Error: Unable to find CreateAbility signature.");

		g_oAbility = g_hGameConf.GetOffset("oAbility");

		delete g_hGameConf;
	}
	else
		SetFailState("[+] S_HGD: Error: Unable to load gamedata file, exiting.");
}

void Sub_ConVarsChanged(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
	Sub_ReloadConVars();
	Sub_ReloadLimits();
	Sub_CheckEventHooks();
}

stock int Sub_CountInfectedClass(any ZClass, bool GetTotal)
{
	int ClassCount, ClassType;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			if (IsPlayerAlive(i))
			{
				ClassType = GetEntProp(i, Prop_Send, "m_zombieClass");
				if (GetTotal && ClassType != ZC_TANK)
				{
					if (!g_bCountFakeBots)
					{
						if (!IsFakeClient(i))
							ClassCount++;
					}
					else
						ClassCount++;
				}
				else
				{
					if (ClassType == ZClass)
					{
						if (!g_bCountFakeBots)
						{
							if (!IsFakeClient(i))
								ClassCount++;
						}
						else
							ClassCount++;
					}
				}
			}
		}
	}
	return ClassCount;
}

stock bool Sub_CheckPerClassLimits(any ZClass)
{
	int ClassCount = Sub_CountInfectedClass(ZClass, false);
	if (g_bCooldownEnable && g_bRespectLimits)
	{
		if (g_iAllowClass[ZClass] != 1)
		{
			Sub_DebugPrint("[+] S_CPCL: Class (%s) cannot be selected while cooling down. Count Raised (%d/%d)", TEAM_CLASS(ZClass), ClassCount, ClassCount + 1);
			ClassCount += 1;
		}
	}

	if (ClassCount < g_iZVLimits[ZClass])
		return true;
	return false;
}

stock bool Sub_CheckAllClassLimits(any ZClass)
{
	for (int i = ZC_SMOKER; i <= ZC_CHARGER; i++)
	{
		int ClassCount = Sub_CountInfectedClass(i, false);
		if (g_bCooldownEnable && g_bRespectLimits)
		{
			if (g_iAllowClass[i] != 1)
				ClassCount += 1;
		}

		if (ZClass == 0)
		{
	        if (ClassCount < g_iZVLimits[i])
        		return true;
		}
		else
		{
			if (ClassCount < g_iZVLimits[i] && ZClass != i)
				return true;
		}
	}
	return false;
}

stock bool Sub_IsTank(any Client)
{
	return IsPlayerAlive(Client) && view_as<int>(GetEntProp(Client, Prop_Send, "m_zombieClass")) == ZC_TANK;
}

stock void Sub_DetermineClass(any Client, any ZClass)
{
	if (ZClass > ZC_CHARGER)
		return;

	g_iNextClass[Client] = (ZClass >= ZC_SMOKER && ZClass < ZC_CHARGER) ? ZClass + 1 : ZC_SMOKER;

	if (g_bRespectLimits)
	{
		do
		{
			if (Sub_IsTank(Client))
				return;

			int ZTotal = Sub_CountInfectedClass(0, true);
			if (!Sub_CheckAllClassLimits(0))
			{
				if (ZTotal < g_iZVLimits[ZC_TOTAL])
				{
					if (g_bNotifyClass)
						CPrintToChat(Client, "%t", "PLAYER_COOLDOWN_WAIT", TEAM_CLASS(g_iLastClass[Client]), ZTotal, g_iZVLimits[ZC_TOTAL]);
				}

				else
				{
					if (g_bNotifyClass)
						CPrintToChat(Client, "%t", "PLAYER_LIMITS_UP", ZTotal, g_iZVLimits[ZC_TOTAL]);
				}

				Sub_DebugPrint("[+] S_DC: (%N) Player limits are up. (%d/%d)", Client, ZTotal, g_iZVLimits[ZC_TOTAL]);

				return;
			}

			for (int i = ZC_SMOKER; i <= ZC_CHARGER; i++)
			{
				if (g_iNextClass[Client] == i)
				{
					if (!Sub_CheckPerClassLimits(i))
					{
						Sub_DebugPrint("[+] S_DC: (%N) Next Class Over Limit (%s)", Client, TEAM_CLASS(i));
						g_iNextClass[Client] = (i >= ZC_SMOKER && i < ZC_CHARGER) ? i + 1 : ZC_SMOKER;
					}
				}

				if (!g_bAllowLastClass)
				{
					if (Sub_CheckLastClass(Client, g_iNextClass[Client]) != 0)
						return;
				}
			}

			Sub_DebugPrint("[+] S_DC: (%N) Zombie Class (Last: %s, Next: %s Total: %d)", Client, TEAM_CLASS(g_iLastClass[Client]), TEAM_CLASS(g_iNextClass[Client]), ZTotal);

			if (!Sub_CheckPerClassLimits(g_iNextClass[Client]))
				Sub_DebugPrint("[+] S_DC: (%N) Looping as (%s) is over limit.", Client, TEAM_CLASS(g_iNextClass[Client]));
		}
		while (!Sub_CheckPerClassLimits(g_iNextClass[Client]));
	}

	if (ZClass == g_iNextClass[Client])
	{
		if (g_bNotifyClass)
			CPrintToChat(Client, "%t", "PLAYER_CLASSES_UP_DENY");

		Sub_DebugPrint("[+] S_DC: (%N) Zombie Class %s is the only class available at this time.", Client, TEAM_CLASS(ZClass));

		return;
	}

	if (Sub_IsPlayerGhost(Client))
	{
		int WeaponIndex;
		while ((WeaponIndex = GetPlayerWeaponSlot(Client, 0)) != -1)
		{
			RemovePlayerItem(Client, WeaponIndex);
			RemoveEdict(WeaponIndex);
		}

		SDKCall(g_hSetClass, Client, g_iNextClass[Client]);
		int cAbility = GetEntPropEnt(Client, Prop_Send, "m_customAbility");
		if (cAbility > 0) AcceptEntityInput(cAbility, "Kill");
		SetEntProp(Client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hCreateAbility, Client), g_oAbility));
	}

	return;
}

stock int Sub_CheckLastClass(any Client, any ZClass)
{
	g_iLastClass[Client] = g_iSLastClass[Client];
	if (g_iLastClass[Client] == ZClass)
	{
		Sub_DebugPrint("[+] S_CLC: (%N) Detected Same Class (%s/%s)", Client, TEAM_CLASS(g_iLastClass[Client]), TEAM_CLASS(g_iNextClass[Client]));

		if (!Sub_CheckAllClassLimits(g_iLastClass[Client]))
		{
			if (g_bAllowLastOnLimit)
			{
				if (g_bNotifyClass)
					CPrintToChat(Client, "%t", "PLAYER_CLASSES_UP_ALLOW");

				Sub_DebugPrint("[+] S_CLC: (%N) Player classes are up. Last class: %s allowed.", Client, TEAM_CLASS(g_iLastClass[Client]));
				g_iSLastClass[Client] = g_iLastClass[Client];
				g_iLastClass[Client] = 0;

				return 0;
			}
			else
			{
				if (g_bNotifyClass)
					CPrintToChat(Client, "%t", "PLAYER_CLASSES_UP_DENY");

				Sub_DebugPrint("[+] S_CLC: (%N) Player classes are up. No more classes allowed.", Client);

				return 1;
			}
		}
		else
			g_iNextClass[Client] = (ZClass >= ZC_SMOKER && ZClass < ZC_CHARGER) ? ZClass + 1 : ZC_SMOKER;
	}
	return 0;
}

stock bool Sub_IsPlayerGhost(any Client)
{
	return view_as<bool>(GetEntProp(Client, Prop_Send, "m_isGhost"));
}

stock bool Sub_IsPlayerCulling(any Client)
{
	return !g_bAllowCullSwitch && view_as<bool>(GetEntProp(Client, Prop_Send, "m_isCulling"));
}

stock void Sub_DebugPrint(const char[] Message, any ...)
{
	if (g_bDebug)
	{
		char DebugBuff[128];
		VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
		LogMessage(DebugBuff);
	}
}

stock void Hud_ShowLimits()
{
	if (!g_bShowHudPanel || !g_bEnable)
		return;

	Panel hPanel = new Panel();
	char sPanelBuff[1024], sCooldownSymbol[8] = "";

	Format(sPanelBuff, sizeof(sPanelBuff), "Infected Limits");
	hPanel.DrawText(sPanelBuff);
	hPanel.DrawText(" ");

	for (int i = ZC_SMOKER; i <= ZC_CHARGER; i++)
	{
		sCooldownSymbol = g_iHudCooldown[i] == 1 ? "(C)" : "   ";
		Format(sPanelBuff, sizeof(sPanelBuff), "->%d. (%d/%d) %s %s", i, Sub_CountInfectedClass(i, false), g_iZVLimits[i], TEAM_CLASS(i), sCooldownSymbol);
		hPanel.DrawText(sPanelBuff);
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
		{
			if (GetClientTeam(i) == TEAM_INFECTED && Sub_IsPlayerGhost(i))
			{
				if ((GetClientMenu(i) == MenuSource_RawPanel) || (GetClientMenu(i) == MenuSource_None))
                    hPanel.Send(i, Hud_LimitsPanel, PLAYER_HUD_DELAY);
			}
		}
	}

	hPanel.Close();
}

int Hud_LimitsPanel(Menu hMenu, MenuAction action, int param1, int param2)
{
	return 0;
}
