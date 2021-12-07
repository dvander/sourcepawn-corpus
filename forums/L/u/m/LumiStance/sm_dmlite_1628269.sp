/* sm_dmlite.sp
Name: Deathmatch Lite
Author: TechKnow / LumiStance
Date: 2011 - 11/13

Description:
	Gives deathmatch respawn to Counter Strike: Source.
	Optionally sets player's money on respawn, removes ground weapons and defuser kits,
	provides spawn and Gun-Game level-up protection, ragdoll dissolve, and removal of player collisions.

	This plugin allows you to have what used to require finding, downloading, and configuring several plugins.
	Configuration is kept to a minimum to simply installation.  Tweaks to colors, timings, etc. can be
	accomplished by recompiling.  PM me if you need help.

	Players won't respawn between round_end and round_start.
	Teleports players up who spawn buried (a log message is generated for this rare event).
	Removes ragdoll of players who spectate.
	Spawn and Gun-Game level-up protection is canceled if the player fires his weapon.
	Will not dissolve ragdolls after round end (should mitigate map change issue).
	The as of 2011, the game engine now removes ragdoll on respawn, team change (including spectate), and
	disconnect.  Dissolve will beat respawn.

	Servers using this mod: www.gametracker.com/search/css/?search_by=server_variable&search_by2=sm_dmlite_version&searchipp=50

Installation:
	Place compiled plugin (sm_dmlite.smx) into your plugins folder.
	The configuration file (dmlite.cfg) is generated automatically.
	Changes to dmlite.cfg are read at map/plugin load time.
	Changes to cvars made in console take effect immediately.

Upgrade Notes:
	Added sm_dmlite_money as of v2.5; add this to dmlite.cfg if you wish to use it.
	Added sm_dmlite_protect as of v2.6; add this to dmlite.cfg if you wish to disable it.
	Added sm_dmlite_dissolve as of v2.6; add this to dmlite.cfg if you wish to disable it.
	Added sm_dmlite_noblock as of v2.6; add this to dmlite.cfg if you wish to disable it.
	Replace sm_dmlite_protect with sm_dmlite_spawn_time and sm_dmlite_level_time as of v2.7;
		update dmlite.cfg appropriately.
	Alternatively, you can delete the old dmlite.cfg and a replacement, with all of the
	cvars provided, will be created when the next map loads.

Problems, Bug Reports, Feature Requests, and Compliments:
	Please send me a private message at http://forums.alliedmods.net/private.php?do=newpm&u=46596
	Include a detailed description of how to reproduce the problem. Information about your server,
	such as dedicate/listen, platform (win32/linux), game, and ip address may be useful.

	I prefer to keep the plugin thread cleared so people don't have to wade through pages of fodder.
	The community will be given a chance to address any bug reports that are posted in the plugin thread.
	If you want a direct response from me, send a private message.

	Compliments are always welcomed in the thread.

Background:
	Originally created by TechKnow. See http://forums.alliedmods.net/showthread.php?t=81787
	Spawn Protection derived from Spawn Protection v1.5 by Fredd.
		See http://forums.alliedmods.net/showthread.php?t=68139
	Ragdoll Dissolve derived from Dissolve (player ragdolls) by L. Duke
		See http://forums.alliedmods.net/showthread.php?t=71084
	No Block derived from NoBlock v1.4.2 by altex and Meng
		See http://forums.alliedmods.net/showthread.php?t=91617
		See http://forums.alliedmods.net/showthread.php?t=107619

Files:
	cstrike/addons/sourcemod/plugins/sm_dmlite.smx
	cstrike/cfg/sourcemod/dmlite.cfg
	cstrike/cfg/server.cfg

Configuration Variables (Change in dmlite.cfg):
	sm_dmlite_delay - Number of seconds before respawing player. 0 Disables respawn. (Default: "3.0")
	sm_dmlite_money - Player respawn money. 0 Disables account adjustment. (Default: "0")
	sm_dmlite_cleanup - Enable/Disable weapon cleanup. (Default: "1")
	sm_dmlite_lives - Number of times player can respawn per round. 0 Disables Limit. (Default: "15")
	sm_dmlite_spawn_time - Spawn Protection time in seconds. 0 Disables Spawn Protection. (Default: "0.85")
	sm_dmlite_level_time - GG Levelup Protection time in seconds. 0 Disables Levelup Protection. (Default: "0.60")
	sm_dmlite_dissolve - Enable/Disable Ragdoll Dissolve. (Default: "1")
	sm_dmlite_noblock - Enable/Disable Removal of Player Collisions. (Default: "1")

Server Configuration Variables (Change in server.cfg):
	mp_startmoney - Set this to match sm_dmlite_money
	mp_buytime - Set this to allow late buying (50000 is longer than a month)
	mp_ignore_round_win_conditions - Set this to prevent round end

To-Do:
	Option to give C4 when mp_ignore_round_win_conditions 1
	Option to remove map objectives
	Complete and publish Gun Menu plugin (it's running on my 27019 server)

Changelog:
	2.9b <-> 2012 - 01/12 LumiStance
		Merge v2.8b with v2.9
	2.9 <-> 2012 - 01/12 LumiStance
		Correct team check in RespawnAllDead
	2.8b <-> 2012 - 01/08 LumiStance
		Added sm_dmlite_lives
	2.8a <-> 2011 - 12/24 LumiStance
		Added FCVAR_REPLICATED to version cvar
	2.8 <-> 2011 - 11/13 LumiStance
		Add CS_TEAM constant labels
		Remove Ragdoll spam; game now removes ragdolls
		Moved CheckClientSpawnHeight call to Event_PlayerSpawn
	2.7 <-> 2011 - 01/10 LumiStance
		Add code to cancel protection on weapon firing
		Replace sm_dmlite_protect with sm_dmlite_spawn_time and sm_dmlite_level_time
		Cache m_hOwnerEntity
	2.6 <-> 2010 - 11/20 LumiStance
		Added Spawn Protection and Gun Game Level-Up protection and sm_dmlite_protect cvar
		Added Ragdoll Dissolve and sm_dmlite_dissolve cvar
		Added No Block and sm_dmlite_noblock cvar
		Removed respawn spam
		Added code to work around A2S_RULES bug in linux orange box
		Added code to find (every 15s) dead players that didn't fire player_death event
	2.5 <-> 2010 - 09/11 LumiStance
		Added code to reset player's account at respawn
		Added code to Event_BombExploded check g_RespawnDelay
		Refactored redundant code
		Added CheckClientSpawnHeight to find players spawned into the ground
		Added code to block respawn at round end
	2.4 <-> 2010 - 09/06 LumiStance
		Corrected usage of MaxClients in RespawnAllDead and StripGroundWeapons
		Added code to Event_PlayerTeam to ignore players who weren't on a team
	2.3 <-> 2010 - 09/02 LumiStance
		Added code to remove defusers with owners - defusers don't exist when equiped
		Stripped IsClientConnected when IsClientInGame was also checked
	2.2 <-> 2010 - 07/20 LumiStance
		Added code to remove ragdoll when player joins spectators
	2.1 <-> 2010 - 07/06 LumiStance
		Added code to find players killed by C4
	2.0 <-> 2010 - 06/28 LumiStance
		Finalize Rebranding and Release with TechKnow's blessing
	1.9 <-> 2010 - 06/27 LumiStance
		Replaced AutoTimer with joinclass command hook
		Cleaned up code
		Change Chat Message to before delay
	1.8 <-> 2010 - 06/26 LumiStance
		Revise Weapon Cleanup code
	1.7 <-> 2010 - 06/25 LumiStance
		Replaced SDKCall for RoundRespawn with CS_RespawnPlayer
			This removes dependency on gamedata.txt and make compatible with Source 2010 Update
		Clean up whitespace
		Added documentation
	1.6 <-> 2008 - 12/11 TechKnow
		Added map weapons removal at round start, replaces the need for plugin Buyitdamnit.
	1.5
		Repaired Autospawn timmer multiple starts.
	1.4
		Removed chat command !spawn and spawn and replaced them with a total AUTO-Spawn because players
		are too stupid to type !spawn or spawn in chat.
	1.3
		Added Remove weapons on players death to prevent other players from picking up the wrong weapon
		and to stop server from lagging when a long round is leaving MANY guns/weapons loose on the
		ground. and cvar to control on or off.
		The scripting of removal of weapons was made by Kigen, a MASTER scripter.
	1.2
		Repaired client chat message saying..
		[GGDM]You can not spawn because you are already alive.
		or
		[GGDM]You can not spawn because you are not on a team.
		Eevry time you typed weather you typed spawn or !spawn or NOT.
	1.1
		Added so players can spawn themselves if they join in the middle of a round so they dont have to
		wait for next round to be spawned.
	1.0
		released
*/

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

// Plugin definitions
#define PLUGIN_VERSION "2.9b-lm"
#define PLUGIN_ANNOUNCE "\x04[DM Lite]\x01 v2.9b-lm by LumiStance"
public Plugin:myinfo =
{
	name = "Deathmatch Lite",
	author = "LumiStance",
	description = "Gives deathmatch respawn to Counter Strike: Source",
	version = PLUGIN_VERSION,
	url = "http://srcds.lumistance.com/"
};

// Console Variables
new Handle:g_ConVar_Delay;
new Handle:g_ConVar_Money;
new Handle:g_ConVar_Cleanup;
new Handle:g_ConVar_SpawnLimit;
new Handle:g_ConVar_SpawnTime;
new Handle:g_ConVar_LevelTime;
new Handle:g_ConVar_Dissolve;
new Handle:g_ConVar_Noblock;
new Handle:g_ConVar_Version;
// Configuration
new Float:g_RespawnDelay;
new g_StartMoney;
new bool:g_CleanupEnable;
new g_RespawnLimit;
new Float:g_SpawnTime;
new Float:g_LevelTime;
new bool:g_DissolveEnable;
new bool:g_NoblockEnable;
// Other Persistant Variables
new bool:g_RoundEnd;
new bool:g_Respawning[MAXPLAYERS+1];
new bool:g_Protected[MAXPLAYERS+1];
new g_RespawnCount[MAXPLAYERS+1];
new Handle:g_RespawnAllTimer = INVALID_HANDLE;

public OnPluginStart()
{
	// Specify console variables used to configure plugin
	g_ConVar_Delay = CreateConVar("sm_dmlite_delay", "3.0", "Number of seconds before respawing player. 0 Disables respawn.", FCVAR_PLUGIN|FCVAR_SPONLY);
	g_ConVar_Money = CreateConVar("sm_dmlite_money", "0", "Player respawn money. 0 Disables account adjustment.", FCVAR_PLUGIN|FCVAR_SPONLY);
	g_ConVar_Cleanup = CreateConVar("sm_dmlite_cleanup", "1", "Enable/Disable weapon cleanup.", FCVAR_PLUGIN|FCVAR_SPONLY);
	g_ConVar_SpawnLimit = CreateConVar("sm_dmlite_lives", "15", "Number of times player can respawn per round. 0 Disables Limit", FCVAR_PLUGIN|FCVAR_SPONLY);
	g_ConVar_SpawnTime = CreateConVar("sm_dmlite_spawn_time", "0.85", "Spawn Protection time in seconds. 0 Disables Spawn Protection", FCVAR_PLUGIN|FCVAR_SPONLY);
	g_ConVar_LevelTime = CreateConVar("sm_dmlite_level_time", "0.60", "GG Levelup Protection time in seconds. 0 Disables Levelup Protection", FCVAR_PLUGIN|FCVAR_SPONLY);
	g_ConVar_Dissolve = CreateConVar("sm_dmlite_dissolve", "1", "Enable/Disable Ragdoll Dissolve.", FCVAR_PLUGIN|FCVAR_SPONLY);
	g_ConVar_Noblock = CreateConVar("sm_dmlite_noblock", "1", "Enable/Disable Removal of Player Collisions.", FCVAR_PLUGIN|FCVAR_SPONLY);
	AutoExecConfig(true, "dmlite");

	// Version of plugin - Make visible to game-monitor.com - Don't store in configuration file
	g_ConVar_Version = CreateConVar("sm_dmlite_version", PLUGIN_VERSION, "[SM] Deathmatch Lite Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Event Hooks
	HookConVarChange(g_ConVar_Delay, Event_CvarChange);
	HookConVarChange(g_ConVar_Money, Event_CvarChange);
	HookConVarChange(g_ConVar_Cleanup, Event_CvarChange);
	HookConVarChange(g_ConVar_SpawnLimit, Event_CvarChange);
	HookConVarChange(g_ConVar_SpawnTime, Event_CvarChange);
	HookConVarChange(g_ConVar_LevelTime, Event_CvarChange);
	HookConVarChange(g_ConVar_Dissolve, Event_CvarChange);
	HookConVarChange(g_ConVar_Noblock, Event_CvarChange);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);	// No event data needed
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);	// No event data needed
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("bomb_exploded", Event_BombExploded);
	RegConsoleCmd("joinclass", Command_JoinClass);
}

// Occurs after round_start
public OnConfigsExecuted()
{
	// Synchronize Cvar Cache after configuration loaded
	RefreshCvarCache();
	// Override config file and work around A2S_RULES bug in linux orange box
	SetConVarString(g_ConVar_Version, PLUGIN_VERSION);
}

// Synchronize Cvar Cache when change made
public Event_CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RefreshCvarCache();
}

stock RefreshCvarCache()
{
	g_RespawnDelay = GetConVarFloat(g_ConVar_Delay);
	g_StartMoney = GetConVarInt(g_ConVar_Money);
	g_CleanupEnable = GetConVarBool(g_ConVar_Cleanup);
	g_RespawnLimit = GetConVarInt(g_ConVar_SpawnLimit);
	g_SpawnTime = GetConVarFloat(g_ConVar_SpawnTime);
	g_LevelTime = GetConVarFloat(g_ConVar_LevelTime);
	g_DissolveEnable = GetConVarBool(g_ConVar_Dissolve);
	g_NoblockEnable = GetConVarBool(g_ConVar_Noblock);

	if(g_RespawnDelay && !g_RoundEnd)
	{
		if (g_RespawnAllTimer == INVALID_HANDLE)
			g_RespawnAllTimer = CreateTimer(0.1, Event_RespawnAllDead);
		else
			RespawnAllDead();
	}

	// Remove weapons that come with map or were dropped
	if (g_CleanupEnable)
		StripGroundWeapons();

	ResetCollisions();
}

public Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	g_RoundEnd = false;

	// Reset Lives
	for (new client_index = 1; client_index <= MaxClients; client_index++)
		g_RespawnCount[client_index] = 0;

	// Start timer to check for rogue deaths
	if(g_RespawnDelay && g_RespawnAllTimer == INVALID_HANDLE)
		g_RespawnAllTimer = CreateTimer(15.0, Event_RespawnAllDead);

	// Remove weapons that come with map
	if (g_CleanupEnable)
		StripGroundWeapons();
}

// Block respawn at round end
public Event_RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	g_RoundEnd = true;
}

public OnClientPutInServer(client_index)
{
	PrintToChat(client_index, PLUGIN_ANNOUNCE);
	// Reset Lives
	g_RespawnCount[client_index] = 0;
}

// Player chose class - Spawn
public Action:Command_JoinClass(client_index, args)
{
	if (g_RespawnDelay && !g_RoundEnd)
		StartRespawn(client_index);

	return Plugin_Continue;
}

// See if player went to spectators, and was on a team
// If so, remove ragdoll
public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_index = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((GetEventInt(event, "team") == CS_TEAM_SPECTATOR) && (GetEventInt(event, "oldteam") > CS_TEAM_SPECTATOR))
	{
		new ragdoll_entity_index = GetEntPropEnt(client_index, Prop_Send, "m_hRagdoll");
		if (IsValidEdict(ragdoll_entity_index))
			RemoveEdict(ragdoll_entity_index);
	}
}

// Player died - Respawn and Cleanup Weapons
public Event_PlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client_index = GetClientOfUserId(GetEventInt(event, "userid"));

	if (g_DissolveEnable && !g_RoundEnd)
		CreateTimer(0.1, Event_DissolveRagdoll, client_index);

	if (g_RespawnDelay && !g_RoundEnd)
		StartRespawn(client_index);

	if (g_CleanupEnable)
		StripGroundWeapons();
}

// Player Spawn - Protect while they get reoriented, apply noblock, unbury
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_index = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_SpawnTime)
		ProtectClient(client_index, g_SpawnTime);
	if (g_NoblockEnable)
		SetEntProp(client_index, Prop_Data, "m_CollisionGroup", 2);	// COLLISION_GROUP_DEBRIS_TRIGGER
	CheckClientSpawnHeight(client_index);
}

// Player Leveled Up - Protect while new weapon is given
public Action:GG_OnClientLevelChange(client_index, level, difference, bool:steal, bool:last, bool:knife)
{
	if (g_LevelTime)
		ProtectClient(client_index, g_LevelTime);
	return Plugin_Continue;
}

// Player Fired Weapon - Cancel Protection
public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_index = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_Protected[client_index])
		RemoveProtection(INVALID_HANDLE, client_index);
}

// Bomb Detonated - Check for dead players
public Event_BombExploded(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (g_RespawnDelay && !g_RoundEnd)
		RespawnAllDead();
}

// Check every quarter minute for dead bots that didn't fire player_death event
public Action:Event_RespawnAllDead(Handle:timer)
{
	if(g_RespawnDelay && !g_RoundEnd)
	{
		RespawnAllDead();
		g_RespawnAllTimer = CreateTimer(15.0, Event_RespawnAllDead);
	}
	else
		g_RespawnAllTimer = INVALID_HANDLE;
}

stock RespawnAllDead()
{
	for (new client_index = 1; client_index <= MaxClients; client_index++)
	{
		if ( IsClientInGame(client_index)
		&& GetClientTeam(client_index) > CS_TEAM_SPECTATOR
		&& !IsPlayerAlive(client_index)
		&& !g_Respawning[client_index] )
			StartRespawn(client_index);
	}
}

stock StartRespawn(any:client_index)
{
	if (!g_RespawnLimit || g_RespawnCount[client_index] < g_RespawnLimit)
	{
		g_Respawning[client_index] = true;
		CreateTimer(g_RespawnDelay, Event_RespawnPlayer, client_index);
	}
}

// After Delay, Respawn if They are Actually Playing
public Action:Event_RespawnPlayer(Handle:timer, any:client_index)
{
	if ( g_RespawnDelay && !g_RoundEnd
	&& IsClientInGame(client_index)
	&& GetClientTeam(client_index) >= CS_TEAM_SPECTATOR
	&& !IsPlayerAlive(client_index) )
	{
		CS_RespawnPlayer(client_index);
		if (g_StartMoney)
			SetEntProp(client_index, Prop_Send, "m_iAccount", g_StartMoney);
	}

	g_Respawning[client_index] = false;
	return Plugin_Continue;
}

// See if player spawned into ground.  If so, teleport them up.
// Assumes player origin at bottom of player, and eyes 64 units up.
// Player is teleported 16 units above ground to clear bumps, slopes, etc.
// A more thorough check would do 4 trace rays at each corner of the players box.
stock CheckClientSpawnHeight(client_index)
{
	new Float:vAnglesDown[3] = {90.0, 0.0, 0.0};
	decl Float:vEyePos[3];
	decl Float:vGround[3];

	GetClientEyePosition(client_index, vEyePos);

	new Handle:trace = TR_TraceRayFilterEx(vEyePos, vAnglesDown, MASK_ALL, RayType_Infinite, TraceEntityFilterWorld);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(vGround, trace);
		if (vEyePos[2] - vGround[2] < 64.0)
		{
			decl String:current_map[32];
			GetCurrentMap(current_map, sizeof(current_map));
			LogMessage("[DM Lite] Player spawned in ground on map %s at location x:%.0f y:%.0f z:%.0f!", current_map, vGround[0], vGround[1], vGround[2]);

			vGround[2] += 16.0;
			TeleportEntity(client_index, vGround, NULL_VECTOR, NULL_VECTOR);
		}
	}
	else
	{
		decl String:current_map[32];
		GetCurrentMap(current_map, sizeof(current_map));
		LogMessage("[DM Lite] Didn't find ground on map %s from location x:%.0f y:%.0f z:%.0f!", current_map, vEyePos[0], vEyePos[1], vEyePos[2]);
	}

	CloseHandle(trace);

	return -1;
}

public bool:TraceEntityFilterWorld(entity, contentsMask)
{
 	return !entity;
}

// Updated by LumiStance 2010 - 06/26
// By Kigen (c) 2008 - Please give me credit. :)
// And Weapon Restrict Plugin - Dr!fter
stock StripGroundWeapons()
{
	new MaxEntities = GetMaxEntities();
	static iOwnerEntity;
	if (!iOwnerEntity)
		iOwnerEntity = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	decl String:name[64];

	for (new index = MaxClients+1; index < MaxEntities; index++)
	{
		if (IsValidEdict(index))
		{
			GetEdictClassname(index, name, sizeof(name));
			if ( StrEqual(name, "item_defuser") || (!strncmp(name, "weapon_", 7, false) || !strncmp(name, "item_", 5, false)) && GetEntDataEnt2(index, iOwnerEntity) == -1)
				RemoveEdict(index);
		}
	}
}

// Updated by LumiStance 2010 - 11/20
// From Spawn Protection v1.5 by Fredd
stock ProtectClient(client_index, Float:protection_time)
{
	if(IsClientInGame(client_index))
	{
		new client_team = GetClientTeam(client_index);
		if (client_team == CS_TEAM_T)	// Terrorist
		{
			g_Protected[client_index] = true;
			SetEntProp(client_index, Prop_Data, "m_takedamage", 0, 1);
			SetEntityRenderMode(client_index, RENDER_TRANSADD);
			SetEntityRenderFx(client_index, RENDERFX_DISTORT);
			SetEntityRenderColor(client_index, 255, 0, 0, 120);
			CreateTimer(protection_time, RemoveProtection, client_index);
		}
		else if (client_team == CS_TEAM_CT)	// Counter-Terrorist
		{
			g_Protected[client_index] = true;
			SetEntProp(client_index, Prop_Data, "m_takedamage", 0, 1);
			SetEntityRenderMode(client_index, RENDER_TRANSADD);
			SetEntityRenderFx(client_index, RENDERFX_DISTORT);
			SetEntityRenderColor(client_index, 0, 0, 255, 120);
			CreateTimer(protection_time, RemoveProtection, client_index);
		}
	}
}

public Action:RemoveProtection(Handle:timer, any:client_index)
{
	if(IsClientInGame(client_index))
	{
		SetEntProp(client_index, Prop_Data, "m_takedamage", 2, 1);
		SetEntityRenderMode(client_index, RENDER_NORMAL);
		SetEntityRenderFx(client_index, RENDERFX_NONE);
		SetEntityRenderColor(client_index);		// (255, 255, 255, 255)
		g_Protected[client_index] = false;
	}
}


// Updated by LumiStance 2010 - 11/20
// From Dissolve (player ragdolls) v1.0.0.2 by L. Duke
public Action:Event_DissolveRagdoll(Handle:timer, any:client_index)
{
	if (IsClientInGame(client_index) && !g_RoundEnd)
	{
		new ragdoll_entity_index = GetEntPropEnt(client_index, Prop_Send, "m_hRagdoll");
		if (!IsValidEdict(ragdoll_entity_index))
			return;	// The Game Engine beat us to it
		new dissolver_entity_index = CreateEntityByName("env_entity_dissolver");
		if (dissolver_entity_index<=0)
		{
			LogMessage("[DM Lite] Could not create dissolver for ragdoll!");
			return;
		}

		// Create unique string to connect ragdoll to dissolver
		new String:dname[16] = "lm_dissolver_x";
		dname[13] = 65 + client_index;

		DispatchKeyValue(ragdoll_entity_index, "targetname", dname);
		DispatchKeyValue(dissolver_entity_index, "dissolvetype", "3");	// 0 ragdoll rises, 1 and 2 on ground, 3 is fast dissolve
		DispatchKeyValue(dissolver_entity_index, "target", dname);
		AcceptEntityInput(dissolver_entity_index, "Dissolve");
		AcceptEntityInput(dissolver_entity_index, "kill");
	}
}

stock ResetCollisions()
{
	new colgroup = (g_NoblockEnable) ? 2 : 5;	// COLLISION_GROUP_DEBRIS_TRIGGER=2, COLLISION_GROUP_PLAYER=5
	for (new client_index = 1; client_index <= MaxClients; client_index++)
	{
		if ( IsClientInGame(client_index)
		&& GetClientTeam(client_index) >= CS_TEAM_SPECTATOR
		&& IsPlayerAlive(client_index) )
			SetEntProp(client_index, Prop_Data, "m_CollisionGroup", colgroup);
	}
}
