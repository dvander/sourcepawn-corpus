/**
 * =====================================================================================
 *  Arena fix
 * =====================================================================================
 *
 * 1.0
 * - Initial release.
 *
 * 1.0.1
 * - Small optimisation.
 * - Added check for dead/spec players.
 *
 * 1.0.2
 * - Plugin now takes into account for melee mode plugins.
 *
 * 1.0.3
 * - Fixed heavy sandvich exploit, there's a posh way (via SDKHooks) which removes the 
 *	 sandvich if thrown, or a rough way via regular slot removal on round start/player spawn
 *   if SDKHooks is not present.
 * - Added in TF2 check just in case.
 * - Fixed a slight bug with the melee code, shouldn't have caused any serious problems 
 *   though.
 * - Optimisations.
 *
 * 1.0.4
 * - Fixed sandvich being restored if you have no SDKHooks and have melee mode enabled.
 *
 * 1.0.5
 * - Fixed disconnect hook.
 * - Fixed version string.
 *
 * 1.0.6
 * - Fixed a rare bug where the sandvich SDKHook could continue to work in non-arena
 *   maps.
 *
 * 1.0.7
 * - Made weapon check more accurate.
 * - Made non-SDKHook check only remove sandvich now.
 * =====================================================================================
 */
 
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#undef REQUIRE_EXTENSIONS
#include <sdkhooks>
#define REQUIRE_EXTENSIONS
#define VERSION "1.0.7"

new Handle:t_RoundStart;
new Handle:cvar_arena;
new Handle:cvar_round_time;
new bool:isArena;
new bool:lateLoad;
new bool:removedSandvich[MAXPLAYERS+1];
new bool:useSDKHooks;

public Plugin:myinfo =
{
	name = "TF2 Arena fix",
	author = "Jamster",
	description = "Fixes health, ammo and loadout problems in arena",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	cvar_arena = FindConVar("tf_gamemode_arena");
	cvar_round_time = FindConVar("tf_arena_preround_time");
	CreateConVar("sm_tf2arenafix_version", VERSION, "TF2 Arena fix version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	decl String:game[4];
	GetGameFolderName(game, 4);
	if (!StrEqual(game, "tf", false))
		SetFailState("You are not running Team Fortress 2! Please remove this plugin.");
	
	// I'm not returning any errors as it doesn't really matter if it fails, just looks nicer in game.
	switch (GetExtensionFileStatus("sdkhooks.ext", game, sizeof(game)))
	{
		case 1:
			useSDKHooks = true;
		default:
		{
			useSDKHooks = false;
			HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
		}
	}
}

SandvichCheck(client)
{
	if (!IsClientInGame(client) || IsFakeClient(client) || IsClientObserver(client))
		return;
	
	if (TF2_GetPlayerClass(client) != TFClass_Heavy)
		return;
	
	new weapon = GetPlayerWeaponSlot(client, 1);
	if (weapon != -1)
	{
		decl String:weapon_name[64];
		GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
		if (StrEqual(weapon_name, "tf_weapon_lunchbox"))
		{
			TF2_RemoveWeaponSlot(client, 1);
			removedSandvich[client] = true;
		}
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	switch (isArena)
	{
		case true:
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			SandvichCheck(client);
		}
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{	
	switch (late)
	{
		case true:
			lateLoad = true;
	}
	
	MarkNativeAsOptional("SDKHook");
	return APLRes_Success;
}

public OnClientPutInServer(client)
{
	switch (useSDKHooks)
	{
		case true:
			SDKHook(client, SDKHook_PreThink, OnPreThink_SandvichCheck);
	}
}

public OnClientDisconnect(client)
{
	// SDK hooks automatically removes client hooks so I don't need to unhook here.
	removedSandvich[client] = false;
}

public OnPreThink_SandvichCheck(client)
{
	if (t_RoundStart != INVALID_HANDLE)
	{
		if (IsPlayerAlive(client) && TF2_GetPlayerClass(client) == TFClass_Heavy)
		{
			if (GetClientButtons(client) & IN_ATTACK2)
			{
				decl String:weapon[32];
				GetClientWeapon(client, weapon, sizeof(weapon));
				if (StrEqual(weapon, "tf_weapon_lunchbox"))
				{
					TF2_RemoveWeaponSlot(client, 1);
					removedSandvich[client] = true;
					ClientCommand(client, "slot1");
				}
			}
		}
	}
}

public OnMapStart()
{
	t_RoundStart = INVALID_HANDLE;
	switch (GetConVarInt(cvar_arena))
	{
		case true:
		{
			isArena = true;
			if (lateLoad && useSDKHooks)
			{
				for (new i = 1; i <= MaxClients; i++) 
					if (IsClientInGame(i))
						SDKHook(i, SDKHook_PreThink, OnPreThink_SandvichCheck);
				lateLoad = false;
			}
		
			for (new i = 1; i <= MAXPLAYERS; i++)
				removedSandvich[i] = false;
		}
		default:
			isArena = false;
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	switch (isArena)
	{
		case true:
		{
			t_RoundStart = CreateTimer(GetConVarFloat(cvar_round_time), t_Regen, _, TIMER_FLAG_NO_MAPCHANGE);
			if (!useSDKHooks)
				for (new i = 1; i <= MaxClients; i++)
					SandvichCheck(i);
		}	
	}
}

public Action:t_Regen(Handle:timer)
{
	new bool:WeaponSlot[6] = true;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
			
		if (!IsPlayerAlive(i))
			continue;
			
		for (new w; w <= 5; w++)
		{
			if (GetPlayerWeaponSlot(i, w) != -1)
				WeaponSlot[w] = true;
			else
				WeaponSlot[w] = false;
		}
		
		if (removedSandvich[i] && TF2_GetPlayerClass(i) == TFClass_Heavy && WeaponSlot[0])
			WeaponSlot[1] = true;
			
		TF2_RegeneratePlayer(i);
		for (new w; w <= 5; w++)
			if (!WeaponSlot[w])
				TF2_RemoveWeaponSlot(i, w);
		// Usually if a classes main weapon is missing you can assume it's melee, so we switch 
		// to the melee weapon to avoid the inactive weapon model remaining for the removed weapon.
		if (!WeaponSlot[0])
			ClientCommand(i, "slot3");
	}
	t_RoundStart = INVALID_HANDLE;
	return Plugin_Stop;
}