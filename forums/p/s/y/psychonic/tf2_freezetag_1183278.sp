/*
 * [TF2] Freeze Tag
 * Author: Chase (chase@sybolt.com)
 * Date: October 4, 2009
 * Portions adapted from Roll The Dice by linux_lover and TF2 Respawn by WoZer
 * 
 * Licensed under the GPL v2 or above.
 */

/*
TODO: (Also marked with TODO: tags in the code)
	-Optional immunity after unfreeze for X seconds?
	-Make sure sentries don't target frozen players, or add an option that disables sentries altogether during freeze tag
	-Find out why a spy w/ dead ringer respawns, and tries to use dead ringer, gives the error: Bad pstudiohdr in GetSequenceLinearMotion()!
	-Class locking
	-Disabling medic auto heal
	-Removing weapon drops on death?
	-Language file support
	-Vote command support
	-FT_ClearFrozenStatus is called too many times. Rethink where it is best suited.
	-Keep current weapon when thawed. (Fix RefreshWeapons())
	-player_healedbymedic event isn't firing. Is it clientside? If so, how can I replace it?
	-Implement FT_HookMedicHeal (see above)
	
CHANGELOG
	v1.1
		-Added debugging information and related cvar (WARNING: There's quite a bit of information)
		-Removed some redudant code that was causing a bit of an issue in some rare situations
		-Fixed some bugs that occured on map changes (Humiliation round would carry onto the next map)
		-Fixed bug in GetClientMaxHealth. 
		-Updated commands freezetag_freeze/unfreeze to use a target list
	REMAINING ISSUES:
		-Humiliation round activates as changelevel is called on the server. This is caused by everyone being disconnected.
			Way to fix that?
		
*/
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

/*	Dukehacks is necessary for allowing teammates to attack each other 
	to heal, and to make sure people cannot harm frozen players.
*/
#include <sdkhooks> 
//#undef REQUIRE_PLUGIN
// ^ What is this?

#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"

//Color codes. (Light blue would be lovely for the [FT] prefix, but alas, we lack proper coloring)
#define cDefault				0x01
#define cLightGreen 			0x03
#define cGreen					0x04
#define cDarkGreen  			0x05

#define PLUGIN_VERSION "1.1"

#define RED_TEAM (2)
#define BLU_TEAM (3)

// *********************************************************************************
// Globals
// *********************************************************************************

//Keeps track of frozen status of all players
new bool:g_bFrozen[MAXPLAYERS+1] = { false, ... };

//Saved position of frozen players, warped to when they attempt to respawn.
new Float:g_fFreezeOrigin[MAXPLAYERS+1][3];
new Float:g_fFreezeAngle[MAXPLAYERS+1][3];

//Players who need to be frozen once they spawn
new bool:g_bFreezeQueue[MAXPLAYERS+1] = { false, ... };

//Timers to handle auto unfreeze for each player
new Handle:g_hUnfreezeTimer[MAXPLAYERS+1] = { INVALID_HANDLE, ... }; 

//Losers stay frozen, winners get to do what they want
new bool:g_bIsHumiliationRound = false;

//The team that won the humiliation round. (RED_TEAM || BLU_TEAM)
new g_iHumiliationRoundWinners = 0;

//Stores the actual enabled state of freeze tag. Turned off after rounds and back on in the next round. 
//Using this instead of the cvar so I can install ftmode voting soon.
new bool:g_bFreezeTagEnabled = false;

//Will medics be allowed to heal themselves? TODO: convar this
new bool:g_bRemoveMedicAutoheal = true;

//Memorization of friendly fire convar previous state
new g_iSavedFriendlyFire = 0;

//Was plugin loaded midgame
new bool:g_bLateLoad = false;

// *********************************************************************************
// ConVars
// *********************************************************************************

//Seconds to automatically unfreeze a frozen player. Value of 0 will disable auto-unfreeze
new Handle:g_cvAutoUnfreeze = INVALID_HANDLE;

//Should the player be sent to their spawn when the auto unfreeze is activated?
new Handle:g_cvSendToSpawnOnAutoUnfreeze = INVALID_HANDLE;

//Should freeze tag be enabled on the server or not
new Handle:g_cvFreezeTagEnabled = INVALID_HANDLE;

//How long the humiliation round should last in seconds. 0 disables humiliation round.
new Handle:g_cvHumiliationRoundDuration = INVALID_HANDLE;

//If !0, will force the specified class on all players. (Valid: 1 through 9)
//new Handle:g_cvForceClass = INVALID_HANDLE; 

//If 0, players cannot unfreeze their teammates. Else, they can attack teammates to unfreeze them and this multiplier is applied to the amount healed. 
//Basically; hp += damage * multipler, if hp == full: unfreeze.
new Handle:g_cvUnfreezeMultiplier = INVALID_HANDLE;

//Will the freeze tag minigame continue after the humiliation round
new Handle:g_cvPersistentFreezeTag = INVALID_HANDLE;

//Should freeze tag be melee only? (imo, more fun)
new Handle:g_cvMeleeOnly = INVALID_HANDLE;

//mp_friendlyfire storage
new Handle:g_cvFriendlyFire = INVALID_HANDLE;

//Toggle active logging
new Handle:g_cvLogging = INVALID_HANDLE;

//Toggle debug logging
new Handle:g_cvDebug = INVALID_HANDLE;

// *********************************************************************************
// Main plugin routines and information
// *********************************************************************************

public Plugin:myinfo =
{
	name = "[TF2] Freeze Tag (modded for SDK Hooks)",
	author = "Chase",
	description = "Freeze Tag Minigame for TF2",
	version = PLUGIN_VERSION,
	url = "http://www.sybolt.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	RegisterCVars();
	RegisterCommands();
	RegisterEvents();
	
	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, FT_PrehookTakeDamage);
			}
		}
	}
	
	LogMessage("Freeze Tag Plugin Loaded");
}

public OnPluginEnd()
{
	FT_End();
}

RegisterCVars()
{
	g_cvFreezeTagEnabled = CreateConVar("freezetag_enabled", "0", "Enable or disable the plugin. 1=On, 0=Off", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvAutoUnfreeze = CreateConVar("freezetag_autounfreeze", "0.0", "Seconds to auto unfreeze frozen players. 0=off", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvSendToSpawnOnAutoUnfreeze = CreateConVar("freezetag_forcerespawn", "0", "Should a player be sent back to spawn when auto unfrozen? 1=On, 0=Off", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvHumiliationRoundDuration = CreateConVar("freezetag_humiliation", "60.0", "Seconds for the freeze tag mini humiliation round to last. 0=off", FCVAR_PLUGIN|FCVAR_NOTIFY);
	//g_cvForceClass = CreateConVar("freezetag_forceclass", "0", "Force a specific class on all players (by index 1-9). 0=off", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvPersistentFreezeTag = CreateConVar("freezetag_persistent", "0", "Keep playing freeze tag after the round has ended. 1=On, 0=Off", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvMeleeOnly = CreateConVar("freezetag_melee", "0", "Melee only mode. 1=On, 0=Off", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvUnfreezeMultiplier = CreateConVar("freezetag_multiplier", "0.5", "Multiplier applied to players attacks on frozen teammates to unfreeze them. 0 to disable completely.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvLogging = CreateConVar("freezetag_logging", "1", "Toggle event logging. 1=On, 0=Off", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvDebug = CreateConVar("freezetag_debug", "0", "Toggle debug logging. 1=On, 0=Off", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	CreateConVar("freezetag_version", PLUGIN_VERSION, "[TF2] Freeze Tag Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookConVarChange(g_cvFreezeTagEnabled, FT_ConVarChangeEnabled);
	//HookConVarChange(g_cvForceClass, FT_ConVarChangeForceClass);
	HookConVarChange(g_cvMeleeOnly, FT_ConVarChangeMeleeOnly);
	
	AutoExecConfig(true, "freezetag");
}

RegisterCommands()
{
	//For testing purposes
	RegAdminCmd("freezetag_unfreeze", FT_CommandFreezeUnfreeze, ADMFLAG_GENERIC, "Unfreeze a target manually");
	RegAdminCmd("freezetag_freeze", FT_CommandFreezeUnfreeze, ADMFLAG_GENERIC, "Freeze a target manually");
	RegAdminCmd("freezetag_toggle", FT_CommandToggle, ADMFLAG_GENERIC, "Toggle freeze tag mode");
}

RegisterEvents()
{
	HookEvent("player_spawn", FT_HookSpawn);
	HookEvent("player_death", FT_HookDeath);
	HookEvent("player_hurt", FT_HookHurt);
	//HookEvent("player_healedbymedic", FT_HookMedicHeal);  Apparently is clientside only?
	
	//EventHookMode_PostNoCopy = minor optimization where event parameters won't get memcpy'd over.
	HookEvent("teamplay_round_win", FT_HookRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start", FT_HookRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_stalemate", FT_HookRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_game_over", FT_HookRoundEnd, EventHookMode_PostNoCopy);

}

// *********************************************************************************
// Freeze Tag's main routines
// *********************************************************************************

/*	Clean up any changes set by freeze tag */
FT_End()
{
	if (GetConVarBool(g_cvLogging))
		LogMessage("Freeze Tag Round End");
		
	for (new i = 1; i <= MaxClients; i++)
	{
		FT_ClearFrozenStatus(i);
	}

	g_bFreezeTagEnabled = false;
	g_bIsHumiliationRound = false;
	//TODO: enable medic autoheal
	
	//Return global convars to their original value
	if (g_cvFriendlyFire != INVALID_HANDLE)
		SetConVarInt(g_cvFriendlyFire, g_iSavedFriendlyFire);
}

/*	Initialize a round of the freeze tag minigame */
FT_Start()
{
	/*if (GetConVarInt(g_cvForceClass) > 0)
	{
		//TODO: do class lock
	}*/
	
	if (g_bRemoveMedicAutoheal)
	{
		//TODO: disable medic autoheal
	}
	
	if (GetConVarBool(g_cvLogging))
		LogMessage("Freeze Tag Round Start");
	
	//Memorize previous state of global convars
	g_cvFriendlyFire = FindConVar("mp_friendlyfire");
	if (g_cvFriendlyFire != INVALID_HANDLE)
	{
		g_iSavedFriendlyFire = GetConVarInt(g_cvFriendlyFire);
		
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_Start] Saving previous sm_friendlyfire value (%i)", g_iSavedFriendlyFire);
		
		SetConVarInt(g_cvFriendlyFire, 1);
	}

	g_bFreezeTagEnabled = true;
	g_bIsHumiliationRound = false;

	if (GetConVarBool(g_cvDebug))
		LogMessage("[FT_Start] Clearing all frozen");
		
	for (new i = 1; i <= MaxClients; i++)
	{
		FT_ClearFrozenStatus(i);
	}

}

/*	Display the rules to the specified client. If -1 for client, will display rules to all players */
DisplayRules(client)
{	
	decl String:message[128];
	Format(message, sizeof(message), "%c[FT]%c * Attack enemies to freeze them, and attack allies to unfreeze", cGreen, cDefault);
	
	if (client == -1)
		PrintToChatAll(message);
	else
		PrintToChat(client, message);
	
	new Float:duration = GetConVarFloat(g_cvHumiliationRoundDuration);
	if (duration > 0.0)
	{
		Format(message, sizeof(message), "%c[FT]%c * First team to freeze all opponents receives a mini humiliation round for %.1f seconds!", cGreen, cDefault, duration);
		if (client == -1)
			PrintToChatAll(message);
		else
			PrintToChat(client, message);
	}
}

/*	Timer callback to auto unfreeze a player */
public Action:FT_AutoUnfreeze(Handle:timer, any:client)
{
	if (GetConVarBool(g_cvDebug))
		LogMessage("[FT_AutoUnfreeze] Activated for %N", client);
	if (g_hUnfreezeTimer[client] == timer) //if this timer wasn't killed/updated, let it do it's thing.
	{
		//Small hack to make sure FT_Unfreeze doesn't closehandle this timer while it's active
		g_hUnfreezeTimer[client] = INVALID_HANDLE;
		
		FT_Unfreeze(client);

		//PrintToChatAll("%c[FT]%c %N has been thawed!", cGreen, cDefault, client);
		if (GetConVarBool(g_cvLogging))
			LogAction(0, client, "\"%N\" has been thawed", client); 
		
		//If the settings say to send them back to spawn, do it.
		if (GetConVarBool(g_cvSendToSpawnOnAutoUnfreeze))
		{
			if (GetConVarBool(g_cvDebug))
				LogMessage("[FT_AutoUnfreeze] TF2_RespawnPlayer(%N)", client);
			TF2_RespawnPlayer(client);
		}
	}
	else if (GetConVarBool(g_cvDebug))
	{
		LogMessage("[FT_AutoUnfreeze] Timer Ignored.");
	}
}

/*	Clear frozen status and, if the client is still valid, cleans up effect */
FT_Unfreeze(client)
{
	if (!g_bFrozen[client])
		return;

	FT_ClearFrozenStatus(client);
	
	if (IsClientOnValidTeam(client))
	{
		if (GetConVarBool(g_cvLogging) || GetConVarBool(g_cvDebug))
			LogAction(0, client, "\"%N\" unfroze", client);

		new Float:vec[3];
		GetClientEyePosition(client, vec);
		EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);
	}
}

/*	Freezes specified client slot, then checks for a winning team. */
FT_Freeze(client)
{
	if (g_bFrozen[client] || !IsClientOnValidTeam(client) || !g_bFreezeTagEnabled)
		return;

	if (GetConVarBool(g_cvLogging) || GetConVarBool(g_cvDebug))
		LogAction(0, client, "\"%N\" froze", client); 
		
	g_bFrozen[client] = true;
	
	//in case we didn't previously save coordinates, do so here (if they suicided or admin froze them manually)
	GetClientAbsOrigin(client, g_fFreezeOrigin[client]);
	GetClientAbsAngles(client, g_fFreezeAngle[client]);
	
	if (GetConVarBool(g_cvDebug))
	{
		LogMessage("[FT_Freeze] Memorizing position (%f,%f,%f) and setting m_iHealth to 1", 
					g_fFreezeOrigin[client][0], g_fFreezeOrigin[client][1], g_fFreezeOrigin[client][2]);
	}
	SetEntProp(client, Prop_Data, "m_iHealth", 1);
	
	//"borrowed" from SM
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 192);

	StripToMelee(client);
	//TF2_RemoveAllWeapons(client); Civ-mode freezing. Don't know if want..
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);

	new Float:autounfreeze = GetConVarFloat(g_cvAutoUnfreeze);
	if (autounfreeze > 0.0)
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_Freeze] Adding timer FT_AutoUnfreeze for %.1f seconds", autounfreeze);
			
		g_hUnfreezeTimer[client] = CreateTimer(autounfreeze, FT_AutoUnfreeze, client);
		
		if (GetConVarBool(g_cvSendToSpawnOnAutoUnfreeze))
			PrintHintText(client, "You will be auto thawed and returned to spawn in %.1f seconds", autounfreeze);
		else
			PrintHintText(client, "You will be auto thawed in %.1f seconds", autounfreeze);
	}
		
	FT_CheckForWinner();
}

/*	Clean up frozen slots. Doesn't need a valid client at that slot. */
FT_ClearFrozenStatus(client)
{
	g_bFrozen[client] = false;
	g_bFreezeQueue[client] = false;
	
	//If we still have a linked timer, kill it
	if (g_hUnfreezeTimer[client] != INVALID_HANDLE)
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_ClearFrozenStatus] CloseHandle(Timer:%i)", client);
			
		CloseHandle(g_hUnfreezeTimer[client]);
		g_hUnfreezeTimer[client] = INVALID_HANDLE;
	}
	
	if (IsClientInGame(client))
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_ClearFrozenStatus] Resetting %N", client);
		
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderColor(client, 255, 255, 255, 255);

		//This also respawns them, thus repairing lost health
		RefreshWeapons(client);
			
		//If we're playing melee only, steal their weapons
		if (GetConVarBool(g_cvMeleeOnly))
			StripToMelee(client);
	}
}

// *********************************************************************************
// Event hooks
// *********************************************************************************

/*	Clear frozen status on a player and checks for a team win in case the  disconnected player was the last one unfrozen. */
public OnClientDisconnect(client)
{
	if (GetConVarBool(g_cvDebug))
		LogMessage("[OnClientDisconnect] %N", client);
		
	FT_ClearFrozenStatus(client);
	FT_CheckForWinner();
}

/*	If we're running freeze tag, tell them */
public OnClientPutInServer(client)
{
	if (GetConVarBool(g_cvDebug))
		LogMessage("[OnClientPutInServer] %N", client);
		
	if (g_bFreezeTagEnabled)
		DisplayRules(client);
	
	SDKHook(client, SDKHook_OnTakeDamage, FT_PrehookTakeDamage);
}

/*	If enabled, initialize a round of freeze tag. Also initialize anything we may require (sounds, graphics, whatev) */
public OnMapStart()
{
	if (GetConVarBool(g_cvDebug))
		LogMessage("[OnMapStart] Precaching Audio: %s", SOUND_FREEZE);
		
	PrecacheSound(SOUND_FREEZE, true);

	if (GetConVarBool(g_cvFreezeTagEnabled))
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[OnMapStart] Starting Freeze Tag");
			
		DisplayRules(-1);
		FT_Start();
	}
}

public OnMapEnd()
{
	FT_End();
}

/*	Toggle enabled state for freeze tag */
public FT_ConVarChangeEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(g_cvFreezeTagEnabled))
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_ConVarChangeEnabled] Starting Freeze Tag");
		DisplayRules(-1);
		FT_Start();
	}
	else
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_ConVarChangeEnabled] Ending Freeze Tag");
		FT_End();
	}
}

/*	Force all players to use a specific class. 0 to allow all to use any */
/*public FT_ConVarChangeForceClass(Handle:convar, const String:oldValue[], const String:newValue[])
{
	//TODO: This
}*/

/*	If enabled, strip all players of weapons. Else return weapons to stripped players (if they're not frozen) */
public FT_ConVarChangeMeleeOnly(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new bool:melee = GetConVarBool(g_cvMeleeOnly);
	
	if (GetConVarBool(g_cvDebug))
		LogMessage("[FT_ConVarChangeMeleeOnly] Melee Only Status set to %i", melee);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (melee)
		{
			StripToMelee(i);
		}
		else if (!g_bFrozen[i])
		{
			RefreshWeapons(i);
		}
	}

	//Don't allow resupply during melee mode, else it breaks everything
	ToggleResupply(!melee);
}

public Action:FT_CommandToggle(client, args)
{
	if (g_bFreezeTagEnabled)
	{
		PrintToChatAll("%c[FT]%c Freeze Tag has ended!", cGreen, cDefault);
		LogAction(client, -1, "%N has ended Freeze Tag", client);
		FT_End();
	}
	else
	{
		PrintToChatAll("%c[FT]%c Freeze Tag has begun!", cGreen, cDefault);
		LogAction(client, -1, "%N has started Freeze Tag", client);
		DisplayRules(-1);
		FT_Start();
	}
	return Plugin_Handled;
}

/*	Admin command to modify frozen status of individuals (or groups) for testing purposes.
		arg1: Target list
		ex: 	freezetag_freeze @me
			freezetag_unfreeze @me
*/
public Action:FT_CommandFreezeUnfreeze(client, args) 
{
	//Below code adapted from http://wiki.alliedmods.net/Introduction_to_SourceMod_Plugins

	if (!g_bFreezeTagEnabled)
	{
		ReplyToCommand(client, "FreezeTag is not enabled!");
		return Plugin_Handled;
	}
	
	decl String:cmd[32], String:arg1[32];
	GetCmdArg(0, cmd, sizeof(cmd));
	GetCmdArg(1, arg1, sizeof(arg1));

	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		if (strcmp(cmd, "freezetag_freeze"))
		{
			FT_Freeze(target_list[i]);
			LogAction(client, target_list[i], "\"%L\" froze \"%L\"", client, target_list[i]);
		}
		else
		{
			FT_Freeze(target_list[i]);
			LogAction(client, target_list[i], "\"%L\" unfroze \"%L\"", client, target_list[i]);
		}
	}
 
	if (tn_is_ml)
	{
		if (strcmp(cmd, "freezetag_freeze"))
			ShowActivity2(client, "[FT] ", "Froze %t!", target_name);
		else
			ShowActivity2(client, "[FT] ", "Unfroze %t!", target_name);
	}
	else
	{
		if (strcmp(cmd, "freezetag_freeze"))
			ShowActivity2(client, "[FT] ", "Froze %s!", target_name);
		else
			ShowActivity2(client, "[FT] ", "Unfroze %s!", target_name);
	}
 
	return Plugin_Handled;
}

/*	Let the winners of the freeze tag match crit all over the place */
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (g_bIsHumiliationRound && g_iHumiliationRoundWinners == GetClientTeam(client))
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[TF2_CalcIsAttackCritical] Will be crit (Humiliation)");
	
		result = true;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/*	Make sure we reset things at the end of a round */
public FT_HookRoundEnd(Handle:invalid, const String:name[], bool:dontBroadcast) 
{
	if (GetConVarBool(g_cvDebug))
		LogMessage("[FT_HookRoundEnd] Ending Freeze Tag");
	FT_End();
}

/*	If the client is frozen, warp them back to their original location and lock movement. If they're queued to be frozen, warp back and freeze them. */
public FT_HookSpawn(Handle:event, const String:name[], bool:dontBroadcast) //doneish
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsClientOnValidTeam(client)) //Can this even happen?
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_HookSpawn] Index %i on invalid team", client);
		return;
	}
	
	if (GetConVarBool(g_cvMeleeOnly))
	{
		StripToMelee(client);
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_HookSpawn] Stripping %N of weapons", client);
	}
	
	if (g_bFreezeTagEnabled)
	{
		//force them back to their frozen position and lock movement
		if (g_bFrozen[client])
		{
			if (GetConVarBool(g_cvDebug))
				LogMessage("[FT_HookSpawn] %N is frozen. Teleporting and stripping", client);
			TeleportEntity(client, g_fFreezeOrigin[client], g_fFreezeAngle[client], NULL_VECTOR);
			SetEntityMoveType(client, MOVETYPE_NONE);
			SetEntProp(client, Prop_Data, "m_iHealth", 1);
			StripToMelee(client);
		}
		else if (g_bFreezeQueue[client]) //need to initialize a freeze on this player
		{
			if (GetConVarBool(g_cvDebug))
				LogMessage("[FT_HookSpawn] %N queued to freeze. Teleporting and freezing", client);
			TeleportEntity(client, g_fFreezeOrigin[client], g_fFreezeAngle[client], NULL_VECTOR);
			FT_Freeze(client);
			g_bFreezeQueue[client] = false;
		}
		
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_HookSpawn] Deleting ragdoll for %N", client);
		RemoveRagdoll(client);
	}
	
}

/*	Anyone who dies will be frozen. This'll tell the system to freeze them at respawn */
public FT_HookDeath(Handle:event, const String:name[], bool:dontBroadcast) //TEMP: Only for testing purposes
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	decl String:n[MAX_NAME_LENGTH];
	GetClientName(client, n, sizeof(n));

	//LogMessage("\"%N\" Death %f,%f,%f", client, g_fFreezeOrigin[client][0], g_fFreezeOrigin[client][1], g_fFreezeOrigin[client][2]);
	
	if (g_bFreezeTagEnabled && !g_bIsHumiliationRound)
	{
		if (!attacker) //not a player, let them respawn and unfreeze...
		{
			FT_ClearFrozenStatus(client); 
			if (GetConVarBool(g_cvLogging) || GetConVarBool(g_cvDebug))
				LogAction(0, client, "\"%N\" thawed by nonclient", client);
		}
		else
		{
			if (IsClientOnValidTeam(attacker) && attacker != client) //Make sure they don't freeze by falling off a cliff or getting hit by a train. Or changing class
			{
				g_bFreezeQueue[client] = true;
				if (GetConVarBool(g_cvLogging) || GetConVarBool(g_cvDebug))
					LogAction(attacker, client, "\"%N\" froze \"%N\"", attacker, client);
			}
			else
			{
				if (GetConVarBool(g_cvDebug))
					LogMessage("[FT_HookDeath] %N died of natural causes", client);
			}
			
			if (GetConVarBool(g_cvDebug))
				LogMessage("[FT_HookDeath] Setting Instant Respawn, triggered by %N", client);
			SetInstantRespawnTime(); //Have to do this since TF_GameRules likes to change during rounds and map changes (Points capped, etc)
			CreateTimer(0.0, SpawnPlayerTimer, client, TIMER_FLAG_NO_MAPCHANGE); //Respawn the player at the specified time
		}
	}
	else if (g_bIsHumiliationRound)
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_HookDeath] Clearing frozen and allowing death for %N (Humiliation)", client);
		FT_ClearFrozenStatus(client);
		//TODO: Awesome explosive death.
	}
	else
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_HookDeath] Ignored death for %N", client);
	}
}

/*	If the client is going to die (0 health), save their coordinates because we're about to freeze them. 
	TODO: Can't this be imported into the takedamage prehook?
		ALSO, if health is zero here, can we increase their health back up and prevent death? (This can help remove the need for dukehacks)
*/
public FT_HookHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetEventInt(event, "health") == 0 && g_bFreezeTagEnabled && !g_bIsHumiliationRound) //we died, save coordinates
	{
		GetClientAbsOrigin(client, g_fFreezeOrigin[client]);
		GetClientAbsAngles(client, g_fFreezeAngle[client]);
		
		if (GetConVarBool(g_cvDebug))
		{
			LogMessage("[FT_HookHurt] %N will die. Position memorized (%f,%f,%f)", client, 
					g_fFreezeOrigin[client][0], g_fFreezeOrigin[client][1], g_fFreezeOrigin[client][2]);
		}
	}
	else if (GetConVarBool(g_cvDebug))
	{
		LogMessage("[FT_HookHurt] %N Hurt. Remaining HP: %i", client, GetEventInt(event, "health"));
	}
}

/*	 If a frozen client is being healed by a medic, and reaches peak hp, thaw them. */
public FT_HookMedicHeal(Handle:event, const String:name[], bool:dontBroadcast)
{
	LogMessage("[FT_HookMedicHeal]");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new healer = GetClientOfUserId(GetEventInt(event, "medic"));
	if (g_bFrozen[client])
	{
		if ( GetClientHealth(client) >= GetClientMaxHealth(client) )
		{
			FT_Unfreeze(client);
			if (GetConVarBool(g_cvLogging) || GetConVarBool(g_cvDebug))
				LogAction(healer, client, "\"%N\" unfroze \"%N\"", healer, client);
		}
	}
}

/*	If victim is frozen, prevent attacks from enemies. 
	If victim is attacked by a teammate, heal and check to see if he should unfreeze.
*/
public Action:FT_PrehookTakeDamage(victim, &attacker, &inflictor, &Float:dmg, &damagetype) //done
{
	if (GetConVarBool(g_cvDebug))
		LogMessage("[FT_PrehookTakeDamage] Victim: %N for dmg: %.1f", victim, dmg);
		
	if (!g_bFreezeTagEnabled)
		return Plugin_Continue;

	//Attacked by something else, let them die.
	if (!IsClientOnValidTeam(attacker))
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_PrehookTakeDamage] Attacker on invalid team");
		return Plugin_Continue;
	}
		
	//don't let players hurt themselves during humiliation (So losers can't escape the torture..)
	if (attacker == victim && g_bIsHumiliationRound)
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_PrehookTakeDamage] Attacked self during humiliation. No damage");
		dmg = 0.0;
		return Plugin_Changed;
	}
	
	//don't allow them to do anything to frozen players... unless it's the mini humiliation round :D
	if (GetClientTeam(attacker) != GetClientTeam(victim))
	{
		if (g_bFrozen[victim] && !g_bIsHumiliationRound)
		{
			if (GetConVarBool(g_cvDebug))
				LogMessage("[FT_PrehookTakeDamage] Attempted to attack frozen client. Ignored. (Attacker: %N)", attacker);
				
			dmg = 0.0;
			return Plugin_Changed;
		}
		else
		{
			if (GetConVarBool(g_cvDebug))
				LogMessage("[FT_PrehookTakeDamage] Dealing damage normally (Attacker: %N)", attacker);
				
			return Plugin_Continue;
		}
	}
	
	//same team, heal up (if frozen and not during humiliation)
	if (attacker != victim) 
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_PrehookTakeDamage] Teammate attacker. (Attacker: %N)", attacker);
			
		if (g_bFrozen[victim] && !g_bIsHumiliationRound)
		{
			if (GetConVarBool(g_cvDebug))
				LogMessage("[FT_PrehookTakeDamage] Attempting to thaw victim", attacker);
			new Float:multiplier = GetConVarFloat(g_cvUnfreezeMultiplier);
			if (multiplier > 0.0)
			{
				//Heal up by the multiplier
				new adjustedHealth = GetClientHealth(victim) + RoundToCeil(dmg * multiplier);
				new maxHealth = GetClientMaxHealth(victim);
				if (adjustedHealth < maxHealth)
				{
					if (GetConVarBool(g_cvDebug))
						LogMessage("[FT_PrehookTakeDamage] Adjusting victim health to %i", adjustedHealth);
						
					SetEntProp(victim, Prop_Data, "m_iHealth", adjustedHealth);
				}
				else
				{
					if (GetConVarBool(g_cvDebug))
						LogMessage("[FT_PrehookTakeDamage] Unfreezing victim");
						
					FT_Unfreeze(victim);
					if (GetConVarBool(g_cvLogging) || GetConVarBool(g_cvDebug))
						LogAction(attacker, victim, "\"%N\" unfroze \"%N\"", attacker, victim);
				}
			}
		}
		else if (GetConVarBool(g_cvDebug))
		{
			LogMessage("[FT_PrehookTakeDamage] Victim not frozen or it's humiliation time.", attacker);
		}

		dmg = 0.0;
		return Plugin_Changed;
	}

	//They were harmed some other way (rocketed themselves or something during freeze tag) Just let it happen
	return Plugin_Continue;
}

// *********************************************************************************
// Humiliation round functions
// *********************************************************************************

/*	If a team is successful at freezing the entire opposing team, and the humiliation round is enabled, humiliation round will start. */
FT_CheckForWinner() 
{
	if (g_bIsHumiliationRound || GetConVarFloat(g_cvHumiliationRoundDuration) == 0.0) //can't win while already in humiliation, silly
		return;

	new redStillActive = 0;
	new bluStillActive = 0;

	if (GetConVarBool(g_cvDebug))
		LogMessage("[FT_CheckForWinner] Scanning for unfrozen clients");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientOnValidTeam(i) && !g_bFrozen[i])
		{
			switch (GetClientTeam(i))
			{
				case BLU_TEAM:
					bluStillActive = 1;
				case RED_TEAM:
					redStillActive = 1;
			}
			//avoid unnecessary tests
			if (redStillActive && bluStillActive)
				break;
		}
	}
	
	if (!redStillActive)
		FT_StartHumiliationRound(BLU_TEAM);
	else if (!bluStillActive)
		FT_StartHumiliationRound(RED_TEAM);
}

/*	Timer callback to end the humiliation round */
public Action:FT_TimerEndHumiliation(Handle:timer, any:client)
{
	if (g_bIsHumiliationRound && g_bFreezeTagEnabled)
	{
		decl String:message[128];
		Format(message, sizeof(message), "%c[FT]%c Mini humiliation round has ended!", cGreen, cDefault);
		PrintToChatAll(message);
		
		if (GetConVarBool(g_cvLogging) || GetConVarBool(g_cvDebug))
			LogMessage(message);
			
		FT_EndHumiliationRound();
	}
	else if (GetConVarBool(g_cvDebug))
	{
		LogMessage("[FT_TimerEndHumiliation] Ignoring timer");
	}	
}

/*	Unfreezes all players of the winning team, kills auto unfreeze timers of all the losers (so they can't unfreeze during humiliation)
	and adds a timer to stop the humiliation round 
*/
FT_StartHumiliationRound(winningTeam)
{
	g_bIsHumiliationRound = true;
	g_iHumiliationRoundWinners = winningTeam;
	
	decl String:message[128];
	Format(message, sizeof(message), "%c[FT]%c %s Team wins this round of freeze tag!", cGreen, cDefault, (winningTeam == RED_TEAM) ? "RED" : "BLU");
	PrintToChatAll(message);
	
	if (GetConVarBool(g_cvLogging) || GetConVarBool(g_cvDebug))
		LogMessage(message);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		//Unfreeze members of the winning team to allow some griefing
		if (g_bFrozen[i] && IsClientOnValidTeam(i))
		{
			if (GetClientTeam(i) == winningTeam)
			{
				FT_Unfreeze(i);
			}
			else if (g_hUnfreezeTimer[i] != INVALID_HANDLE) 
			{
				//Don't let them auto unfreeze during humiliation round
				CloseHandle(g_hUnfreezeTimer[i]);
				g_hUnfreezeTimer[i] = INVALID_HANDLE;
			}
		}
	}
	
	//If this round is 0 seconds (disabled), hop right to finishing it. Otherwise, wait.
	new Float:duration = GetConVarFloat(g_cvHumiliationRoundDuration);

	PrintToChatAll("%c[FT]%c %s Team gets %.1f seconds to humiliate the losers! Have at it!", 
					cGreen, cDefault, (winningTeam == RED_TEAM) ? "RED" : "BLU", duration);

	if (GetConVarBool(g_cvLogging) || GetConVarBool(g_cvDebug))
		LogMessage("[FT_StartHumiliationRound] Humiliation round will last for %.1f seconds", duration);
					
	CreateTimer(duration, FT_TimerEndHumiliation, winningTeam);
}

/*	Unfreeze and respawn losers. If we are to keep playing freeze tag, start a new round. Otherwise end it */
FT_EndHumiliationRound()
{
	PrintToChatAll("%c[FT]%c Losers have been thawed and respawned!", cGreen, cDefault);
	
	if (GetConVarBool(g_cvLogging) || GetConVarBool(g_cvDebug))
		LogMessage("Humiliation round has ended. Losers thawed and respawned");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_bFrozen[i])
		{
			FT_ClearFrozenStatus(i);
			TF2_RespawnPlayer(i);
		}
	}
	
	g_bIsHumiliationRound = false;

	if (GetConVarBool(g_cvPersistentFreezeTag)) //restart the mode
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_EndHumiliationRound] Restarting FT");
		FT_Start();
	}
	else
	{
		if (GetConVarBool(g_cvDebug))
			LogMessage("[FT_EndHumiliationRound] Ending FT");
			
		FT_End();
	}
}

// *********************************************************************************
// Other generic functions
// *********************************************************************************

/*	Returns true if the client is actively playing on RED or BLU */
stock bool:IsClientOnValidTeam(client)
{
	//TODO: Might have too many checks here. What is (not) necessary?
	if (!IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
		return false;

	new team = GetClientTeam(client);
	return (team == BLU_TEAM || team == RED_TEAM);
}

/*	Deletes all weapon slots except for melee for the specified client */
stock StripToMelee(client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client)) 
	{
		for (new i = 0; i <= 5; i++)
		{
			if (i != 2)
				TF2_RemoveWeaponSlot(client, i);
		}
		
		new weapon = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

/*	Returns all weapons with full ammo back to the client. 
	This function requires a hack due to broken functionality */
stock RefreshWeapons(client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		// TF2_EquipPlayerClassWeapons() is broken, so respawn and teleport.
		new Float:origin[3];
		GetClientAbsOrigin(client, origin);
		new Float:angles[3];
		GetClientAbsAngles(client, angles);
		TF2_RespawnPlayer(client);
		TeleportEntity(client, origin, angles, NULL_VECTOR);
	}
}

/*	Returns default health for the specified client */
stock GetClientMaxHealth(client)
{
	return GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

/*	Enables/Disables resupply lockers. */
stock ToggleResupply(bool:enable) 
{
	new search = -1;
	while ((search = FindEntityByClassname(search, "func_regenerate")) != -1)
		AcceptEntityInput( search, ((enable) ? "Enable" : "Disable") );
}

/*	Delete the ragdoll of the specific client. Good for situations where we want to leave no evidence of death */
stock RemoveRagdoll(client)
{
	decl String:classname[64];

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (IsValidEdict(ragdoll))
	{
		GetEdictClassname(ragdoll, classname, sizeof(classname)); 

		if (StrEqual(classname, "tf_ragdoll", false)) 
			RemoveEdict(ragdoll);
	}
	//TODO: remove weapon drops?
}

stock SetInstantRespawnTime() //From TF2 Respawn by WoZeR
{
	new gamerules = FindEntityByClassname(-1, "tf_gamerules");
	if (gamerules != -1)
	{
		SetVariantFloat(0.0);
		AcceptEntityInput(gamerules, "SetRedTeamRespawnWaveTime", -1, -1, 0);
		SetVariantFloat(0.0);
		AcceptEntityInput(gamerules, "SetBlueTeamRespawnWaveTime", -1, -1, 0);
	}
}

public Action:SpawnPlayerTimer(Handle:timer, any:client) //From TF2 Respawn by WoZeR
{
     //Respawn the player if he is in game and is dead.
     if (IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client))
     {
          new PlayerTeam = GetClientTeam(client);
          if ( (PlayerTeam == RED_TEAM) || (PlayerTeam == BLU_TEAM) )
          {
               TF2_RespawnPlayer(client);
          }
     }
     return Plugin_Continue;
} 


