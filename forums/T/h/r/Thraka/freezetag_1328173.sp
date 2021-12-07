/*
 * Todo:
 * - Ring mode:
 * 	TE_SetupBeamRingPoint(location,10.0,500.0,orange,g_HaloSprite,0,10,0.6,10.0,0.5,color,10,0);
 * 	TE_SendToAll();
 * 
 * X Start of plugin, capture the FF setting, enable FF. When unloaded, restore FF setting.
 * 		If the heal players isn't on, don't worry about it
 * X Prevent FF from working at end of round.
 * X Thaw winning team when end of round.
 * - Seperate damage modifiers for heal and kil
 * X When thawed, you're immune for X seconds
 * - Spies shouldn't delete the ragdoll body
 * - Test heavy effects when frozen. Noticed they can punch.
 * - Tell connected players the intro msg
 * - Add option to save uber charge value and restore when thawed
*/ 


#include <tf2>
#include <tf2_stocks>
#include <sourcemod>
#include <sdkhooks>
#include <colors>
#include <sdktools_functions>

#define PLUGIN_VERSION	"0.9.4"

#define SOUND_FREEZE	"physics/glass/glass_largesheet_break3.wav"
#define SOUND_UNFREEZE	"physics/flesh/flesh_squishy_impact_hard2.wav"

//#define FREEZE_STATE 	TF_STUNFLAGS_LOSERSTATE
#define FREEZE_STATE 	TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT
#define RED_TEAM 2
#define BLU_TEAM 3
public Plugin:myinfo = 
{
	name = "Freeze Tag",
	author = "Thraka",
	description = "Freeze Tag",
	version = PLUGIN_VERSION,
	url = ""
}

// CVAR Handles
new Handle:cvar_ft_enabled = INVALID_HANDLE;
new Handle:cvar_ft_thawDuration = INVALID_HANDLE;
new Handle:cvar_ft_frozenDmgMod = INVALID_HANDLE;
new Handle:cvar_ft_autothawrespawn = INVALID_HANDLE;
new Handle:cvar_ft_canenemykillfrozen = INVALID_HANDLE;
new Handle:cvar_ft_canfriendlyhealfrozen = INVALID_HANDLE;
new Handle:cvar_ft_endroundonallfrozen = INVALID_HANDLE;
new Handle:cvar_ft_thawimmunitytime = INVALID_HANDLE;
new Handle:cvar_ft_thawimmunecanfire = INVALID_HANDLE;

// CVAR Values
new bool:IsFreezeEnabled = true;
new ThawDuration = 15;
new Float:FrozenDamageMod = 0.3;
new bool:EnemeyCanKillFrozen = true;
new bool:FriendlyCanHealFrozen = true;
new bool:RespawnOnAutoThaw = false;
new bool:EndRoundOnAllFrozen = false;

// State Related
new bool:FrozenPlayers[MAXPLAYERS+1] = { false, ... };
new bool:IsThawImmune[MAXPLAYERS+1] = { false, ... };
new bool:FreezeMeOnSpawn[MAXPLAYERS+1] = { false, ... };
new Handle:FrozenPlayerTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new FrozenPlayerTimerLeft[MAXPLAYERS+1] = { 0, ... };
new Float:FrozenPlayerOrigin[MAXPLAYERS+1][3];
new Float:FrozenPlayerAngle[MAXPLAYERS+1][3];
new Float:ThawImmuneTime = 2.0;
new bool:RoundEnd = false;
new bool:CanFireWhileImmune = false;


// Misc
new bool:PlayerHooked[MAXPLAYERS+1] = { false, ... };


public OnPluginStart()
{
	CreateConVar("freezetag_version", PLUGIN_VERSION, "Version of Freeze Tag", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	cvar_ft_enabled = CreateConVar("ft_enable","1","Enable/Disable freeze tag mod", FCVAR_PLUGIN);
	cvar_ft_thawDuration = CreateConVar("ft_thaw_duration","15","Automatic thaw duration. 0 = no automatic thaw.", FCVAR_PLUGIN, true, 0.0);
	cvar_ft_frozenDmgMod = CreateConVar("ft_frozen_damage_mod","0.3","When shooting frozen players, this is the percent of damage used for hurt or heal", FCVAR_PLUGIN, true, 0.1, true, 1.0);
	cvar_ft_autothawrespawn = CreateConVar("ft_respawn_on_auto_thaw","0","When shooting frozen players, this is the percent of damage used", FCVAR_PLUGIN);
	cvar_ft_canenemykillfrozen = CreateConVar("ft_enemy_kill_frozen","1","Enemey players can hurt frozen players (of opposite team) If HP goes to 0, frozen players die", FCVAR_PLUGIN);
	cvar_ft_canfriendlyhealfrozen = CreateConVar("ft_friendly_heal_frozen","1","Friendly players can hurt frozen players, which heals them. If HP goes to 100%, players thaw.", FCVAR_PLUGIN);
	cvar_ft_endroundonallfrozen = CreateConVar("ft_end_round_all_frozen","0","Ends the game round when a whole team is frozen.", FCVAR_PLUGIN);
	cvar_ft_thawimmunitytime = CreateConVar("ft_thaw_immune_time","2.0","How long a player has damage immunity just after they were thawed. Set to 0.0 to disable thawed immunity", FCVAR_PLUGIN, true, _, true, 10.0);
	cvar_ft_thawimmunecanfire = CreateConVar("ft_thaw_immune_can_fire","0","Set to 1 to allow a player who was just thawed to be able to fire at the enemy while immune to damage.", FCVAR_PLUGIN);
	
	ThawDuration = GetConVarInt(cvar_ft_thawDuration);
	FrozenDamageMod = GetConVarFloat(cvar_ft_frozenDmgMod);
	RespawnOnAutoThaw = GetConVarBool(cvar_ft_autothawrespawn);
	EnemeyCanKillFrozen = GetConVarBool(cvar_ft_canenemykillfrozen);
	FriendlyCanHealFrozen = GetConVarBool(cvar_ft_canfriendlyhealfrozen);
	EndRoundOnAllFrozen = GetConVarBool(cvar_ft_endroundonallfrozen);
	ThawImmuneTime = GetConVarFloat(cvar_ft_thawimmunitytime);
	CanFireWhileImmune = GetConVarBool(cvar_ft_thawimmunecanfire);
	IsFreezeEnabled = GetConVarBool(cvar_ft_enabled);
	
	HookConVarChange(cvar_ft_thawDuration, ThawDuration_CVAR_Changed);
	HookConVarChange(cvar_ft_frozenDmgMod, FrozenDmgMod_CVAR_Changed);
	HookConVarChange(cvar_ft_autothawrespawn, AutoRespawnThaw_CVAR_Changed);
	HookConVarChange(cvar_ft_canenemykillfrozen, EnemeyKillFrozen_CVAR_Changed);
	HookConVarChange(cvar_ft_canfriendlyhealfrozen, FriendlyHealFrozen_CVAR_Changed);
	HookConVarChange(cvar_ft_endroundonallfrozen,   EndOnAllFrozen_CVAR_Changed);
	HookConVarChange(cvar_ft_thawimmunitytime,   ThawImmuneTime_CVAR_Changed);
	HookConVarChange(cvar_ft_thawimmunecanfire,   ThawImmuneCanFire_CVAR_Changed);
	HookConVarChange(cvar_ft_enabled, FreezeTag_CVAR_Changed);
	
	Initialize();
	
	AutoExecConfig(true, "freezetag");
	
	RegAdminCmd("ft_unfreeze", Cmd_Unfreeze, ADMFLAG_GENERIC, "Unfreeze a target");
	RegAdminCmd("ft_freeze", Cmd_Freeze, ADMFLAG_GENERIC, "Freeze a target");
	RegConsoleCmd("freeze", Cmd_Rules, "Displays the current rules to the player");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
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
	Initialize();
}

public OnClientPutInServer(client)
{
	if (IsFreezeEnabled && PlayerHooked[client] == false)
	{
		PrintToChatAll("Hooking player %i", client);
		PlayerHooked[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_PreThink, OnPreThink);
		ThawPlayer(client);
		RemoveThawImmunity(client);
	}
}

public OnClientDisconnect(client)
{
	PlayerHooked[client] = false;
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	ThawPlayer(client);
	RemoveThawImmunity(client);
}

Initialize()
{
	if (IsFreezeEnabled)
	{
		FriendlyHealSet(FriendlyCanHealFrozen);
		
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
		for (new client = 1; client <= MaxClients; client++) 
		{ 
			if (IsClientInGame(client)) 
			{
				OnClientDisconnect(client);
			}
		}
		
		SetFF(false);
	}
	
	RoundEnd = false;
}

public OnPreThink(client)
{
	if (FrozenPlayers[client] || (IsThawImmune[client] && CanFireWhileImmune == false))
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

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsFreezeEnabled == false)
		return Plugin_Continue;
	
	new clientHealth = GetClientHealth(victim);
	new clientMaxHealth = GetClientMaxHealth(victim);
	
	new bool:sameTeam = GetClientTeam(attacker) == GetClientTeam(victim);
	
	//PrintToChatAll("victim %i hp %i max %i dmg %f ", victim, clientHealth, clientMaxHealth, damage);
	
	if (FrozenPlayers[victim] == false)
	{
		// Friendly fire, we dont allow it, or the attacker himself is frozen and attacking non frozen
		if ((sameTeam && victim != attacker) || FrozenPlayers[attacker] || IsThawImmune[victim])
			return Plugin_Handled;
		
		GetClientAbsOrigin(victim, FrozenPlayerOrigin[victim]);
		GetClientAbsAngles(victim, FrozenPlayerAngle[victim]);
		return Plugin_Continue;
	}
	else
	{
		// World or self inflicted and we're frozen, so skip
		if (victim == attacker || attacker == 0)
			return Plugin_Handled;
		
		// End of the round, let the damage commence unless same team!
		if (RoundEnd)
		{
			if (sameTeam)
				return Plugin_Handled;
			else
				return Plugin_Continue;
		}
		
		// Modify the base damage done by the damage mod and fix
		new roundedDmg = RoundToNearest(damage * FrozenDamageMod);
		
		// Same team and can heal
		if (sameTeam && FriendlyCanHealFrozen)
		{
			// lets heal them or thaw them
			if (clientHealth + roundedDmg > clientMaxHealth)
			{
				ThawPlayer(victim, true);
				GivePlayerThawImmunity(victim);
			}
			else
				SetEntityHealth(victim, clientHealth + roundedDmg);
			
			return Plugin_Handled;
		}
		else if (!sameTeam && EnemeyCanKillFrozen)
		{
			
			if (clientHealth - roundedDmg <= 0)
			{
				//SetEntityHealth(victim, -1);
				ForcePlayerSuicide(victim);
				return Plugin_Handled;
			}
			else
			{
				SetEntityHealth(victim, clientHealth - roundedDmg);
				return Plugin_Handled;
			}
		}

		return Plugin_Handled;
	}
	
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsFreezeEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (FreezeMeOnSpawn[client])
		{
			RemoveRagdoll(client);
			FreezeMeOnSpawn[client] = false;
			TeleportEntity(client, FrozenPlayerOrigin[client], FrozenPlayerAngle[client], NULL_VECTOR);
			CreateTimer(0.1, FreezePlayerTimer, client, TIMER_FLAG_NO_MAPCHANGE); 
		}
		else
		{
			ThawPlayer(client);
			RemoveThawImmunity(client);
		}
	}
}

public Action:Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsFreezeEnabled)
	{
		RoundEnd = true;
		
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
	if (IsFreezeEnabled)
	{
		RoundEnd = false;
		DisplayRules(-1);
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsFreezeEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		// only process players who didn't die of self or world. Also, they must not be frozen.
		if (attacker != 0 && attacker != client && FrozenPlayers[client] == false && !RoundEnd)
		{
			FreezeMeOnSpawn[client] = true;
			SetInstantRespawnTime(); //Have to do this since TF_GameRules likes to change during rounds and map changes (Points capped, etc)
			CreateTimer(0.0, SpawnPlayerTimer, client, TIMER_FLAG_NO_MAPCHANGE); //Respawn the player at the specified time
		}
		else if (FrozenPlayers[client])
		{
			KillThawTimer(client);
		}
	}
}

/*	 If a frozen client is being healed by a medic, and reaches peak hp, thaw them. 
public Event_MedicHeal(Handle:event, const String:name[], bool:dontBroadcast)
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
*/

bool:FreezePlayer(player)
{
	if (IsClientInGame(player) && IsPlayerAlive(player) && FrozenPlayers[player] == false)
	{
		TF2_RemovePlayerDisguise(player);
		StripToMelee(player);
		TF2_StunPlayer(player, 100.0, 1.0, FREEZE_STATE);
		
		//TF2_StunPlayer(player, 5.0, 0.0, TF_STUNFLAG_NOSOUNDOREFFECT|TF_STUNFLAG_THIRDPERSON|TF_STUNFLAG_BONKSTUCK);
		FrozenPlayers[player] = true;
		
		KillThawTimer(player)
		if (!RoundEnd)
		{
			CreateThawTimer(player);
			TellPlayerFrozen(player);
		}
		
		SetEntityHealth(player, GetClientMaxHealth(player) / 2);
		//SetEntityMoveType(player, MOVETYPE_NONE);
		
		new Float:vec[3];
		GetClientEyePosition(player, vec);
		EmitAmbientSound(SOUND_FREEZE, vec, player);
		SetEntityRenderColor(player, 122, 246, 255, 192);
		
		if (!RoundEnd && EndRoundOnAllFrozen)
			CheckForWinningTeam();
		
		return true;
	}
	else
		return false;
}

bool:ThawPlayer(player, bool:resetHealth = true)
{
	if (player == 0)
		return false;
	
	if (IsClientInGame(player) && IsPlayerAlive(player) && FrozenPlayers[player])
	{
		FrozenPlayers[player] = false;
		FreezeMeOnSpawn[player] = false;
		
		TF2_StunPlayer(player, 0.0, 0.0, FREEZE_STATE);
		SetEntityRenderColor(player, 255, 255, 255, 255);
		
		new currentHealth = GetClientHealth(player);
		TF2_RegeneratePlayer(player);
		
		if (!resetHealth)
			SetEntityHealth(player, currentHealth);
			
		
		KillThawTimer(player)
		
		new Float:vec[3];
		GetClientEyePosition(player, vec);
		EmitAmbientSound(SOUND_UNFREEZE, vec, player);
		//SOUND_FROM_PLAYER
		//SetEntityRenderFx(player, RENDERFX_NONE);
		return true;
	}
	else
	{
		// Either way, we need to clear flags
		FrozenPlayers[player] = false;
		//FrozenPlayerDamageSinceFrozen[player] = 0.0;
		KillThawTimer(player)
		FreezeMeOnSpawn[player] = false;
		return false;
	}
}

RemoveThawImmunity(player)
{
	if (player == 0)
		return;
	
	if (IsClientInGame(player) && IsPlayerAlive(player) && IsThawImmune[player])
	{
		IsThawImmune[player] = false;
		SetEntityRenderFx(player, RENDERFX_NONE);
	}
}

GivePlayerThawImmunity(player)
{
	if (player == 0)
		return;
	
	if (IsClientInGame(player) && IsPlayerAlive(player) && ThawImmuneTime > 0.0 && RespawnOnAutoThaw == false)
	{
		IsThawImmune[player] = true;
		
		// End the immune time period
		CreateTimer(ThawImmuneTime, ThawImmunityEnded, player);
		
		// Configure the graphics
		SetEntityRenderFx(player, RENDERFX_STROBE_FAST);
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
				if (FrozenPlayers[client])
					bluFrozen++;
			}
			else if (PlayerTeam == RED_TEAM)
			{
				redFound++;
				if (FrozenPlayers[client])
					redFrozen++;
				
			}
		}
	}
	
	//PrintToChatAll("blu %i bluFrozen %i red %i redFrozen %i", bluFound, bluFrozen, redFound, redFrozen);
	
	if (bluFound > 0 && redFound > 0)
	{
		if (redFound == redFrozen)
			ForceTeamWin(TFTeam_Blue);
		else if (bluFound == bluFrozen)
			ForceTeamWin(TFTeam_Red);
	}
}


/////////////////////////////////////////////////////////////////////
///  Comms
/////////////////////////////////////////////////////////////////////
TellPlayerFrozen(player)
{
	if (ThawDuration != 0)
	{
		if (RespawnOnAutoThaw)
			PrintHintText(player, "You are FROZEN and will thaw in about %i seconds and be sent to spawn", ThawDuration);
		else
			PrintHintText(player, "You are FROZEN and will thaw in about %i seconds. Prepare to fight!", ThawDuration);
	}
	else
	{
		if (FriendlyCanHealFrozen)
			PrintHintText(player, "You are FROZEN! Ask a teammate to damage to full health to be thawed!", player);
		else
			PrintHintText(player, "You are FROZEN! You must wait until the end!", player);
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
		
		if (ThawDuration != 0)
		{
			if (RespawnOnAutoThaw)
				CPrintToChat(player, "When {blue}frozen{default}, you cannot move or shoot for about {olive}%i{default} seconds! If you stay frozen the whole time, you will respawn.", ThawDuration);
			else
				CPrintToChat(player, "When {blue}frozen{default}, you cannot move or shoot for about {olive}%i{default} seconds! If you stay frozen the whole time, you will be thawed.", ThawDuration);
			
		}
		else			
			CPrintToChat(player, "When {blue}frozen{default}, you cannot move or shoot!");
		
		
		if (FriendlyCanHealFrozen && EnemeyCanKillFrozen)
			CPrintToChat(player, "While {blue}frozen{default}, if your teammate hurts you, you heal. Reach 100% health and you will {green}thaw{default}. However, if the enemy hurts you down to 0 you will {green}die{default}!");
		else if (FriendlyCanHealFrozen)
			CPrintToChat(player, "While {blue}frozen{default}, if your teammate hurts you, you heal. Reach 100% health and you will {olive}thaw{default}.");
		else if (EnemeyCanKillFrozen)
			CPrintToChat(player, "While {blue}frozen{default}, if the enemy hurts you down to 0 you will {green}die{default}!");
		
		
		if (EndRoundOnAllFrozen)
			CPrintToChat(player, "Win the map by normal means, or {blue}Freeze{default} the whole enemy team and WIN!");
		else
			CPrintToChat(player, "Win the map by normal means.");
		
		
	}
}

/////////////////////////////////////////////////////////////////////
///  Helpers	
/////////////////////////////////////////////////////////////////////

KillThawTimer(client)
{
	if (FrozenPlayerTimers[client] != INVALID_HANDLE)
	{
		KillTimer(FrozenPlayerTimers[client]);
		FrozenPlayerTimers[client] = INVALID_HANDLE;
		FrozenPlayerTimerLeft[client] = 0;
	}
}

CreateThawTimer(client)
{
	if (FrozenPlayerTimers[client] == INVALID_HANDLE && ThawDuration != 0)
	{
		FrozenPlayerTimerLeft[client] = ThawDuration;
		FrozenPlayerTimers[client] = CreateTimer(1.0, FrozenPlayerCountdown, client, TIMER_REPEAT);
	}
}

stock GetClientMaxHealth(client)
{
	return GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

StripToMelee(client) 
{
	if(IsClientInGame(client) && IsPlayerAlive(client)) 
	{
		for(new i = 0; i <= 5; i++)
		{
			if(i != 2)
			{
				if(TF2_GetPlayerClass(client) != TFClass_Spy)
				{
					TF2_RemoveWeaponSlot(client, i);
				}else{
					if(i != 4)
						TF2_RemoveWeaponSlot(client, i);
				}
			}
		}
			
		new weapon = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
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

stock SetFF(bool:on)
{
	new Handle:friendlyFire = FindConVar("mp_friendlyfire");
	new flags = GetConVarFlags(friendlyFire);
	
	if (flags & FCVAR_NOTIFY)
		SetConVarFlags(friendlyFire, flags & ~FCVAR_NOTIFY);

	SetConVarBool(friendlyFire, on);
	
	SetConVarFlags(friendlyFire, flags);
}

/////////////////////////////////////////////////////////////////////
///  Timers	
/////////////////////////////////////////////////////////////////////

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

public Action:FreezePlayerTimer(Handle:timer, any:client) //From TF2 Respawn by WoZeR
{
     //Respawn the player if he is in game and is dead.
     if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
     {
          FreezePlayer(client);
     }
     return Plugin_Continue;
}

public Action:ThawImmunityEnded(Handle:timer, any:client) //From TF2 Respawn by WoZeR
{
     //Respawn the player if he is in game and is dead.
     if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
     {
		RemoveThawImmunity(client);
     }
     return Plugin_Continue;
}

public Action:FrozenPlayerCountdown(Handle:timer, any:client)
{
	if (FrozenPlayerTimers[client] != INVALID_HANDLE)
	{	
		//FrozenPlayerTimers[client] = INVALID_HANDLE;
		//SetEntityRenderColor(player, 0, 128, 255, 192);
		if (FrozenPlayerTimerLeft[client] == 0)
		{
			KillThawTimer(client);
			ThawPlayer(client, false);
			
			if (RespawnOnAutoThaw)
				TF2_RespawnPlayer(client);
			else
				GivePlayerThawImmunity(client);
		}
		else
		{
			FrozenPlayerTimerLeft[client] -= 1;
			
		}
	}
}

/////////////////////////////////////////////////////////////////////
///  CVAR CHANGED
/////////////////////////////////////////////////////////////////////

public FreezeTag_CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	IsFreezeEnabled = StrEqual(newValue, "1");
	Initialize();
}

public ThawDuration_CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ThawDuration = GetConVarInt(cvar_ft_thawDuration);
}

public FrozenDmgMod_CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	FrozenDamageMod = GetConVarFloat(cvar_ft_frozenDmgMod);
}

public AutoRespawnThaw_CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RespawnOnAutoThaw = StrEqual(newValue, "1");
}

public EnemeyKillFrozen_CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	EnemeyCanKillFrozen= StrEqual(newValue, "1");
}

public FriendlyHealFrozen_CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!IsFreezeEnabled)
		return;
	
	FriendlyHealSet(StrEqual(newValue, "1"));
}

public EndOnAllFrozen_CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	EndRoundOnAllFrozen = StrEqual(newValue, "1");
}

public ThawImmuneTime_CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ThawImmuneTime = GetConVarFloat(cvar_ft_thawimmunitytime);
}

public ThawImmuneCanFire_CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CanFireWhileImmune = GetConVarBool(cvar_ft_thawimmunecanfire);
}


FriendlyHealSet(bool:on)
{
	SetFF(on);
	FriendlyCanHealFrozen = on;
}

/////////////////////////////////////////////////////////////////////
///  Commands	
/////////////////////////////////////////////////////////////////////
public Action:Cmd_Unfreeze(client, args) 
{
	//Below code adapted from http://wiki.alliedmods.net/Introduction_to_SourceMod_Plugins

	if (!IsFreezeEnabled)
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

	if (!IsFreezeEnabled)
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

	if (!IsFreezeEnabled)
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