#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_NAME "[L4D2] Damage Mod"
#define PLUGIN_VERSION "1.0"
#define DevInfo false
#define CVARS FCVAR_NOTIFY
ConVar IsPluginEnabled;
ConVar l4d2_hunter_damage;
ConVar l4d2_smoker_damage;
ConVar l4d2_boomer_damage;
ConVar l4d2_spitter1_damage;
ConVar l4d2_spitter2_damage;
ConVar l4d2_jockey_damage;
ConVar l4d2_charger_damage;
ConVar l4d2_tank_damage;
ConVar l4d2_tankrock_damage;
ConVar l4d2_common_damage;

public Plugin myinfo =
{
   name = PLUGIN_NAME,
   author = "Jonny",
   description = "",
   version = PLUGIN_VERSION,
   url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	IsPluginEnabled = CreateConVar("l4d2_damagemod", "1", "Is the plugin enabled.", CVARS);
//	HookEvent("player_spawn", Event_PlayerSpawn);
	l4d2_hunter_damage = CreateConVar("l4d2_hunter_damage", "0", "Hunter additional damage", CVARS);
	l4d2_smoker_damage = CreateConVar("l4d2_smoker_damage", "0", "Smoker additional damage", CVARS);
	l4d2_boomer_damage = CreateConVar("l4d2_boomer_damage", "0", "Boomer additional damage", CVARS);
	l4d2_spitter1_damage = CreateConVar("l4d2_spitter1_damage", "0", "Spitter additional damage", CVARS);
	l4d2_spitter2_damage = CreateConVar("l4d2_spitter2_damage", "0", "Spitter additional damage (spit)", CVARS);
	l4d2_jockey_damage = CreateConVar("l4d2_jockey_damage", "0", "Jockey additional damage", CVARS);
	l4d2_charger_damage = CreateConVar("l4d2_charger_damage", "0", "Charger additional damage", CVARS);
	l4d2_tank_damage = CreateConVar("l4d2_tank_damage", "0", "Tank additional damage", CVARS);
	l4d2_tankrock_damage = CreateConVar("l4d2_tankrock_damage", "0", "Tank additional damage", CVARS);
	l4d2_common_damage = CreateConVar("l4d2_common_damage", "0", "Common additional damage", CVARS);
	HookEvent("player_hurt", Event_PlayerHurt);
}

stock int ApplyCustomDamage(int Health, int Damage)
{
	if (Damage >= Health)
		return 1;
	else
		return Health - Damage;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarInt(IsPluginEnabled) < 1)
	{
		return Plugin_Continue;
	}
	int enemy = GetClientOfUserId(GetEventInt(event, "attacker"));
	int target = GetClientOfUserId(GetEventInt(event, "userid"));
	if (target == 0)
		return Plugin_Continue;
		
	if (enemy == target)
		return Plugin_Continue;

	int damagetype = GetEventInt(event, "type");

	char weapon[16];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
//	int damage = GetEventInt(event, "dmg_health");
	int health = GetClientHealth(target);

	if (StrEqual(weapon, "", false))
	{
		if (damagetype != 128)
		{
#if DevInfo
			PrintToChatAll("\x05Unknown damage:\x01 Common -> \x04?\x01 :: Type (\x04%d\x01) :: Damage (\x04%d\x01)", damagetype, damage);
#endif
			return Plugin_Continue;
		}
		SetEntityHealth(target, ApplyCustomDamage(health, GetConVarInt(l4d2_common_damage)));
	}
	else if (StrEqual(weapon, "boomer_claw", false))
	{
		if (damagetype != 128)
		{
#if DevInfo		
			PrintToChatAll("\x05Unknown damage:\x01 Boomer -> \x04boomer_claw\x01 :: Type (\x04%d\x01) :: Damage (\x04%d\x01)", damagetype, damage);
#endif
			return Plugin_Continue;
		}
		SetEntityHealth(target, ApplyCustomDamage(health, GetConVarInt(l4d2_boomer_damage)));
	}
	else if (StrEqual(weapon, "charger_claw", false))
	{
		if (damagetype != 128)
		{
#if DevInfo		
			PrintToChatAll("\x05Unknown damage:\x01 Charger -> \x04charger_claw\x01 :: Type (\x04%d\x01) :: Damage (\x04%d\x01)", damagetype, damage);
#endif
			return Plugin_Continue;
		}
		SetEntityHealth(target, ApplyCustomDamage(health, GetConVarInt(l4d2_charger_damage)));
	}
	else if (StrEqual(weapon, "hunter_claw", false))
	{
		if (damagetype != 128)
		{
#if DevInfo		
			PrintToChatAll("\x05Unknown damage:\x01 Hunter -> \x04hunter_claw\x01 :: Type (\x04%d\x01) :: Damage (\x04%d\x01)", damagetype, damage);
#endif
			return Plugin_Continue;
		}
		SetEntityHealth(target, ApplyCustomDamage(health, GetConVarInt(l4d2_hunter_damage)));
	}
	else if (StrEqual(weapon, "smoker_claw", false))
	{
		if (damagetype != 128)
		{
#if DevInfo		
			PrintToChatAll("\x05Unknown damage:\x01 Smoker -> \x04smoker_claw\x01 :: Type (\x04%d\x01) :: Damage (\x04%d\x01)", damagetype, damage);
#endif
			return Plugin_Continue;
		}
		SetEntityHealth(target, ApplyCustomDamage(health, GetConVarInt(l4d2_smoker_damage)));
	}
	else if (StrEqual(weapon, "spitter_claw", false))
	{
		if (damagetype != 128)
		{
#if DevInfo		
			PrintToChatAll("\x05Unknown damage:\x01 Spitter -> \x04spitter_claw\x01 :: Type (\x04%d\x01) :: Damage (\x04%d\x01)", damagetype, damage);
#endif
			return Plugin_Continue;
		}
		SetEntityHealth(target, ApplyCustomDamage(health, GetConVarInt(l4d2_spitter1_damage)));
	}
	else if (StrEqual(weapon, "insect_swarm", false))
	{
		if (damagetype != 263168)
		{
#if DevInfo		
			PrintToChatAll("\x05Unknown damage:\x01 Spitter -> \x04insect_swarm\x01 :: Type (\x04%d\x01) :: Damage (\x04%d\x01)", damagetype, damage);
#endif
			return Plugin_Continue;
		}
		SetEntityHealth(target, ApplyCustomDamage(health, GetConVarInt(l4d2_spitter2_damage)));
	}
	else if (StrEqual(weapon, "jockey_claw", false))
	{
		if (damagetype != 128)
		{
#if DevInfo		
			PrintToChatAll("\x05Unknown damage:\x01 Jockey -> \x04jockey_claw\x01 :: Type (\x04%d\x01) :: Damage (\x04%d\x01)", damagetype, damage);
#endif
			return Plugin_Continue;
		}
		SetEntityHealth(target, ApplyCustomDamage(health, GetConVarInt(l4d2_jockey_damage)));
	}
	else if (StrEqual(weapon, "tank_claw", false))
	{
		if (damagetype != 128)
		{
#if DevInfo		
			PrintToChatAll("\x05Unknown damage:\x01 Tank -> \x04tank_claw\x01 :: Type (\x04%d\x01) :: Damage (\x04%d\x01)", damagetype, damage);
#endif
			return Plugin_Continue;
		}
		SetEntityHealth(target, ApplyCustomDamage(health, GetConVarInt(l4d2_tank_damage)));
	}
	else if (StrEqual(weapon, "tank_rock", false))
	{
		if (damagetype != 128)
		{
#if DevInfo		
			PrintToChatAll("\x05Unknown damage:\x01 Tank -> \x04tank_rock\x01 :: Type (\x04%d\x01) :: Damage (\x04%d\x01)", damagetype, damage);
#endif
			return Plugin_Continue;
		}
		SetEntityHealth(target, ApplyCustomDamage(health, GetConVarInt(l4d2_tankrock_damage)));
	}
	else
	{
#if DevInfo		
		PrintToChatAll("\x05 DMG(%d): \x04%N\x01 --dmgto-> \x04%N\x01 :: weapon(\x04%s\x01) :: type(\x04%d\x01)", damage, enemy, target, weapon, damagetype);
#endif		
	}
	return Plugin_Continue;
}