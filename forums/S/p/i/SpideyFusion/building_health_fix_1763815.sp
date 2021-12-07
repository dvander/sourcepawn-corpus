#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define TF_BUILDING_HEALTH_LV1 150
#define TF_BUILDING_HEALTH_LV2 180
#define TF_BUILDING_HEALTH_LV3 216

#define TFI_REDTAPE 810
#define TFI_REDTAPE_GENUINE 831

new g_oSentryLevel;
new g_oSentryHealth;
new g_oSentryMaxHealth;

new g_oDispenserLevel;
new g_oDispenserHealth;
new g_oDispenserMaxHealth;

new g_oTeleporterLevel;
new g_oTeleporterHealth;
new g_oTeleporterMaxHealth;

new Handle:g_sapperQueue;

enum
{ 
    Sapper_Id = 0,
    Sapper_Engineer,
	Sapper_Type
}

public Plugin:myinfo =
{
	name = "Building Health Fix",
	author = "spidEY",
	description = "Fixes the amount of health for buildings that get sapped with The Red-Tape Recorder.",
	version = "1.0.0",
	url = "http://edge-gamers.com/"
};

public OnPluginStart()
{
	HookEvent("player_sapped_object", Event_SappedObject);
	HookEvent("object_destroyed", Event_ObjectDestroyed, EventHookMode_Pre);

	g_oSentryLevel = FindSendPropOffs("CObjectSentrygun", "m_iUpgradeLevel");
	g_oSentryHealth = FindSendPropOffs("CObjectSentrygun", "m_iHealth");
	g_oSentryMaxHealth = FindSendPropOffs("CObjectSentrygun", "m_iMaxHealth");

	g_oDispenserLevel = FindSendPropOffs("CObjectDispenser", "m_iUpgradeLevel");
	g_oDispenserHealth = FindSendPropOffs("CObjectDispenser", "m_iHealth");
	g_oDispenserMaxHealth = FindSendPropOffs("CObjectDispenser", "m_iMaxHealth");

	g_oTeleporterLevel = FindSendPropOffs("CObjectTeleporter", "m_iUpgradeLevel");
	g_oTeleporterHealth = FindSendPropOffs("CObjectTeleporter", "m_iHealth");
	g_oTeleporterMaxHealth = FindSendPropOffs("CObjectTeleporter", "m_iMaxHealth");

	g_sapperQueue = CreateArray();
}

AdjustBuildingHealth(object)
{
	new offsetLevel, offsetHealth, offsetMaxHealth;

	decl String:className[32];
	GetEntityClassname(object, className, sizeof(className));

	if (!strcmp(className, "obj_sentrygun"))
	{
		offsetLevel = g_oSentryLevel;
		offsetHealth = g_oSentryHealth;
		offsetMaxHealth = g_oSentryMaxHealth;
	}
	else if (!strcmp(className, "obj_dispenser"))
	{
		offsetLevel = g_oDispenserLevel;
		offsetHealth = g_oDispenserHealth;
		offsetMaxHealth = g_oDispenserMaxHealth;
	}
	else if (!strcmp(className, "obj_teleporter"))
	{
		offsetLevel = g_oTeleporterLevel;
		offsetHealth = g_oTeleporterHealth;
		offsetMaxHealth = g_oTeleporterMaxHealth;
	}

	new objectLevel = GetEntData(object, offsetLevel);
	new objectHealth = TF_BUILDING_HEALTH_LV1;

	switch (objectLevel)
	{
		case 2:
		{
			objectHealth = TF_BUILDING_HEALTH_LV2;
		}
		case 3:
		{
			objectHealth = TF_BUILDING_HEALTH_LV3;
		}
	}

	SetEntData(object, offsetHealth, objectHealth);
	SetEntData(object, offsetMaxHealth, objectHealth);
}

GetClientBuilding(client, const String:className[])
{
	new entity = -1;
	 
	while ((entity = FindEntityByClassname(entity, className)) != INVALID_ENT_REFERENCE)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client)
			return entity;
	}
	
	return entity;
}

ProcessSapperEvent(sapperId)
{
	new queueSize = GetArraySize(g_sapperQueue);
	new engineer, sapperType, sapperIndex, Handle:sapper;

	for (new i = 0; i < queueSize; i++)
	{
		sapper = GetArrayCell(g_sapperQueue, i);

		if (GetArrayCell(sapper, Sapper_Id) == sapperId)
		{
			sapperType = GetArrayCell(sapper, Sapper_Type);
			sapperIndex = GetEntProp(sapperType, Prop_Send, "m_iItemDefinitionIndex");

			if (sapperIndex != TFI_REDTAPE && sapperIndex != TFI_REDTAPE_GENUINE)
				break;

			engineer = GetArrayCell(sapper, Sapper_Engineer);
			RemoveFromArray(g_sapperQueue, i);
			break;
		}
	}

	return engineer;
}

public Action:Event_SappedObject(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new Handle:sapper = CreateArray();

	PushArrayCell(sapper, GetEventInt(event, "sapperid"));
	PushArrayCell(sapper, GetClientOfUserId(GetEventInt(event, "ownerid")));
	PushArrayCell(sapper, GetPlayerWeaponSlot(GetClientOfUserId(GetEventInt(event, "userid")), 1));

	PushArrayCell(g_sapperQueue, sapper);
}

public Action:Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new sapperId = GetEventInt(event, "index");

	if (TF2_GetObjectType(sapperId) != TFObjectType:TFObject_Sapper)
		return;

	new engineer = ProcessSapperEvent(sapperId);

	if (!engineer)
		return;

	new object = -1;

	if ((object = GetClientBuilding(engineer, "obj_sentrygun")) != -1)
		AdjustBuildingHealth(object);

	if ((object = GetClientBuilding(engineer, "obj_dispenser")) != -1)
		AdjustBuildingHealth(object);

	if ((object = GetClientBuilding(engineer, "obj_teleporter")) != -1)
		AdjustBuildingHealth(object);
}