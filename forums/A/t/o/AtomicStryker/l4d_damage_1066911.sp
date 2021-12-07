#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION								"1.0.4"

#define TEST_DEBUG									0
#define TEST_DEBUG_LOG								0

static Handle:modifyDamageEnabled					=	INVALID_HANDLE;
static Handle:modifyMeleeDamageCommons				=	INVALID_HANDLE;

static Handle:trieModdedWeapons						=	INVALID_HANDLE;
static Handle:trieModdedWeaponsTank					=	INVALID_HANDLE;

static 		damageModEnabled						=	1;
static 		damageModEnabledForCI					=	1;
static bool:ignoreNextDamageDealt[MAXPLAYERS+1]		=	false;


public Plugin:myinfo =
{
	name = "L4D Weapon Damage Mod",
	author = "AtomicStryker",
	description = "Modify damage for each Weapon",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=116668"
};

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (StrContains(game_name, "left4dead", false) < 0)
		SetFailState("Plugin supports Left 4 Dead or L4D2 only.");

	CreateConVar("l4d_damage_mod_version", PLUGIN_VERSION, "L4D Weapon Damage Mod Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	
	modifyDamageEnabled = CreateConVar("l4d_damage_enabled", "1", "Enable or Disable the L4D Damage Plugin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	modifyMeleeDamageCommons = CreateConVar("l4d_damage_melee_commons_enabled", "0", "Enable or Disable modifying melee weapon damage on Common Infected (CAUTION)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_damage_weaponmulti", CmdSetWeaponMultiplier, ADMFLAG_CHEATS);
	RegAdminCmd("sm_damage_tank_weaponmulti", CmdSetWeaponMultiplierTank, ADMFLAG_CHEATS);
	RegAdminCmd("sm_damage_reset", CmdClearWeaponsTrie, ADMFLAG_CHEATS);
	
	trieModdedWeapons = CreateTrie();
	trieModdedWeaponsTank = CreateTrie();
	
	HookConVarChange(modifyDamageEnabled, _DM_ConVarChange);
	HookConVarChange(modifyMeleeDamageCommons, _DM_ConVarChange);
	
	_DM_OnModuleEnabled();
}

public _DM_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(modifyDamageEnabled))
	{
		_DM_OnModuleEnabled();
		damageModEnabled = 1;
	}
	else
	{
		_DM_OnModuleDisabled();
		damageModEnabled = 0;
	}
	
	damageModEnabledForCI = GetConVarBool(modifyMeleeDamageCommons);
}

_DM_OnModuleEnabled()
{
	HookEvent("player_hurt",_DM_PlayerHurt_Event, EventHookMode_Pre);
	HookEvent("infected_hurt", _DM_InfectedHurt_Event);
}

_DM_OnModuleDisabled()
{
	UnhookEvent("player_hurt",_DM_PlayerHurt_Event, EventHookMode_Pre);
	UnhookEvent("infected_hurt", _DM_InfectedHurt_Event);
}

public OnPluginEnd()
{
	CloseHandle(trieModdedWeapons);
	CloseHandle(trieModdedWeaponsTank);
}

public Action:_DM_PlayerHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client || !attacker || ignoreNextDamageDealt[attacker]) return Plugin_Continue; // both must be valid players.
	
	decl Float:multiplierWeapon, String:weaponname[64];
	
	new dmg_health = GetEventInt(event, "dmg_health");	 // get the amount of damage done
	new eventhealth = GetEventInt(event, "health");	// get the health after damage as the event sees it
	new damagedelta;
	
	if (dmg_health < 1 || eventhealth < 1) return Plugin_Continue; // exclude pointless cases
	
	GetClientWeapon(attacker, weaponname, sizeof(weaponname)); // get the attacker weapon
	
	if (StrEqual(weaponname, "weapon_melee"))
	{
		GetEntPropString(GetPlayerWeaponSlot(attacker, 1), Prop_Data, "m_strMapSetScriptName", weaponname, sizeof(weaponname));
	}
	
	if (IsPlayerTank(client) ? GetTrieValue(trieModdedWeaponsTank, weaponname, multiplierWeapon) : GetTrieValue(trieModdedWeapons, weaponname, multiplierWeapon))
	{
		damagedelta = RoundToNearest((dmg_health * multiplierWeapon) - dmg_health);
		
		switch (damagedelta > 0)
		{
			case true:
			{
				applyDamage(damagedelta, client, attacker);
				DebugPrintToAll("Changed weapon %s damage used by %N on %N, was %i, adding %i", weaponname, attacker, client, dmg_health, damagedelta);
			}
			case false:
			{
				new health = eventhealth - damagedelta;
			
				if (health < 1)
				{
					damagedelta += (health - 1);
					health = 1;
				}
				
				SetEntityHealth(client, health);
				SetEventInt(event, "dmg_health", dmg_health + damagedelta); // for correct stats.
				SetEventInt(event, "health", health);
				
				DebugPrintToAll("Changed weapon %s damage used by %N on %N, was %i, is now %i, oldhealth %i, newhealth %i", weaponname, attacker, client, dmg_health, dmg_health+damagedelta, eventhealth, health);
			}
		}
	}

	return Plugin_Continue;
}

public Action:_DM_InfectedHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl Float:multiplierWeapon, String:weaponname[64];
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new entity = (GetEventInt(event, "entityid"));
	
	if (!attacker || !IsValidEntity(entity) || ignoreNextDamageDealt[attacker]) return; //both must be valid
	
	decl String:entname[32];
	GetEdictClassname(entity, entname, sizeof(entname));
	
	new dmg_health = GetEventInt(event,"amount");	 // get the amount of damage done
	new eventhealth = GetEntProp(entity, Prop_Data, "m_iHealth");	// get the health after damage was applied (its a POST hook)
	new damagedelta;
	
	if (dmg_health < 1 || eventhealth < 1) return; // exclude zero damage calculations
	
	GetClientWeapon(attacker, weaponname, sizeof(weaponname));
	
	if (StrEqual(weaponname, "weapon_melee"))
	{
		if (StrEqual(entname, "infected", false) && !damageModEnabledForCI) return; // melee weapon mods against commons is tricky business
	
		GetEntPropString(GetPlayerWeaponSlot(attacker, 1), Prop_Data, "m_strMapSetScriptName", weaponname, sizeof(weaponname));
	}
	
	if(GetTrieValue(trieModdedWeapons, weaponname, multiplierWeapon))
	{
		damagedelta = RoundToNearest((dmg_health * multiplierWeapon) - dmg_health);
		
		switch (damagedelta > 0)
		{
			case true:
			{
				applyDamage(damagedelta, entity, attacker);
				DebugPrintToAll("Changed weapon %s damage used by %N on a Witch, was %i, adding %i", weaponname, attacker, dmg_health, damagedelta);
			}
			case false:
			{
				new health = eventhealth - damagedelta;
			
				if (health < 1)
				{
					damagedelta += (health - 1);
					health = 1;
				}
				
				SetEntProp(entity, Prop_Data, "m_iHealth", health);
				SetEventInt(event, "amount", damagedelta); // for correct stats.
				
				DebugPrintToAll("Changed weapon %s damage used by %N on a Witch, was %i, is now %i, oldhealth %i, newhealth %i", weaponname, attacker, dmg_health, dmg_health+damagedelta, eventhealth, health);
			}
		}
	}
}

public Action:CmdSetWeaponMultiplier(client, args)
{
	if (!damageModEnabled) return Plugin_Handled;
	
	decl String:weapon[64], String:multiplier[20];
	
	if (args == 2)
	{
		GetCmdArg(1, weapon, sizeof(weapon));
		GetCmdArg(2, multiplier, sizeof(multiplier));
		
		SetTrieValue(trieModdedWeapons, weapon, StringToFloat(multiplier));
		ReplyToCommand(client, "Successfully set damage of weapon: %s to %.2f!", weapon, StringToFloat(multiplier));
	}
	else if (client)
	{
		decl String:weaponname[64];
		GetClientWeapon(client, weaponname, sizeof(weaponname));
		
		if (StrEqual(weaponname, "weapon_melee"))
		{
			GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_strMapSetScriptName", weaponname, sizeof(weaponname));
		}
		
		ReplyToCommand(client,"Usage: sm_damage_weapon <weapon> <multiplier> - your current weapon is %s", weaponname);
	}
	else ReplyToCommand(client,"Usage: sm_damage_weapon <weapon> <multiplier>");
	
	return Plugin_Handled;
}

public Action:CmdSetWeaponMultiplierTank(client, args)
{
	if (!damageModEnabled) return Plugin_Handled;
	
	decl String:weapon[64], String:multiplier[20];
	
	if (args == 2)
	{
		GetCmdArg(1, weapon, sizeof(weapon));
		GetCmdArg(2, multiplier, sizeof(multiplier));
		
		SetTrieValue(trieModdedWeaponsTank, weapon, StringToFloat(multiplier));
		ReplyToCommand(client, "Successfully set tank damage of weapon: %s to %.2f!", weapon, StringToFloat(multiplier));
	}
	else if (client)
	{
		decl String:weaponname[64];
		GetClientWeapon(client, weaponname, sizeof(weaponname));
		
		if (StrEqual(weaponname, "weapon_melee"))
		{
			GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_strMapSetScriptName", weaponname, sizeof(weaponname));
		}
		
		ReplyToCommand(client,"Usage: sm_damage_tank_weapon <weapon> <multiplier> - your current weapon is %s", weaponname);
	}
	else ReplyToCommand(client,"Usage: sm_damage_tank_weapon <weapon> <multiplier>");
	
	return Plugin_Handled;
}

public Action:CmdClearWeaponsTrie(client, args)
{
	if (!damageModEnabled) return Plugin_Handled;
	
	ClearTrie(trieModdedWeapons);
	ClearTrie(trieModdedWeaponsTank);
	ReplyToCommand(client, "Cleared the stored damage multipliers of all weapons!");
	
	return Plugin_Handled;
}

stock IsPlayerTank(client)
{
	decl String:playermodel[96];
	GetClientModel(client, playermodel, sizeof(playermodel));
	return (StrContains(playermodel, "hulk", false) > -1);
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if TEST_DEBUG	|| TEST_DEBUG_LOG
	decl String:buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[DAMAGE] %s", buffer);
	PrintToConsole(0, "[DAMAGE] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}

// timer idea by dirtyminuth, damage dealing by pimpinjuice http://forums.alliedmods.net/showthread.php?t=111684
// added some L4D specific checks
static applyDamage(damage, victim, attacker)
{ 
	new Handle:dataPack = CreateDataPack();
	WritePackCell(dataPack, damage);  
	WritePackCell(dataPack, victim);
	WritePackCell(dataPack, attacker);
	
	CreateTimer(0.1, timer_stock_applyDamage, dataPack);
	ignoreNextDamageDealt[attacker] = true;
	CreateTimer(0.2, timer_resetStop, attacker);
}

public Action:timer_resetStop(Handle:timer, any:client)
{
	ignoreNextDamageDealt[client] = false;
}

public Action:timer_stock_applyDamage(Handle:timer, Handle:dataPack)
{
	ResetPack(dataPack);
	new damage = ReadPackCell(dataPack);  
	new victim = ReadPackCell(dataPack);
	new attacker = ReadPackCell(dataPack);
	CloseHandle(dataPack);   

	decl Float:victimPos[3], String:strDamage[16], String:strDamageTarget[16];
	
	if (victim < 20 && IsClientInGame(victim))
	{
		GetClientEyePosition(victim, victimPos);
	}
	else if (IsValidEntity(victim))
	{
		GetEntityAbsOrigin(victim, victimPos);
	}
	else return;
	
	IntToString(damage, strDamage, sizeof(strDamage));
	Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", victim);
	
	new entPointHurt = CreateEntityByName("point_hurt");
	if(!entPointHurt) return;

	// Config, create point_hurt
	DispatchKeyValue(victim, "targetname", strDamageTarget);
	DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
	DispatchKeyValue(entPointHurt, "Damage", strDamage);
	DispatchKeyValue(entPointHurt, "DamageType", "0"); // DMG_GENERIC
	DispatchSpawn(entPointHurt);
	
	// Teleport, activate point_hurt
	TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entPointHurt, "Hurt", (attacker && attacker < 20 && IsClientInGame(attacker)) ? attacker : -1);
	
	// Config, delete point_hurt
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	RemoveEdict(entPointHurt);
}

//entity abs origin code from here
//http://forums.alliedmods.net/showpost.php?s=e5dce96f11b8e938274902a8ad8e75e9&p=885168&postcount=3
stock GetEntityAbsOrigin(entity,Float:origin[3])
{
	if (entity > 0 && IsValidEntity(entity))
	{
		decl Float:mins[3], Float:maxs[3];
		GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
		GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
		GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
		
		origin[0] += (mins[0] + maxs[0]) * 0.5;
		origin[1] += (mins[1] + maxs[1]) * 0.5;
		origin[2] += (mins[2] + maxs[2]) * 0.5;
	}
}