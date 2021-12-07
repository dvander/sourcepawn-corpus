/*
* 
* 						Drop Money On Death SourceMOD Plugin
* 						Copyright (c) 2008  SAMURAI
* 
* 						Visit http://www.cs-utilz.net
* 
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "Drop money on death",
	author = "SAMURAI",
	description = "",
	version = "0.2",
	url = "www.cs-utilz.net"
}


stock const String:szMoneyModel[] = "models/props/cs_assault/money.mdl";

new g_iMoney = -1;

new Handle:g_iConVar 		= INVALID_HANDLE;
new Handle:g_iConVarPercent = INVALID_HANDLE

#define SOLID_VPHYSICS  6
#define	DAMAGE_NO		0

new g_VictimMoney[2049] = 0;
new g_lostMoney[33] = 0;

new g_iMaxClients;

public OnPluginStart()
{
	g_iMoney = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	g_iConVar = CreateConVar("drop_mny_ondth","1");
	g_iConVarPercent = CreateConVar("drop_mny_ondth_percent","50"); // 50 %
	
	HookEvent("player_death",event_player_death);
	HookEvent("player_spawn",Event_spawn);
	
	
	g_iMaxClients = GetMaxClients();
}

public OnMapStart()
{
	PrecacheModel(szMoneyModel);
}


public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if(!IsClientConnected(client) && !IsClientInGame(client))
		return;
	
	if(!GetConVarInt(g_iConVar))
		return;
	
	static Float:victimOrigin[3],Float:newOrigin[3];
	GetClientAbsOrigin(client,victimOrigin);
	
	new ent = CreateEntityByName("prop_physics_override");
	
	SetEntityModel(ent,szMoneyModel);
	DispatchSpawn(ent);
	
	newOrigin[0] = victimOrigin[0] + 20.0;
	newOrigin[1] = victimOrigin[1];
	newOrigin[2] = victimOrigin[2] - 65.0;
	TeleportEntity(ent,newOrigin,NULL_VECTOR,NULL_VECTOR);
	
	SetEntityMoveType(ent, MOVETYPE_NONE);
	SetEntProp(ent, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
	SetEntProp(ent, Prop_Data, "m_takedamage", DAMAGE_NO);
	
	SDKHook(ent, SDKHook_StartTouch, OnTouch);

	g_VictimMoney[ent] = GetPercent(get_user_money(client),GetConVarInt(g_iConVarPercent));
	g_lostMoney[client] = GetPercent(get_user_money(client),GetConVarInt(g_iConVarPercent));

}


public Action:OnTouch(entity, client)
{
	if(!GetConVarInt(g_iConVar))
		return;
	
	decl String:model[128];
	GetEntityModel(entity,model)
	
	if(StrEqual(model,szMoneyModel) 
	&& ISPlayer(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		static money_found, money_have, money_set;
		money_found = g_VictimMoney[entity];
		money_have = get_user_money(client);
		money_set = money_found + money_have;
	
		// if result >= 16000 
		if(money_set >= 16000)
			return;
		
		set_user_money(client,money_set);
		

		if(IsValidEdict(entity))
		{
			//ent_touched[entity] = true;
			RemoveEdict(entity);
			SDKUnhook(entity, SDKHook_StartTouch, OnTouch);
		}
	}
}


public Action:Event_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(!IsClientConnected(client) && !IsClientInGame(client) && !IsPlayerAlive(client))
		return;
	
	new ent = -1;
	decl String:model[128];
	while( ( ent = FindEntityByClassname(ent,"prop_physics_override") ))
	{
		if(!IsValidEdict(ent))	
		{
			set_user_money(client,get_user_money(client) - g_lostMoney[client]);
			break;
		}
			
		else if(IsValidEdict(ent) && !StrEqual(model,szMoneyModel)) 
		{
			set_user_money(client,get_user_money(client) - g_lostMoney[client]);
			break;
		}
	}
	
}



//* 	 Util Functions 	*//

stock set_user_money(client, amount)
{
	if(g_iMoney != -1)
		SetEntData(client, g_iMoney, amount);
}

stock get_user_money(client)
{
	if(g_iMoney != -1)
		return GetEntData(client, g_iMoney);

	return 0;
}

stock ISPlayer(entity)
{
	return (entity > 0 && entity <= g_iMaxClients) ? 1 : 0;
}

stock GetEntityModel(entity,String:model[128])
{
	return GetEntPropString(entity, Prop_Data, "m_ModelName", model,sizeof(model));
}

stock GetPercent(num,percent)
{
	return (num * percent / 100);
}