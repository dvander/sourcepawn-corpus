#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <store>
#include <smjansson>

#undef REQUIRE_PLUGIN
#include <zombiereloaded>

enum Trail
{
	String:TrailName[STORE_MAX_NAME_LENGTH],
	String:TrailMaterial[PLATFORM_MAX_PATH],
	Float:TrailLifetime,
	Float:TrailWidth,
	Float:TrailEndWidth,
	TrailFadeLength,
	TrailColor[4],
	TrailModelIndex
}

new g_trails[1024][Trail];
new g_trailCount;
new bool:g_zombieReloaded;

new bool:g_bEnvExp[2048] = false;

new String:g_game[32];

new Handle:g_trailsNameIndex = INVALID_HANDLE;
new Handle:g_trailTimers[MAXPLAYERS+1];
new g_SpriteModel[MAXPLAYERS + 1];

/**
 * Called before plugin is loaded.
 * 
 * @param myself    The plugin handle.
 * @param late      True if the plugin was loaded after map change, false on map start.
 * @param error     Error message if load failed.
 * @param err_max   Max length of the error message.
 *
 * @return          APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("ZR_IsClientHuman"); 
	MarkNativeAsOptional("ZR_IsClientZombie"); 

	return APLRes_Success;
}

public Plugin:myinfo =
{
	name        = "[Store] Trails",
	author      = "alongub",
	description = "Trails component for [Store]",
	version     = "1.1-alpha+JS_88",
	url         = "https://github.com/alongubkin/store"
};

/**
 * Plugin is loading.
 */
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("store.phrases");

	g_zombieReloaded = LibraryExists("zombiereloaded");
	
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", PlayerTeam);
	HookEvent("round_end", RoundEnd);

	GetGameFolderName(g_game, sizeof(g_game));

	Store_RegisterItemType("trails", OnEquip, LoadItem);
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "env_explosion", false))
	{
		//Hook spawn to delete trails of any player it spawns near (engine teleports the entity before spawning it)
		//Also, index it for scanning later
		g_bEnvExp[entity] = true;
		SDKHook(entity, SDKHook_Spawn, ExpSpawn);
	}
}
public Action:ExpSpawn(entity)
{
	decl Float:epos[3];
	decl Float:pos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", epos);
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && IsValidEdict(i))
		{
			GetClientAbsOrigin(i, pos);
			if(FloatAbs(GetVectorDistance(pos, epos)) <= 250.0)
			{
				//Remove the trail if the env_explosion spawned nearby
				//Note: Had to resort to removing the trail, hooking OnTakeDamage and blocking
				//doesn't happen fast enough to save to server (or you can't block OnTakeDamage, not real sure)
				KillTrail(i);
				CreateTimer(1.0, Timer_AttachTrail, i, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}
public OnEntityDestroyed(entity)
{
	if(entity <= 2048 && entity >= 0)
		g_bEnvExp[entity] = false;	
	SDKUnhook(entity, SDKHook_Spawn, ExpSpawn);
}
/** 
 * Called when a new API library is loaded.
 */
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "zombiereloaded"))
	{
		g_zombieReloaded = true;
	}
	else if (StrEqual(name, "store-inventory"))
	{
		Store_RegisterItemType("trails", OnEquip, LoadItem);
	}	
}

/** 
 * Called when an API library is removed.
 */
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "zombiereloaded"))
	{
		g_zombieReloaded = false;
	}
}

/**
 * Map is starting
 */
public OnMapStart()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		g_SpriteModel[client] = -1;
	}

	for (new item = 0; item < g_trailCount; item++)
	{
		if (strcmp(g_trails[item][TrailMaterial], "") != 0 && (FileExists(g_trails[item][TrailMaterial]) || FileExists(g_trails[item][TrailMaterial], true)))
		{
			decl String:_sBuffer[PLATFORM_MAX_PATH];
			strcopy(_sBuffer, sizeof(_sBuffer), g_trails[item][TrailMaterial]);
			g_trails[item][TrailModelIndex] = PrecacheModel(_sBuffer);
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
		if (g_trailTimers[client] != INVALID_HANDLE)
		{
			CloseHandle(g_trailTimers[client]);
			g_trailTimers[client] = INVALID_HANDLE;
		}

		g_SpriteModel[client] = -1;
	}
}

public Store_OnReloadItems() 
{
	if (g_trailsNameIndex != INVALID_HANDLE)
		CloseHandle(g_trailsNameIndex);
		
	g_trailsNameIndex = CreateTrie();
	g_trailCount = 0;
}

public LoadItem(const String:itemName[], const String:attrs[])
{
	strcopy(g_trails[g_trailCount][TrailName], STORE_MAX_NAME_LENGTH, itemName);
		
	SetTrieValue(g_trailsNameIndex, g_trails[g_trailCount][TrailName], g_trailCount);
	
	new Handle:json = json_load(attrs);
	json_object_get_string(json, "material", g_trails[g_trailCount][TrailMaterial], PLATFORM_MAX_PATH);

	g_trails[g_trailCount][TrailLifetime] = json_object_get_float(json, "lifetime")
	; 
	if (g_trails[g_trailCount][TrailLifetime] == 0.0)
		g_trails[g_trailCount][TrailLifetime] = 1.0;

	g_trails[g_trailCount][TrailWidth] = json_object_get_float(json, "width");

	if (g_trails[g_trailCount][TrailWidth] == 0.0)
		g_trails[g_trailCount][TrailWidth] = 15.0;

	g_trails[g_trailCount][TrailEndWidth] = json_object_get_float(json, "endwidth"); 

	if (g_trails[g_trailCount][TrailEndWidth] == 0.0)
		g_trails[g_trailCount][TrailEndWidth] = 6.0;

	g_trails[g_trailCount][TrailFadeLength] = json_object_get_int(json, "fadelength"); 

	if (g_trails[g_trailCount][TrailFadeLength] == 0)
		g_trails[g_trailCount][TrailFadeLength] = 1;

	new Handle:color = json_object_get(json, "color");

	if (color == INVALID_HANDLE)
	{
		g_trails[g_trailCount][TrailColor] = { 255, 255, 255, 255 };
	}
	else
	{
		for (new i = 0; i < 4; i++)
			g_trails[g_trailCount][TrailColor][i] = json_array_get_int(color, i);

		CloseHandle(color);
	}

	CloseHandle(json);

	if (strcmp(g_trails[g_trailCount][TrailMaterial], "") != 0 && (FileExists(g_trails[g_trailCount][TrailMaterial]) || FileExists(g_trails[g_trailCount][TrailMaterial], true)))
	{
		decl String:_sBuffer[PLATFORM_MAX_PATH];
		strcopy(_sBuffer, sizeof(_sBuffer), g_trails[g_trailCount][TrailMaterial]);
		g_trails[g_trailCount][TrailModelIndex] = PrecacheModel(_sBuffer);
		AddFileToDownloadsTable(_sBuffer);
		ReplaceString(_sBuffer, sizeof(_sBuffer), ".vmt", ".vtf", false);
		AddFileToDownloadsTable(_sBuffer);
	}
	
	g_trailCount++;
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

	if (g_zombieReloaded && !ZR_IsClientHuman(client))
	{
		PrintToChat(client, "%s%t", STORE_PREFIX, "Equipped item apply next spawn");	
		return Store_EquipItem;
	}
	
	decl String:name[STORE_MAX_NAME_LENGTH];
	Store_GetItemName(itemId, name, sizeof(name));
	
	decl String:loadoutSlot[STORE_MAX_LOADOUTSLOT_LENGTH];
	Store_GetItemLoadoutSlot(itemId, loadoutSlot, sizeof(loadoutSlot));
	
	KillTrail(client);

	if (equipped)
	{
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Unequipped item", displayName);

		return Store_UnequipItem;
	}
	else
	{		
		if (!Equip(client, name))
			return Store_DoNothing;
			
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Equipped item", displayName);

		return Store_EquipItem;
	}
}

public OnClientDisconnect(client)
{
	if (g_trailTimers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_trailTimers[client]);
		g_trailTimers[client] = INVALID_HANDLE;
	}

	g_SpriteModel[client] = -1;
}

public Action:PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsClientInGame(client) && IsPlayerAlive(client)) 
	{
		if (g_trailTimers[client] != INVALID_HANDLE)
		{
			CloseHandle(g_trailTimers[client]);
			g_trailTimers[client] = INVALID_HANDLE;
		}

		g_SpriteModel[client] = -1;

		CreateTimer(1.0, GiveTrail, GetClientSerial(client));
	}
}

public PlayerTeam(Handle:Spawn_Event, const String:Death_Name[], bool:Death_Broadcast )
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event,"userid") );
	new team = GetEventInt(Spawn_Event, "team");
	
	if (team == 1)
	{
		KillTrail(client);
	}
}

public Action:PlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillTrail(client);
}

public Action:RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (g_trailTimers[client] != INVALID_HANDLE)
		{
			CloseHandle(g_trailTimers[client]);
			g_trailTimers[client] = INVALID_HANDLE;
		}

		g_SpriteModel[client] = -1;
	}
}

public Action:GiveTrail(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	if (client == 0)
		return Plugin_Handled;

	if (!IsPlayerAlive(client))
		return Plugin_Continue;
		
	if (g_zombieReloaded && !ZR_IsClientHuman(client))
		return Plugin_Continue;
		
	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "trails", Store_GetClientLoadout(client), OnGetPlayerTrail, GetClientSerial(client));
	return Plugin_Handled;
}

public Store_OnClientLoadoutChanged(client)
{
	Store_GetEquippedItemsByType(Store_GetClientAccountID(client), "trails", Store_GetClientLoadout(client), OnGetPlayerTrail, GetClientSerial(client));
}

public OnGetPlayerTrail(ids[], count, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
		return;
		
	if (g_zombieReloaded && !ZR_IsClientHuman(client))
		return;
		
	KillTrail(client);
	
	for (new index = 0; index < count; index++)
	{
		decl String:itemName[32];
		Store_GetItemName(ids[index], itemName, sizeof(itemName));
		
		Equip(client, itemName);
	}
}

bool:Equip(client, const String:name[])
{	
	KillTrail(client);

	new trail = -1;
	if (!GetTrieValue(g_trailsNameIndex, name, trail))
	{
		PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
		return false;
	}

	if (StrEqual(g_game, "csgo"))
	{
		EquipTrailTempEnts(client, trail);

		new Handle:pack;
		g_trailTimers[client] = CreateDataTimer(0.1, Timer_RenderBeam, pack, TIMER_REPEAT);

		WritePackCell(pack, GetClientSerial(client));
		WritePackCell(pack, trail);

		return true;
	}
	else
	{
		return EquipTrail(client, trail);
	}
}

bool:EquipTrailTempEnts(client, trail)
{
	new entityToFollow = GetPlayerWeaponSlot(client, 2);
	if (entityToFollow == -1)
		entityToFollow = client;

	new color[4];
	Array_Copy(g_trails[client][TrailColor], color, sizeof(color));

	TE_SetupBeamFollow(entityToFollow, 
						g_trails[trail][TrailModelIndex], 
						0, 
						g_trails[trail][TrailLifetime], 
						g_trails[trail][TrailWidth], 
						g_trails[trail][TrailEndWidth], 
						g_trails[trail][TrailFadeLength], 
						color);
	TE_SendToAll();

	return true;
}

bool:EquipTrail(client, trail)
{
	g_SpriteModel[client] = CreateEntityByName("env_spritetrail");
	
	if (!IsValidEntity(g_SpriteModel[client])) 
		return false;

	new String:strTargetName[MAX_NAME_LENGTH];
	GetClientName(client, strTargetName, sizeof(strTargetName));

	DispatchKeyValue(client, "targetname", strTargetName);
	DispatchKeyValue(g_SpriteModel[client], "parentname", strTargetName);
	DispatchKeyValueFloat(g_SpriteModel[client], "lifetime", g_trails[trail][TrailLifetime]);
	DispatchKeyValueFloat(g_SpriteModel[client], "endwidth", g_trails[trail][TrailEndWidth]);
	DispatchKeyValueFloat(g_SpriteModel[client], "startwidth", g_trails[trail][TrailWidth]);
	DispatchKeyValue(g_SpriteModel[client], "spritename", g_trails[trail][TrailMaterial]);
	DispatchKeyValue(g_SpriteModel[client], "renderamt", "255");

	decl String:color[32];
	Format(color, sizeof(color), "%d %d %d %d", g_trails[trail][TrailColor][0], g_trails[trail][TrailColor][1], g_trails[trail][TrailColor][2], g_trails[trail][TrailColor][3]);

	DispatchKeyValue(g_SpriteModel[client], "rendercolor", color);
	DispatchKeyValue(g_SpriteModel[client], "rendermode", "5");
	
	DispatchSpawn(g_SpriteModel[client]);

	//Scan for nearby explosions every 100ms and remove trail if any are found
	//Unfortunately, this proved necessary to catch entities that are spawned
	//in map load, because hooking Think doesn't fire soon enough to save the server
	CreateTimer(0.1, Timer_ExpScan, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	new Float:Client_Origin[3];
	GetClientAbsOrigin(client,Client_Origin);
	Client_Origin[2] += 10.0; //Beam clips into the floor without this

	TeleportEntity(g_SpriteModel[client], Client_Origin, NULL_VECTOR, NULL_VECTOR);

	SetVariantString(strTargetName);
	AcceptEntityInput(g_SpriteModel[client], "SetParent"); 
	SetEntPropFloat(g_SpriteModel[client], Prop_Send, "m_flTextureRes", 0.05);

	return true;
}

KillTrail(client)
{
	if (g_trailTimers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_trailTimers[client]);
		g_trailTimers[client] = INVALID_HANDLE;
	}

	if (g_SpriteModel[client] != -1 && IsValidEntity(g_SpriteModel[client]))
	{
		RemoveEdict(g_SpriteModel[client]);
	}
	g_SpriteModel[client] = -1;
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	KillTrail(client);
}

public Action:Timer_RenderBeam(Handle:timer, Handle:pack)
{
	ResetPack(pack);

	new client = GetClientFromSerial(ReadPackCell(pack));

	if (client == 0)
		return Plugin_Stop;

	decl Float:velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);		

	new bool:isMoving = !(velocity[0] == 0.0 && velocity[1] == 0.0 && velocity[2] == 0.0);
	if (isMoving)
		return Plugin_Continue;

	EquipTrailTempEnts(client, ReadPackCell(pack));
	return Plugin_Continue;
}
public Action:Timer_ExpScan(Handle:timer, any:client)
{
	if(IsValidEntity(g_SpriteModel[client]))
	{
		//Scan for explosions
		if(ExpScan(client, 250.0))
		{
			//Kill trail if we find an explosion, and create a timer to re-attach it
			KillTrail(client);
			CreateTimer(1.0, Timer_AttachTrail, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Stop;
		}
		else
		{
			return Plugin_Continue;
		}
	}
	else
	{
		return Plugin_Stop;
	}
}
public Action:Timer_AttachTrail(Handle:tiemr, any:client)
{
	if(IsValidEntity(client))
	{
		//Any explosions nearby?
		if(!ExpScan(client, 250.0))
		{
			//If not, give their trail back
			GiveTrail(INVALID_HANDLE, GetClientSerial(client));
			return Plugin_Stop;
		}
		else
		{
			return Plugin_Continue;
		}
	}
	else
	{
		return Plugin_Stop;
	}
}
public bool:ExpScan(entity, Float:distance)
{
	if(IsValidEntity(entity))
	{
		decl Float:pos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
		decl Float:epos[3];
		for(new i = MaxClients + 1; i < GetEntityCount(); i++)
		{
			//Use our array index of env_explosion entities to save time.
			//Keeps us from having to GetEdictClassname() and StrEqual for
			//every entity everytime through the loop
			if(IsValidEntity(i) && g_bEnvExp[i] == true)
			{
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", epos);				
				if(FloatAbs(GetVectorDistance(epos, pos)) <= distance)
				{
					return true;
				}
			}
		}
	}
	return false;
}

/**
 * Copies a 1 dimensional static array.
 *
 * @param array			Static Array to copy from.
 * @param newArray		New Array to copy to.
 * @param size			Size of the array (or number of cells to copy)
 * @noreturn
 */
stock Array_Copy(const any:array[], any:newArray[], size)
{
	for (new i=0; i < size; i++) 
	{
		newArray[i] = array[i];
	}
}