#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define ITEM_INDEX_GUNSLINGER 142
#define ITEM_INDEX_SOUTHERNHOSPITALITY 155
#define ITEM_INDEX_WRENCH 7

#define ITEM_CLASS_WRENCH "tf_weapon_wrench"
#define ITEM_CLASS_ROBOTARM "tf_weapon_robot_arm"

public Plugin:myinfo = 
{
	name = "Steal Engineer Buildings",
	author = "Thraka",
	description = "Allows the opposite teams engineer to steal your buildings by hitting it with his wrench weapons.",
	version = "1.0",
	url = ""
}

new m_hActiveWeapon;
new m_hOwnerEntity;

public OnPluginStart()
{
	m_hActiveWeapon = FindSendPropOffs("CBasePlayer", "m_hActiveWeapon");
	m_hOwnerEntity = FindSendPropOffs("CBasePlayer", "m_hOwnerEntity");
	
	
	if(m_hActiveWeapon <= 0)
	{
		SetFailState("Could not locate offset for: %s!", "CBasePlayer::m_hActiveWeapon");
		return;
	}
	else if(m_hOwnerEntity <= 0)
	{
		SetFailState("Could not locate offset for: %s!", "CBasePlayer::m_hOwnerEntity");
		return;
	}
	
	HookEvent("player_builtobject", Event_ObjectBuilt);
	HookEvent("object_destroyed", Event_ObjectDestroyed);
	HookEvent("building_info_changed", Event_BuildingInfoChanged);
	HookEvent("object_removed", Event_ObjectRemoved);
	
	RegConsoleCmd("test", Cmd_Test, "");
}


public Action:Event_ObjectBuilt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ent = GetEventInt(event, "index");
	PrintToChatAll("Object built %i", ent);
	if (TF2_GetObjectType(ent) == TFObject_Teleporter)
	{
		if (TF2_GetObjectMode(ent) == TFObjectMode_Entrance)
			return Plugin_Continue;
	}
	
	SDKHook(ent, SDKHook_OnTakeDamagePost, OnTakeDamage);
	
	return Plugin_Continue;
}

public Action:Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ent = GetEventInt(event, "index");
	PrintToChatAll("Object destroyed");
	if (TF2_GetObjectType(ent) == TFObject_Teleporter)
	{
		if (TF2_GetObjectMode(ent) == TFObjectMode_Entrance)
			return Plugin_Continue;
	}
	
	PrintToChatAll("unhooking %i", ent);
	SDKUnhook(ent, SDKHook_OnTakeDamagePost, OnTakeDamage);
	
	return Plugin_Continue;
}

public Action:Event_BuildingInfoChanged(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("Building info changed");
	return Plugin_Continue;
}

public Action:Event_ObjectRemoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new ent = GetEventInt(event, "index");
	new objType = GetEventInt(event, "objecttype");
	new owner = GetEventInt(event, "userid");
	
	PrintToChatAll("Object removed- index: %i objtype: %i owner: %i", ent, objType, owner);
		
	if (TF2_GetObjectType(ent) == TFObject_Teleporter)
	{
		if (TF2_GetObjectMode(ent) == TFObjectMode_Entrance)
			return Plugin_Continue;
	}
	
	PrintToChatAll("unhooking %i", ent);
	SDKUnhook(ent, SDKHook_OnTakeDamagePost, OnTakeDamage);
	
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	PrintToChatAll("Damage building attacker is %i inflictor is %i victim is %i", attacker, inflictor, victim);
	if (attacker != 0)
	{
		decl String:className[64];
		//GetEntPropString(attacker, Prop_Data, "m_iClassname", className, sizeof(className))
		PrintToChatAll("attacker class name is %s", className);
		
		//GetEntPropString(inflictor, Prop_Data, "m_iClassname", className, sizeof(className))
		PrintToChatAll("inflictor class name is %s", className);
		
		PrintToChatAll("Getting owner id: %i", GetEntPropEnt(attacker, Prop_Send, "m_hOwnerEntity"));
		
		
		new TFTeam:buildingTeam = TFTeam:GetEntProp(victim, Prop_Send, "m_iTeamNum");
		new TFTeam:attackerTeam = TFTeam:GetClientTeam(attacker);

		PrintToChatAll("building team %i attacking team %i", buildingTeam, attackerTeam);
		
		if (buildingTeam != attackerTeam)
		{
			if (TF2_GetPlayerClass(attacker) == TFClass_Engineer && IsValidItem(GetActiveWeapon(attacker)))
			{
				PrintToChatAll("Should steal building!");
			}
		}
		
	}
	return Plugin_Continue;
}

GetActiveWeapon(client)
{
	return GetEntDataEnt2(client, m_hActiveWeapon);
}

GetItemDefinition(weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
}

bool:IsValidItem(weapon)
{
	decl String:class[32];
	if (GetEdictClassname(weapon,class,sizeof(class)))
	{
		if (StrEqual(class, ITEM_CLASS_WRENCH) || StrEqual(class, ITEM_CLASS_ROBOTARM))
		{
			return true;
		}
	}
	
	return false;
}

public Action:Cmd_Test(client, args) 
{
	PrintToChatAll("Player weapon %i definition index %i is valid %i", GetActiveWeapon(client), GetItemDefinition(GetActiveWeapon(client)), IsValidItem(GetActiveWeapon(client)));
	
	if (GetCmdArgs() == 1)
	{
		new String:arg1[32];
		GetCmdArg(1, arg1, 32);
		
	}
	
}