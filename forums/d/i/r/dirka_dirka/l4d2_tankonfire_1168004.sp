#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define PLUGIN_VERSION "1.1"

#define ZOMBIECLASS_TANK 8
#define DMG_BURN (1 << 3)    // heat burned
#define SPECTATORS 1
#define SURVIVORS 2
#define INFECTED 3
#define NORMAL_SPEED 1.0
#define TAG		"\x03[TANK]\x01 "

public Plugin:myinfo =
{
	name = "L4D2 Tank-on-fire Speed Booster",
	author = "DarkNoghri && Dirka_Dirka",
	description = "Increase the speed of tanks when on fire in versus.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

new tankIndex[MAXPLAYERS+1] = 0;
new bool:isFast[MAXPLAYERS+1] = false;
new Handle:h_cvarBoostEnabled=INVALID_HANDLE;
new Handle:h_cvarSpeedBoost=INVALID_HANDLE;
new Handle:h_cvarWarningEnabled=INVALID_HANDLE;
new Handle:h_cvarFireDamage=INVALID_HANDLE;
new Handle:h_CheckFireTimer=INVALID_HANDLE;
new boost_enabled;
new warning_enabled;
new fire_damage;
new Float:multiplier;
new tankCount = 0;
new num_warnings[MAXPLAYERS+1] = 0;

public OnPluginStart()
{
	CreateConVar("l4d2_tankonfire_version", PLUGIN_VERSION, "Version of L4D2 Tank-on-fire Speed Booster", FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false) && !StrEqual(game_name, "left4dead", false))
	{		
		SetFailState("Plugin supports Left 4 Dead 1 or 2 only.");
	}
	
	HookEvent("round_start", EventRoundStart);
	HookEvent("round_end", EventRoundEnd);
	
	HookEvent("player_spawn", EventTanks);
	HookEvent("player_disconnect", EventTanks);
	HookEvent("player_death", EventTanks);
	
	HookEvent("player_bot_replace", EventTanks);
	HookEvent("bot_player_replace", EventTanks);
	HookEvent("player_team", EventTanksDelayed);
	
	HookEvent("player_hurt", EventPlayerHurt, EventHookMode_Pre);
	
	h_cvarBoostEnabled = CreateConVar("l4d2_tankfire_boost_enable", "1", "0 turns speed boost off, 1 turns it on.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	h_cvarSpeedBoost = CreateConVar("l4d2_tankfire_boost_amount", "1.25", "Multiplier for tank speed while on fire.", FCVAR_PLUGIN, true, 0.5, true, 2.0);
	h_cvarWarningEnabled = CreateConVar("l4d2_tankfire_warning_enable", "1", "1 prints a warning to the screen when the tank is lit. 0 does not.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	h_cvarFireDamage = CreateConVar("l4d2_tankfire_damage_amount", "0", "Amount of fire damage the tank deals upon punching.", FCVAR_PLUGIN, true, 0.0, true, 15.0);
	
	HookConVarChange(h_cvarBoostEnabled, ChangeVars);
	HookConVarChange(h_cvarSpeedBoost, ChangeVars);
	HookConVarChange(h_cvarWarningEnabled, ChangeVars);
	HookConVarChange(h_cvarFireDamage, ChangeVars);
	
	boost_enabled = GetConVarInt(h_cvarBoostEnabled);
	multiplier = GetConVarFloat(h_cvarSpeedBoost);
	warning_enabled = GetConVarInt(h_cvarWarningEnabled);
	fire_damage = GetConVarInt(h_cvarFireDamage);
}

public Action:CheckFire(Handle:timer)
{
	if (!boost_enabled) return Plugin_Continue;
	if (!tankCount) return Plugin_Continue;
	
	new index = 0;
	for (new i=1; i <= tankCount; i++)
	{	
		index = tankIndex[i];
		if (!IsValidEntity(index)) continue;
		
		if (IsPlayerOnFire(index))
		{
			if (!isFast[index])
			{
				SetTankSpeed(index, multiplier);
				isFast[index] = true;
				if(warning_enabled == 1 && num_warnings[i] == 0) 
				{
					PrintToChatAll("%sTank: \x04%N\x01 is a burnin'. Watch out!", TAG, index);
					num_warnings[i]++;
				}
			}
		}
		else if(isFast[index])	//not on fire but still fast
		{
			SetTankSpeed(index, NORMAL_SPEED);
			isFast[index] = false;
		}
	}
	return Plugin_Continue;
}	
/* Currently.. not needed.
public OnMapStart()
{
}
*/
public OnMapEnd()
{
	if (h_CheckFireTimer != INVALID_HANDLE)
	{
		KillTimer(h_CheckFireTimer);
		h_CheckFireTimer = INVALID_HANDLE;
	}
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	RebuildTankIndex();
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (h_CheckFireTimer != INVALID_HANDLE)
	{
		KillTimer(h_CheckFireTimer);
		h_CheckFireTimer = INVALID_HANDLE;
	}
}

public EventTanks(Handle:event, const String:name[], bool:dontBroadcast)
{
	RebuildTankIndex();
}

public EventTanksDelayed(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.3, RebuildIndexTimer);
}

public Action:EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(fire_damage == 0 || !boost_enabled) return Plugin_Continue;
	if(!tankCount) return Plugin_Continue;
	
	new attackerID = GetEventInt(event, "attacker");
	new defenderID = GetEventInt(event, "userid");
	
	new attacker = GetClientOfUserId(attackerID);
	new defender = GetClientOfUserId(defenderID);
	
	new String:weaponType[64];
	GetEventString(event, "weapon", weaponType, sizeof(weaponType));
	
	if(attacker == 0 || defender == 0 || !IsPlayerTank(attacker) || GetClientTeam(defender) != SURVIVORS || !IsPlayerOnFire(attacker) || !StrEqual(weaponType, "tank_claw", false)) return Plugin_Continue;
	
	DamageEffect(defender);
	
	new hardhp = GetEntProp(defender, Prop_Data, "m_iHealth") +2;
	
	if (fire_damage < hardhp || IsPlayerIncapped(defender))
	{
		SetEntityHealth(defender, hardhp - fire_damage);
	}
	
	else if (fire_damage >= hardhp)
	{
		new Float:temphp = GetEntPropFloat(defender, Prop_Send, "m_healthBuffer");
		
		if (fire_damage < temphp)
		{
			SetEntPropFloat(defender, Prop_Send, "m_healthBuffer", FloatSub(temphp, GetConVarFloat(h_cvarFireDamage)));
		}
	}
	
	return Plugin_Continue;
}

bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

public Action:RebuildIndexTimer(Handle:timer)
{
	RebuildTankIndex();
}

RebuildTankIndex()
{
	tankCount = 0;
	for(new i = 1; i < MaxClients; i++)
	{
		num_warnings[i] = 0;
		
		if(!IsClientInGame(i)) continue;
		if(GetClientTeam(i) != INFECTED) continue;
		if(!IsPlayerAlive(i)) continue;
		if(!IsPlayerTank(i)) continue;
		
		tankCount++;
		tankIndex[tankCount] = i;
	}
	
	if ((tankCount != 0) && h_CheckFireTimer == INVALID_HANDLE)
		h_CheckFireTimer = CreateTimer(1.0, CheckFire, _, TIMER_REPEAT);
	
	if ((tankCount == 0) && h_CheckFireTimer != INVALID_HANDLE)
	{
		KillTimer(h_CheckFireTimer);
		h_CheckFireTimer = INVALID_HANDLE; // not sure what KillTimer sets the handle to...
	}
}

// Checking the zombieclass requires a different check for each game, this doesn't.
stock IsPlayerTank(client)
{
	decl String:playermodel[96];
	GetClientModel(client, playermodel, sizeof(playermodel));
	return (StrContains(playermodel, "hulk", false) > -1);
}

bool:IsPlayerOnFire(client)
{
	if(GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONFIRE) return true;
	else return false;
}

SetTankSpeed(client, Float:value)
{
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", value);
}

public ChangeVars(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	multiplier = GetConVarFloat(h_cvarSpeedBoost);
	boost_enabled = GetConVarInt(h_cvarBoostEnabled);
	warning_enabled = GetConVarInt(h_cvarWarningEnabled);
	fire_damage = GetConVarInt(h_cvarFireDamage);
	
	if(boost_enabled == 0)
	{
		new index = 0;
		for(new i = 1; i <= tankCount; i++)
		{	
			index = tankIndex[i];	//now points to the client
			if(isFast[index])
			{
				isFast[index] = false;
				SetTankSpeed(index, NORMAL_SPEED);
			}
		}
	}
	if(warning_enabled == 0)
	{
		for( new i = 1; i <= MaxClients; i++)
		{
			num_warnings[i] = 0;
		}
	}
}

public Action:DamageEffect(target)
{
	new pointHurt = CreateEntityByName("point_hurt");			// Create point_hurt
	DispatchKeyValue(target, "targetname", "hurtme");				// mark target (client), with the key "targetname" with the value "hurtme"
	DispatchKeyValue(pointHurt, "Damage", "0");					// No Damage, just HUD display. Does stop Reviving though (mark the pointHurt with damage key of 0)
	DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");		// Target Assignment (mark pointHurt with a target, using the previously set value on the client)
	DispatchKeyValue(pointHurt, "DamageType", "DMG_BURN");			// Type of damage (set type on the pointHurt)
	DispatchSpawn(pointHurt);										// Spawn descriped point_hurt
	AcceptEntityInput(pointHurt, "Hurt"); 						// Trigger point_hurt execute (use predefined Hurt command to do damage to target)
	AcceptEntityInput(pointHurt, "Kill"); 						// Remove point_hurt
	DispatchKeyValue(target, "targetname",	"cake");			// Clear target's mark (ie, not the target next time)
}
