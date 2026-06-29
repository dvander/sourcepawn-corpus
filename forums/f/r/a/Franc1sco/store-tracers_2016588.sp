#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <store>
#include <smjansson>

enum Tracer
{
	String:TracerName[STORE_MAX_NAME_LENGTH],
	String:TracerMaterial[PLATFORM_MAX_PATH],
	Float:TracerLifetime,
	Float:TracerWidth,
	TracerColor[4],
	TracerModelIndex
}

new g_tracers[1024][Tracer];
new g_tracerCount;

new Handle:g_tracersNameIndex = INVALID_HANDLE;

new g_clientTracers[MAXPLAYERS+1];


new g_iTeam[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bFake[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name        = "[Store] Tracers",
	author      = "Franc1sco steam: franug",
	description = "Tracers component for [Store]",
	version     = "1.0.2",
	url         = "http://servers-cfg.foroactivo.com/"
};

/**
 * Plugin is loading.
 */
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("store.phrases");

	HookEvent("bullet_impact", Event_OnBulletImpact);
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);

	Store_RegisterItemType("tracers", OnEquip, LoadItem);

}

/**
 * Map is starting
 */
public OnMapStart()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		g_clientTracers[client] = -1;
	}

	for (new item = 0; item < g_tracerCount; item++)
	{
		if (strcmp(g_tracers[item][TracerMaterial], "") != 0 && (FileExists(g_tracers[item][TracerMaterial]) || FileExists(g_tracers[item][TracerMaterial], true)))
		{
			decl String:_sBuffer[PLATFORM_MAX_PATH];
			strcopy(_sBuffer, sizeof(_sBuffer), g_tracers[item][TracerMaterial]);
			g_tracers[item][TracerModelIndex] = PrecacheModel(_sBuffer);
			AddFileToDownloadsTable(_sBuffer);
			ReplaceString(_sBuffer, sizeof(_sBuffer), ".vmt", ".vtf", false);
			AddFileToDownloadsTable(_sBuffer);
		}
	}
}

/**
 * The map is ending.
 */
public OnMapEnd()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		g_clientTracers[client] = -1;
	}
}

/** 
 * Called when a new API library is loaded.
 */
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "store-inventory"))
	{
		Store_RegisterItemType("tracers", OnEquip, LoadItem);
	}	
}

public OnConfigsExecuted()
{
	for (new i = 1; i <= MaxClients; i++)
	{	
		if (IsClientInGame(i))
		{
			g_iTeam[i] = GetClientTeam(i);
			g_bAlive[i] = IsPlayerAlive(i) ? true : false;
			g_bFake[i] = IsFakeClient(i) ? true : false;
		}
	}
}
public OnClientPutInServer(client)
{
	g_bFake[client] = IsFakeClient(client) ? true : false;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;

	g_iTeam[client] = GetEventInt(event, "team");
	if(g_iTeam[client] <= 1)
		g_bAlive[client] = false;

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client) || g_iTeam[client] <= 1 || IsFakeClient(client))
		return Plugin_Continue;
	
	g_bAlive[client] = true;

	g_clientTracers[client] = -1;
	CreateTimer(1.0, GiveTracer, GetClientSerial(client));

	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;
	
	g_bAlive[client] = false;
	g_clientTracers[client] = -1;

	return Plugin_Continue;
}

public Action:Event_OnBulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_clientTracers[client] != -1)
	{
		decl Float:_fOrigin[3], Float:_fImpact[3], Float:_fDifference[3];
		GetClientEyePosition(client, _fDifference);
		GetClientEyeAngles(client, _fOrigin);
		new Handle:_hTemp = TR_TraceRayFilterEx(_fDifference, _fOrigin, MASK_SHOT_HULL, RayType_Infinite, Bool_TraceFilterPlayers);
			
		if(TR_DidHit(_hTemp))
			TR_GetEndPosition(_fImpact, _hTemp);
		else
		{
			CloseHandle(_hTemp);
			return Plugin_Continue;
		}

		CloseHandle(_hTemp);

		new tracer = g_clientTracers[client];

		new color[4];
		for (new i = 0; i < 4; i++)
			color[i] = g_tracers[tracer][TracerColor][i];

		TE_SetupBeamPoints(_fDifference, 
			_fImpact, 
			g_tracers[tracer][TracerModelIndex], 
			0, 
			0, 
			0, 
			g_tracers[tracer][TracerLifetime], 
			g_tracers[tracer][TracerWidth], 
			g_tracers[tracer][TracerWidth], 
			1, 
			0.0, 
			color, 
			0);

		TE_SendToAll();
	}

	return Plugin_Continue;
}

public bool:Bool_TraceFilterPlayers(entity, contentsMask, any:client) 
{
	return !entity || entity > MaxClients;
}

public Store_OnReloadItems() 
{
	if (g_tracersNameIndex != INVALID_HANDLE)
		CloseHandle(g_tracersNameIndex);
		
	g_tracersNameIndex = CreateTrie();
	g_tracerCount = 0;
}

public LoadItem(const String:itemName[], const String:attrs[])
{
	strcopy(g_tracers[g_tracerCount][TracerName], STORE_MAX_NAME_LENGTH, itemName);
		
	SetTrieValue(g_tracersNameIndex, g_tracers[g_tracerCount][TracerName], g_tracerCount);
	
	new Handle:json = json_load(attrs);
	json_object_get_string(json, "material", g_tracers[g_tracerCount][TracerMaterial], PLATFORM_MAX_PATH);

	g_tracers[g_tracerCount][TracerLifetime] = json_object_get_float(json, "lifetime"); 
	if (g_tracers[g_tracerCount][TracerLifetime] == 0.0)
		g_tracers[g_tracerCount][TracerLifetime] = 0.5;

	g_tracers[g_tracerCount][TracerWidth] = json_object_get_float(json, "width");
	if (g_tracers[g_tracerCount][TracerWidth] == 0.0)
		g_tracers[g_tracerCount][TracerWidth] = 1.0;

	new Handle:color = json_object_get(json, "color");

	if (color == INVALID_HANDLE)
	{
		g_tracers[g_tracerCount][TracerColor] = { 255, 255, 255, 255 };
	}
	else
	{
		for (new i = 0; i < 4; i++)
			g_tracers[g_tracerCount][TracerColor][i] = json_array_get_int(color, i);

		CloseHandle(color);
	}

	CloseHandle(json);

	if (strcmp(g_tracers[g_tracerCount][TracerMaterial], "") != 0 && (FileExists(g_tracers[g_tracerCount][TracerMaterial]) || FileExists(g_tracers[g_tracerCount][TracerMaterial], true)))
	{
		decl String:_sBuffer[PLATFORM_MAX_PATH];
		strcopy(_sBuffer, sizeof(_sBuffer), g_tracers[g_tracerCount][TracerMaterial]);
		g_tracers[g_tracerCount][TracerModelIndex] = PrecacheModel(_sBuffer);
		AddFileToDownloadsTable(_sBuffer);
		ReplaceString(_sBuffer, sizeof(_sBuffer), ".vmt", ".vtf", false);
		AddFileToDownloadsTable(_sBuffer);
	}
	
	g_tracerCount++;
}

public Store_ItemUseAction:OnEquip(client, itemId, bool:equipped)
{
	if (!IsClientInGame(client))
	{
		return Store_DoNothing;
	}
	
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s%t", STORE_PREFIX, "Equipped item apply next spawn");
		return Store_EquipItem;
	}
	
	decl String:name[STORE_MAX_NAME_LENGTH];
	Store_GetItemName(itemId, name, sizeof(name));
	
	decl String:loadoutSlot[STORE_MAX_LOADOUTSLOT_LENGTH];
	Store_GetItemLoadoutSlot(itemId, loadoutSlot, sizeof(loadoutSlot));
	
	if (equipped)
	{
		g_clientTracers[client] = -1;

		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Unequipped item", displayName);

		return Store_UnequipItem;
	}
	else
	{		
		new tracer = -1;
		if (!GetTrieValue(g_tracersNameIndex, name, tracer))
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
			return Store_DoNothing;
		}

		g_clientTracers[client] = tracer;

		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Equipped item", displayName);

		return Store_EquipItem;
	}
}

public OnClientDisconnect(client)
{
	g_clientTracers[client] = -1;
	g_iTeam[client] = 0;
	g_bAlive[client] = false;
}

public Action:GiveTracer(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	if (client == 0)
		return Plugin_Handled;

	if (!IsPlayerAlive(client) || IsFakeClient(client))
		return Plugin_Continue;

	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "tracers", Store_GetClientLoadout(client), OnGetPlayerTracers, GetClientSerial(client));
	return Plugin_Handled;
}

public Store_OnClientLoadoutChanged(client)
{
	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "tracers", Store_GetClientLoadout(client), OnGetPlayerTracers, GetClientSerial(client));
}

public OnGetPlayerTracers(ids[], count, any:serial)
{
	new client = GetClientFromSerial(serial);
	if (client == 0)
		return;
		
	g_clientTracers[client] = -1;

	for (new index = 0; index < count; index++)
	{
		decl String:itemName[32];
		Store_GetItemName(ids[index], itemName, sizeof(itemName));
		
		new tracer = -1;
		if (!GetTrieValue(g_tracersNameIndex, itemName, tracer))
		{
			continue;
		}

		g_clientTracers[client] = tracer;
		break;
	}
}