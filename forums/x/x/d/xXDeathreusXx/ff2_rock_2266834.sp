//////////////////////
//Table of contents://
//	   Defines		//
//	   Abilities	//
//	   Timers		//
//	   Stocks		//
//////////////////////

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo = {
	name    = "Freak Fortress 2: Rock Ability",
	author  = "Deathreus, coding snippets from Darthmule, Flamin Sarge, and Otokiru",
	version = "1.2",
};

/////////////////////////////////////////
//Defines some terms used by the plugin//
/////////////////////////////////////////

//new bool: g_bIsBoss[MAXPLAYERS+1] = false;
//new bool:g_bHasRaged = false;
new BossTeam=_:TFTeam_Blue;


public OnPluginStart2()
{
	//HookEvent("teamplay_round_end", event_round_end);
	//HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_death", event_player_death);
	LoadTranslations("freak_fortress_2.phrases");
}

public Action:FF2_OnAbility2(client, const String:plugin_name[], const String:ability_name[], status)
{
	if (!strcmp(ability_name, "rage_therock"))
		Rage_TheRock(client, ability_name);
	return Plugin_Continue;
}

public OnMapEnd()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			SDKUnhook(i, SDKHook_StartTouch, OnRockTouch);
			SDKUnhook(i, SDKHook_ShouldCollide, OnRockCollide);
			//g_bIsBoss[i] = false;
		}
	}
	//g_bHasRaged = false;
}

/*public Action:event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
	{
		SDKHook(client, SDKHook_StartTouch, OnRockTouch);
		SDKHook(client, SDKHook_ShouldCollide, OnRockCollide);
		if(FF2_HasAbility(client, this_plugin_name, "rage_therock"))
			g_bIsBoss[client] = true;
	}
	return Plugin_Continue;
}*/
public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Continue;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(victim))
	{
		SDKUnhook(victim, SDKHook_StartTouch, OnRockTouch);
		SDKUnhook(victim, SDKHook_ShouldCollide, OnRockCollide);
	}
	return Plugin_Continue;
}
/*public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	//g_bHasRaged = false;
	return Plugin_Continue;
}*/

////////////////////////////////////
//Abilities start below this point//
////////////////////////////////////

Rage_TheRock(client, const String:ability_name[])
{
	new Boss = GetClientOfUserId(FF2_GetBossUserId(client));
	//new Float:Range =	FF2_GetAbilityArgumentFloat(client, this_plugin_name, ability_name, 1);	 // Range
	new Float:Duration = FF2_GetAbilityArgumentFloat(client, this_plugin_name, ability_name, 1);	// Duration

	if(GetClientTeam(Boss)==BossTeam)
	{
		SDKHook(Boss, SDKHook_StartTouch, OnRockTouch);
		SDKHook(Boss, SDKHook_ShouldCollide, OnRockCollide);
		TF2_AddCondition(Boss, TFCond_MegaHeal, Duration);
		TF2_AddCondition(Boss, TFCond_SpeedBuffAlly, Duration);
		CreateTimer(Duration, UnHook, Boss);
		//g_bHasRaged = true;
	}
}

/////////////////////////////////
//Timers start below this point//
/////////////////////////////////

public Action:UnHook(Handle:timer, any:Boss)
{
	if(IsValidClient(Boss))
	{
		SDKUnhook(Boss, SDKHook_StartTouch, OnRockTouch);
		SDKUnhook(Boss, SDKHook_ShouldCollide, OnRockCollide);
	}
}

/////////////////////////////////
//Stocks start below this point//
/////////////////////////////////

public Action:OnRockTouch(Boss, entity)
{
	if(GetClientTeam(Boss)!=BossTeam)
	{
		SDKUnhook(Boss, SDKHook_Touch, OnRockTouch);
		return;
	}

	static Float:origin[3], Float:angles[3], Float:targetpos[3];
	if(entity > 0 && entity <= MaxClients && IsClientInGame(entity) && IsPlayerAlive(entity) && GetClientTeam(entity)!=BossTeam)
	{
		GetClientEyeAngles(Boss, angles);
		GetClientEyePosition(Boss, origin);
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", targetpos);
		GetAngleVectors(angles, angles, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(angles, angles);
		SubtractVectors(targetpos, origin, origin);

		if(GetVectorDotProduct(origin, angles) > 0.0)
		{
			SDKHooks_TakeDamage(entity, Boss, Boss, 15.0, DMG_CRUSH|DMG_PREVENT_PHYSICS_FORCE|DMG_ALWAYSGIB);	// Make boss get credit for the kill
			FakeClientCommandEx(entity, "explode");
		}		
	}
}

public bool:OnRockCollide(entity, collisiongroup, contentsmask, bool:originalResult)
{
	if(GetClientTeam(entity)!=BossTeam)
		SDKUnhook(entity, SDKHook_ShouldCollide, OnRockCollide);

	if(contentsmask & CONTENTS_TEAM1 == CONTENTS_TEAM1 || contentsmask & CONTENTS_TEAM2 == CONTENTS_TEAM2)
	{
		//if(g_bHasRaged)
		return false;
	}

	return originalResult;
}

/*stock IsBoss(client)
{
	if (client <= 0)
		return 0;
	for(new i = 0; i <= MaxClients; i++)
		if (g_bIsBoss[i] == true)
			return 1;
	return 0;
}*/

stock bool:IsValidClient(client, bool:bReplay = true)
{
	if(client <= 0
	|| client > MaxClients
	|| !IsClientInGame(client))
		return false;

	if(bReplay
	&& (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}