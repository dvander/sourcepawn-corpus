#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#define REQUIRE_PLUGIN
#include <tf2autoitems>

public Plugin:myinfo = 
{
	name = "[TF2] CW: Rebel's Curse",
	author = "FlaminSarge, Leonardo",
	description = "Rebel's Curse's effects",
	version = "1.0.2",
	url = "http://sourcemod.net"
};

public OnPluginStart()
{
	HookEvent("post_inventory_application", Event_UpdateItems,  EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath,  EventHookMode_Post);
	HookEvent("player_death", Event_PlayerPreDeath,  EventHookMode_Pre);
}

public Action:Event_UpdateItems(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient) || !IsClientInGame(iClient) || GetClientTeam(iClient)<=1 || !IsPlayerAlive(iClient))
		return Plugin_Continue;
	
	CreateTimer(0.5, Timer_CheckWeapons, iClient);
	
	return Plugin_Continue;
}

public Action:Event_PlayerPreDeath(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(iAttacker<=0 || iAttacker>MaxClients || !IsClientConnected(iAttacker) || !IsPlayerAlive(iAttacker))
		return Plugin_Continue;
	
	new iActiveWeapon = GetEntPropEnt(iAttacker, Prop_Send, "m_hActiveWeapon");
	if(GetEventInt(hEvent, "weaponid")!=TF_WEAPON_WRENCH || !IsValidEntity(iActiveWeapon))
		return Plugin_Continue;
	
	if(GetEntProp(iActiveWeapon, Prop_Send, "m_iItemDefinitionIndex")==197 && GetEntProp(iActiveWeapon, Prop_Send, "m_iEntityLevel")==-115)
		SetEventString(hEvent, "weapon_logclassname", "rebels_curse");
	
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if(iVictim<=0 || iVictim>MaxClients || !IsClientConnected(iVictim))
		return Plugin_Continue;
	if(iAttacker<=0 || iAttacker>MaxClients || !IsClientConnected(iAttacker) || !IsPlayerAlive(iAttacker))
		return Plugin_Continue;
	
	new iActiveWeapon = GetEntPropEnt(iAttacker, Prop_Send, "m_hActiveWeapon");
	if(GetEventInt(hEvent, "weaponid")!=TF_WEAPON_WRENCH || !IsValidEntity(iActiveWeapon))
		return Plugin_Continue;
	
	if(GetEntProp(iActiveWeapon, Prop_Send, "m_iItemDefinitionIndex")==197 && GetEntProp(iActiveWeapon, Prop_Send, "m_iEntityLevel")==-115)
		CreateTimer(0.01, Timer_DissolveBody, iVictim);
	
	return Plugin_Continue;
}

public Action:Timer_CheckWeapons(Handle:hTimer, any:iClient)
{
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient) || !IsClientInGame(iClient) || GetClientTeam(iClient)<=1 || !IsPlayerAlive(iClient))
		return Plugin_Handled;
	
	new iWeapon = GetPlayerWeaponSlot(iClient, 2);
	if(IsValidEntity(iWeapon))
		if(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex")==197 && GetEntProp(iWeapon, Prop_Send, "m_iEntityLevel")==-115)
		{
			SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(iWeapon, 120, 10, 255, 245);
			
			new iEntity = -1;
			while((iEntity = FindEntityByClassname2(iEntity, "prop_physics")) != -1)
				if(GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity")==iClient)
				{
					SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
					SetEntityRenderColor(iEntity, 120, 10, 255, 245);
				}
		}
	
	return Plugin_Handled;
}

public Action:Timer_DissolveBody(Handle:hTimer, any:iClient)
{
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient))
		return Plugin_Handled;
	
	new iRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");
	if(!IsValidEntity(iRagdoll))
		return Plugin_Handled;
	
	new iDissolver = CreateEntityByName("env_entity_dissolver");
	if (iDissolver!=-1)
	{
		decl String:sDissolveName[32];
		Format(sDissolveName, sizeof(sDissolveName), "dis_%d", iClient);
		DispatchKeyValue(iRagdoll, "targetname", sDissolveName);
		
		DispatchKeyValue(iDissolver, "dissolvetype", "0");
		DispatchKeyValue(iDissolver, "magnitude", "1");
		DispatchKeyValue(iDissolver, "target", sDissolveName);
		AcceptEntityInput(iDissolver, "Dissolve");
		AcceptEntityInput(iDissolver, "Kill");
	}
	
	return Plugin_Handled;
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
		startEnt--;
	return FindEntityByClassname(startEnt, classname);
}