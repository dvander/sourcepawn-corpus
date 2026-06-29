#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.2"

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8

public Plugin:myinfo = {
	name = "Digestion",
	author = "Oshroth",
	description = "Infected regain health from attacking survivors.",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public OnPluginStart() {
	decl String:game[12];
	new Handle:version = INVALID_HANDLE;
	
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1) SetFailState("Digestion will only work with Left 4 Dead 2!");
	
	version = CreateConVar("sm_digestion_version", PLUGIN_VERSION, "Digestion plugin version.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	CreateConVar("sm_digestion_hunter_heal", "0.5", "Amount of damage converted to health", _, true, 0.0);
	CreateConVar("sm_digestion_hunter_healmaxhp", "750", "Hunter max health", _, true, 0.0, true, 65535.0);
	CreateConVar("sm_digestion_hunter_incap", "125", "Amount of health given for incapping a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_hunter_kill", "250", "Amount of health given for killing a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_hunter_enable", "1", "Enable digestion for hunter", _, true, 0.0, true, 1.0);
	
	CreateConVar("sm_digestion_smoker_heal", "0.5", "Amount of damage converted to health", _, true, 0.0);
	CreateConVar("sm_digestion_smoker_healmaxhp", "750", "Smoker max health", _, true, 0.0, true, 65535.0);
	CreateConVar("sm_digestion_smoker_incap", "125", "Amount of health given for incapping a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_smoker_kill", "250", "Amount of health given for killing a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_smoker_enable", "1", "Enable digestion for smoker", _, true, 0.0, true, 1.0);
	
	CreateConVar("sm_digestion_boomer_heal", "0.5", "Amount of damage converted to health", _, true, 0.0);
	CreateConVar("sm_digestion_boomer_healmaxhp", "150", "Boomer max health", _, true, 0.0, true, 65535.0);
	CreateConVar("sm_digestion_boomer_incap", "25", "Amount of health given for incapping a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_boomer_kill", "50", "Amount of health given for killing a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_boomer_enable", "1", "Enable digestion for boomer", _, true, 0.0, true, 1.0);
	
	CreateConVar("sm_digestion_charger_heal", "0.5", "Amount of damage converted to health", _, true, 0.0);
	CreateConVar("sm_digestion_charger_healmaxhp", "1800", "Charger max health", _, true, 0.0, true, 65535.0);
	CreateConVar("sm_digestion_charger_incap", "300", "Amount of health given for incapping a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_charger_kill", "600", "Amount of health given for killing a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_charger_enable", "1", "Enable digestion for charger", _, true, 0.0, true, 1.0);
	
	CreateConVar("sm_digestion_tank_heal", "0.5", "Amount of damage converted to health", _, true, 0.0);
	CreateConVar("sm_digestion_tank_healmaxhp", "18000", "Tank max health", _, true, 0.0, true, 65535.0);
	CreateConVar("sm_digestion_tank_incap", "500", "Amount of health given for incapping a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_tank_kill", "1000", "Amount of health given for killing a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_tank_enable", "1", "Enable digestion for tank", _, true, 0.0, true, 1.0);
	
	CreateConVar("sm_digestion_spitter_heal", "0.5", "Amount of damage converted to health", _, true, 0.0);
	CreateConVar("sm_digestion_spitter_healmaxhp", "300", "Spitter max health", _, true, 0.0, true, 65535.0);
	CreateConVar("sm_digestion_spitter_incap", "50", "Amount of health given for incapping a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_spitter_kill", "100", "Amount of health given for killing a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_spitter_enable", "1", "Enable digestion for spitter", _, true, 0.0, true, 1.0);
	
	CreateConVar("sm_digestion_jockey_heal", "0.5", "Amount of damage converted to health", _, true, 0.0);
	CreateConVar("sm_digestion_jockey_healmaxhp", "975", "Jockey max health", _, true, 0.0, true, 65535.0);
	CreateConVar("sm_digestion_jockey_incap", "163", "Amount of health given for incapping a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_jockey_kill", "325", "Amount of health given for killing a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_jockey_enable", "1", "Enable digestion for jockey", _, true, 0.0, true, 1.0);
	
	/*CreateConVar("sm_digestion_witch_heal", "0.25", "Amount of damage converted to health", _, true, 0.0);
	CreateConVar("sm_digestion_witch_healmaxhp", "250", "Max health", _, true, 0.0, true, 65535.0);
	CreateConVar("sm_digestion_witch_incap", "100", "Amount of health given for incapping a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_witch_kill", "200", "Amount of health given for killing a survivor", _, true, 0.0);
	CreateConVar("sm_digestion_witch_enable", "1", "Enable digestion", _, true, 0.0, true, 1.0);*/
	
	AutoExecConfig(true, "l4d2_digestion");
	
	SetConVarString(version, PLUGIN_VERSION, true);
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_incapacitated", Event_PlayerIncap);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	new damage = GetEventInt(event, "dmg_health");
	new Float:recover;
	new maxHP;
	new enable;
	new oldHealth;
	new newHealth;
	if(attacker <= 0 || target <= 0) {
		return Plugin_Continue;
	}
	if(!IsClientInGame(attacker) || !IsPlayerAlive(attacker)) {
		return Plugin_Continue;
	}
	
	if((GetClientTeam(target) == 2) && (GetClientTeam(attacker) == 3)) {
		new class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
		
		switch (class)  
		{	
			case ZOMBIECLASS_BOOMER:
			{
				recover = GetConVarFloat(FindConVar("sm_digestion_boomer_heal"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_boomer_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_boomer_enable"));
			}
			
			case ZOMBIECLASS_CHARGER:
			{
				recover = GetConVarFloat(FindConVar("sm_digestion_charger_heal"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_charger_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_charger_enable"));
			}
			
			case ZOMBIECLASS_JOCKEY:
			{
				recover = GetConVarFloat(FindConVar("sm_digestion_jockey_heal"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_jockey_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_jockey_enable"));
			}
			case ZOMBIECLASS_HUNTER:
			{
				recover = GetConVarFloat(FindConVar("sm_digestion_hunter_heal"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_hunter_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_hunter_enable"));
			}
			
			case ZOMBIECLASS_SMOKER:
			{
				recover = GetConVarFloat(FindConVar("sm_digestion_smoker_heal"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_smoker_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_smoker_enable"));
			}
			
			case ZOMBIECLASS_SPITTER:
			{
				recover = GetConVarFloat(FindConVar("sm_digestion_spitter_heal"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_spitter_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_spitter_enable"));
			}
			
			case ZOMBIECLASS_TANK:
			{
				recover = GetConVarFloat(FindConVar("sm_digestion_tank_heal"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_tank_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_tank_enable"));
			}
		}
		if(!enable || recover <= 0.0) {
			return Plugin_Continue;
		}
		oldHealth = GetClientHealth(attacker);
		newHealth = RoundToCeil(damage * recover) + oldHealth;
		//PrintToChatAll("%N OM NOM NOM NOM'd %N", atacker, target);
		//PrintToChatAll("%N got %d HP back for %d damage.", attacker, RoundToCeil(damage * recover), damage);
		if(newHealth > maxHP) {
			newHealth = maxHP;
		}
		if(newHealth > 65355) {
			newHealth = 65355;
		}
		SetEntityHealth(attacker, newHealth);
	}
	return Plugin_Continue;
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	new bonus;
	new maxHP;
	new enable;
	new oldHealth;
	new newHealth;
	if(attacker <= 0 || target <= 0) {
		return Plugin_Continue;
	}
	if(!IsClientInGame(attacker) || !IsPlayerAlive(attacker)) {
		return Plugin_Continue;
	}
	
	if((GetClientTeam(target) == 2) && (GetClientTeam(attacker) == 3)) {
		new class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
		
		switch (class)  
		{	
			case ZOMBIECLASS_BOOMER:
			{
				bonus = GetConVarInt(FindConVar("sm_digestion_boomer_kill"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_boomer_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_boomer_enable"));
			}
			
			case ZOMBIECLASS_CHARGER:
			{
				bonus = GetConVarInt(FindConVar("sm_digestion_charger_kill"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_charger_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_charger_enable"));
			}
			
			case ZOMBIECLASS_JOCKEY:
			{
				bonus = GetConVarInt(FindConVar("sm_digestion_jockey_kill"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_jockey_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_jockey_enable"));
			}
			case ZOMBIECLASS_HUNTER:
			{
				bonus = GetConVarInt(FindConVar("sm_digestion_hunter_kill"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_hunter_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_hunter_enable"));
			}
			
			case ZOMBIECLASS_SMOKER:
			{
				bonus = GetConVarInt(FindConVar("sm_digestion_smoker_kill"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_smoker_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_smoker_enable"));
			}
			
			case ZOMBIECLASS_SPITTER:
			{
				bonus = GetConVarInt(FindConVar("sm_digestion_spitter_kill"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_spitter_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_spitter_enable"));
			}
			
			case ZOMBIECLASS_TANK:
			{
				bonus = GetConVarInt(FindConVar("sm_digestion_tank_kill"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_tank_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_tank_enable"));
			}
		}
		if(!enable || bonus <= 0) {
			return Plugin_Continue;
		}
		oldHealth = GetClientHealth(attacker);
		newHealth = bonus + oldHealth;
		PrintHintTextToAll("%N got %d health for killing %N.", attacker, bonus, target);
		if(newHealth > maxHP) {
			newHealth = maxHP;
		}
		if(newHealth > 65355) {
			newHealth = 65355;
		}
		SetEntityHealth(attacker, newHealth);
	}
	return Plugin_Continue;
}

public Action:Event_PlayerIncap(Handle:event, const String:name[], bool:dontBroadcast) {
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	new bonus;
	new maxHP;
	new enable;
	new oldHealth;
	new newHealth;
	if(attacker <= 0 || target <= 0) {
		return Plugin_Continue;
	}
	if(!IsClientInGame(attacker) || !IsPlayerAlive(attacker)) {
		return Plugin_Continue;
	}
	
	if((GetClientTeam(target) == 2) && (GetClientTeam(attacker) == 3)) {
		new class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
		
		switch (class)  
		{	
			case ZOMBIECLASS_BOOMER:
			{
				bonus = GetConVarInt(FindConVar("sm_digestion_boomer_incap"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_boomer_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_boomer_enable"));
			}
			
			case ZOMBIECLASS_CHARGER:
			{
				bonus = GetConVarInt(FindConVar("sm_digestion_charger_incap"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_charger_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_charger_enable"));
			}
			
			case ZOMBIECLASS_JOCKEY:
			{
				bonus = GetConVarInt(FindConVar("sm_digestion_jockey_incap"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_jockey_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_jockey_enable"));
			}
			case ZOMBIECLASS_HUNTER:
			{
				bonus = GetConVarInt(FindConVar("sm_digestion_hunter_incap"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_hunter_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_hunter_enable"));
			}
			
			case ZOMBIECLASS_SMOKER:
			{
				bonus = GetConVarInt(FindConVar("sm_digestion_smoker_incap"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_smoker_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_smoker_enable"));
			}
			
			case ZOMBIECLASS_SPITTER:
			{
				bonus = GetConVarInt(FindConVar("sm_digestion_spitter_incap"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_spitter_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_spitter_enable"));
			}
			
			case ZOMBIECLASS_TANK:
			{
				bonus = GetConVarInt(FindConVar("sm_digestion_tank_incap"));
				maxHP = GetConVarInt(FindConVar("sm_digestion_tank_healmaxhp"));
				enable = GetConVarBool(FindConVar("sm_digestion_tank_enable"));
			}
		}
		if(!enable || bonus <= 0) {
			return Plugin_Continue;
		}
		oldHealth = GetClientHealth(attacker);
		newHealth = bonus + oldHealth;
		PrintHintTextToAll("%N got %d health for incapping %N.", attacker, bonus, target);
		if(newHealth > maxHP) {
			newHealth = maxHP;
		}
		if(newHealth > 65355) {
			newHealth = 65355;
		}
		SetEntityHealth(attacker, newHealth);
	}
	return Plugin_Continue;
}