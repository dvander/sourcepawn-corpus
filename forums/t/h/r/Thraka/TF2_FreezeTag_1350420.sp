/*
 *
 * Version 0.9.6
 * - Seperate damage modifiers for heal and kill
 * - Add setting for % of health you gain on thaw
 * - Add option to save uber charge value and restore when thawed
 * - Fixed spy dead ringer 
 * 
 * Version 0.9.7
 * - Fixed the medic heal amount being saved
 * - Prevent kill command when frozen
 * - Add setting to allow\disallow class change while frozen (not used yet)
 * 
 * Version 0.9.7.1
 * - Testing FL_NOTARGET flags to remove turrent targetting from frozen players.
 * 
 * Version 0.9.7.2
 * - Restructured plugin. Will be on bug hunt now...
 * - Slightly changed on damage and the freeze\thaw timers and functions.
 * - File name is now TF2_FreezeTag
 * - New CVAR: ft_frozen_health_mod
 * 
 * Version 0.9.7.3
 * - Set thaw on players when plugin disabled
 * - Turn ff off when plugin disabled
 * 
 * Version 0.9.7.4
 * - Merged all convar changed hooks into a single callback
 * - FL_NOTARGET doesn't work. Removing and replacing with an invisible model.
 * - Added the turrent block and remove turret block methods which are called during freeze and thaw. Solved turret targetting issue.
 * 
 * ==================================
 * TODO:
 * ==================================
 * X Start of plugin, capture the FF setting, enable FF. When unloaded, restore FF setting.
 * 		If the heal players isn't on, don't worry about it
 * X Prevent FF from working at end of round.
 * X Thaw winning team when end of round.
 * X When thawed, you're immune for X seconds
 * - Spies shouldn't delete the ragdoll body
 * - Test heavy effects when frozen. Noticed they can punch.
 * - Tell connected players the intro msg
 * - Investigate the code trail (events) taken when player changes class while frozen, fix any exploits.
 * - Add game mode of thaw via players near
 *		- Configurable range
 * 		- Configurable amount of friendlies near to start a thaw
 * 		- Configurable duration of thaw 
 * 		- Toggle enemy near stops thaw 
 * 		- Configurable enemy near to stop range
 * 		NOTE: TE_SetupBeamRingPoint(location,10.0,500.0,orange,g_HaloSprite,0,10,0.6,10.0,0.5,color,10,0);
 * 		NOTE: TE_SendToAll();
 * - Investigate sprite attach (like donator plugin) for frozen players
 * 		- Add sprite for what friendly ppl see "Shoot me to thaw!"
 * 		- Add sprite for what enemey ppl see "Finish him!"
 * 		- Optionally, display a countdown sprite 30 down to 0 (something like that) that all players see.
 * 		- Annotation system may be too costly.
 * - Attachable ice model
 * 		- Always been my vision to have people actually be surrounded by an ice block.
 * 		- Model must have flags to NOT block damage	
 * 
 * 


This is the event path taken for changing a class. Use when implementing class change while frozen
 
suicide after class change
CLASS
DEATH
SPAWN

non-suicide after class change
CLASS

change class in respawn
CLASS
SPAWN 
*/ 



/// =================================================================
/// Includes
/// =================================================================
#include <tf2>
#include <tf2_stocks>
#include <sourcemod>
#include <sdkhooks>
#include <colors>
#include <sdktools_functions>


/// =================================================================
/// Defines
/// =================================================================
#define PLUGIN_VERSION	"0.9.7.4"

#define SOUND_FREEZE	"physics/glass/glass_largesheet_break3.wav"
#define SOUND_UNFREEZE	"physics/flesh/flesh_squishy_impact_hard2.wav"

#define MODEL_FROZEN	"models/egypt/pillar/pillar_medium.mdl"

#define FREEZE_STATE 	TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT
#define RED_TEAM 2
#define BLU_TEAM 3

/// =================================================================
/// Plugin Info
/// =================================================================
public Plugin:myinfo = 
{
	name = "Freeze Tag",
	author = "Thraka",
	description = "Freeze Tag",
	version = PLUGIN_VERSION,
	url = ""
}

/// =================================================================
/// CVARs
/// =================================================================
new Handle:cvar_ft_enabled = INVALID_HANDLE;
new Handle:cvar_ft_thawDuration = INVALID_HANDLE;
new Handle:cvar_ft_frozenDmgMod_heal = INVALID_HANDLE;
new Handle:cvar_ft_frozenDmgMod_kill = INVALID_HANDLE;
new Handle:cvar_ft_autothawrespawn = INVALID_HANDLE;
new Handle:cvar_ft_canenemykillfrozen = INVALID_HANDLE;
new Handle:cvar_ft_canfriendlyhealfrozen = INVALID_HANDLE;
new Handle:cvar_ft_endroundonallfrozen = INVALID_HANDLE;
new Handle:cvar_ft_thawimmunitytime = INVALID_HANDLE;
new Handle:cvar_ft_thawimmunecanfire = INVALID_HANDLE;
new Handle:cvar_ft_thawedNewHealthMod = INVALID_HANDLE;
new Handle:cvar_ft_frozenNewHealthMod = INVALID_HANDLE;
new Handle:cvar_ft_medicSavesUberCharge = INVALID_HANDLE;
new Handle:cvar_ft_allowClassChangeFrozen = INVALID_HANDLE;


// Values
new bool:CFG_IsFreezeEnabled = true;
new CFG_ThawDuration = 15;
new Float:CFG_FrozenDamageModHeal = 0.6;
new Float:CFG_FrozenDamageModKill = 0.3;
new bool:CFG_EnemeyCanKillFrozen = true;
new bool:CFG_FriendlyCanHealFrozen = true;
new bool:CFG_RespawnOnAutoThaw = false;
new bool:CFG_EndRoundOnAllFrozen = false;
new Float:CFG_ThawedHealthMod = 1.0;
new Float:CFG_FrozenHealthMod = 0.5;
new bool:CFG_CanFireWhileImmune = false;
new bool:CFG_MedicSavesUberWhenFrozen = true;
new bool:CFG_AllowClassChangeWhenFrozen = false;
new Float:CFG_ThawImmuneTime = 2.0;


/// =================================================================
/// Player Data Specific
/// =================================================================
new bool:Player_IsHooked[MAXPLAYERS+1];
new bool:Player_IsFrozen[MAXPLAYERS+1];
new bool:Player_IsThawImmune[MAXPLAYERS+1];
new bool:Player_FreezeMeOnSpawn[MAXPLAYERS+1];
new Float:Player_FrozenOrigin[MAXPLAYERS+1][3];
new Float:Player_FrozenAngle[MAXPLAYERS+1][3];
new Handle:Player_FrozenTimerHandle[MAXPLAYERS+1] = {INVALID_HANDLE, ... };
new Player_FrozenTimerCountLeft[MAXPLAYERS+1];
new Player_MedicUberValue[MAXPLAYERS+1];
new Player_BlockingModel[MAXPLAYERS+1] = {-1, ...};


/// =================================================================
/// Misc Trackers
/// =================================================================
new bool:IsRoundEnd;






/// =================================================================
/// Mod Logic Related
/// =================================================================
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CFG_IsFreezeEnabled)
	{
		SetInstantRespawnTime();
		
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (Player_FreezeMeOnSpawn[client])
		{
			RemoveRagdoll(client);
			TeleportEntity(client, Player_FrozenOrigin[client], Player_FrozenAngle[client], NULL_VECTOR);
			CreateTimer(0.1, Timer_FreezePlayerTimer, client, TIMER_FLAG_NO_MAPCHANGE); 
		}
		else
		{
			Player_MedicUberValue[client] = 0;
			ThawPlayer(client);
			RemoveThawImmunity(client);
			//OriginalClass[client] = TF2_GetPlayerClass(client);
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (CFG_IsFreezeEnabled == false)
		return Plugin_Continue;
	
	new clientHealth = GetClientHealth(victim);
	new clientMaxHealth = GetClientMaxHealth(victim);
	new bool:worldKill = attacker == 0;
	new bool:sameTeam;
	
	if (!worldKill)
		sameTeam = GetClientTeam(attacker) == GetClientTeam(victim);
	
	// Player isn't frozen and is going to take damage
	if (Player_IsFrozen[victim] == false)
	{
		// Damage types we're not allowing
		if ((sameTeam && victim != attacker) 	// FF attacked
			|| Player_IsFrozen[attacker] 		// Attacker is hurting player
			|| Player_IsThawImmune[victim] 		// Player is immune because of thaw
			|| Player_FreezeMeOnSpawn[victim])	// Player is slated for respawn-freeze
				return Plugin_Handled;
		
		// Store the players location for later respawn if they die
		GetClientAbsOrigin(victim, Player_FrozenOrigin[victim]);
		GetClientAbsAngles(victim, Player_FrozenAngle[victim]);
		
		// Store the uber charge value if they have one
		if (TF2_GetPlayerClass(victim) == TFClass_Medic)
			Player_MedicUberValue[victim] =  TF2_GetUberLevel(victim); 
		
		// Allow the game to process the damage
		return Plugin_Continue;
	}
	else	// Player is frozen
	{
		// World or self inflicted and we're frozen, so skip
		if (victim == attacker || attacker == 0)
			return Plugin_Handled;
		
		// End of the round, let the damage commence unless same team!
		if (IsRoundEnd)
		{
			if (sameTeam)
				return Plugin_Handled;
			else
				return Plugin_Continue;
		}
		
		// Same team and can heal
		if (sameTeam && CFG_FriendlyCanHealFrozen)
		{
			new roundedDmg = RoundToNearest(damage * CFG_FrozenDamageModHeal);
			
			// lets heal them or thaw them
			if (clientHealth + roundedDmg > clientMaxHealth)
				ThawPlayer(victim);
			else
				SetEntityHealth(victim, clientHealth + roundedDmg);
			
			return Plugin_Handled;
		}
		else if (!sameTeam && CFG_EnemeyCanKillFrozen)
		{
			new roundedDmg = RoundToNearest(damage * CFG_FrozenDamageModKill);
			
			// Kill the player off if they wen't to 0, otherwise apply simple damage
			if (clientHealth - roundedDmg <= 0)
				ForcePlayerSuicide(victim);
			else
				SetEntityHealth(victim, clientHealth - roundedDmg);
			
			return Plugin_Handled;
		}

		return Plugin_Handled;
	}
	
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CFG_IsFreezeEnabled)
	{
		//if ((GetEventInt(event, "weaponid") == TF_WEAPON_BAT_FISH && GetEventInt(event, "customkill") != TF_CUSTOM_FISH_KILL) || (GetEventInt(event, "death_flags") & 32))
		if (GetEventInt(event, "death_flags") & 32)
			return;
			
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		// only process players who didn't die of self or world. Also, they must not be frozen.
		if (attacker != 0 && attacker != client && Player_IsFrozen[client] == false && !IsRoundEnd)
		{
			Player_FreezeMeOnSpawn[client] = true;
			SetInstantRespawnTime(); //Have to do this since TF_GameRules likes to change during rounds and map changes (Points capped, etc)
			CreateTimer(0.0, Timer_InstantSpawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE); //Respawn the player at the specified time
		}
		else if (Player_IsFrozen[client])
		{
			KillThawTimer(client);
		}
	}
}

public OnPreThink(client)
{
	if (Player_IsFrozen[client] || (Player_IsThawImmune[client] && CFG_CanFireWhileImmune == false))
	{
		new iButtons = GetClientButtons(client);
		new bool:flagged = false;
		
		if (iButtons & IN_ATTACK2)
		{
			iButtons &= ~IN_ATTACK2;
			flagged = true;
		}
		
		if (iButtons & IN_ATTACK)
		{
			iButtons &= ~IN_ATTACK;
			flagged = true;
		}
		
		if (flagged)
			SetEntProp(client, Prop_Data, "m_nButtons", iButtons);
	}
}

public Action:Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CFG_IsFreezeEnabled)
	{
		IsRoundEnd = true;
		
		new team = GetEventInt(event, "team");
		
		for (new client = 1; client <= MaxClients; client++)
		{
			
			if (IsClientConnected(client) && IsClientInGame(client))
			{
				if (GetClientTeam(client) != team)
					FreezePlayer(client);
				else
					ThawPlayer(client);
			}
		}
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CFG_IsFreezeEnabled)
	{
		IsRoundEnd = false;

		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientConnected(client) && IsClientInGame(client))
			{
				ThawPlayer(client);
			}
		}
	}
}

public Action:Timer_FreezePlayerTimer(Handle:timer, any:client)
{
    if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
    {
        FreezePlayer(client);
    }
    return Plugin_Continue;
}

public Action:Timer_FrozenPlayerCountdown(Handle:timer, any:client)
{
	if (Player_FrozenTimerHandle[client] != INVALID_HANDLE)
	{	
		//FrozenPlayerTimers[client] = INVALID_HANDLE;
		//SetEntityRenderColor(player, 0, 128, 255, 192);
		if (Player_FrozenTimerCountLeft[client] == 0)
		{
			KillThawTimer(client);
			ThawPlayer(client, false);
		}
		else
		{
			Player_FrozenTimerCountLeft[client]--;
			
		}
	}
}

public Action:Timer_ThawImmunityEnded(Handle:timer, any:client)
{
	//Respawn the player if he is in game and is dead.
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		RemoveThawImmunity(client);
	}
	return Plugin_Continue;
}

/// =================================================================
/// Mod Functions
/// =================================================================
bool:FreezePlayer(player)
{
	if (player == 0)
		return false;
	
	if (IsClientInGame(player) && IsPlayerAlive(player) && Player_IsFrozen[player] == false)
	{
		TF2_RemovePlayerDisguise(player);
		TF2_StunPlayer(player, 100.0, 1.0, FREEZE_STATE);
		
		if (TF2_GetPlayerClass(player) == TFClass_Medic && CFG_MedicSavesUberWhenFrozen && Player_MedicUberValue[player] != 0)
			TF2_SetUberLevel(player, Player_MedicUberValue[player]); 
		
		Player_IsFrozen[player] = true;
		
		// We only get to frozen if we spawned (or a cmd was used) so we can safely clear the flag.
		Player_FreezeMeOnSpawn[player] = false;
		
		// If we're not at the end of the round, create a timer for unthawing.
		if (!IsRoundEnd)
		{
			CreateThawTimer(player);
			TellPlayerFrozen(player);
		}
		
		// Set the player's frozen health starting value
		SetEntityHealth(player, RoundToNearest(GetClientMaxHealth(player) * CFG_FrozenHealthMod));
		
		// Add the flag for it being a target of turrets
		CreateTurretBlocker(player);
		
		// Play the freeze sound, set the characters color, and attach the model (TODO)
		new Float:vec[3];
		GetClientEyePosition(player, vec);
		EmitAmbientSound(SOUND_FREEZE, vec, player);
		SetEntityRenderColor(player, 122, 246, 255, 192);
		
		if (!IsRoundEnd && CFG_EndRoundOnAllFrozen)
			CheckForWinningTeam();
		
		return true;
	}
	else
		return false;
}

bool:ThawPlayer(player, bool:justClearingFlags = false)
{
	if (player == 0)
		return false;
	
	if (IsClientInGame(player) && IsPlayerAlive(player) && (Player_IsFrozen[player] || justClearingFlags))
	{
		Player_IsFrozen[player] = false;
		Player_FreezeMeOnSpawn[player] = false;
		
		// Clear stun and colors
		TF2_StunPlayer(player, 0.0, 0.0, FREEZE_STATE);
		SetEntityRenderColor(player, 255, 255, 255, 255);
		
		// Store health for reusage
		//new currentHealth = GetClientHealth(player);
		
		// Regenerate the players ammo and health
		//TF2_RegeneratePlayer(player);
		
		// Clear the flag that lets a turret target them.	
		RemoveTurretBlocker(player);
		
		// We're thawed, kill any timers still running
		KillThawTimer(player)
		
		if (!justClearingFlags)
		{
			// Player unfrozen sound
			new Float:vec[3];
			GetClientEyePosition(player, vec);
			EmitAmbientSound(SOUND_UNFREEZE, vec, player);
			
			if (CFG_RespawnOnAutoThaw)
				TF2_RespawnPlayer(player);
			else
			{
				SetEntityHealth(player, RoundToNearest(GetClientMaxHealth(player) * CFG_ThawedHealthMod));
				GivePlayerThawImmunity(player);
			}
		}
		return true;
	}
	else
	{
		// Player wasn't frozen and we need to unfreeze them. Or they were frozen but not alive some how.
		// Either way, we need to clear flags
		KillThawTimer(player)
		Player_IsFrozen[player] = false;
		Player_FreezeMeOnSpawn[player] = false;
		
		return false;
	}
}


CreateTurretBlocker(player)
{
	// Saftey, remove it if it existed
	RemoveTurretBlocker(player);
	
	new entity = CreateEntityByName("prop_dynamic");

	if (entity != -1)
	{
		Player_BlockingModel[player] = entity;
		
		//cache model if necesary
		if (!IsModelPrecached(MODEL_FROZEN))
		{
			if(!PrecacheModel(MODEL_FROZEN))
			{
				return;
			}
		}
		
		DispatchKeyValue(entity, "model", MODEL_FROZEN);
		DispatchKeyValue(entity, "solid", "6");
		DispatchSpawn(entity);
		
		
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
		
		AcceptEntityInput(entity, "DisableShadow");
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 255, 255, 0);
		
		TeleportEntity(entity, Player_FrozenOrigin[player], Player_FrozenAngle[player], NULL_VECTOR);
		
		new String:szTemp[64]; 
		Format(szTemp, sizeof(szTemp), "client%i", player);
		DispatchKeyValue(player, "targetname", szTemp);
		DispatchKeyValue(entity, "parentname", szTemp);

		SetVariantString(szTemp);
		AcceptEntityInput(entity, "SetParent", entity, entity, 0);
	}
}

RemoveTurretBlocker(player)
{
	if (IsValidEntity(Player_BlockingModel[player]))
	{
		RemoveEdict(Player_BlockingModel[player]);
	}
}

RemoveThawImmunity(player)
{
	if (player == 0)
		return;
	
	if (IsClientInGame(player) && IsPlayerAlive(player))
	{
		Player_IsThawImmune[player] = false;
		SetEntityRenderFx(player, RENDERFX_NONE);
	}
}

GivePlayerThawImmunity(player)
{
	if (player == 0)
		return;
	
	if (IsClientInGame(player) && IsPlayerAlive(player) && CFG_ThawImmuneTime > 0.0 && CFG_RespawnOnAutoThaw == false)
	{
		Player_IsThawImmune[player] = true;
		
		// End the immune time period
		CreateTimer(CFG_ThawImmuneTime, Timer_ThawImmunityEnded, player);
		
		// Configure the graphics
		SetEntityRenderFx(player, RENDERFX_HOLOGRAM);
	}
}

CheckForWinningTeam()
{
	new bluFrozen = 0;
	new redFrozen = 0;
	new bluFound = 0;
	new redFound = 0;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		
		if (IsClientConnected(client) && IsClientInGame(client))
		{
			new PlayerTeam = GetClientTeam(client);
			
			if (PlayerTeam == BLU_TEAM)
			{
				bluFound++;
				if (Player_IsFrozen[client])
					bluFrozen++;
			}
			else if (PlayerTeam == RED_TEAM)
			{
				redFound++;
				if (Player_IsFrozen[client])
					redFrozen++;
				
			}
		}
	}
	
	
	if (bluFound > 0 && redFound > 0)
	{
		if (redFound == redFrozen)
			ForceTeamWin(TFTeam_Blue);
		else if (bluFound == bluFrozen)
			ForceTeamWin(TFTeam_Red);
	}
}

KillThawTimer(client)
{
	if (Player_FrozenTimerHandle[client] != INVALID_HANDLE)
	{
		KillTimer(Player_FrozenTimerHandle[client]);
		Player_FrozenTimerHandle[client] = INVALID_HANDLE;
		Player_FrozenTimerCountLeft[client] = 0;
	}
}

CreateThawTimer(client)
{
	if (Player_FrozenTimerHandle[client] == INVALID_HANDLE && CFG_ThawDuration != 0)
	{
		Player_FrozenTimerCountLeft[client] = CFG_ThawDuration;
		Player_FrozenTimerHandle[client] = CreateTimer(1.0, Timer_FrozenPlayerCountdown, client, TIMER_REPEAT);
	}
}



/// =================================================================
/// Helpers
/// =================================================================
public Action:Timer_InstantSpawnPlayer(Handle:timer, any:client) //From TF2 Respawn by WoZeR
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

stock GetClientMaxHealth(client)
{
	return GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

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
}

stock ForceTeamWin(TFTeam:team)
{
	new ent = CreateEntityByName("game_round_win");
	DispatchKeyValue(ent, "force_map_reset", "1");
	DispatchSpawn(ent);
	if (team != TFTeam_Spectator)
	{
		SetVariantInt(team);
		AcceptEntityInput(ent, "SetTeam");
	}
	AcceptEntityInput(ent, "RoundWin");
	AcceptEntityInput(ent, "Kill");
}

stock TF2_GetUberLevel(client)
{
    new index = GetPlayerWeaponSlot(client, 1);
    if (index > 0)
        return RoundFloat(GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100);
    else
        return 0;
}

stock TF2_SetUberLevel(client, uberlevel)
{
    new index = GetPlayerWeaponSlot(client, 1);
    if (index > 0)
    {
        SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
    }
}



/// =================================================================
/// Communications With Player
/// =================================================================
TellPlayerFrozen(player)
{
	if (CFG_ThawDuration != 0)
	{
		if (CFG_RespawnOnAutoThaw)
			PrintHintText(player, "You are FROZEN and will thaw in about %i seconds and be sent to spawn", CFG_ThawDuration);
		else
			PrintHintText(player, "You are FROZEN and will thaw in about %i seconds. Prepare to fight!", CFG_ThawDuration);
	}
	else
	{
		if (CFG_FriendlyCanHealFrozen)
			PrintHintText(player, "You are FROZEN! Ask a teammate to damage you to full health to be thawed!", player);
		else
			PrintHintText(player, "You are FROZEN! You must wait until the end of the round!", player);
	}
}

DisplayRules(player)
{
	if (player == -1)
	{
		CPrintToChatAll("{default}Welcome to {green}Freeze Tag{default}. Type {olive}/freeze{default} in chat to see the rules.");
	}
	else
	{
		CPrintToChat(player, "If you die by another players hand, you will be {blue}frozen{default}!");
		
		if (CFG_ThawDuration != 0)
		{
			if (CFG_RespawnOnAutoThaw)
				CPrintToChat(player, "When {blue}frozen{default}, you cannot move or shoot for about {olive}%i{default} seconds! If you stay frozen the whole time, you will respawn.", CFG_ThawDuration);
			else
				CPrintToChat(player, "When {blue}frozen{default}, you cannot move or shoot for about {olive}%i{default} seconds! If you stay frozen the whole time, you will be thawed.", CFG_ThawDuration);
			
		}
		else			
			CPrintToChat(player, "When {blue}frozen{default}, you cannot move or shoot!");
		
		
		if (CFG_FriendlyCanHealFrozen && CFG_EnemeyCanKillFrozen)
			CPrintToChat(player, "While {blue}frozen{default}, if your teammate hurts you, you heal. Reach 100% health and you will {green}thaw{default}. However, if the enemy hurts you down to 0 you will {green}die{default}!");
		else if (CFG_FriendlyCanHealFrozen)
			CPrintToChat(player, "While {blue}frozen{default}, if your teammate hurts you, you heal. Reach 100% health and you will {olive}thaw{default}.");
		else if (CFG_EnemeyCanKillFrozen)
			CPrintToChat(player, "While {blue}frozen{default}, if the enemy hurts you down to 0 you will {green}die{default}!");
		
		
		if (CFG_EndRoundOnAllFrozen)
			CPrintToChat(player, "Win the map by normal means, or {blue}Freeze{default} the whole enemy team and WIN!");
		else
			CPrintToChat(player, "Win the map by normal means.");
		
		
	}
}








/// =================================================================
/// Misc Helpers
/// =================================================================
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

stock SetFF(bool:on)
{
	new Handle:friendlyFire = FindConVar("mp_friendlyfire");
	new flags = GetConVarFlags(friendlyFire);
	
	if (flags & FCVAR_NOTIFY)
		SetConVarFlags(friendlyFire, flags & ~FCVAR_NOTIFY);

	SetConVarBool(friendlyFire, on);
	
	SetConVarFlags(friendlyFire, flags);
}







/// =================================================================
/// Startup\Setup
/// =================================================================
public OnPluginStart()
{
	CreateConVar("freezetag_version", PLUGIN_VERSION, "Version of Freeze Tag", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	cvar_ft_enabled = CreateConVar("ft_enable","1","Enable/Disable freeze tag mod", FCVAR_PLUGIN);
	cvar_ft_thawDuration = CreateConVar("ft_thaw_duration","15","Automatic thaw duration. 0 = no automatic thaw.", FCVAR_PLUGIN, true, 0.0);
	cvar_ft_frozenDmgMod_heal = CreateConVar("ft_frozen_damage_mod_heal","0.6","When shooting frozen players to thaw them, this is the percent of damage used", FCVAR_PLUGIN, true, 0.1, true, 1.0);
	cvar_ft_frozenDmgMod_kill = CreateConVar("ft_frozen_damage_mod_kill","0.3","When shooting frozen players to finish them off, this is the percent of damage used", FCVAR_PLUGIN, true, 0.1, true, 1.0);
	cvar_ft_autothawrespawn = CreateConVar("ft_respawn_on_auto_thaw","0","When shooting frozen players, this is the percent of damage used", FCVAR_PLUGIN);
	cvar_ft_canenemykillfrozen = CreateConVar("ft_enemy_kill_frozen","1","Enemey players can hurt frozen players (of opposite team) If HP goes to 0, frozen players die", FCVAR_PLUGIN);
	cvar_ft_canfriendlyhealfrozen = CreateConVar("ft_friendly_heal_frozen","1","Friendly players can hurt frozen players, which heals them. If HP goes to 100%, players thaw.", FCVAR_PLUGIN);
	cvar_ft_endroundonallfrozen = CreateConVar("ft_end_round_all_frozen","0","Ends the game round when a whole team is frozen.", FCVAR_PLUGIN);
	cvar_ft_thawimmunitytime = CreateConVar("ft_thaw_immune_time","2.0","How long a player has damage immunity just after they were thawed. Set to 0.0 to disable thawed immunity", FCVAR_PLUGIN, true, _, true, 10.0);
	cvar_ft_thawimmunecanfire = CreateConVar("ft_thaw_immune_can_fire","0","Set to 1 to allow a player who was just thawed to be able to fire at the enemy while immune to damage.", FCVAR_PLUGIN);
	cvar_ft_thawedNewHealthMod = CreateConVar("ft_thawed_health_mod", "1.0", "Percentage of health applied to a player who has just thawed.", FCVAR_PLUGIN, true, 0.1, true, 1.0);
	cvar_ft_frozenNewHealthMod = CreateConVar("ft_frozen_health_mod", "0.5", "Percentage of health applied to a player who has just been frozen.", FCVAR_PLUGIN, true, 0.1, true, 0.9);
	cvar_ft_medicSavesUberCharge = CreateConVar("ft_thawed_medic_keep_uber","1","Enable/Disable allowing a medic to keep his uber charge when thawed.", FCVAR_PLUGIN);
	cvar_ft_allowClassChangeFrozen = CreateConVar("ft_change_class_frozen","1","Enable/Disable allowing a player to change class while frozen.", FCVAR_PLUGIN);
	
	CFG_ThawDuration = GetConVarInt(cvar_ft_thawDuration);
	CFG_FrozenDamageModHeal = GetConVarFloat(cvar_ft_frozenDmgMod_heal);
	CFG_FrozenDamageModKill = GetConVarFloat(cvar_ft_frozenDmgMod_kill);
	CFG_RespawnOnAutoThaw = GetConVarBool(cvar_ft_autothawrespawn);
	CFG_EnemeyCanKillFrozen = GetConVarBool(cvar_ft_canenemykillfrozen);
	CFG_FriendlyCanHealFrozen = GetConVarBool(cvar_ft_canfriendlyhealfrozen);
	CFG_EndRoundOnAllFrozen = GetConVarBool(cvar_ft_endroundonallfrozen);
	CFG_ThawImmuneTime = GetConVarFloat(cvar_ft_thawimmunitytime);
	CFG_CanFireWhileImmune = GetConVarBool(cvar_ft_thawimmunecanfire);
	CFG_IsFreezeEnabled = GetConVarBool(cvar_ft_enabled);
	CFG_ThawedHealthMod = GetConVarFloat(cvar_ft_thawedNewHealthMod);
	CFG_FrozenHealthMod = GetConVarFloat(cvar_ft_frozenNewHealthMod);
	CFG_MedicSavesUberWhenFrozen = GetConVarBool(cvar_ft_medicSavesUberCharge);
	CFG_AllowClassChangeWhenFrozen = GetConVarBool(cvar_ft_allowClassChangeFrozen);
	
	HookConVarChange(cvar_ft_thawDuration, CVAR_Changed);
	HookConVarChange(cvar_ft_frozenDmgMod_heal, CVAR_Changed);
	HookConVarChange(cvar_ft_frozenDmgMod_kill, CVAR_Changed);
	HookConVarChange(cvar_ft_autothawrespawn, CVAR_Changed);
	HookConVarChange(cvar_ft_canenemykillfrozen, CVAR_Changed);
	HookConVarChange(cvar_ft_canfriendlyhealfrozen, CVAR_Changed);
	HookConVarChange(cvar_ft_endroundonallfrozen,   CVAR_Changed);
	HookConVarChange(cvar_ft_thawimmunitytime,   CVAR_Changed);
	HookConVarChange(cvar_ft_thawimmunecanfire,   CVAR_Changed);
	HookConVarChange(cvar_ft_thawedNewHealthMod, CVAR_Changed);
	HookConVarChange(cvar_ft_frozenNewHealthMod, CVAR_Changed);
	HookConVarChange(cvar_ft_medicSavesUberCharge, CVAR_Changed);
	HookConVarChange(cvar_ft_enabled, CVAR_Changed);
	HookConVarChange(cvar_ft_allowClassChangeFrozen, CVAR_Changed);
	
	Initialize();
	
	AutoExecConfig(true, "freezetag");
	
	RegAdminCmd("ft_unfreeze", Cmd_Unfreeze, ADMFLAG_GENERIC, "Unfreeze a target");
	RegAdminCmd("ft_freeze", Cmd_Freeze, ADMFLAG_GENERIC, "Freeze a target");
	RegConsoleCmd("freeze", Cmd_Rules, "Displays the current rules to the player");
	RegConsoleCmd("kill", Cmd_OverrideKill, "");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	//HookEvent("player_changeclass", Event_ChangeClass);
	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

Initialize()
{
	if (CFG_IsFreezeEnabled)
	{
		SetInstantRespawnTime();
		
		FriendlyHealSet(CFG_FriendlyCanHealFrozen);
		
		for (new client = 1; client <= MaxClients; client++)
		{ 
			if (IsClientInGame(client)) 
			{
				OnClientPutInServer(client);
			}
		}
		
		DisplayRules(-1);
	}
	else
	{
		SetFF(false);
		
		for (new client = 1; client <= MaxClients; client++)
		{ 
			if (IsClientInGame(client)) 
			{
				ThawPlayer(client, true);
				RemoveThawImmunity(client);
			}
		}
	}
	
	IsRoundEnd = false;
}

public OnPluginEnd()
{
	// Clear all players
	for (new i = 1; i <= MaxClients; i++)
	{
		ThawPlayer(i);
	}
}

public OnMapStart()
{
	PrecacheSound(SOUND_FREEZE, true);
	PrecacheSound(SOUND_UNFREEZE, true);
}

public OnClientPutInServer(client)
{
	if (CFG_IsFreezeEnabled && Player_IsHooked[client] == false)
	{
		Player_IsHooked[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_PreThink, OnPreThink);
		ThawPlayer(client, true);
	}
}

public OnClientDisconnect(client)
{
	Player_IsHooked[client] = false;
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	ThawPlayer(client, true);
}









/// =================================================================
///  CVAR CHANGED
/// =================================================================

public CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_ft_enabled)
	{
		CFG_IsFreezeEnabled = StrEqual(newValue, "1");
		Initialize();
	}
	else if (convar == cvar_ft_thawDuration)
	{
		CFG_ThawDuration = GetConVarInt(cvar_ft_thawDuration);
	}
	else if (convar == cvar_ft_frozenDmgMod_heal || convar == cvar_ft_frozenDmgMod_kill)
	{
		CFG_FrozenDamageModHeal = GetConVarFloat(cvar_ft_frozenDmgMod_heal);
		CFG_FrozenDamageModKill = GetConVarFloat(cvar_ft_frozenDmgMod_kill);
	}
	else if (convar == cvar_ft_autothawrespawn)
	{
		CFG_RespawnOnAutoThaw = StrEqual(newValue, "1");
	}
	else if (convar == cvar_ft_canenemykillfrozen)
	{
		CFG_EnemeyCanKillFrozen = StrEqual(newValue, "1");
	}
	else if (convar == cvar_ft_canfriendlyhealfrozen)
	{
		if (!CFG_IsFreezeEnabled)
			return;
	
		FriendlyHealSet(StrEqual(newValue, "1"));
	}
	else if (convar == cvar_ft_endroundonallfrozen)
	{
		CFG_EndRoundOnAllFrozen = StrEqual(newValue, "1");
	}
	else if (convar == cvar_ft_thawimmunitytime)
	{
		CFG_ThawImmuneTime = GetConVarFloat(cvar_ft_thawimmunitytime);
	}
	else if (convar == cvar_ft_thawimmunecanfire)
	{
		CFG_CanFireWhileImmune = GetConVarBool(cvar_ft_thawimmunecanfire);
	}
	else if (convar == cvar_ft_thawedNewHealthMod || convar == cvar_ft_frozenNewHealthMod)
	{
		CFG_ThawedHealthMod = GetConVarFloat(cvar_ft_thawedNewHealthMod);
		CFG_FrozenHealthMod = GetConVarFloat(cvar_ft_frozenNewHealthMod);
	}
	else if (convar == cvar_ft_medicSavesUberCharge)
	{
		CFG_MedicSavesUberWhenFrozen = StrEqual(newValue, "1");
	}
	else if (convar == cvar_ft_allowClassChangeFrozen)
	{
		CFG_AllowClassChangeWhenFrozen = GetConVarBool(cvar_ft_allowClassChangeFrozen);
	}
}

FriendlyHealSet(bool:on)
{
	SetFF(on);
	CFG_FriendlyCanHealFrozen = on;
}






/// =================================================================
///  Commands	
/// =================================================================
public Action:Cmd_Unfreeze(client, args) 
{
	//Below code adapted from http://wiki.alliedmods.net/Introduction_to_SourceMod_Plugins

	if (!CFG_IsFreezeEnabled)
	{
		ReplyToCommand(client, "Freeze Tag mod is not enabled.");
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
		if (ThawPlayer(target_list[i]))
		{
			LogAction(client, target_list[i], "\"%L\" unfroze \"%L\"", client, target_list[i]);
			ShowActivity2(client, "[FT] ", "Unfroze %s!", target_name);
		}
	}
 
	return Plugin_Handled;
}

public Action:Cmd_Rules(client, args) 
{
	//Below code adapted from http://wiki.alliedmods.net/Introduction_to_SourceMod_Plugins

	if (!CFG_IsFreezeEnabled)
	{
		ReplyToCommand(client, "Freeze Tag mod is not enabled.");
		return Plugin_Handled;
	}
	
	if (client != 0)
	{
		if (IsClientConnected(client) && IsClientInGame(client))
		{
			DisplayRules(client);
		}
	}
	return Plugin_Handled;
}

public Action:Cmd_Freeze(client, args) 
{
	//Below code adapted from http://wiki.alliedmods.net/Introduction_to_SourceMod_Plugins

	if (!CFG_IsFreezeEnabled)
	{
		ReplyToCommand(client, "Freeze Tag mod is not enabled.");
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
		if (FreezePlayer(target_list[i]))
		{
			LogAction(client, target_list[i], "\"%L\" froze \"%L\"", client, target_list[i]);
			ShowActivity2(client, "[FT] ", "Froze %s!", target_name);
		}
	}

 
	return Plugin_Handled;
}

public Action:Cmd_OverrideKill(client, args) 
{
	if (!CFG_IsFreezeEnabled || client == 0)
		return Plugin_Continue;
	
	else if (Player_IsFrozen[client] || Player_FreezeMeOnSpawn[client])
		return Plugin_Handled;
	
	else
		return Plugin_Continue;
}











