/**
 * Teleport to Spawn plugin
 * by sarysa
 *
 * You're free to do what you want with it. No warranty.
 */

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>

#pragma semicolon 1

#define FAR_FUTURE 100000000.0
#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

new Float:OFF_THE_MAP[3] = { 16383.0, 16383.0, -16383.0 };
new bool:PRINT_DEBUG_INFO = false;

#define MAX_CENTER_TEXT_LENGTH 128

new BossTeam = _:TFTeam_Blue;
new MercTeam = _:TFTeam_Red;

public Plugin:myinfo = {
	name = "Teleport to Spawn",
	author = "sarysa",
	version = "1.0.4",
}

// cvars
new Handle:TTS_CvarEnabled = INVALID_HANDLE;
new Handle:TTS_CvarDamageThreshold = INVALID_HANDLE;
new Handle:TTS_CvarShouldUber = INVALID_HANDLE;
new Handle:TTS_CvarShouldInvincible = INVALID_HANDLE;
new Handle:TTS_CvarShouldKnockbackImmune = INVALID_HANDLE;
new Handle:TTS_CvarShouldImmobilize = INVALID_HANDLE;
new Handle:TTS_CvarStunLevel = INVALID_HANDLE;
new Handle:TTS_CvarEffectDuration = INVALID_HANDLE;
new Handle:TTS_CvarIncludeRed = INVALID_HANDLE;
new Handle:TTS_CvarDamageFactorBlu = INVALID_HANDLE;
new Handle:TTS_CvarDamageFactorRed = INVALID_HANDLE;
new Handle:TTS_CvarOpposingSpawnDelay = INVALID_HANDLE;
new Handle:TTS_CvarBlacklist = INVALID_HANDLE;
new Handle:TTS_CvarMessage = INVALID_HANDLE;
new Handle:TTS_CvarMessageStun = INVALID_HANDLE;

// settings
#define TTS_BLACKLIST_SIZE 1000
#define TTS_STUN_NONE 0
#define TTS_STUN_FEAR 1
#define TTS_STUN_MOONSHOT 2
new bool:TTS_Enabled;
new Float:TTS_DamageThreshold;
new bool:TTS_ShouldUber;
new bool:TTS_ShouldInvincible;
new bool:TTS_ShouldKnockbackImmune;
new bool:TTS_ShouldImmobilize;
new TTS_StunLevel;
new Float:TTS_EffectDuration;
new bool:TTS_IncludeRed;
new Float:TTS_DamageFactorBlu;
new Float:TTS_DamageFactorRed;
new Float:TTS_OpposingSpawnDelay;
new String:TTS_Blacklist[TTS_BLACKLIST_SIZE];
new String:TTS_Message[MAX_CENTER_TEXT_LENGTH];
new String:TTS_MessageStun[MAX_CENTER_TEXT_LENGTH];

// internals
new bool:TTS_RoundActive;
new bool:TTS_ShouldStun;
new bool:TTS_TeleportPending[MAX_PLAYERS_ARRAY];
new Float:TTS_RedSpawn[3];
new Float:TTS_BluSpawn[3];
new Float:TTS_RemoveEffectsAt[MAX_PLAYERS_ARRAY];
new Float:TTS_StartOpposingSpawnAt;
new bool:TTS_IsBlacklisted;

public OnPluginStart()
{
	//InitTestValues();
	
	// create convars
	TTS_CvarEnabled = CreateConVar("tts_enabled", "1", "Is this plugin enabled?", FCVAR_PLUGIN);
	TTS_CvarDamageThreshold = CreateConVar("tts_mindamage", "100.0", "Minimum world damage before hale is teleported.", FCVAR_PLUGIN);
	TTS_CvarShouldUber = CreateConVar("tts_uber", "0", "Should uber hale on teleport.", FCVAR_PLUGIN);
	TTS_CvarShouldInvincible = CreateConVar("tts_invincible", "0", "Should make hale completely invincible on teleport.", FCVAR_PLUGIN);
	TTS_CvarShouldKnockbackImmune = CreateConVar("tts_megaheal", "0", "Should should make hale knockback immune on teleport.", FCVAR_PLUGIN);
	TTS_CvarShouldImmobilize = CreateConVar("tts_immobilize", "0", "Should immobilize hale on teleport.", FCVAR_PLUGIN);
	TTS_CvarStunLevel = CreateConVar("tts_stunlevel", "0", "Stun level on teleport. Will not work if tts_megaheal is 1. 0=no stun, 1=fear, 2=moonshot", FCVAR_PLUGIN);
	TTS_CvarEffectDuration = CreateConVar("tts_effectduration", "0.0", "Duration of effects on teleport.", FCVAR_PLUGIN);
	TTS_CvarIncludeRed = CreateConVar("tts_includered", "0", "Also teleport RED team to safety.", FCVAR_PLUGIN);
	TTS_CvarDamageFactorRed = CreateConVar("tts_redfactor", "1.0", "Damage factor for RED team. Only works if tts_includered is 1.", FCVAR_PLUGIN);
	TTS_CvarDamageFactorBlu = CreateConVar("tts_blufactor", "1.0", "Damage factor for BLU team. Set to 0.5 to fix FF2's excessive environmental damage.", FCVAR_PLUGIN);
	TTS_CvarOpposingSpawnDelay = CreateConVar("tts_timebeforeredspawn", "60.0", "Time to elapse before ", FCVAR_PLUGIN);
	TTS_CvarBlacklist = CreateConVar("tts_blacklist", "vsh_dr_;dr_", "Maps to exclude, semicolon separated. Will only compare with beginning of strings. Example: koth_;vsh_dr_;dr_;vsh_runblitz_", FCVAR_PLUGIN);
	TTS_CvarMessage = CreateConVar("tts_message_nostun", "You've been teleported safely to spawn.", "Message to display to players when they get teleported. Use \n for new line.", FCVAR_PLUGIN);
	TTS_CvarMessageStun = CreateConVar("tts_message_stun", "You've been teleported safely to spawn.\nYou won't be able to move for a few seconds.", "Message to display to players when they get teleported and stunned or immobilized.", FCVAR_PLUGIN);
	
	AutoExecConfig(true, "tts");
	
	HookEvent("teamplay_round_start", TTS_RoundStart);
	HookEvent("teamplay_round_win", TTS_RoundEnd);
	
	// fix for bug with minions who die to environment and are resummoned
	HookEvent("player_death", TTS_PlayerDeath);
}

public OnMapStart()
{
	// reload tts.cfg
	AutoExecConfig(true, "tts");
}

public TTS_AdjustConvarInternals()
{
	TTS_ShouldStun = TTS_StunLevel != TTS_STUN_NONE;
}

public TTS_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (PRINT_DEBUG_INFO)
		PrintToServer("Round start executed.");

	// update convars at the start of every round
	TTS_Enabled = GetConVarBool(TTS_CvarEnabled);
	TTS_DamageThreshold = GetConVarFloat(TTS_CvarDamageThreshold);
	TTS_ShouldUber = GetConVarBool(TTS_CvarShouldUber);
	TTS_ShouldInvincible = GetConVarBool(TTS_CvarShouldInvincible);
	TTS_ShouldKnockbackImmune = GetConVarBool(TTS_CvarShouldKnockbackImmune);
	TTS_ShouldImmobilize = GetConVarBool(TTS_CvarShouldImmobilize);
	TTS_StunLevel = GetConVarInt(TTS_CvarStunLevel);
	TTS_EffectDuration = GetConVarFloat(TTS_CvarEffectDuration);
	TTS_IncludeRed = GetConVarBool(TTS_CvarIncludeRed);
	TTS_DamageFactorBlu = GetConVarFloat(TTS_CvarDamageFactorBlu);
	TTS_DamageFactorRed = GetConVarFloat(TTS_CvarDamageFactorRed);
	TTS_OpposingSpawnDelay = GetConVarFloat(TTS_CvarOpposingSpawnDelay);
	GetConVarString(TTS_CvarBlacklist, TTS_Blacklist, TTS_BLACKLIST_SIZE);
	GetConVarString(TTS_CvarMessage, TTS_Message, MAX_CENTER_TEXT_LENGTH);
	GetConVarString(TTS_CvarMessageStun, TTS_MessageStun, MAX_CENTER_TEXT_LENGTH);
	
	// correct \n
	ReplaceString(TTS_Message, MAX_CENTER_TEXT_LENGTH, "\\n", "\n");
	ReplaceString(TTS_MessageStun, MAX_CENTER_TEXT_LENGTH, "\\n", "\n");
	
	// disabled?
	if (!TTS_Enabled)
	{
		PrintToServer("Teleport to Spawn is disabled. Will not execute this round.");
		TTS_IsBlacklisted = true;
		return;
	}
	
	// init internals that depend on convars
	TTS_AdjustConvarInternals();
	
	// check the actual blacklist
	static String:mapName[64];
	GetCurrentMap(mapName, 64);
	if (strlen(TTS_Blacklist) > 0)
	{
		if (FindCharInString(TTS_Blacklist, ';') == -1)
			TTS_IsBlacklisted = StrContains(mapName, TTS_Blacklist) == 0;
		else
		{
			new startPos = 0;
			new bool:breakInside = false;
			new length = strlen(TTS_Blacklist);
			new mapLength = strlen(mapName);
			while (!breakInside)
			{
				new endPos = CharPos(TTS_Blacklist, length, ';', startPos);
				if (endPos == -1)
				{
					breakInside = true;
					endPos = length;
				}
				
				TTS_IsBlacklisted = StartsWithSubstring(mapName, mapLength, TTS_Blacklist, startPos, endPos);
				
				if (TTS_IsBlacklisted)
					break;
				
				if (breakInside)
					break;
					
				startPos = endPos + 1;
				if (startPos >= length)
					break; // in case last character is a semicolon
			}
		}
	}
	
	if (TTS_IsBlacklisted)
	{
		PrintToServer("Current map %s is blacklisted. Teleport to Spawn disabled this round.", mapName);
		return;
	}
	else if (PRINT_DEBUG_INFO)
		PrintToServer("Current map %s is not blacklisted.", mapName);

	// init
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		TTS_TeleportPending[clientIdx] = false;
		TTS_RemoveEffectsAt[clientIdx] = GetEngineTime(); // in case of effects lingering from the previous round. rare, but possible.
		
		if (IsClientInGame(clientIdx))
			SDKHook(clientIdx, SDKHook_OnTakeDamage, TTS_OnTakeDamage);
	}
	
	// get current red/blu spawns
	new randomRed = FindRandomPlayer(false);
	new randomBlu = FindRandomPlayer(true);
	if (IsValidEntity(randomRed))
	{
		GetEntPropVector(randomRed, Prop_Send, "m_vecOrigin", TTS_RedSpawn);
	}
	else
	{
		TTS_RedSpawn[0] = OFF_THE_MAP[0];
		TTS_RedSpawn[1] = OFF_THE_MAP[1];
		TTS_RedSpawn[2] = OFF_THE_MAP[2];
	}

	if (IsValidEntity(randomBlu))
	{
		GetEntPropVector(randomBlu, Prop_Send, "m_vecOrigin", TTS_BluSpawn);
	}
	else
	{
		TTS_BluSpawn[0] = OFF_THE_MAP[0];
		TTS_BluSpawn[1] = OFF_THE_MAP[1];
		TTS_BluSpawn[2] = OFF_THE_MAP[2];
	}
	
	// timing for allowing opposing spawn usage
	TTS_StartOpposingSpawnAt = GetEngineTime() + TTS_OpposingSpawnDelay;
	
	TTS_RoundActive = true;
}

public TTS_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (PRINT_DEBUG_INFO)
		PrintToServer("Round end executed.");

	if (TTS_IsBlacklisted)
		return;
	
	// cleanup
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (TTS_RemoveEffectsAt[clientIdx] != FAR_FUTURE)
			TTS_RemoveEffectsAt[clientIdx] = GetEngineTime();
			
		if (IsClientInGame(clientIdx))
			SDKUnhook(clientIdx, SDKHook_OnTakeDamage, TTS_OnTakeDamage);
	}
	
	TTS_RoundActive = false;
}

public TTS_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (TTS_IsBlacklisted)
		return;
		
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (victim > 0 && victim <= MAX_PLAYERS)
		TTS_TeleportPending[victim] = false;
}

public Action:TTS_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePos[3], damagecustom)
{
	// various validity checks
	if (TTS_IsBlacklisted || !TTS_RoundActive || !IsLivingPlayer(victim))
		return Plugin_Continue;
	
	// ensure it's not a player
	if (attacker >= 1 && attacker <= MaxClients)
		return Plugin_Continue;
		
	// exclude reds if necessary
	if (!TTS_IncludeRed && GetClientTeam(victim) == MercTeam)
		return Plugin_Continue;
		
	// exclude fall damage from self
	if (attacker == 0 && inflictor == 0 && (damagetype & DMG_FALL) != 0)
		return Plugin_Continue;
		
	// we now know it's world damage. ensure it meets the damage standard.
	if (damage < TTS_DamageThreshold)
		return Plugin_Continue;
	
	// set things up
	TTS_TeleportPending[victim] = true;
	if (GetClientTeam(victim) == BossTeam)
	{
		damage *= TTS_DamageFactorBlu;
		if (PRINT_DEBUG_INFO)
			PrintToServer("Applying %f factor to BLU team pit damage.", TTS_DamageFactorBlu);
	}
	else
	{
		damage *= TTS_DamageFactorRed;
		if (PRINT_DEBUG_INFO)
			PrintToServer("Applying %f factor to RED team pit damage.", TTS_DamageFactorRed);
	}
	return Plugin_Changed;
}

public TTS_RefreshEffects(clientIdx)
{
	if (IsLivingPlayer(clientIdx))
	{
		if (TTS_ShouldStun && !TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
		{
			if (TTS_StunLevel == TTS_STUN_FEAR)
				TF2_StunPlayer(clientIdx, 300.0, 0.0, TF_STUNFLAGS_SMALLBONK | TF_STUNFLAG_NOSOUNDOREFFECT);
			else if (TTS_StunLevel == TTS_STUN_MOONSHOT)
				TF2_StunPlayer(clientIdx, 300.0, 0.0, TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT);
		}
		if (TTS_ShouldUber && !TF2_IsPlayerInCondition(clientIdx, TFCond_Ubercharged))
			TF2_AddCondition(clientIdx, TFCond_Ubercharged, -1.0);
		if (TTS_ShouldInvincible && GetEntProp(clientIdx, Prop_Data, "m_takedamage") != 0)
			SetEntProp(clientIdx, Prop_Data, "m_takedamage", 0);
		if (TTS_ShouldKnockbackImmune && !TF2_IsPlayerInCondition(clientIdx, TFCond_MegaHeal))
			TF2_AddCondition(clientIdx, TFCond_MegaHeal, -1.0);
			
		// note for below: assume that any movetype other than walk is artificial (i.e. a rage) and shouldn't be overriden
		if (TTS_ShouldImmobilize && GetEntProp(clientIdx, Prop_Send, "movetype") == any:MOVETYPE_WALK)
			SetEntityMoveType(clientIdx, MOVETYPE_NONE);
			
	}
	else // dead player, stop this
		TTS_RemoveEffectsAt[clientIdx] = FAR_FUTURE;
}

public OnGameFrame()
{
	if (TTS_IsBlacklisted)
		return;

	new Float:curTime = GetEngineTime();

	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;
			
		if (TTS_TeleportPending[clientIdx])
		{
			TTS_TeleportPending[clientIdx] = false;
			
			new bool:toOpposingSpawn = GetRandomInt(0, (curTime >= TTS_StartOpposingSpawnAt) ? 1 : 0) == 1;
			new bool:toRedSpawn = (GetClientTeam(clientIdx) == BossTeam && toOpposingSpawn) || (GetClientTeam(clientIdx) == MercTeam && !toOpposingSpawn);
			if (toRedSpawn && TTS_RedSpawn[0] != OFF_THE_MAP[0])
				TeleportEntity(clientIdx, TTS_RedSpawn, NULL_VECTOR, Float:{0.0,0.0,0.0});
			else if (TTS_BluSpawn[0] != OFF_THE_MAP[0])
				TeleportEntity(clientIdx, TTS_BluSpawn, NULL_VECTOR, Float:{0.0,0.0,0.0});
				
			TTS_RemoveEffectsAt[clientIdx] = curTime + TTS_EffectDuration;
			
			if (PRINT_DEBUG_INFO)
				PrintToServer("Teleporting %d to spawn.", clientIdx);

			if (TTS_ShouldStun || TTS_ShouldImmobilize)
			{
				PrintCenterText(clientIdx, TTS_MessageStun);
				PrintToChat(clientIdx, TTS_MessageStun);
			}
			else
			{
				PrintCenterText(clientIdx, TTS_Message);
				PrintToChat(clientIdx, TTS_Message);
			}
		}
		
		if (curTime >= TTS_RemoveEffectsAt[clientIdx])
		{
			TTS_RemoveEffectsAt[clientIdx] = FAR_FUTURE;
			
			if (IsLivingPlayer(clientIdx))
			{
				if (TTS_ShouldUber && TF2_IsPlayerInCondition(clientIdx, TFCond_Ubercharged))
					TF2_RemoveCondition(clientIdx, TFCond_Ubercharged);
				if (TTS_ShouldInvincible && GetEntProp(clientIdx, Prop_Data, "m_takedamage") == 0)
					SetEntProp(clientIdx, Prop_Data, "m_takedamage", 2);
				if (TTS_ShouldKnockbackImmune && TF2_IsPlayerInCondition(clientIdx, TFCond_MegaHeal))
					TF2_RemoveCondition(clientIdx, TFCond_MegaHeal);
				if (TTS_ShouldStun && TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
					TF2_RemoveCondition(clientIdx, TFCond_Dazed);
				if (TTS_ShouldImmobilize && GetEntProp(clientIdx, Prop_Send, "movetype") == any:MOVETYPE_NONE)
				{
					SetEntityMoveType(clientIdx, MOVETYPE_WALK);
					TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, Float:{0.0,0.0,0.0});
				}
			}
		}
		else if (TTS_RemoveEffectsAt[clientIdx] != FAR_FUTURE)
			TTS_RefreshEffects(clientIdx);
	}
}

stock InitTestValues()
{
	TTS_Enabled = true;
	TTS_DamageThreshold = 99.0;
	TTS_ShouldUber = true;
	TTS_ShouldInvincible = true;
	TTS_ShouldKnockbackImmune = true;
	TTS_ShouldStun = true;
	TTS_EffectDuration = 5.0;
	TTS_StunLevel = 2;
	TTS_IncludeRed = false;
	TTS_DamageFactorBlu = 0.5;
	TTS_DamageFactorRed = 1.0;
	TTS_OpposingSpawnDelay = 60.0;
	TTS_Blacklist = "koth_;vsh_2fortdesk_;arena_nucleus";
}

stock bool:IsPlayerInRange(player, Float:position[3], Float:maxDistance)
{
	maxDistance *= maxDistance;
	
	static Float:playerPos[3];
	GetEntPropVector(player, Prop_Data, "m_vecOrigin", playerPos);
	return GetVectorDistance(position, playerPos, true) <= maxDistance;
}

stock FindRandomPlayer(bool:isBossTeam, Float:position[3] = NULL_VECTOR, Float:maxDistance = 0.0)
{
	new player = -1;

	// first, get a player count for the team we care about
	new playerCount = 0;
	for (new clientIdx = 0; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;
			
		if (maxDistance > 0.0 && !IsPlayerInRange(clientIdx, position, maxDistance))
			continue;

		if ((isBossTeam && GetClientTeam(clientIdx) == BossTeam) || (!isBossTeam && GetClientTeam(clientIdx) != BossTeam))
			playerCount++;
	}

	// ensure there's at least one living valid player
	if (playerCount <= 0)
		return -1;

	// now randomly choose our victim
	new rand = GetRandomInt(0, playerCount - 1);
	playerCount = 0;
	for (new clientIdx = 0; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;

		if (maxDistance > 0.0 && !IsPlayerInRange(clientIdx, position, maxDistance))
			continue;
			
		if ((isBossTeam && GetClientTeam(clientIdx) == BossTeam) || (!isBossTeam && GetClientTeam(clientIdx) != BossTeam))
		{
			if (playerCount == rand) // needed if rand is 0
			{
				player = clientIdx;
				break;
			}
			playerCount++;
			if (playerCount == rand) // needed if rand is playerCount - 1, executes for all others except 0
			{
				player = clientIdx;
				break;
			}
		}
	}
	
	return player;
}

stock bool:IsLivingPlayer(clientIdx)
{
	if (clientIdx <= 0 || clientIdx >= MAX_PLAYERS)
		return false;
		
	return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
}

stock CharPos(const String:str[], length, c, startPos)
{
	for (new i = startPos; i < length; i++)
		if (str[i] == c)
			return i;

	return -1;
}

stock bool:StartsWithSubstring(String:str[], strLength, String:multiStr[], startPos, endPos)
{
	new compareCount = endPos - startPos;
	if (strLength < compareCount)
		return false; // impossible
	
	for (new i = 0; i < compareCount; i++)
		if (CharToLower(str[i]) != CharToLower(multiStr[startPos + i]))
			return false;
			
	return true;
}
