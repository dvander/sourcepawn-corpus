#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "Zombie Character Select"
#define PLUGIN_AUTHOR "XBetaAlpha"
#define PLUGIN_DESC "Allows Infected To Change Characters While In Ghost Mode."
#define PLUGIN_VERSION "0.9.5"
#define PLUGIN_URL "http://dev.andrewx.net/sm/zcs-l4d2"
#define PLUGIN_FILENAME "zcs-l4d2"

#define L4D_MAXPLAYERS 32
#define L4D_GAMENAME "left4dead2"

#define ZC_SMOKER 1
#define ZC_BOOMER 2
#define ZC_HUNTER 3
#define ZC_SPITTER 4
#define ZC_JOCKEY 5
#define ZC_CHARGER 6
#define ZC_WITCH 7
#define ZC_TANK 8
#define ZC_NOTINFECTED 9
#define ZC_TOTAL 7
#define ZC_LIMITSIZE ZC_TOTAL + 1
#define ZC_INDEXSIZE ZC_TOTAL + 3
#define ZC_TIMEROFFSET 0.8
#define ZC_TIMERDEATHCHECK 0.01
#define ZC_TIMERAFTERTANK 0.01
#define	ZC_TIMERCHECKGHOST 0.1

#define PLAYER_ADMFLAG_SIZE	8
#define PLAYER_HUD_DELAY 1
#define PLAYER_KEY_DELAY 2.5
#define PLAYER_LOCK_DELAY 2.5
#define PLAYER_NOTIFY_KEY "\x04Press the %s key as ghost to change zombie class."
#define PLAYER_LIMITS_UP "\x04Limits reached. Select current class or wait. (%d/%d)"
#define PLAYER_COOLDOWN_WAIT "\x04Waiting for %s class to become available. (%d/%d)"
#define PLAYER_CLASSES_UP_ALLOW "\x04No more classes available. Last class allowed."
#define PLAYER_CLASSES_UP_DENY "\x04No more classes available. Select current class or wait."
#define PLAYER_NOTIFY_LOCK "\x04Locking Class Selection In %.0fs."
#define PLAYER_SWITCH_LOCK "\x04Locked Class Selection! (%.0fs up)"

#define CVAR_DIRECTOR_ALLOW_IB "director_allow_infected_bots"
#define CVAR_Z_VS_SMOKER_LIMIT "z_versus_smoker_limit"
#define CVAR_Z_VS_BOOMER_LIMIT "z_versus_boomer_limit"
#define CVAR_Z_VS_HUNTER_LIMIT "z_versus_hunter_limit"
#define CVAR_Z_VS_SPITTER_LIMIT "z_versus_spitter_limit"
#define CVAR_Z_VS_JOCKEY_LIMIT "z_versus_jockey_limit"
#define CVAR_Z_VS_CHARGER_LIMIT "z_versus_charger_limit"

#define TEAM_SPECTATORS 1
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

#define TEAM_CLASS(%1) (%1 == 1 ? "Smoker" : (%1 == 2 ? "Boomer" : (%1 == 3 ? "Hunter" :(%1 == 4 ? "Spitter" : (%1 == 5 ? "Jockey" : (%1 == 6 ? "Charger" : (%1 == 7 ? "Witch" : (%1 == 8 ? "Tank" : "None"))))))))
#define SELECT_KEY(%1) (%1 == 1 ? IN_ATTACK2 : (%1 == 2 ? IN_RELOAD : (%1 == 3 ? IN_ZOOM : 0)))
#define PLAYER_KEYS(%1) (%1 == 1 ? "MELEE" : (%1 == 2 ? "RELOAD" : (%1 == 3 ? "ZOOM" : "None")))

new Handle:g_hSetClass = INVALID_HANDLE;
new Handle:g_hCreateAbility	= INVALID_HANDLE;
new Handle:g_hGameConf = INVALID_HANDLE;

new Handle:g_hEnable = INVALID_HANDLE;
new Handle:g_hEnableVIB = INVALID_HANDLE;
new Handle:g_hRespectLimits = INVALID_HANDLE;
new Handle:g_hShowHudPanel = INVALID_HANDLE;
new Handle:g_hCountFakeBots = INVALID_HANDLE;
new Handle:g_hAllowFinaleSwitch = INVALID_HANDLE;
new Handle:g_hAllowLastClass = INVALID_HANDLE;
new Handle:g_hAllowLastOnLimit = INVALID_HANDLE;
new Handle:g_hAllowClassSwitch = INVALID_HANDLE;
new Handle:g_hAllowCullSwitch = INVALID_HANDLE;
new Handle:g_hAllowSpawnSwitch = INVALID_HANDLE;
new Handle:g_hAccessLevel = INVALID_HANDLE;
new Handle:g_hSelectKey = INVALID_HANDLE;
new Handle:g_hNotifyKey = INVALID_HANDLE;
new Handle:g_hNotifyKeyVerbose = INVALID_HANDLE;
new Handle:g_hNotifyClass = INVALID_HANDLE;
new Handle:g_hNotifyLock = INVALID_HANDLE;
new Handle:g_hSelectDelay = INVALID_HANDLE;
new Handle:g_hCooldownEnable = INVALID_HANDLE;
new Handle:g_hCooldownSmoker = INVALID_HANDLE;
new Handle:g_hCooldownBoomer = INVALID_HANDLE;
new Handle:g_hCooldownHunter = INVALID_HANDLE;
new Handle:g_hCooldownSpitter = INVALID_HANDLE;
new Handle:g_hCooldownJockey = INVALID_HANDLE;
new Handle:g_hCooldownCharger = INVALID_HANDLE;
new Handle:g_hLockDelay = INVALID_HANDLE;
new Handle:g_hSmokerLimit = INVALID_HANDLE;
new Handle:g_hBoomerLimit = INVALID_HANDLE;
new Handle:g_hHunterLimit = INVALID_HANDLE;
new Handle:g_hSpitterLimit = INVALID_HANDLE;
new Handle:g_hJockeyLimit = INVALID_HANDLE;
new Handle:g_hChargerLimit = INVALID_HANDLE;

new Handle:g_hLockTimer[L4D_MAXPLAYERS+1] = {INVALID_HANDLE,...};
new Handle:g_hAllowClassTimer[ZC_INDEXSIZE] = {INVALID_HANDLE,...};
new Handle:g_hSpawnGhostTimer[L4D_MAXPLAYERS+1] = {INVALID_HANDLE,...};

new String:g_sAccessLevel[PLAYER_ADMFLAG_SIZE];

new bool:g_bIsHoldingMelee[L4D_MAXPLAYERS+1] = {false,...};
new bool:g_bIsChanging[L4D_MAXPLAYERS+1] = {false,...};
new bool:g_bSwitchLock[L4D_MAXPLAYERS+1] = {false,...};
new bool:g_bHasMaterialised[L4D_MAXPLAYERS+1] = {false,...};
new bool:g_bHasSpawned[L4D_MAXPLAYERS+1] = {false,...};
new bool:g_bUserFlagsCheck[L4D_MAXPLAYERS+1] = {false,...};
new bool:g_bEnable = false;
new bool:g_bRespectLimits = false;
new bool:g_bShowHudPanel = false;
new bool:g_bCountFakeBots = false;
new bool:g_bAllowFinaleSwitch = false;
new bool:g_bAllowLastClass = false;
new bool:g_bAllowLastOnLimit = false;
new bool:g_bAllowClassSwitch = false;
new bool:g_bAllowCullSwitch	= false;
new bool:g_bAllowSpawnSwitch = false;
new bool:g_bCooldownEnable = false;
new bool:g_bNotifyKey = false;
new bool:g_bNotifyKeyVerbose = false;
new bool:g_bNotifyClass = false;
new bool:g_bNotifyLock = false;
new bool:g_bSwitchDisabled = false;
new bool:g_bRoundStart = false;
new bool:g_bRoundEnd = false;
new bool:g_bLeftSafeRoom = false;
new bool:g_bHookedEvents = false;

new g_iSmokerLimit = -1;
new g_iBoomerLimit = -1;
new g_iHunterLimit = -1;
new g_iSpitterLimit = -1;
new g_iJockeyLimit = -1;
new g_iChargerLimit = -1;
new g_iSelectKey = 0;
new g_oAbility = 0;

new Float:g_fLockDelay = 0.0;
new Float:g_fSelectDelay = 0.0;
new Float:g_fCooldownSmoker = 0.0;
new Float:g_fCooldownBoomer = 0.0;
new Float:g_fCooldownHunter = 0.0;
new Float:g_fCooldownSpitter = 0.0;
new Float:g_fCooldownJockey = 0.0;
new Float:g_fCooldownCharger = 0.0;
new Float:g_fClassDelay[ZC_INDEXSIZE] = {0.0,...};

new g_iNotifyKeyVerbose[L4D_MAXPLAYERS+1] = {0,...};
new g_iLastClass[L4D_MAXPLAYERS+1] = {0,...};
new g_iNextClass[L4D_MAXPLAYERS+1] = {0,...};
new g_iSLastClass[L4D_MAXPLAYERS+1] = {0,...};
new g_iZVLimits[ZC_LIMITSIZE] = {0,...};
new g_iAllowClass[ZC_INDEXSIZE] = {1,...};
new g_iHudCooldown[ZC_INDEXSIZE] = {0,...};

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:isAfterMapLoaded, String:error[], err_max)
{
	if (!Sub_CheckGameName(L4D_GAMENAME))
	{
		Format(error, err_max, "[SM] Plugin Supports L4D2 Only!");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public OnPluginStart()
{
	Sub_HookGameData(PLUGIN_FILENAME);
	
	CreateConVar("zcs-l4d2_version", PLUGIN_VERSION, "Zombie Character Select Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hEnable = CreateConVar("zcs-l4d2_enable", "1", "Enable/Disable Plugin", FCVAR_NOTIFY);
	g_hEnableVIB = CreateConVar("zcs-l4d2_enable_vib", "1", "Enable/Disable Valve Infected Bots", FCVAR_NOTIFY);
	g_hRespectLimits = CreateConVar("zcs-l4d2_respect_limits", "1", "Enable/Disable Respect Limits", FCVAR_NOTIFY);
	g_hShowHudPanel = CreateConVar("zcs-l4d2_show_hud_panel", "0", "Enable/Disable HUD Panel", FCVAR_NOTIFY);
	g_hCountFakeBots = CreateConVar("zcs-l4d2_count_fake_bots", "1", "Enable/Disable Include Fake Bots", FCVAR_NOTIFY);
	g_hAllowFinaleSwitch = CreateConVar("zcs-l4d2_allow_finale_switch", "1", "Enable/Disable Class Switch In Finales", FCVAR_NOTIFY);
	g_hAllowLastClass = CreateConVar("zcs-l4d2_allow_last_class", "1", "Enable/Disable Last Class Select", FCVAR_NOTIFY);
	g_hAllowLastOnLimit	= CreateConVar("zcs-l4d2_allow_last_on_limit", "0", "Enable/Disable Reached Class Limits Select", FCVAR_NOTIFY);
	g_hAllowClassSwitch	= CreateConVar("zcs-l4d2_allow_class_switch", "1", "Enable/Disable Class Select", FCVAR_NOTIFY);
	g_hAllowCullSwitch = CreateConVar("zcs-l4d2_allow_cull_switch", "0", "Enable/Disable Culling Class Select", FCVAR_NOTIFY);
	g_hAllowSpawnSwitch = CreateConVar("zcs-l4d2_allow_spawn_switch", "1", "Enable/Disable Ghost Switch", FCVAR_NOTIFY);
	g_hAccessLevel = CreateConVar("zcs-l4d2_access_level", "-1", "Access Required To Class Switch", FCVAR_NOTIFY);
	g_hSelectKey = CreateConVar("zcs-l4d2_select_key", "1", "Key Mode: 1 = MELEE, 2 = RELOAD, 3 = ZOOM", FCVAR_NOTIFY, true, 1.0, true, 3.0);
	g_hSelectDelay = CreateConVar("zcs-l4d2_select_delay", "0.5", "Delay To Class Switch", FCVAR_NOTIFY, true, 0.1, true, 10.0);
	g_hNotifyKey = CreateConVar("zcs-l4d2_notify_key", "1", "Enable/Disable Key Notifications", FCVAR_NOTIFY);
	g_hNotifyKeyVerbose	= CreateConVar("zcs-l4d2_notify_key_verbose", "0", "Notification Mode: 0 = First Time, 1 = Every Time", FCVAR_NOTIFY);
	g_hNotifyClass = CreateConVar("zcs-l4d2_notify_class", "1", "Enable/Disable Notifications", FCVAR_NOTIFY);
	g_hNotifyLock = CreateConVar("zcs-l4d2_notify_lock", "1", "Enable/Disable Lock Notifications", FCVAR_NOTIFY);
	g_hCooldownEnable = CreateConVar("zcs-l4d2_cooldown_enable", "0", "Enable/Disable Cooldown", FCVAR_NOTIFY);
	g_hCooldownSmoker = CreateConVar("zcs-l4d2_cooldown_smoker", "-1", "Time before smoker class is allowed after player death in (s). (-1=Use Director, 0=No delay, 1-60=Delay)", FCVAR_NOTIFY, true, -1.0, true, 60.0);
	g_hCooldownBoomer = CreateConVar("zcs-l4d2_cooldown_boomer", "-1", "Time before boomer class is allowed after player death in (s). (-1=Use Director, 0=No delay, 1-60=Delay)", FCVAR_NOTIFY, true, -1.0, true, 60.0);
	g_hCooldownHunter = CreateConVar("zcs-l4d2_cooldown_hunter", "-1", "Time before hunter class is allowed after player death in (s). (-1=Use Director, 0=No delay, 1-60=Delay)", FCVAR_NOTIFY, true, -1.0, true, 60.0);
	g_hCooldownSpitter = CreateConVar("zcs-l4d2_cooldown_spitter", "-1", "Time before spitter class is allowed after player death in (s). (-1=Use Director, 0=No delay, 1-60=Delay)", FCVAR_NOTIFY, true, -1.0, true, 60.0);
	g_hCooldownJockey = CreateConVar("zcs-l4d2_cooldown_jockey", "-1", "Time before jockey class is allowed after player death in (s). (-1=Use Director, 0=No delay, 1-60=Delay)", FCVAR_NOTIFY, true, -1.0, true, 60.0);
	g_hCooldownCharger = CreateConVar("zcs-l4d2_cooldown_charger", "-1", "Time before charger class is allowed after player death in (s). (-1=Use Director, 0=No delay, 1-60=Delay)", FCVAR_NOTIFY, true, -1.0, true, 60.0);
	g_hLockDelay = CreateConVar("zcs-l4d2_lock_delay", "0", "Time Before Locking Class Selections", FCVAR_NOTIFY, true, 0.0, true, 600.0);
	g_hSmokerLimit = CreateConVar("zcs-l4d2_smoker_limit", "2", "Number Of Smokers Limited", FCVAR_NOTIFY, true, -1.0, true, 10.0);
	g_hBoomerLimit = CreateConVar("zcs-l4d2_boomer_limit", "2", "Number Of Boomers Limited", FCVAR_NOTIFY, true, -1.0, true, 10.0);
	g_hHunterLimit = CreateConVar("zcs-l4d2_hunter_limit", "3", "Number Of Hunters Limited", FCVAR_NOTIFY, true, -1.0, true, 10.0);
	g_hSpitterLimit = CreateConVar("zcs-l4d2_spitter_limit", "2", "Number Of Spitters Limited", FCVAR_NOTIFY, true, -1.0, true, 10.0);
	g_hJockeyLimit = CreateConVar("zcs-l4d2_jockey_limit", "2", "Number Of Jockeys Limited", FCVAR_NOTIFY, true, -1.0, true, 10.0);
	g_hChargerLimit = CreateConVar("zcs-l4d2_charger_limit", "2", "Number Of Chargers Limited", FCVAR_NOTIFY, true, -1.0, true, 10.0);
	
	HookConVarChange(g_hEnable, Sub_ConVarsChanged);
	HookConVarChange(g_hEnableVIB, Sub_ConVarsChanged);
	HookConVarChange(g_hRespectLimits, Sub_ConVarsChanged);
	HookConVarChange(g_hShowHudPanel, Sub_ConVarsChanged);
	HookConVarChange(g_hCountFakeBots, Sub_ConVarsChanged);
	HookConVarChange(g_hAllowFinaleSwitch, Sub_ConVarsChanged);
	HookConVarChange(g_hAllowLastClass, Sub_ConVarsChanged);
	HookConVarChange(g_hAllowLastOnLimit, Sub_ConVarsChanged);
	HookConVarChange(g_hAllowClassSwitch, Sub_ConVarsChanged);
	HookConVarChange(g_hAllowCullSwitch, Sub_ConVarsChanged);
	HookConVarChange(g_hAllowSpawnSwitch, Sub_ConVarsChanged);
	HookConVarChange(g_hAccessLevel, Sub_ConVarsChanged);
	HookConVarChange(g_hSelectKey, Sub_ConVarsChanged);
	HookConVarChange(g_hSelectDelay, Sub_ConVarsChanged);
	HookConVarChange(g_hNotifyKey, Sub_ConVarsChanged);
	HookConVarChange(g_hNotifyKeyVerbose, Sub_ConVarsChanged);
	HookConVarChange(g_hNotifyClass, Sub_ConVarsChanged);
	HookConVarChange(g_hNotifyLock, Sub_ConVarsChanged);
	HookConVarChange(g_hCooldownEnable, Sub_ConVarsChanged);
	HookConVarChange(g_hCooldownSmoker, Sub_ConVarsChanged);
	HookConVarChange(g_hCooldownBoomer, Sub_ConVarsChanged);
	HookConVarChange(g_hCooldownHunter, Sub_ConVarsChanged);
	HookConVarChange(g_hCooldownSpitter, Sub_ConVarsChanged);
	HookConVarChange(g_hCooldownJockey, Sub_ConVarsChanged);
	HookConVarChange(g_hCooldownCharger, Sub_ConVarsChanged);
	HookConVarChange(g_hLockDelay, Sub_ConVarsChanged);
	HookConVarChange(g_hSmokerLimit, Sub_ConVarsChanged);
	HookConVarChange(g_hBoomerLimit, Sub_ConVarsChanged);
	HookConVarChange(g_hHunterLimit, Sub_ConVarsChanged);
	HookConVarChange(g_hSpitterLimit, Sub_ConVarsChanged);
	HookConVarChange(g_hJockeyLimit, Sub_ConVarsChanged);
	HookConVarChange(g_hChargerLimit, Sub_ConVarsChanged);
	
	HookConVarChange(FindConVar(CVAR_Z_VS_SMOKER_LIMIT), Sub_ConVarsChanged);
	HookConVarChange(FindConVar(CVAR_Z_VS_BOOMER_LIMIT), Sub_ConVarsChanged);
	HookConVarChange(FindConVar(CVAR_Z_VS_HUNTER_LIMIT), Sub_ConVarsChanged);
	HookConVarChange(FindConVar(CVAR_Z_VS_SPITTER_LIMIT), Sub_ConVarsChanged);
	HookConVarChange(FindConVar(CVAR_Z_VS_JOCKEY_LIMIT), Sub_ConVarsChanged);
	HookConVarChange(FindConVar(CVAR_Z_VS_CHARGER_LIMIT), Sub_ConVarsChanged);
	
	AutoExecConfig(true, PLUGIN_FILENAME);
	
	Sub_ReloadConVars();
	Sub_CheckEventHooks();
}

public OnMapStart()
{
	Sub_ReloadConVars();
	Sub_ReloadLimits();
}

public OnClientDisconnect(Client)
{
	if (IsFakeClient(Client))
	{
		return;
	}
	
	Sub_ClearClassLock(Client);
	Sub_ClearSpawnGhostTimer(Client);
	
	g_bHasMaterialised[Client] = false;
	g_bHasSpawned[Client] = false;
	g_bUserFlagsCheck[Client] = false;
}

public OnClientPutInServer(Client)
{
	if (IsFakeClient(Client))
	{
		return;
	}
	
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

public Action:OnRoundStart(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bRoundStart)
	{
		return Plugin_Continue;
	}
	
	g_bRoundStart = true;
	g_bRoundEnd = false;
	g_bSwitchDisabled = false;
	g_bLeftSafeRoom = false;
	
	Sub_InitArrays();
	
	if (g_bShowHudPanel)
	{
		CreateTimer(float(PLAYER_HUD_DELAY), Timer_ShowHud, _, TIMER_REPEAT);
	}
	
	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bRoundEnd)
	{
		return Plugin_Continue;
	}
	
	g_bRoundStart = false;
	g_bRoundEnd = true;
	g_bSwitchDisabled = true;
	g_bLeftSafeRoom = false;
	
	return Plugin_Continue;
}

public Action:OnFinaleStart(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (!g_bAllowFinaleSwitch)
	{
		g_bSwitchDisabled = true;
	}
	else
	{
		g_bSwitchDisabled = false;
	}
}

public Action:OnPlayerTeam(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (Client == 0 || !IsClientInGame(Client))
	{
		return Plugin_Continue;
	}
	
	new NewTeam = GetEventInt(hEvent, "team");
	new OldTeam = GetEventInt(hEvent, "oldteam");
	
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

public Action:OnPlayerSpawn(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (Client == 0 || !IsClientInGame(Client) || IsFakeClient(Client) || GetClientTeam(Client) != TEAM_INFECTED)
	{
		return Plugin_Continue;
	}
	
	if (!g_bHasSpawned[Client])
	{
		Sub_ClearSpawnGhostTimer(Client);
	}
	
	if (g_bLeftSafeRoom)
	{
		Sub_ClearClassLock(Client);
		
		if (!g_bAllowSpawnSwitch)
		{
			g_bHasMaterialised[Client] = true;
		}
		else
		{
			g_bHasMaterialised[Client] = false;
		}
	}
	
	g_bHasSpawned[Client] = true;
	
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (g_bRoundEnd || Client == 0 || !IsClientInGame(Client) || IsFakeClient(Client) || GetClientTeam(Client) != TEAM_INFECTED)
	{
		return Plugin_Continue;
	}
	
	if (g_bCooldownEnable && g_bRespectLimits)
	{
		if (!Sub_IsPlayerGhost(Client))
		{
			new ZClass = GetEntProp(Client, Prop_Send, "m_zombieClass");
			
			if ((ZClass >= ZC_SMOKER) && (ZClass <= ZC_CHARGER))
			{
				if (g_iAllowClass[ZClass] != 0 && g_hAllowClassTimer[ZClass] == INVALID_HANDLE)
				{
					if (g_fClassDelay[ZClass] == -1 || g_fClassDelay[ZClass] > 0)
					{
						g_iAllowClass[ZClass] = 0;
					}
					else
					{
						g_iAllowClass[ZClass] = 1;
					}
				}
			}
		}
	}
	
	if (Sub_IsPlayerGhost(Client))
	{
		Sub_ClearClassLock(Client);
	}
	
	g_bHasMaterialised[Client] = false;
	g_bHasSpawned[Client] = false;
	
	return Plugin_Continue;
}

public Action:OnGhostSpawnTime(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (g_bRoundEnd || Client == 0 || !IsClientInGame(Client) || IsFakeClient(Client))
	{
		return Plugin_Continue;
	}
	
	if (IsPlayerAlive(Client))
	{
		return Plugin_Continue;
	}
	
	Sub_ClearClassLock(Client);
	new Float:SpawnTime = GetEventFloat(hEvent, "spawntime");
	
	if (g_hSpawnGhostTimer[Client] == INVALID_HANDLE)
	{
		g_hSpawnGhostTimer[Client] = CreateTimer(SpawnTime - ZC_TIMEROFFSET, Timer_SpawnGhostClass, Client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (g_bCooldownEnable && g_bRespectLimits)
	{
		new ZClass = GetEntProp(Client, Prop_Send, "m_zombieClass");
		
		if ((ZClass >= ZC_SMOKER) && (ZClass <= ZC_CHARGER))
		{
			if (g_iAllowClass[ZClass] != 1 && g_hAllowClassTimer[ZClass] == INVALID_HANDLE)
			{
				if (g_fClassDelay[ZClass] > 0)
				{
					SpawnTime = g_fClassDelay[ZClass];
				}
				
				g_iHudCooldown[ZClass] = 1;
				g_hAllowClassTimer[ZClass] = CreateTimer(SpawnTime, Timer_ReleaseClass, ZClass, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	
	g_bHasMaterialised[Client] = false;
	g_bHasSpawned[Client] = false;
	
	return Plugin_Continue;
}

public Action:OnPlayerLeftStartArea(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bLeftSafeRoom || g_bRoundEnd)
	{
		return Plugin_Continue;
	}
	
	g_bLeftSafeRoom = true;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			Sub_CheckClassLock(i);
		}
	}
	
	return Plugin_Continue;
}

public Action:OnDoorOpen(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bLeftSafeRoom || g_bRoundEnd)
	{
		return Plugin_Continue;
	}
	
	if (!GetEventBool(hEvent, "checkpoint"))
	{
		return Plugin_Continue;
	}
	
	g_bLeftSafeRoom = true;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			Sub_CheckClassLock(i);
		}
	}
	
	return Plugin_Continue;
}

public Action:OnTankFrustrated(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bRoundEnd)
	{
		return Plugin_Continue;
	}
	
	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	g_bHasMaterialised[Client] = false;
	g_bHasSpawned[Client] = false;
	g_hSpawnGhostTimer[Client] = CreateTimer(ZC_TIMERAFTERTANK, Timer_SpawnGhostClass, Client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(Client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!g_bEnable || Client == 0 || !IsClientInGame(Client) || IsFakeClient(Client))
	{
		return Plugin_Continue;
	}
	
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
					
					if (!g_bUserFlagsCheck[Client])
					{
						Sub_DetermineClass(Client, GetEntProp(Client, Prop_Send, "m_zombieClass"));
					}
					
					CreateTimer(g_fSelectDelay, Timer_DelayChange, Client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			else
			{
				g_bIsHoldingMelee[Client] = false;
			}
		}
	}
	
	if (buttons & IN_ATTACK && Sub_IsPlayerGhost(Client))
	{
		CreateTimer(1.0, Timer_SelectDelay, Client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action:Timer_SelectDelay(Handle:hTimer, any:Client)
{
	if (!IsClientInGame(Client) || IsFakeClient(Client))
	{
		return Plugin_Continue;
	}
	
	if (!Sub_IsPlayerGhost(Client))
	{
		g_iLastClass[Client] = GetEntProp(Client, Prop_Send, "m_zombieClass");
		g_iSLastClass[Client] = g_iLastClass[Client];
	}
	
	return Plugin_Continue;
}

public Action:Timer_NotifyKey(Handle:hTimer, any:Client)
{
	if (IsClientInGame(Client) && !IsFakeClient(Client) && GetClientTeam(Client) == TEAM_INFECTED)
	{
		if (g_bNotifyKey && !g_bUserFlagsCheck[Client])
		{
			PrintToChat(Client, PLAYER_NOTIFY_KEY, PLAYER_KEYS(g_iSelectKey));
		}
	}
}

public Action:Timer_NotifyLock(Handle:hTimer, any:Client)
{
	if (IsClientInGame(Client) && !IsFakeClient(Client) && GetClientTeam(Client) == TEAM_INFECTED)
	{
		if (g_bNotifyLock && !g_bUserFlagsCheck[Client])
		{
			PrintToChat(Client, PLAYER_NOTIFY_LOCK, g_fLockDelay);
		}
	}
}

public Action:Timer_DelayChange(Handle:hTimer, any:Client)
{
	g_bIsChanging[Client] = false;
}

public Action:Timer_CheckPlayerGhostDelayed(Handle:hTimer, any:Client)
{
	if (Client > 0 && IsClientInGame(Client) && IsFakeClient(Client) && Sub_IsPlayerGhost(Client))
	{
		Sub_CheckClassLock(Client);
		Sub_DetermineClass(Client, GetEntProp(Client, Prop_Send, "m_zombieClass"));
		
		if (g_bNotifyKey)
		{
			CreateTimer(PLAYER_KEY_DELAY, Timer_NotifyKey, Client, TIMER_FLAG_NO_MAPCHANGE);
			g_iNotifyKeyVerbose[Client] = 1;
		}
	}
}

public Action:Timer_ReleaseClass(Handle:hTimer, any:ZClass)
{
	if (g_iAllowClass[ZClass] != 1)
	{
		g_iAllowClass[ZClass] = 1;
		g_iHudCooldown[ZClass] = 0;
		g_hAllowClassTimer[ZClass] = INVALID_HANDLE;
	}
}

public Action:Timer_SpawnGhostClass(Handle:hTimer, any:Client)
{
	g_hSpawnGhostTimer[Client] = INVALID_HANDLE;
	
	if (g_bRoundEnd || Client == 0 || !IsClientInGame(Client) || IsFakeClient(Client) || GetClientTeam(Client) != TEAM_INFECTED)
	{
		return Plugin_Continue;
	}
	
	if (!IsPlayerAlive(Client))
	{
		CreateTimer(ZC_TIMERDEATHCHECK, Timer_SpawnGhostClass, Client, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}
	
	if (!Sub_IsPlayerGhost(Client))
	{
		return Plugin_Continue;
	}
	
	Sub_CheckClassLock(Client);
	
	new ZClass = GetEntProp(Client, Prop_Send, "m_zombieClass");
	
	if (!g_bRespectLimits)
	{
		if (ZClass == g_iLastClass[Client])
		{
			Sub_DetermineClass(Client, ZClass);
		}
	}
	else
	{
		Sub_DetermineClass(Client, ZClass);
	}
	
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
	
	return Plugin_Continue;
}

public Action:Timer_SwitchLock(Handle:hTimer, any:Client)
{
	if (Client == 0 || !IsClientInGame(Client) || IsFakeClient(Client) || GetClientTeam(Client) != TEAM_INFECTED)
	{
		return Plugin_Continue;
	}
	
	if (g_fLockDelay > 0 && g_bLeftSafeRoom && !Sub_IsTank(Client) && g_bAllowClassSwitch)
	{
		if (Sub_IsPlayerGhost(Client))
		{
			if (g_bNotifyLock)
			{
				PrintToChat(Client, PLAYER_SWITCH_LOCK, g_fLockDelay);
			}
			
			g_bSwitchLock[Client] = true;
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_ShowHud(Handle:hTimer)
{
	if (g_bRoundEnd)
	{
		return Plugin_Stop;
	}
	
	Hud_ShowLimits();
	
	return Plugin_Continue;
}

public Sub_ClearSpawnGhostTimer(any:Client)
{
	if (g_hSpawnGhostTimer[Client] != INVALID_HANDLE)
	{
		CloseHandle(g_hSpawnGhostTimer[Client]);
		g_hSpawnGhostTimer[Client] = INVALID_HANDLE;
	}
}

public Sub_ClearClassLock(any:Client)
{
	if (g_fLockDelay > 0 && g_bLeftSafeRoom)
	{
		if (g_hLockTimer[Client] != INVALID_HANDLE)
		{
			if (!g_bSwitchLock[Client] && !IsFakeClient(Client))
			{
				CloseHandle(g_hLockTimer[Client]);
			}
			
			g_hLockTimer[Client] = INVALID_HANDLE;
			g_bSwitchLock[Client] = false;
		}
	}
}

public Sub_CheckClassLock(any:Client)
{
	if (g_fLockDelay > 0 && g_bLeftSafeRoom && !Sub_IsTank(Client) && IsPlayerAlive(Client) && g_bAllowClassSwitch)
	{
		if (g_hLockTimer[Client] == INVALID_HANDLE)
		{
			CreateTimer(PLAYER_LOCK_DELAY, Timer_NotifyLock, Client, TIMER_FLAG_NO_MAPCHANGE);
			g_hLockTimer[Client] = CreateTimer(g_fLockDelay, Timer_SwitchLock, Client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Sub_InitArrays()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		g_iNextClass[i] = 0;
		g_iLastClass[i] = 0;
		g_iSLastClass[i] = 0;
		g_bSwitchLock[i] = false;
		g_bIsHoldingMelee[i] = false;
		g_bIsChanging[i] = false;
		g_bHasMaterialised[i] = false;
		g_bHasSpawned[i] = false;
		g_hLockTimer[i] = INVALID_HANDLE;
		g_hSpawnGhostTimer[i] = INVALID_HANDLE;
		g_iNotifyKeyVerbose[i] = 0;
	}
	
	if (g_bCooldownEnable)
	{
		for (new i = 1; i <= ZC_TOTAL; i++)
		{
			g_hAllowClassTimer[i] = INVALID_HANDLE;
			g_iAllowClass[i] = 1;
			g_iHudCooldown[i] = 0;
		}
	}
}

public Sub_CheckEventHooks()
{
	if (g_bEnable)
	{
		if (!g_bHookedEvents)
		{
			HookEvent("round_start", OnRoundStart);
			HookEvent("round_end", OnRoundEnd);
			HookEvent("mission_lost", OnRoundEnd);
			HookEvent("finale_win", OnRoundEnd);
			HookEvent("finale_start", OnFinaleStart);
			HookEvent("player_team", OnPlayerTeam);
			HookEvent("ghost_spawn_time", OnGhostSpawnTime);
			HookEvent("player_left_start_area", OnPlayerLeftStartArea);
			HookEvent("player_death", OnPlayerDeath);
			HookEvent("player_spawn", OnPlayerSpawn);
			HookEvent("door_open", OnDoorOpen);
			HookEvent("tank_frustrated", OnTankFrustrated);
			
			g_bHookedEvents = true;
		}
	}
	else if (!g_bEnable)
	{
		if (g_bHookedEvents)
		{
			UnhookEvent("round_start", OnRoundStart);
			UnhookEvent("round_end", OnRoundEnd);
			UnhookEvent("mission_lost", OnRoundEnd);
			UnhookEvent("finale_win", OnRoundEnd);
			UnhookEvent("finale_start", OnFinaleStart);
			UnhookEvent("player_team", OnPlayerTeam);
			UnhookEvent("ghost_spawn_time", OnGhostSpawnTime);
			UnhookEvent("player_left_start_area", OnPlayerLeftStartArea);
			UnhookEvent("player_death", OnPlayerDeath);
			UnhookEvent("player_spawn", OnPlayerSpawn);
			UnhookEvent("door_open", OnDoorOpen);
			UnhookEvent("tank_frustrated", OnTankFrustrated);
			
			g_bHookedEvents = false;
		}
	}
}

public Sub_ReloadConVars()
{
	g_bEnable = GetConVarBool(g_hEnable);
	g_bRespectLimits = GetConVarBool(g_hRespectLimits);
	g_bShowHudPanel = GetConVarBool(g_hShowHudPanel);
	g_bCountFakeBots = GetConVarBool(g_hCountFakeBots);
	g_bAllowFinaleSwitch = GetConVarBool(g_hAllowFinaleSwitch);
	g_bAllowLastClass = GetConVarBool(g_hAllowLastClass);
	g_bAllowLastOnLimit = GetConVarBool(g_hAllowLastOnLimit);
	g_bAllowClassSwitch = GetConVarBool(g_hAllowClassSwitch);
	g_bAllowCullSwitch = GetConVarBool(g_hAllowCullSwitch);
	g_bAllowSpawnSwitch = GetConVarBool(g_hAllowSpawnSwitch);
	GetConVarString(g_hAccessLevel, g_sAccessLevel, sizeof(g_sAccessLevel));
	g_iSelectKey = GetConVarInt(g_hSelectKey);
	g_bNotifyKey = GetConVarBool(g_hNotifyKey);
	g_bNotifyKeyVerbose = GetConVarBool(g_hNotifyKeyVerbose);
	g_bNotifyClass = GetConVarBool(g_hNotifyClass);
	g_bNotifyLock = GetConVarBool(g_hNotifyLock);
	g_fSelectDelay = GetConVarFloat(g_hSelectDelay);
	g_bCooldownEnable = GetConVarBool(g_hCooldownEnable);
	g_fCooldownSmoker = GetConVarFloat(g_hCooldownSmoker);
	g_fCooldownBoomer = GetConVarFloat(g_hCooldownBoomer);
	g_fCooldownHunter = GetConVarFloat(g_hCooldownHunter);
	g_fCooldownSpitter = GetConVarFloat(g_hCooldownSpitter);
	g_fCooldownJockey = GetConVarFloat(g_hCooldownJockey);
	g_fCooldownCharger = GetConVarFloat(g_hCooldownCharger);
	g_fLockDelay = GetConVarFloat(g_hLockDelay);
	g_iSmokerLimit = GetConVarInt(g_hSmokerLimit);
	g_iBoomerLimit = GetConVarInt(g_hBoomerLimit);
	g_iHunterLimit = GetConVarInt(g_hHunterLimit);
	g_iSpitterLimit = GetConVarInt(g_hSpitterLimit);
	g_iJockeyLimit = GetConVarInt(g_hJockeyLimit);
	g_iChargerLimit = GetConVarInt(g_hChargerLimit);
	
	if (GetConVarBool(g_hEnableVIB))
	{
		SetConVarInt(FindConVar(CVAR_DIRECTOR_ALLOW_IB), 1);
	}
	else
	{
		SetConVarInt(FindConVar(CVAR_DIRECTOR_ALLOW_IB), 0);
	}
}

public Sub_ReloadLimits()
{
	for (new i = 1; i <= ZC_TOTAL; i++)
	{
		g_iZVLimits[i] = 0;
		g_fClassDelay[i] = 0.0;
	}
	
	g_iZVLimits[ZC_SMOKER] = g_iSmokerLimit != -1 ? g_iSmokerLimit : GetConVarInt(FindConVar(CVAR_Z_VS_SMOKER_LIMIT));
	g_iZVLimits[ZC_BOOMER] = g_iBoomerLimit != -1 ? g_iBoomerLimit : GetConVarInt(FindConVar(CVAR_Z_VS_BOOMER_LIMIT));
	g_iZVLimits[ZC_HUNTER] = g_iHunterLimit != -1 ? g_iHunterLimit : GetConVarInt(FindConVar(CVAR_Z_VS_HUNTER_LIMIT));
	g_iZVLimits[ZC_SPITTER] = g_iSpitterLimit != -1 ? g_iSpitterLimit : GetConVarInt(FindConVar(CVAR_Z_VS_SPITTER_LIMIT));
	g_iZVLimits[ZC_JOCKEY] = g_iJockeyLimit != -1 ? g_iJockeyLimit : GetConVarInt(FindConVar(CVAR_Z_VS_JOCKEY_LIMIT));
	g_iZVLimits[ZC_CHARGER] = g_iChargerLimit != -1 ? g_iChargerLimit : GetConVarInt(FindConVar(CVAR_Z_VS_CHARGER_LIMIT));
	
	for (new i = ZC_SMOKER; i <= ZC_CHARGER; i++)
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

public Sub_HookGameData(String:GameDataFile[])
{
	g_hGameConf = LoadGameConfigFile(GameDataFile);
	if (g_hGameConf == INVALID_HANDLE)
	{
		SetFailState("[ZCS] Game Data Not Found!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "SetClass");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSetClass = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CreateAbility");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hCreateAbility = EndPrepSDKCall();
	
	g_oAbility = GameConfGetOffset(g_hGameConf, "oAbility");
	
	CloseHandle(g_hGameConf);
}

public Sub_ConVarsChanged(Handle:hConVar, const String:oldValue[], const String:newValue[])
{
	Sub_ReloadConVars();
	Sub_ReloadLimits();
	Sub_CheckEventHooks();
}

public Sub_CountInfectedClass(any:ZClass, bool:GetTotal)
{
	new ClassCount, ClassType;
	
	for (new i = 1; i <= MaxClients; i++)
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
						{
							ClassCount++;
						}
					}
					else
					{
						ClassCount++;
					}
				}
				else
				{
					if (ClassType == ZClass)
					{
						if (!g_bCountFakeBots)
						{
							if (!IsFakeClient(i))
							{
								ClassCount++;
							}
						}
						else
						{
							ClassCount++;
						}
					}
				}
			}
		}
	}
	
	return ClassCount;
}

public bool:Sub_CheckPerClassLimits(any:ZClass)
{
	new ClassCount = Sub_CountInfectedClass(ZClass, false);
	
	if (g_bCooldownEnable && g_bRespectLimits)
	{
		if (g_iAllowClass[ZClass] != 1)
		{
			ClassCount += 1;
		}
	}
	
	if (ClassCount < g_iZVLimits[ZClass])
	{
		return true;
	}
	
	return false;
}

public bool:Sub_CheckAllClassLimits(any:ZClass)
{
	for (new i = ZC_SMOKER; i <= ZC_CHARGER; i++)
	{
		new ClassCount = Sub_CountInfectedClass(i, false);
		
		if (g_bCooldownEnable && g_bRespectLimits)
		{
			if (g_iAllowClass[i] != 1)
			{
				ClassCount += 1;
			}
		}
		
		if (ZClass == 0)
		{
	        if (ClassCount < g_iZVLimits[i])
            {
				return true;
			}
		}
		else
		{
			if (ClassCount < g_iZVLimits[i] && ZClass != i)
			{
				return true;
			}
		}
	}
	
	return false;
}

public bool:Sub_IsTank(any:Client)
{
	new ZClass = GetEntProp(Client, Prop_Send, "m_zombieClass");
	
	if (IsPlayerAlive(Client) && ZClass == ZC_TANK)
	{
		return true;
	}
	
	return false;
}

public Sub_DetermineClass(any:Client, any:ZClass)
{
	if (ZClass > ZC_CHARGER)
	{
		return;
	}
	
	g_iNextClass[Client] = (ZClass >= ZC_SMOKER && ZClass < ZC_CHARGER) ? ZClass + 1 : ZC_SMOKER;
	
	if (g_bRespectLimits)
	{
		do
		{
			if (Sub_IsTank(Client))
			{
				return;
			}
			
			new ZTotal = Sub_CountInfectedClass(0, true);
			
			if (!Sub_CheckAllClassLimits(0))
			{
				if (ZTotal < g_iZVLimits[ZC_TOTAL])
				{
					if (g_bNotifyClass)
					{
						PrintToChat(Client, PLAYER_COOLDOWN_WAIT, TEAM_CLASS(g_iLastClass[Client]), ZTotal, g_iZVLimits[ZC_TOTAL]);
					}
				}
				else
				{
					if (g_bNotifyClass)
					{
						PrintToChat(Client, PLAYER_LIMITS_UP, ZTotal, g_iZVLimits[ZC_TOTAL]);
					}
				}
				
				return;
			}
			
			for (new i = ZC_SMOKER; i <= ZC_CHARGER; i++)
			{
				if (g_iNextClass[Client] == i)
				{
					if (!Sub_CheckPerClassLimits(i))
					{
						g_iNextClass[Client] = (i >= ZC_SMOKER && i < ZC_CHARGER) ? i + 1 : ZC_SMOKER;
					}
				}
				
				if (!g_bAllowLastClass)
				{
					if (Sub_CheckLastClass(Client, g_iNextClass[Client]) != 0)
					{
						return;
					}
				}
			}
		}
		while (!Sub_CheckPerClassLimits(g_iNextClass[Client]));
	}
	
	if (ZClass == g_iNextClass[Client])
	{
		if (g_bNotifyClass)
		{
			PrintToChat(Client, PLAYER_CLASSES_UP_DENY);
		}
		
		return;
	}
	
	if (Client > 0 && IsClientInGame(Client) && !IsFakeClient(Client) && Sub_IsPlayerGhost(Client))
	{
		new WeaponIndex;
		while ((WeaponIndex = GetPlayerWeaponSlot(Client, 0)) != -1)
		{
			RemovePlayerItem(Client, WeaponIndex);
			RemoveEdict(WeaponIndex);
		}
		
		SDKCall(g_hSetClass, Client, g_iNextClass[Client]);
		AcceptEntityInput(MakeCompatEntRef(GetEntProp(Client, Prop_Send, "m_customAbility")), "Kill");
		SetEntProp(Client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hCreateAbility, Client), g_oAbility));
	}
	
	return;
}

public Sub_CheckLastClass(any:Client, any:ZClass)
{
	g_iLastClass[Client] = g_iSLastClass[Client];
	
	if (g_iLastClass[Client] == ZClass)
	{
		if (!Sub_CheckAllClassLimits(g_iLastClass[Client]))
		{
			if (g_bAllowLastOnLimit)
			{
				if (g_bNotifyClass)
				{
					PrintToChat(Client, PLAYER_CLASSES_UP_ALLOW);
				}
				
				g_iSLastClass[Client] = g_iLastClass[Client];
				g_iLastClass[Client] = 0;

				return 0;
			}
			else
			{
				if (g_bNotifyClass)
				{
					PrintToChat(Client, PLAYER_CLASSES_UP_DENY);
				}
				
				return 1;
			}
		}
		else
		{
			g_iNextClass[Client] = (ZClass >= ZC_SMOKER && ZClass < ZC_CHARGER) ? ZClass + 1 : ZC_SMOKER;
		}
	}
	
	return 0;
}

public Sub_IsPlayerGhost(any:Client)
{
	if (GetEntProp(Client, Prop_Send, "m_isGhost"))
	{
		return true;
	}
	else
	{
		return false;
	}
}

public Sub_IsPlayerCulling(any:Client)
{
	if (g_bAllowCullSwitch)
	{
		return false;
	}
	
	if (GetEntProp(Client, Prop_Send, "m_isCulling"))
	{
		return true;
	}
	else
	{
		return false;
	}
}

public Sub_CheckGameName(String:GameInput[])
{
	decl String:GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	
	if (!StrEqual(GameName, GameInput, false))
	{
		return false;
	}
	
	return true;
}

public Hud_ShowLimits()
{
	if (!g_bShowHudPanel || !g_bEnable)
	{
		return;
	}
	
	new Handle:hPanel = CreatePanel();
	decl String:sPanelBuff[1024];
	decl String:sCooldownSymbol[8] = "";
	
	Format(sPanelBuff, sizeof(sPanelBuff), "Infected Limits");
	DrawPanelText(hPanel, sPanelBuff);
	DrawPanelText(hPanel, " ");
	
	for (new i = ZC_SMOKER; i <= ZC_CHARGER; i++)
	{
		sCooldownSymbol = g_iHudCooldown[i] == 1 ? "(C)" : "   ";
		Format(sPanelBuff, sizeof(sPanelBuff), "->%d. (%d/%d) %s %s", i, Sub_CountInfectedClass(i, false), g_iZVLimits[i], TEAM_CLASS(i), sCooldownSymbol);
		DrawPanelText(hPanel, sPanelBuff);
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
		{
			if (GetClientTeam(i) == TEAM_INFECTED && Sub_IsPlayerGhost(i))
			{
				if ((GetClientMenu(i) == MenuSource_RawPanel) || (GetClientMenu(i) == MenuSource_None))
                {
					SendPanelToClient(hPanel, i, Hud_LimitsPanel, PLAYER_HUD_DELAY);
				}
			}
		}
	}

	CloseHandle(hPanel);
}

public Hud_LimitsPanel(Handle:hMenu, MenuAction:action, param1, param2)
{
	return;
}

