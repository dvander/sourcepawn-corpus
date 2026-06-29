#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

new Handle:K_length;
new Handle:K_heal;
new loopy[64];

public OnPluginStart(){
	HookEvent("player_chargedeployed", Event_playeruberen);
	K_length = CreateConVar("sm_krit_length","10","Length of nanites live or at all");
	K_heal = CreateConVar("sm_krit_heal","30","How much the nanite infusion heals for");
}


///Healing target function by barracuda on Sourcemod forums.
public GetHealTarget(client)
{
	if(!IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return -1;
	}

	new weapon = GetPlayerWeaponSlot(client, 1);

	if (weapon == -1)
	{
		return -1;
	}

	if(!IsPlayerAlive(client)){
		return -1;
	}
	new String:classname[64];
	GetEdictClassname(weapon, classname, 63);
	return GetEntDataEnt2(weapon, FindSendPropInfo("CWeaponMedigun", "m_hHealingTarget"));
}

public Event_playeruberen(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(!IsPlayerAlive(client)){return Plugin_Stop;}
	new weapon = GetPlayerWeaponSlot(client,1);

	if(GetEntProp(weapon, Prop_Send, "m_iEntityLevel") == 8)
	{
		Assignzero(client);
	}

	return Plugin_Continue;
}

public Assignzero(client){
	if(!IsPlayerAlive(client)){return Plugin_Stop;}
	new targ = GetHealTarget(client);
	if(client <= 0){
		return Plugin_Stop;
	}
	loopy[client] = 0;
	CreateTimer(1.0, nanite, targ, TIMER_REPEAT);
	return Plugin_Continue;
}

public Action:nanite(Handle:timer, any:client){

	if(client <= 0){
		return Plugin_Stop;
	}
	if(loopy[client]++ >= GetConVarInt(Handle:K_length)){
		loopy[client] = 0;
		return Plugin_Stop;
	}

	new chp = GetClientHealth(client);

	if(chp == -1){
		loopy[client] = 0;
		return Plugin_Stop;
	}

	chp = chp + GetConVarInt(Handle:K_heal);
	SetEntityHealth(client, chp);

	return Plugin_Continue;
}