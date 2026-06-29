#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#define REQUIRE_PLUGIN
#include <tf2autoitems>

#define PLUGIN_VERSION "1.0.0"

new bool:bJarated[MAXPLAYERS+1] = { false, ... };

public Plugin:myinfo =
{
	name = "[TF2] CW: Jar of Ants",
	author = "FlaminSarge, Leonardo",
	description = "...",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1406229"
};

public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("PlayerJarated"), Event_PlayerJarated);
	HookUserMessage(GetUserMessageId("PlayerJaratedFade"), Event_PlayerJaratedFade);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public OnMapStart()
	for(new iClient=1; iClient<=MaxClients; iClient++)
		bJarated[iClient] = false;

public OnClientPutInServer(iClient)
	bJarated[iClient] = false;

public OnClientDisconnect_Post(iClient)
	bJarated[iClient] = false;

public Action:Event_PlayerDeath(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if(	iVictim<=0 || iVictim>MaxClients || iAttacker==iVictim || iAttacker<=0 || iAttacker>MaxClients)
		return Plugin_Continue;
	
	new iWeapon = GetPlayerWeaponSlot(iAttacker, 1);
	if(GetEventInt(hEvent, "customkill")!=TF_CUSTOM_BLEEDING || !IsValidEntity(iWeapon) || !bJarated[iVictim])
		return Plugin_Continue;
	
	if(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex")==58 && GetEntProp(iWeapon, Prop_Send, "m_iEntityLevel")==-6)
	{
		SetEventString(hEvent, "weapon_logclassname", "ants");
		bJarated[iVictim] = false;
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerJarated(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new iAttacker = BfReadByte(bf);
	new iVictim = BfReadByte(bf);
	
	new iWeapon = GetPlayerWeaponSlot(iAttacker, 1);
	if(!IsValidEntity(iWeapon))
		return Plugin_Continue;
	
	if(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex")==58 && GetEntProp(iWeapon, Prop_Send, "m_iEntityLevel")==-6)
	{
		CreateTimer(0.0, Timer_RemoveEffect, iVictim);
		bJarated[iVictim] = true;
		TF2_MakeBleed(iVictim, iAttacker, 10.0);
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerJaratedFade(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	BfReadByte(bf);
	CreateTimer(10.0, Timer_CleanData, BfReadByte(bf));
}

public Action:Timer_RemoveEffect(Handle:hTimer, any:iClient)
	TF2_RemoveCondition(iClient, TFCond_Jarated);

public Action:Timer_CleanData(Handle:hTimer, any:iClient)
	if(iClient>0 && iClient<=MaxClients)
		bJarated[iClient] = false;