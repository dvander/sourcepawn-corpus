/*
 * Kill Cash Reward
 * 
 * Players earn money for every enemy kill based on 
 * the damage/hit ratio, distance and weapon used.
 * 
 * by Jannik 'Peace-Maker' Hartung
 * visit http://www.wcfan.de/
 * 
 * as requested by MoshMage
 * 
 * http://forums.alliedmods.net/showthread.php?t=141482
 * 
 * Changelog:
 * 1.0: Initial release
 * 1.1: Added convars to adjust the money given
 */

#include <sourcemod>
#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

new Handle:g_hEnable = INVALID_HANDLE;
new Handle:g_hHeadBonus = INVALID_HANDLE;
new Handle:g_hDistanceMultip = INVALID_HANDLE;
new Handle:g_hGrenadeMultip = INVALID_HANDLE;
new Handle:g_hKnifeMultip = INVALID_HANDLE;
new Handle:g_hKnifeBonus = INVALID_HANDLE;

new g_PlayerHitCount[MAXPLAYERS+1][MAXPLAYERS+1];
new g_PlayerDamageDone[MAXPLAYERS+1][MAXPLAYERS+1];

new g_iAccount = -1;

public Plugin:myinfo = 
{
	name = "Kill Cash Reward",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Player earn money by killing an enemy based on dmg/hit, distance and weapon.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	CreateConVar("sm_killcash_version", PLUGIN_VERSION, "Kill Cash Reward version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnable = CreateConVar("sm_killcash_enable", "1", "Enable Kill Cash Reward", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hHeadBonus = CreateConVar("sm_killcash_headbonus", "1000", "Bonus money for headshots", FCVAR_PLUGIN, true, 0.0);
	g_hDistanceMultip = CreateConVar("sm_killcash_distmulti", "10", "Multiplicator of distance between victim and attacker. Isn't used for sniper rifle and knife kills.", FCVAR_PLUGIN, true, 1.0);
	g_hGrenadeMultip = CreateConVar("sm_killcash_grenadeupper", "5", "Upper limit of random multiplicator for HE kills. (1 to x)", FCVAR_PLUGIN, true, 1.0);
	g_hKnifeMultip = CreateConVar("sm_killcash_knifeupper", "5", "Upper limit of random multiplicator for knife kills. (1 to x)", FCVAR_PLUGIN, true, 1.0);
	g_hKnifeBonus = CreateConVar("sm_killcash_knifebonus", "1000", "Bonus money for knife kills", FCVAR_PLUGIN, true, 0.0);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
}

public OnClientDisconnect(client)
{
	ResetHitCount(client);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ResetHitCount(client);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_hEnable))
		return Plugin_Continue;
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	// Don't care for world damage (falling) or selfdamage (hegrenade)
	if(attacker < 1 || victim == attacker)
		return Plugin_Continue;
	
	g_PlayerHitCount[attacker][victim]++;
	g_PlayerDamageDone[attacker][victim] += GetEventInt(event, "dmg_health");
	
	// Player got killed
	if(GetEventInt(event, "health") <= 0)
	{
		new iMoneyIncrease = g_PlayerDamageDone[attacker][victim] / g_PlayerHitCount[attacker][victim];
		
		decl String:weapon_name[32];
		GetEventString(event, "weapon", weapon_name, sizeof(weapon_name));
		
		// Don't add distance for sniping weapons and knife
		if(!StrEqual(weapon_name, "awp") && !StrEqual(weapon_name, "scout") && !StrEqual(weapon_name, "sg550") && !StrEqual(weapon_name, "knife"))
		{			
			//Get the distance
			new Float:victimLoc[3];
			new Float:attackerLoc[3];
			GetClientAbsOrigin(victim,victimLoc);
			GetClientAbsOrigin(attacker,attackerLoc);
			new distance = RoundToNearest(FloatDiv(calcDistance(victimLoc[0], attackerLoc[0], victimLoc[1], attackerLoc[1], victimLoc[2], attackerLoc[2]), 12.0));
			
			iMoneyIncrease += distance * GetConVarInt(g_hDistanceMultip);
			
			// Bonus for hegrenade kill
			if(StrEqual(weapon_name, "hegrenade"))
			{
				iMoneyIncrease *= GetRandomInt(1, GetConVarInt(g_hGrenadeMultip));
			}
		}
		
		// Bonus for knife kills
		if(StrEqual(weapon_name, "knife"))
		{
			iMoneyIncrease += GetConVarInt(g_hKnifeBonus);
			iMoneyIncrease *= GetRandomInt(1, GetConVarInt(g_hKnifeMultip));
		}
		
		// Headshot bonus
		if(GetEventInt(event, "hitgroup") == 1)
		{
			iMoneyIncrease += GetConVarInt(g_hHeadBonus);
		}
		
		// Don't get higher than $16000
		new iNewMoney = GetEntData(attacker, g_iAccount) + iMoneyIncrease;
		if(iNewMoney > 16000)
			iNewMoney = 16000;
		
		SetEntData(attacker, g_iAccount, iNewMoney, 4, true);
	}
	
	return Plugin_Continue;
}

ResetHitCount(client)
{
	for(new i=1;i<MaxClients;i++)
	{
		g_PlayerDamageDone[client][i] = 0;
		g_PlayerHitCount[client][i] = 0;
	}
}

Float:calcDistance(Float:x1,Float:x2,Float:y1,Float:y2,Float:z1,Float:z2){ 
	//Distance between two 3d points
	new Float:dx = x1-x2;
	new Float:dy = y1-y2;
	new Float:dz = z1-z2;

	return (SquareRoot(dx*dx + dy*dy + dz*dz));
}