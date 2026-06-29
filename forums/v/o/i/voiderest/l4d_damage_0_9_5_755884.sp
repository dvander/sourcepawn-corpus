//added shove damage

#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define VERSION "0.9.5"

public Plugin:myinfo = {
	name = "L4D Damage",
	author = "Voiderest",
	description = "Adds damage related cvars.",
	version = VERSION,
	url = "N/A"
}

new Handle:melee_damage=INVALID_HANDLE;
new Handle:head_damage=INVALID_HANDLE;
new Handle:chest_damage=INVALID_HANDLE;
new Handle:stomach_damage=INVALID_HANDLE;
new Handle:arm_damage=INVALID_HANDLE;
new Handle:leg_damage=INVALID_HANDLE;
new Handle:ff_damage=INVALID_HANDLE;
new Handle:shove_damage=INVALID_HANDLE;

public OnPluginStart() {
	//create new cvars
	melee_damage = CreateConVar("l4d_damage_melee", "1", "0: Melee does no damage.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	head_damage = CreateConVar("l4d_damage_head_only", "0", "1: Head damage only.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	chest_damage = CreateConVar("l4d_damage_chest", "1", "1: Allow chest damage.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	stomach_damage = CreateConVar("l4d_damage_stomach", "1", "1: Allow stomach damage.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	arm_damage = CreateConVar("l4d_damage_arm", "1", "1: Allow arm damage.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	leg_damage = CreateConVar("l4d_damage_leg", "1", "1: Allow leg damage.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	ff_damage = CreateConVar("l4d_damage_ff", "1", "0: FF off 1: FF normal 2: FF reverse 3: FF split",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,3.0);
	shove_damage = CreateConVar("l4d_damage_shove", "0", "The amount of damage shoving a player does", FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY, true, 0.0);
	
	HookConVarChange(head_damage, Headshot_Only);
	
	//hook events
	HookEvent("infected_hurt", Event_Infected_Hurt, EventHookMode_Pre);
	HookEvent("player_hurt", Event_Player_Hurt, EventHookMode_Pre);
	HookEvent("player_shoved", Event_Player_Shoved, EventHookMode_Pre);
	
	AutoExecConfig(true,"l4d_damage");
}

public OnClientPostAdminCheck(client) {
	if (GetConVarInt(head_damage) == 1)
	{
		PrintHintText(client, "AIM FOR THE HEAD!");
		PrintToChat(client, "Only headshots work on zombies.");
	}
}

public Action:Event_Infected_Hurt(Handle:event, const String:name[], bool:dontBroadcast) {
	
	//new attacker_userid = GetEventInt(event, "attacker");
	//new attacker =  GetClientOfUserId(attacker_userid);
	new zombieid = GetEventInt(event, "entityid");
	new hitgroup = GetEventInt(event, "hitgroup");
	new amount = GetEventInt(event, "amount");
	new type = GetEventInt(event, "type");

	//if (attacker != 0) {
	//	PrintToChatAll("%N hurt infected %d by %d on %d, also %d", attacker, zombieid, amount, hitgroup, type);
	//}
	
	if ((type == 128 && GetConVarInt(melee_damage) == 0) ||
	(GetConVarInt(head_damage) == 1) ||
	(hitgroup == 2 && GetConVarInt(chest_damage) == 0) ||
	(hitgroup == 3 && GetConVarInt(stomach_damage) == 0) ||
	((hitgroup == 4 || hitgroup == 5) && GetConVarInt(arm_damage) == 0) ||
	((hitgroup == 6 || hitgroup == 7) && GetConVarInt(leg_damage) == 0))
	{
		//PrintToServer("given %f", amount);
		new health=GetEntProp(zombieid, Prop_Data, "m_iHealth"); //Get the value of m_iHealth
		SetEntProp(zombieid, Prop_Data, "m_iHealth", (health + amount)); //give health back
	}
	
	return Plugin_Continue;
}

public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new client_userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_userid);
	new attacker_userid = GetEventInt(event, "attacker");
	new attacker =  GetClientOfUserId(attacker_userid);
	new health = GetEventInt(event, "health");
	new dmg = GetEventInt(event, "dmg_health");
	new type = GetEventInt(event, "type");
	
	new fftype = GetConVarInt(ff_damage);
	
	if (attacker == 0 || client == 0 || fftype == 1 || (type == 64 || type == 8) || (GetClientTeam(client) != GetClientTeam(attacker)))
	{
		return Plugin_Continue;
	}
	
	FF_Damage(client, attacker, dmg, fftype, health);
	
	return Plugin_Continue;
}

public Action:Event_Player_Shoved(Handle:event, const String:name[], bool:dontBroadcast) {
	new attacker_userid = GetEventInt(event, "attacker");
	new attacker =  GetClientOfUserId(attacker_userid);
	new client_userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_userid);
	new damage = GetConVarInt(shove_damage);
	
	new fftype = GetConVarInt(ff_damage);
	
	if(attacker == 0 || client == 0 || fftype == 1 || damage <= 0 || (GetClientTeam(client) != GetClientTeam(attacker)))
	{
		return Plugin_Continue;
	}
	
	FF_Damage(client, attacker, damage, GetConVarInt(ff_damage), GetEntProp(client, Prop_Data, "m_iHealth"));
	
	return Plugin_Continue;
}

public FF_Damage(client, attacker, dmg, fftype, health) {
	if (fftype == 0)
	{
		SetEntProp(client, Prop_Data, "m_iHealth", (health + dmg)); //give health back
	}
	else if (fftype == 2)
	{
		SetEntProp(client, Prop_Data, "m_iHealth", (health + dmg)); //give health back
		health = GetEntProp(attacker, Prop_Data, "m_iHealth");
		if ((health - dmg) <= 0)
		{
			IgniteEntity(attacker, 5.0);
		}
		SetEntProp(attacker, Prop_Data, "m_iHealth", (health - dmg)); //damage
	}
	else
	{
		dmg = dmg/2;
		SetEntProp(client, Prop_Data, "m_iHealth", (health + dmg)); //give health back
		health = GetEntProp(attacker, Prop_Data, "m_iHealth");
		if (health - dmg <= 0)
		{
			IgniteEntity(attacker, 5.0);
		}
		SetEntProp(attacker, Prop_Data, "m_iHealth", (health - dmg)); //damage
	}
}

public Headshot_Only(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal) == 1)
	{
		PrintHintTextToAll("AIM FOR THE HEAD!");
		PrintToChatAll("Only headshots work on zombies.");
	}
}
