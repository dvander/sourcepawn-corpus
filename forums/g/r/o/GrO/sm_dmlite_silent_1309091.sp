/* sm_fragwin.sp
Name: Deathmatch Lite
Author: TechKnow / LumiStance
Date: 2010 - 09/11

Description:
	Gives deathmatch respawn to Counter Strike: Source.
	Optionally provides removal of ground weapons and defuser kits.
	Optionallly sets player's money on respawn.

	Players won't respawn between round_end and round_start.
	Teleports players up who spawn buried (a log message is generated for this rare event).
	Removes ragdoll of players who specate.

	Servers using this mod: http://www.game-monitor.com/search.php?vars=dmlite_version

Installation:
	Place compiled plugin (sm_dmlite.smx) into your plugins folder.
	The configuration file (dmlite.cfg) is generated automatically.
	Changes to dmlite.cfg are read at map/plugin load time.
	Changes to cvars made in console take effect immediately.

Upgrade Notes:
	Added sm_dmlite_money as of v2.5; add this to dmlite.cfg if you wish to use it.

Background:
	Originally created by TechKnow. See http://forums.alliedmods.net/showthread.php?t=81787

Files:
	cstrike/addons/sourcemod/plugins/sm_dmlite.smx
	cstrike/cfg/sourcemod/dmlite.cfg
	cstrike/cfg/server.cfg

Configuration Variables (Change in dmlite.cfg):
	sm_dmlite_delay - Number of seconds before respawing player. 0 Disables respawn. (Default: "3.0")
	sm_dmlite_cleanup - Enable/Disable weapon cleanup. (Default: "1")
	sm_dmlite_money - Player respawn money. 0 Disables account adjustment. (Default: "0")

Server Configuration Variables (Change in server.cfg):
	mp_startmoney - Set this to match sm_dmlite_money
	mp_buytime - Set this to allow late buying (50000 is longer than a month)
	mp_ignore_round_win_conditions - Set this to prevent round end

Other Suggestions:
	Spawn Protection: http://forums.alliedmods.net/showthread.php?t=68139

To-Do:
	Spawn Protection
	Ragdoll Dissolve
	Option to give C4 when mp_ignore_round_win_conditions 1
	Detect dead bots
	Gun Menu
	Option to remove map objectives

Changelog:
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
#define PLUGIN_VERSION "2.5-lm"
#define PLUGIN_ANNOUNCE "\x04[DM Lite]\x01 v2.5-lm by LumiStance"
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
new Handle:g_ConVar_Cleanup;
new Handle:g_ConVar_Money;
// Configuration
new Float:g_RespawnDelay;
new bool:g_CleanupEnable;
new g_StartMoney;
new bool:g_RoundEnd;
// Other Persistant Variables
new bool:g_Respawning[MAXPLAYERS+1];

public OnPluginStart()
{
	// Specify console variables used to configure plugin
	g_ConVar_Delay = CreateConVar("sm_dmlite_delay", "3.0", "Number of seconds before respawing player. 0 Disables respawn.", FCVAR_PLUGIN|FCVAR_SPONLY);
	g_ConVar_Cleanup = CreateConVar("sm_dmlite_cleanup", "1", "Enable/Disable weapon cleanup.", FCVAR_PLUGIN|FCVAR_SPONLY);
	g_ConVar_Money = CreateConVar("sm_dmlite_money", "0", "Player respawn money. 0 Disables account adjustment.", FCVAR_PLUGIN|FCVAR_SPONLY);
	AutoExecConfig(true, "dmlite");

	// Version of plugin - Visible to game-monitor.com - Don't store in configuration file - Force correct value
	SetConVarString(
		CreateConVar("sm_dmlite_version", PLUGIN_VERSION, "[SM] Deathmatch Lite Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD),
		PLUGIN_VERSION);

	// Event Hooks
	HookConVarChange(g_ConVar_Delay, Event_CvarChange);
	HookConVarChange(g_ConVar_Cleanup, Event_CvarChange);
	HookConVarChange(g_ConVar_Money, Event_CvarChange);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);	// No event data needed
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);	// No event data needed
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("bomb_exploded", Event_BombExploded);
	RegConsoleCmd("joinclass", Command_JoinClass);
}

// Synchronize Cvar Cache after configuration loaded
public OnConfigsExecuted()
{
	RefreshCvarCache();
}

// Synchronize Cvar Cache when change made
public Event_CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RefreshCvarCache();
}

stock RefreshCvarCache()
{
	g_RespawnDelay = GetConVarFloat(g_ConVar_Delay);

	if(g_RespawnDelay && !g_RoundEnd)
		RespawnAllDead();
	g_CleanupEnable = GetConVarBool(g_ConVar_Cleanup);

	if (g_CleanupEnable)
		StripGroundWeapons();

	g_StartMoney = GetConVarInt(g_ConVar_Money);
}

// Remove weapons that come with map
public Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	g_RoundEnd = false;
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

	if ((GetEventInt(event, "team") == 1) && (GetEventInt(event, "oldteam") > 1))
	{
		new ragdoll_entity_index = GetEntPropEnt(client_index, Prop_Send, "m_hRagdoll");
		if (ragdoll_entity_index < 0)
			LogMessage("[DM Lite] Could not get ragdoll for player!");
		else
			RemoveEdict(ragdoll_entity_index);
	}
}

// Player died - Respawn and Cleanup Weapons
public Event_PlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (g_RespawnDelay && !g_RoundEnd)
		StartRespawn(GetClientOfUserId(GetEventInt(event, "userid")));

	if (g_CleanupEnable)
		StripGroundWeapons();
}

// Bomb Detonated - Check for dead players
public Event_BombExploded(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (g_RespawnDelay && !g_RoundEnd)
		RespawnAllDead();
}

stock RespawnAllDead()
{
	for (new client_index = 1; client_index <= MaxClients; client_index++)
	{
		if ( IsClientInGame(client_index)
		&& GetClientTeam(client_index) >= 2
		&& !IsPlayerAlive(client_index)
		&& !g_Respawning[client_index] )
			StartRespawn(client_index);
	}
}

stock StartRespawn(any:client_index)
{
// 	PrintToChat(client_index,"\x04[DM Lite]\x01 You will spawn shortly");
	g_Respawning[client_index] = true;
	CreateTimer(g_RespawnDelay, Event_RespawnPlayer, client_index);
}

// After Delay, Respawn if They are Actually Playing
public Action:Event_RespawnPlayer(Handle:timer, any:client_index)
{
	if ( g_RespawnDelay && !g_RoundEnd
	&& IsClientInGame(client_index)
	&& GetClientTeam(client_index) >= 2
	&& !IsPlayerAlive(client_index) )
	{
		CS_RespawnPlayer(client_index);
		CheckClientSpawnHeight(client_index);
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
	new iOwnerEntity = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
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
