/**
 * HLstatsX Community Edition - SourceMod plugin to generate advanced weapon logging
 * http://www.hlxcommunity.com
 * Copyright (C) 2009 Nicholas Hastings (psychonic)
 * Copyright (C) 2007-2008 TTS Oetzel & Goerz GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#pragma semicolon 1
 
#define REQUIRE_EXTENSIONS
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define VERSION "1.4.6"

// update fields with //u when adding weapons

#define TF2
#define UNLOCKABLE_OFFSET 12
#define MAX_WEAPON_LEN 26
#define PREFIX_LEN 10
#define SHOOT 1
#define HIT 2

#define MAX_LOG_WEAPONS 21
#define HASUNLOCKABLE_IDX_START 5
#define HASUNLOCKABLE_IDX_END 8
#define SHOOTAUXCOUNT 5
#define HITAUXCOUNT 2
#define BULLET_WEAPONS 1048288

#define DISPENSER 0
#define SENTRY 3
#define TELEENT 1
#define TELEEXIT 2

#define WEAPONID_MEDICSAW 11
#define WEAPONID_ROCKET 22
#define WEAPONID_DIRECTHIT 64

new Handle:g_cvar_actions = INVALID_HANDLE;
new Handle:g_cvar_teleports = INVALID_HANDLE;
new Handle:g_cvar_headshots = INVALID_HANDLE;
new Handle:g_cvar_backstabs = INVALID_HANDLE;
new Handle:g_cvar_sandvich = INVALID_HANDLE;
new Handle:g_cvar_fire = INVALID_HANDLE;
new Handle:g_cvar_wstats = INVALID_HANDLE;
new Handle:g_cvar_heals = INVALID_HANDLE;
new Handle:g_cvar_weaponcrits = INVALID_HANDLE;
new Handle:g_cvar_rolelogfix = INVALID_HANDLE;
new Handle:g_cvar_objlogfix = INVALID_HANDLE;

new bool:g_logactions = true;
new bool:g_logteleports = true;
new bool:g_logheadshots = false;
new bool:g_logbackstabs = true;
new bool:g_logsandvich = false;
new bool:g_logfire = true;
new bool:g_logwstats = true;
new bool:g_logheals = true;
new bool:g_crits = true;
new bool:g_wstatsnet = true;
new bool:g_rolelogfix = true;
new bool:g_objlogfix = true;

new bool:g_sdkhooksavailable;

new g_weapon_stats[MAXPLAYERS+1][MAX_LOG_WEAPONS][7];
new const String:g_weapon_list[MAX_LOG_WEAPONS][MAX_WEAPON_LEN] = {
	"flaregun",
	"tf_projectile_arrow",
	"tf_projectile_rocket",
	"tf_projectile_pipe",
	"tf_projectile_pipe_remote",
	"revolver",
	"minigun",
	"scattergun",
	"syringegun_medic",
	"smg",
	"pistol_scout",
	"shotgun_pyro",
	"shotgun_hwg",
	"shotgun_soldier",
	"shotgun_primary",
	"pistol",
	"sniperrifle",
	"ambassador",
	"natascha",
	"force_a_nature",
	"blutsauger"
};

new const String:g_weapon_list_shootaux[SHOOTAUXCOUNT][MAX_WEAPON_LEN] = {
	"flaregun",
	"compound_bow",
	"rocketlauncher",
	"grenadelauncher",
	"pipebomblauncher"
};

new const String:g_weapon_list_hitaux[HITAUXCOUNT][MAX_WEAPON_LEN] = {
	"tf_projectile_flare",
	"tf_projectile_arrow_fire"
};

new g_weapon_hashes[MAX_LOG_WEAPONS];
new g_weapon_hashes_shootaux[SHOOTAUXCOUNT];
new g_weapon_hashes_hitaux[HITAUXCOUNT];
new g_nexthurt[MAXPLAYERS+1] = {-1, ...};
new g_iHealPointCache[MAXPLAYERS+1];

new bool:g_ignoreNextLog;
new bool:g_bDestroyObj[MAXPLAYERS+1];
new TFClassType:g_iNextRole[MAXPLAYERS+1];
new TFClassType:g_iCurrentRole[MAXPLAYERS+1];
new g_iBuildingCount[MAXPLAYERS+1][4];
new g_iMaxEntities;
new g_iHealsOff;
new g_iWeaponOff;
new bool:g_bNextKillUbersawTaunt[MAXPLAYERS+1];

#include <loghelper>
#include <wstatshelper>

#undef REQUIRE_EXTENSIONS
#include <sdkhooks>

#if defined _sdkhooks_included
	#define NAME "SuperLogs: TF2"
#else
	#define NAME "SuperLogs: TF2 (No SDKHooks)"
#endif

public Plugin:myinfo = {
	name = NAME,
	author = "psychonic",
	description = "Advanced logging for TF2. Generates auxilary logging for use with log parsers such as HLstatsX and Psychostats",
	version = VERSION,
	url = "http://www.hlxcommunity.com"
};

public OnPluginStart()
{
	CalcInitialHashes();
	
	g_cvar_actions = CreateConVar("superlogs_actions", "1", "Enable logging of most player actions, such as \"stun\" (default on)", 0, true, 0.0, true, 1.0);
	g_cvar_teleports = CreateConVar("superlogs_teleports", "1", "Enable logging of teleports (default on)", 0, true, 0.0, true, 1.0);
	g_cvar_headshots = CreateConVar("superlogs_headshots", "0", "Enable logging of headshot player action (default off)", 0, true, 0.0, true, 1.0);
	g_cvar_backstabs = CreateConVar("superlogs_backstabs", "1", "Enable logging of backstab player action (default on)", 0, true, 0.0, true, 1.0);
	g_cvar_sandvich = CreateConVar("superlogs_sandvich", "0", "Enable logging of sandvich eating (may be resource intensive) (default off)", 0, true, 0.0, true, 1.0);
	g_cvar_fire = CreateConVar("superlogs_fire", "1", "Enable logging of fiery arrows as a separate weapon from regular arrows (default on)", 0, true, 0.0, true, 1.0);
	g_cvar_wstats = CreateConVar("superlogs_wstats", "1", "Enable logging of weapon stats (default on, only works when tf_weapon_criticals is 1)", 0, true, 0.0, true, 1.0);
	g_cvar_heals = CreateConVar("superlogs_heals", "1", "Enable logging of healpoints upon death (default on)", 0, true, 0.0, true, 1.0);
	g_cvar_rolelogfix = CreateConVar("superlogs_rolelogfix", "1", "Enable delay of logging class change until first spwan as new class (default on)", 0, true, 0.0, true, 1.0);
	g_cvar_objlogfix = CreateConVar("superlogs_objlogfix", "1", "Enable logging of owner object destruction on team/class change (default on)", 0, true, 0.0, true, 1.0);
	g_cvar_weaponcrits = FindConVar("tf_weapon_criticals");
	g_crits = GetConVarBool(g_cvar_weaponcrits);
	if (g_crits)
	{
		hook_wstats();
	}
	else
	{
		g_wstatsnet = false;
	}
	
	hook_actions();
	hook_rolefix();
	hook_objfix();
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_teleported", Event_Teleport);
	HookEvent("player_changeclass", Event_ChangeClass, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookConVarChange(g_cvar_actions, OnCvarActionsChange);
	HookConVarChange(g_cvar_headshots, OnCvarHeadshotsChange);
	HookConVarChange(g_cvar_backstabs, OnCvarBackstabsChange);
	HookConVarChange(g_cvar_sandvich, OnCvarSandvichChange);
	HookConVarChange(g_cvar_fire, OnCvarFireChange);
	HookConVarChange(g_cvar_wstats, OnCvarWstatsChange);
	HookConVarChange(g_cvar_heals, OnCvarHealsChange);
	HookConVarChange(g_cvar_weaponcrits, OnCvarWeaponCritsChange);
	HookConVarChange(g_cvar_rolelogfix, OnCvarRoleLogFixChange);
	HookConVarChange(g_cvar_objlogfix, OnCvarObjLogFixChange);
	CreateConVar("superlogs_tf2_version", VERSION, NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	CreateTimer(1.0, LogMap);
	
	GetTeams();
	
	g_iHealsOff = FindSendPropInfo("CTFPlayer", "m_iHealPoints");
	g_iWeaponOff = FindSendPropInfo("CTFPlayer", "m_hActiveWeapon");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientConnected(i))
		{
			g_iHealPointCache[i] = GetEntData(i, g_iHealsOff);
		}
	}
	
	g_iMaxEntities = GetMaxEntities();
}


public OnAllPluginsLoaded()
{
	if (GetExtensionFileStatus("sdkhooks.ext") == 1)
	{
		g_sdkhooksavailable = true;
		
		// hook clients already in game
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamage);
			}
		}		
	}
	else if (g_logwstats && g_crits)
	{
		HookEvent("player_hurt", Event_PlayerHurt);
	}
}

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{
	new String:szGameDesc[64];
	GetGameDescription(szGameDesc, sizeof(szGameDesc), true);
	if (StrContains(szGameDesc, "Team Fortress", false) == -1)
	{
		new String:szGameDir[64];
		GetGameFolderName(szGameDir, sizeof(szGameDir));
		if (StrContains(szGameDir, "tf", false) == -1)
		{
			strcopy(error, err_max, "This plugin is only supported on TF2");
			#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
				return APLRes_Failure;
			#else
				return false;
			#endif
		}
	}
	
	MarkNativeAsOptional("SDKHook");
	
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
	return APLRes_Success;
#else
	return true;
#endif
}

public OnMapStart()
{
	GetTeams();
}


hook_actions()
{
	HookEvent("player_stealsandvich", Event_StealSandvich);
	HookEvent("player_stunned", Event_Stunned);
	HookEvent("teamplay_win_panel", Event_WinPanel);
	HookEvent("arena_win_panel", Event_WinPanel);
	HookEvent("player_escort_score", Event_EscortScore);
	HookEvent("deploy_buff_banner", Event_DeployBuffBanner);
	HookEvent("medic_defended", Event_MedicDefended);
	HookUserMessage(GetUserMessageId("PlayerJarated"), Event_Jarated);
	HookUserMessage(GetUserMessageId("PlayerShieldBlocked"), Event_ShieldBlocked);
}

unhook_actions()
{
	UnhookEvent("player_stealsandvich", Event_StealSandvich);
	UnhookEvent("player_stunned", Event_Stunned);
	UnhookEvent("teamplay_win_panel", Event_WinPanel);
	UnhookEvent("arena_win_panel", Event_WinPanel);
	UnhookEvent("player_escort_score", Event_EscortScore);
	UnhookEvent("deploy_buff_banner", Event_DeployBuffBanner);
	UnhookEvent("medic_defended", Event_MedicDefended);
	UnhookUserMessage(GetUserMessageId("PlayerJarated"), Event_Jarated);
	UnhookUserMessage(GetUserMessageId("PlayerShieldBlocked"), Event_ShieldBlocked);
}

hook_wstats()
{
	HookEvent("teamplay_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
}

unhook_wstats()
{
	UnhookEvent("teamplay_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	UnhookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
}

hook_rolefix()
{
	AddGameLogHook(LogHook);
	g_ignoreNextLog = false;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientConnected(i))
		{
			g_iNextRole[i] = TF2_GetPlayerClass(i);
		}
	}
}

unhook_rolefix()
{
	RemoveGameLogHook(LogHook);
}

hook_objfix()
{
	HookEvent("player_team", Event_ChangeTeam, EventHookMode_Pre);
	for (new i = 1; i <= MaxClients; i++)
	{
		g_bDestroyObj[i] = false;
		if (IsClientInGame(i) && IsClientConnected(i))
		{
			g_iCurrentRole[i] = TF2_GetPlayerClass(i);
		}
	}
}

unhook_objfix()
{
	UnhookEvent("player_team", Event_ChangeTeam, EventHookMode_Pre);
}


public Action:LogHook(const String:message[])
{
	if (g_rolelogfix && g_ignoreNextLog)
	{
		g_ignoreNextLog = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


public OnClientPutInServer(client)
{
	g_bNextKillUbersawTaunt[client] = false;
	if (g_sdkhooksavailable)
	{
		SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamage);
	}
}


public Action:Event_ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:newRole = TFClassType:GetEventInt(event, "class");
	g_iNextRole[client] = newRole;
	new TFClassType:iCurrRole = g_iCurrentRole[client];
	
	if (newRole != iCurrRole)
	{
		g_ignoreNextLog = true;

		if (g_objlogfix && iCurrRole == TFClass_Engineer)
		{
			g_bDestroyObj[client] = true;
			CheckBuildings(client);
		}
	}
	else if (newRole == iCurrRole)
	{
		g_ignoreNextLog = false;

		if (g_objlogfix)
		{
			g_bDestroyObj[client] = false;
			g_iBuildingCount[client][0] = 0;
			g_iBuildingCount[client][1] = 0;
			g_iBuildingCount[client][2] = 0;
			g_iBuildingCount[client][3] = 0;
		}
	}
}

public Action:Event_ChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_iCurrentRole[client] == TFClass_Engineer)
	{
		CheckBuildings(client);
		LogBuildings(client);
	}
}

CheckBuildings(client)
{
	// Check is adapted from Tsunami's code in TF2 Build Restrictions plugin
	if (IsClientInGame(client))
	{
		decl String:sClassName[8];

		for(new i = MaxClients + 1; i < g_iMaxEntities; i++)
		{
			if(IsValidEntity(i))
			{
				GetEntityNetClass(i, sClassName, sizeof(sClassName));
				if (strncmp(sClassName, "CObject", 7) == 0  && GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client)
				{
					new type = GetEntProp(i, Prop_Send, "m_iObjectType");
					if (type < 4)
					{
						g_iBuildingCount[client][type]++;
					}
				}
			}
		}
	}
}

LogBuildings(client)
{
	decl String:owner[96];
	decl String: player_authid[32];
	if (!GetClientAuthString(client, player_authid, sizeof(player_authid)))
	{
		strcopy(player_authid, sizeof(player_authid), "UNKNOWN");
	}
	Format(owner, sizeof(owner), "\"%N<%d><%s><%s>\"", client, GetClientUserId(client), player_authid, g_team_list[GetClientTeam(client)]);
	for (new i = 0; i < 4; i++)
	{
		new objcount = g_iBuildingCount[client][i];
		if (objcount > 0)
		{
			decl String:objname[24];
			switch(i)
			{
				case SENTRY:
					objname = "OBJ_SENTRYGUN";
				case DISPENSER:
					objname = "OBJ_DISPENSER";
				case TELEENT:
					objname = "OBJ_TELEPORTER_ENTRANCE";
				case TELEEXIT:
					objname = "OBJ_TELEPORTER_EXIT";
			}
			for (new j = 0; j < objcount; j++)
			{
				LogToGame("%s triggered \"killedobject\" (object \"%s\") (weapon \"pda_engineer\") (objectowner %s)", owner, objname, owner);
			}
		}
		g_iBuildingCount[client][i] = 0;
	}
}

public Action:TF2_CalcIsAttackCritical(attacker, weapon, String:weaponname[], &bool:result)
{
	if (g_wstatsnet && attacker > 0)
	{
		new weapon_index = get_weapon_index(weaponname[PREFIX_LEN], SHOOT);
		
		if (weapon_index > -1)
		{
			if (weapon_index >= HASUNLOCKABLE_IDX_START && weapon_index <= HASUNLOCKABLE_IDX_END && GetEntProp(weapon, Prop_Send, "m_iEntityQuality") > 0)
			{
				weapon_index += UNLOCKABLE_OFFSET;
			}
			
			g_weapon_stats[attacker][weapon_index][LOG_HIT_SHOTS]++;
			if ((1 << weapon_index) & BULLET_WEAPONS)
			{
				g_nexthurt[attacker] = weapon_index;
			}
		}
	}
}

public OnTakeDamage(victim, attacker, inflictor, Float:damage, damagetype)
{
	if(g_wstatsnet && inflictor > 0)
	{
		new weapon_index = -1;
		new idamage = RoundFloat(damage);
		new weaponent = -1;
		
		// not world
		if (inflictor <= MaxClients)
		{
			if  (damagetype & DMG_BURN)
			{
				return;
			}
			// is a player
			decl String:weapon[MAX_WEAPON_LEN + PREFIX_LEN];
			GetClientWeapon(inflictor, weapon, sizeof(weapon));
			weaponent = GetEntDataEnt2(attacker, g_iWeaponOff);
			weapon_index = get_weapon_index(weapon[PREFIX_LEN]);
		}
		else if (IsValidEdict(inflictor))
		{
			decl String:weapon[MAX_WEAPON_LEN + PREFIX_LEN];
			GetEdictClassname(inflictor, weapon, sizeof(weapon));
			// is a weapon or projectile
			if (weapon[3] == 'p')
			{
				// is projectile
				weapon_index = get_weapon_index(weapon, HIT);
				if (weapon_index == -1)
				{
					return;
				}
				if (strncmp(weapon[14], "pipe", 4) == 0)
				{
					new owner = GetEntPropEnt(inflictor, Prop_Send, "m_hThrower");
					if (owner > -1)
					{
						weaponent = GetEntDataEnt2(owner, g_iWeaponOff);
					}
				}
				else
				{
					new owner = GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity");
					if (owner > -1)
					{
						weaponent = GetEntDataEnt2(owner, g_iWeaponOff);
					}
				}
			}
			else
			{
				// is weapon
				weapon_index = get_weapon_index(weapon[PREFIX_LEN]);
				weaponent = inflictor;
			}
		}
		if (weapon_index > -1)
		{
			if (weaponent > -1 && weapon_index >= HASUNLOCKABLE_IDX_START && weapon_index <= HASUNLOCKABLE_IDX_END && GetEntProp(weaponent, Prop_Send, "m_iEntityQuality") > 0)
			{
				weapon_index += UNLOCKABLE_OFFSET;
			}
			g_weapon_stats[attacker][weapon_index][LOG_HIT_DAMAGE] += idamage;
			g_weapon_stats[attacker][weapon_index][LOG_HIT_HITS]++;
		}
	}
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (!g_sdkhooksavailable)
	{
		if (g_nexthurt[attacker] > -1)
		{
			g_weapon_stats[attacker][g_nexthurt[attacker]][LOG_HIT_HITS]++;
		}
		g_nexthurt[attacker] = -1;
	}
	
	if (g_logactions)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (victim > 0 && victim <= MaxClients && IsClientInGame(victim)
			&& (GetEntityFlags(victim) & FL_ONGROUND) != FL_ONGROUND
			)
		{
			switch (GetEventInt(event, "weaponid"))
			{
				case WEAPONID_ROCKET:
					LogRocketAirshot(attacker);
				case WEAPONID_DIRECTHIT:
					LogRocketAirshot(attacker);
			}
		}
	}
	
	if (GetEventInt(event, "weaponid") == WEAPONID_MEDICSAW
		&& GetEventInt(event, "damageamount") >= 400
		)
	{
		g_bNextKillUbersawTaunt[attacker] = true;
	}
}

LogRocketAirshot(attacker)
{
	LogPlayerEvent(attacker, "triggered", "airshot_rocket");
}

public Action:Event_PlayerDeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new customkill = GetEventInt(event, "customkill");
	
	switch (customkill)
	{
		case 1:
			if (g_logheadshots)
				LogPlyrPlyrEvent(attacker, victim, "triggered", "headshot");
		case 2:
			if (g_logbackstabs)
				LogPlyrPlyrEvent(attacker, victim, "triggered", "backstab");
	}
	
	if (g_bNextKillUbersawTaunt[attacker])
	{
		if (GetEventInt(event, "weaponid") == WEAPONID_MEDICSAW)
		{
			SetEventString(event, "weapon_logclassname", "taunt_medic");
		}
		g_bNextKillUbersawTaunt[attacker] = false;
	}
	
	if (g_logfire && (customkill == 17 || customkill == 18))
	{
		decl String:logweapon[64];
		GetEventString(event, "weapon_logclassname", logweapon, sizeof(logweapon));
		// Don't override reflected arrows
		if (logweapon[0] != 'r')
		{
			SetEventString(event, "weapon_logclassname", "tf_projectile_arrow_fire");
		}
	}
	return Plugin_Continue;
}


public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "userid"		"short"   	// user ID who died				
	// "attacker"	"short"	 	// user ID who killed
	// "weapon"	"string" 	// weapon name killer used 
	// "weaponid"	"short"		// ID of weapon killed used
	// "damagebits"	"long"		// bits of type of damage
	// "customkill"	"short"		// type of custom kill
	// "assister"	"short"		// user ID of assister
	// "weapon_logclassname"	"string" 	// weapon name that should be printed on the log
	// "stun_flags"	"short"	// victim's stun flags at the moment of death
	// "death_flags"	"short" //death flags.
	
	new death_flags = GetEventInt(event, "death_flags");

	if (!(death_flags & 32))
	{
		new custom_kill = GetEventInt(event, "customkill");
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (g_logactions && (attacker == victim) && (custom_kill == 6))
		{
			// psychonic & octo     log forced suicides ("kill" & "explode")
			LogPlayerEvent(victim, "triggered", "force_suicide");
		}
		else if (g_logactions)
		{
			// octo & psychonic     log kills resulting from critical hits, train hits, and drownings
			new bits = GetEventInt(event,"damagebits");
			if (bits & 16384)
			{
				LogPlayerEvent(victim, "triggered", "drowned");
			}
			else if (attacker != victim)
			{
				if ((bits & 1048576) && (attacker > 0) && (custom_kill == 0 || custom_kill > 2))
				{
					LogPlayerEvent(attacker, "triggered", "crit_kill");
				}
				else if (death_flags & 16)
				{
					LogPlayerEvent(attacker, "triggered", "first_blood");
				}
				if (custom_kill == 1
					&& victim > 0 && victim <= MaxClients && IsClientInGame(victim)
					&& (GetEntityFlags(victim) & FL_ONGROUND) != FL_ONGROUND
					)
				{
					LogPlayerEvent(attacker, "triggered", "airshot_headshot");
				}
			}
		}
		if (g_wstatsnet)
		{
			if (victim > 0 && attacker > 0)
			{
				decl String:weaponlogname[MAX_WEAPON_LEN];
				GetEventString(event, "weapon_logclassname", weaponlogname, sizeof(weaponlogname));
				new weapon_index = get_weapon_index(weaponlogname);
				if (weapon_index > -1)
				{
					g_weapon_stats[attacker][weapon_index][LOG_HIT_KILLS]++;
					if (custom_kill == 1)
					{
						g_weapon_stats[attacker][weapon_index][LOG_HIT_HEADSHOTS]++;
					}
					g_weapon_stats[victim][weapon_index][LOG_HIT_DEATHS]++;
					if (GetClientTeam(victim) == GetClientTeam(attacker))
					{
						g_weapon_stats[attacker][weapon_index][LOG_HIT_TEAMKILLS]++;
					}
				}
			}
			dump_player_stats(victim);
		}
		if (g_logheals && victim > 0)
		{
			DumpHeals(victim);
		}
	}
}

public Event_StealSandvich(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "owner"		"short"
	// "target"		"short"
		
	LogPlyrPlyrEvent(GetClientOfUserId(GetEventInt(event, "target")), GetClientOfUserId(GetEventInt(event, "owner")), "triggered", "steal_sandvich", true);
}

public Event_Stunned(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "stunner"	"short"
	// "victim"	"short"
	// "victim_capping"	"bool"
	// "big_stun"	"bool"
		
	LogPlyrPlyrEvent(GetClientOfUserId(GetEventInt(event, "stunner")), GetClientOfUserId(GetEventInt(event, "victim")), "triggered", "stun", true);
}

public Event_WinPanel(Handle:event, const String:name[], bool:dontBroadcast)
{
	LogPlayerEvent(GetEventInt(event, "player_1"), "triggered", "mvp1");
	LogPlayerEvent(GetEventInt(event, "player_2"), "triggered", "mvp2");
	LogPlayerEvent(GetEventInt(event, "player_3"), "triggered", "mvp3");
}

public Event_EscortScore(Handle:event, const String:name[], bool:dontBroadcast)
{
	LogPlayerEvent(GetEventInt(event, "player"), "triggered", "escort_score");
}

public Event_DeployBuffBanner(Handle:event, const String:name[], bool:dontBroadcast)
{
	LogPlayerEvent(GetClientOfUserId(GetEventInt(event, "buff_owner")), "triggered", "buff_deployed");
}
public Event_MedicDefended(Handle:event, const String:name[], bool:dontBroadcast)
{
	LogPlayerEvent(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "defended_medic");
}

public Action:Event_Jarated(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new client = BfReadByte(bf);
	new victim = BfReadByte(bf);
		
	LogPlyrPlyrEvent(client, victim, "triggered", "jarate", true);
	return Plugin_Continue;
}

public Action:Event_ShieldBlocked(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new victim = BfReadByte(bf);
	new client = BfReadByte(bf);
		
	LogPlyrPlyrEvent(client, victim, "triggered", "shield_blocked", true);
	return Plugin_Continue;
}


public Event_Teleport(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "userid"	"short"		// userid of the player
	// "builderid"	"short"		// userid of the player who built the teleporter
	
	new userid = GetEventInt(event, "builderid");
	
	if (userid != GetEventInt(event, "userid"))
	{
		LogPlayerEvent(GetClientOfUserId(userid), "triggered", "teleport");
	}
	else
	{
		LogPlayerEvent(GetClientOfUserId(userid), "triggered", "teleport_self");
	}
}


// octo - generate sandvich action in log
public Action:sound_hook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(StrEqual(sample,"vo/SandwichEat09.wav") && (clients[0] == entity))
	{
		LogPlayerEvent(clients[0], "triggered", "sandvich");
	}
	return Plugin_Continue;
}
//end octo

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "userid"        "short"         // user ID on server          

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0)
	{
		if (g_wstatsnet)
		{
			reset_player_stats(client);
		}
		if (g_objlogfix || g_rolelogfix)
		{
			if (g_objlogfix && g_bDestroyObj[client])
			{
				LogBuildings(client);
				g_bDestroyObj[client] = false;
			}
			
			g_iCurrentRole[client] = TF2_GetPlayerClass(client);
			new TFClassType:nextRole = g_iNextRole[client];
			
			if (nextRole > TFClass_Unknown)
			{
				switch(nextRole)
				{
					case TFClass_Scout:
						LogRoleChange(client, "scout");
					case TFClass_Sniper:
						LogRoleChange(client, "sniper");
					case TFClass_Soldier:
						LogRoleChange(client, "soldier");
					case TFClass_DemoMan:
						LogRoleChange(client, "demoman");
					case TFClass_Medic:
						LogRoleChange(client, "medic");
					case TFClass_Heavy:
						LogRoleChange(client, "heavyweapons");
					case TFClass_Pyro:
						LogRoleChange(client, "pyro");
					case TFClass_Spy:
						LogRoleChange(client, "spy");
					case TFClass_Engineer:
						LogRoleChange(client, "engineer");
				}
			}
			g_iNextRole[client] = TFClass_Unknown;
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	WstatsDumpAll();
}


DumpHeals(client)
{
	new iTotalHealPoints = GetEntData(client, g_iHealsOff);
	new iLifeHealPoints = iTotalHealPoints - g_iHealPointCache[client];
	if (iLifeHealPoints > 0 && TF2_GetPlayerClass(client) != TFClass_Medic)
	{
		decl String:szProperties[24];
		Format(szProperties, sizeof(szProperties), " (healing \"%d\")", iLifeHealPoints);
		LogPlayerEvent(client, "triggered", "healed", false, szProperties);
	}
	g_iHealPointCache[client] = iTotalHealPoints;
}

public Action:LogMap(Handle:timer)
{
	// Called 1 second after OnPluginStart since srcds does not log the first map loaded. Idea from Stormtrooper's "mapfix.sp" for psychostats
	LogMapLoad();
}


public OnCvarActionsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new bool:old_value = g_logactions;
	g_logactions = GetConVarBool(g_cvar_actions);
	
	if (old_value != g_logactions)
	{
		if (g_logactions)
		{
			hook_actions();
			if (!g_wstatsnet && !g_logheals)
			{
				HookEvent("player_death", Event_PlayerDeath);
			}
			if (g_sdkhooksavailable)
			{
				HookEvent("player_hurt", Event_PlayerHurt);
			}
		}
		else
		{
			unhook_actions();
			if (!g_wstatsnet && !g_logheals)
			{
				UnhookEvent("player_death", Event_PlayerDeath);
			}
			if (g_sdkhooksavailable)
			{
				UnhookEvent("player_hurt", Event_PlayerHurt);
			}
		}
	}
}


public OnCvarHeadshotsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new bool:old_value = g_logheadshots;
	g_logheadshots = GetConVarBool(g_cvar_headshots);
	
	if (old_value != g_logheadshots)
	{
		if (g_logheadshots && !g_logbackstabs && !g_logfire)
		{
			HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
		}
		else if (!g_logbackstabs && !g_logfire)
		{
			UnhookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
		}
	}
}

public OnCvarBackstabsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new bool:old_value = g_logbackstabs;
	g_logbackstabs = GetConVarBool(g_cvar_backstabs);
	
	if (old_value != g_logbackstabs)
	{
		if (g_logbackstabs && !g_logheadshots && !g_logfire)
		{
			HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
		}
		else if (!g_logheadshots && !g_logfire)
		{
			UnhookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
		}
	}
}

public OnCvarSandvichChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new bool:old_value = g_logsandvich;
	g_logsandvich = GetConVarBool(g_cvar_sandvich);
	
	if (old_value != g_logsandvich)
	{
		if (g_logsandvich)
		{
			//octo - added sound hook for sandvich event
			AddNormalSoundHook(sound_hook);
		}
		else
		{
			RemoveNormalSoundHook(sound_hook);
		}
	}
}

public OnCvarFireChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new bool:old_value = g_logfire;
	g_logfire = GetConVarBool(g_cvar_fire);
	
	if (old_value != g_logfire)
	{
		if (g_logfire && !g_logheadshots && !g_logbackstabs)
		{
			HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
		}
		else if (!g_logheadshots && !g_logbackstabs)
		{
			UnhookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
		}
	}
}

public OnCvarWstatsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_logwstats = GetConVarBool(g_cvar_wstats);
	WstatsChange();
}

public OnCvarWeaponCritsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_crits = GetConVarBool(g_cvar_weaponcrits);
	WstatsChange();
}

WstatsChange()
{
	new bool:old_net = g_wstatsnet;
	g_wstatsnet = (g_logwstats && g_crits);
	
	if (old_net != g_wstatsnet)
	{
		if (g_wstatsnet)
		{
			hook_wstats();
			if (!g_sdkhooksavailable && !g_logactions)
			{
				HookEvent("player_hurt", Event_PlayerHurt);
			}
			if (!g_logactions && !g_logheals)
			{
				HookEvent("player_death", Event_PlayerDeath);
			}
		}
		else
		{
			WstatsDumpAll();
			unhook_wstats();
			if (!g_sdkhooksavailable && !g_logactions)
			{
				UnhookEvent("player_hurt", Event_PlayerHurt);
			}
			if (!g_logactions && !g_logheals)
			{
				UnhookEvent("player_death", Event_PlayerDeath);
			}
		}
	}
}

public OnCvarTeleportsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new bool:old_value = g_logteleports;
	g_logteleports = GetConVarBool(g_cvar_teleports);
	
	if (old_value != g_logteleports)
	{
		if (g_logteleports)
		{
			HookEvent("player_teleported", Event_Teleport);
		}
		else
		{
			UnhookEvent("player_teleported", Event_Teleport);
		}
	}
}

public OnCvarHealsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new bool:old_value = g_logheals;
	g_logheals = GetConVarBool(g_cvar_heals);
	
	if (old_value != g_logheals)
	{
		if (g_logheals && !g_wstatsnet && !g_logactions)
		{
			HookEvent("player_death", Event_PlayerDeath);
		}
		else if (!g_wstatsnet && !g_logactions)
		{
			UnhookEvent("player_death", Event_PlayerDeath);
		}
	}
}

public OnCvarRoleLogFixChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new bool:old_value = g_rolelogfix;
	g_rolelogfix = GetConVarBool(g_cvar_rolelogfix);
	
	if (old_value != g_rolelogfix)
	{
		if (g_rolelogfix)
		{
			hook_rolefix();
			if (!g_objlogfix)
			{
				HookEvent("player_changeclass", Event_ChangeClass, EventHookMode_Pre);
				if (!g_wstatsnet)
				{
					HookEvent("player_spawn", Event_PlayerSpawn);
				}
			}
		}
		else
		{
			unhook_rolefix();
			if (!g_objlogfix)
			{
				UnhookEvent("player_changeclass", Event_ChangeClass, EventHookMode_Pre);
				if (!g_wstatsnet)
				{
					UnhookEvent("player_spawn", Event_PlayerSpawn);
				}
			}
		}
	}
}

public OnCvarObjLogFixChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new bool:old_value = g_objlogfix;
	g_objlogfix = GetConVarBool(g_cvar_objlogfix);
	
	if (old_value != g_objlogfix)
	{
		if (g_objlogfix)
		{
			hook_objfix();
			if (!g_rolelogfix)
			{
				HookEvent("player_changeclass", Event_ChangeClass, EventHookMode_Pre);
				if (!g_wstatsnet)
				{
					HookEvent("player_spawn", Event_PlayerSpawn);
				}
			}
		}
		else
		{
			unhook_objfix();
			if (!g_rolelogfix)
			{
				UnhookEvent("player_changeclass", Event_ChangeClass, EventHookMode_Pre);
				if (!g_wstatsnet)
				{
					UnhookEvent("player_spawn", Event_PlayerSpawn);
				}
			}
		}
	}
}
