#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <smartdm>
#include <store>
#include <smjansson>
#include <smlib>

#undef REQUIRE_PLUGIN
#include <ToggleEffects>
#include <zombiereloaded>

#define PLUGIN_NAME "[Store] Equipment Items Module"
#define PLUGIN_DESCRIPTION "Allows players to equip items such as hats & accessories for public Sourcemod store."
#define PLUGIN_VERSION_CONVAR "store_equipment_version"

enum Equipment
{
	String:EquipmentName[STORE_MAX_NAME_LENGTH],
	String:EquipmentModelPath[PLATFORM_MAX_PATH],
	Float:EquipmentPosition[3],
	Float:EquipmentAngles[3],
	String:EquipmentAttachment[32],
	String:EquipmentPhysicsModelPath[PLATFORM_MAX_PATH],
	EquipmentTeam[10],
	Float:EquipmentScale
}

enum EquipmentPlayerModelSettings
{
	String:EquipmentName[STORE_MAX_NAME_LENGTH],
	String:PlayerModelPath[PLATFORM_MAX_PATH],
	Float:Position[3],
	Float:Angles[3],
	currentlyLockedByClient
}

new Handle:g_hLookupAttachment = INVALID_HANDLE;

new bool:g_bZombieReloaded;
new bool:g_bToggleEffects;

new g_equipment[1024][Equipment];
new g_equipmentCount = 0;

new Handle:g_equipmentNameIndex = INVALID_HANDLE;
new Handle:g_loadoutSlotList = INVALID_HANDLE;
new lastLoadOutSlotSelected[MAXPLAYERS + 1];
new lastTargetSelected[MAXPLAYERS + 1];

new g_playerModels[2048][EquipmentPlayerModelSettings];
new g_playerModelCount = 0;

new String:g_sCurrentEquipment[MAXPLAYERS+1][32][STORE_MAX_NAME_LENGTH];
new g_iEquipment[MAXPLAYERS+1][32];

new g_player_death_equipment_effect;
new String:g_player_death_dissolve_type[2];
new String:g_default_physics_model[PLATFORM_MAX_PATH];
new bool:g_show_negative_numbers;

new bool:g_bShowOwnItems = false;
new bool:g_bShowOwnItemsClients[MAXPLAYERS + 1] = { false, ... };

new clientsPressStoreEditorBigchange[MAXPLAYERS + 1 ] = {false, ... };

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("ZR_IsClientHuman"); 
	MarkNativeAsOptional("ZR_IsClientZombie"); 

	return APLRes_Success;
}

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = STORE_AUTHORS,
	description = PLUGIN_DESCRIPTION,
	version = STORE_VERSION,
	url = STORE_URL
};

public OnPluginStart()
{
	CreateConVar(PLUGIN_VERSION_CONVAR, STORE_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	LoadTranslations("common.phrases");
	LoadTranslations("store.phrases");
	LoadTranslations("store.equipment.phrases");
	
	g_loadoutSlotList = CreateArray(ByteCountToCells(32));
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	
	new Handle:hGameConf = LoadGameConfigFile("store-equipment.gamedata");
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "LookupAttachment");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hLookupAttachment = EndPrepSDKCall();	

	RegAdminCmd("store_editor", Command_OpenEditor, ADMFLAG_RCON, "Opens store-equipment editor.");
	
	RegConsoleCmd("+store_editor_bigchange", Command_StoreEditorBigChangeStart);
	RegConsoleCmd("-store_editor_bigchange", Command_StoreEditorBigChangeStop);
		
	LoadConfig();
}

public Store_OnDatabaseInitialized()
{
	Store_RegisterPluginModule(PLUGIN_NAME, PLUGIN_DESCRIPTION, PLUGIN_VERSION_CONVAR, STORE_VERSION);
}

public Action:Command_StoreEditorBigChangeStart(client, args)
{
	clientsPressStoreEditorBigchange[client] = true;
}

public Action:Command_StoreEditorBigChangeStop(client, args)
{
	clientsPressStoreEditorBigchange[client] = false;
}

public OnAllPluginsLoaded()
{
	g_bZombieReloaded = LibraryExists("zombiereloaded");
	g_bToggleEffects = LibraryExists("specialfx");
}

LoadConfig() 
{
	new Handle:kv = CreateKeyValues("root");
	
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/store/equipment.cfg");
	
	if (!FileToKeyValues(kv, path)) 
	{
		CloseHandle(kv);
		SetFailState("Can't read config file %s", path);
	}
	
	new String:sMenuCommands[256];
	KvGetString(kv, "equipment_editor_commands", sMenuCommands, sizeof(sMenuCommands), "!editor /editor");
	Store_RegisterChatCommands(sMenuCommands, ChatCommand_OpenEquipmentEditor);

	g_player_death_equipment_effect = KvGetNum(kv, "player_death_equipment_effect");
	KvGetString(kv, "player_death_dissolve_type", g_player_death_dissolve_type, sizeof(g_player_death_dissolve_type), "0");
	KvGetString(kv, "default_physics_model", g_default_physics_model, sizeof(g_default_physics_model), "models/props_junk/metalbucket01a.mdl");
	g_show_negative_numbers = bool:KvGetNum(kv, "show_negative_numbers", 0);
	
	CloseHandle(kv);
	
	Store_RegisterItemType("equipment", OnEquip, LoadItem);
}

public ChatCommand_OpenEquipmentEditor(client)
{
	if (!CheckCommandAccess(client, "StoreEquipmentEditor", ADMFLAG_ROOT)) return;
	
	Command_OpenEditor(client, 0);
}

public OnMapStart()
{
	new count = 0;
	for (new i = 0; i < g_equipmentCount; i++)
	{
		if (strcmp(g_equipment[i][EquipmentModelPath], "") != 0 && (FileExists(g_equipment[i][EquipmentModelPath]) || FileExists(g_equipment[i][EquipmentModelPath], true)))
		{
			PrecacheModel(g_equipment[i][EquipmentModelPath]);
			Downloader_AddFileToDownloadsTable(g_equipment[i][EquipmentModelPath]);
			count++;
		}
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "zombiereloaded"))
	{
		g_bZombieReloaded = true;
	}
	else if (StrEqual(name, "store-inventory"))
	{
		Store_RegisterItemType("equipment", OnEquip, LoadItem);
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "zombiereloaded"))
	{
		g_bZombieReloaded = false;
	}
}

public OnClientConnected(client)
{
	for (new i = 0; i < g_playerModelCount; i++)
	{
		g_playerModels[i][currentlyLockedByClient] = 0;
	}

	g_bShowOwnItemsClients[client] = false;
	clientsPressStoreEditorBigchange[client] = false;
}

public OnClientDisconnect(client)
{
	UnequipAll(client);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!g_bZombieReloaded || (g_bZombieReloaded && ZR_IsClientHuman(client)))
	{
		CreateTimer(1.0, SpawnTimer, GetClientSerial(client));
	}
	else
	{
		UnequipAll(client);
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "health") <= 0)
	{
		UnequipAll(GetClientOfUserId(GetEventInt(event, "userid")), false);
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	UnequipAll(GetClientOfUserId(GetEventInt(event, "userid")), false);
	return Plugin_Continue;
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	UnequipAll(client);
}

public ZR_OnClientRespawned(client, ZR_RespawnCondition:condition)
{
	UnequipAll(client);
}

public Action:SpawnTimer(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (!client || !IsClientInGame(client) || IsFakeClient(client) || g_bZombieReloaded && !ZR_IsClientHuman(client))
	{
		return Plugin_Continue;
	}
	
	Store_GetEquippedItemsByType(GetSteamAccountID(client), "equipment", Store_GetClientLoadout(client), OnGetPlayerEquipment, serial);
	return Plugin_Continue;
}

public Store_OnClientLoadoutChanged(client)
{
	Store_GetEquippedItemsByType(GetSteamAccountID(client), "equipment", Store_GetClientLoadout(client), OnGetPlayerEquipment, GetClientSerial(client));
}

public Store_OnReloadItems() 
{
	if (g_equipmentNameIndex != INVALID_HANDLE)
	{
		CloseHandle(g_equipmentNameIndex);
	}
	
	g_equipmentNameIndex = CreateTrie();
	g_equipmentCount = 0;
	g_playerModelCount = 0;
}

json_object_get_string_default(Handle:hObj, const String:sKey[], String:sBuffer[], maxlength, String:sDefault[])
{
	new Handle:hElement = json_object_get(hObj, sKey);
	if (hElement == INVALID_HANDLE)
	{
		strcopy(sBuffer, maxlength, sDefault);
	}
	else
	{
		if(json_is_string(hElement))
		{
			json_string_value(hElement, sBuffer, maxlength);
		}
		else
		{
			strcopy(sBuffer, maxlength, sDefault);
		}
		CloseHandle(hElement);
	}
}

public LoadItem(const String:itemName[], const String:attrs[])
{
	strcopy(g_equipment[g_equipmentCount][EquipmentName], STORE_MAX_NAME_LENGTH, itemName);
	SetTrieValue(g_equipmentNameIndex, g_equipment[g_equipmentCount][EquipmentName], g_equipmentCount);

	new Handle:json = json_load(attrs);
	json_object_get_string(json, "model", g_equipment[g_equipmentCount][EquipmentModelPath], PLATFORM_MAX_PATH);
	json_object_get_string(json, "attachment", g_equipment[g_equipmentCount][EquipmentAttachment], 32);
	json_object_get_string_default(json, "physicsmodel", g_equipment[g_equipmentCount][EquipmentPhysicsModelPath], PLATFORM_MAX_PATH, "");

	for (new i = 0; i < 10; i++)
	{
		g_equipment[g_equipmentCount][EquipmentTeam][i] = -1;
	}
	
	new Handle:team = json_object_get(json, "team");
	if (team != INVALID_HANDLE)
	{
		new size = json_array_size(team);
		if (size > 0)
		{
			for (new i = 0; i < size; i++)
			{
				g_equipment[g_equipmentCount][EquipmentTeam][i] = json_array_get_int(team, i);
			}
		}
		CloseHandle(team);
	}


	g_equipment[g_equipmentCount][EquipmentScale] = json_object_get_float(json, "scale");

	new Handle:position = json_object_get(json, "position");

	for (new i = 0; i <= 2; i++)
	{
		g_equipment[g_equipmentCount][EquipmentPosition][i] = json_array_get_float(position, i);
	}
	
	CloseHandle(position);

	new Handle:angles = json_object_get(json, "angles");

	for (new i = 0; i <= 2; i++)
	{
		g_equipment[g_equipmentCount][EquipmentAngles][i] = json_array_get_float(angles, i);
	}
	
	CloseHandle(angles);

	if (strcmp(g_equipment[g_equipmentCount][EquipmentModelPath], "") != 0 && (FileExists(g_equipment[g_equipmentCount][EquipmentModelPath]) || FileExists(g_equipment[g_equipmentCount][EquipmentModelPath], true)))
	{
		PrecacheModel(g_equipment[g_equipmentCount][EquipmentModelPath]);
		Downloader_AddFileToDownloadsTable(g_equipment[g_equipmentCount][EquipmentModelPath]);
	}

	new Handle:playerModels = json_object_get(json, "playermodels");

	if (playerModels != INVALID_HANDLE && json_typeof(playerModels) == JSON_ARRAY)
	{
		for (new i = 0, size = json_array_size(playerModels); i < size; i++)
		{
			new Handle:playerModel = json_array_get(playerModels, i);
			
			if (playerModel == INVALID_HANDLE)
			{
				continue;
			}
			
			if (json_typeof(playerModel) != JSON_OBJECT)
			{
				CloseHandle(playerModel);
				continue;
			}
			
			json_object_get_string(playerModel, "playermodel", g_playerModels[g_playerModelCount][PlayerModelPath], PLATFORM_MAX_PATH);
			
			new Handle:playerModelPosition = json_object_get(playerModel, "position");
			
			for (new x = 0; x <= 2; x++)
			{
				g_playerModels[g_playerModelCount][Position][x] = json_array_get_float(playerModelPosition, x);
			}
			
			CloseHandle(playerModelPosition);
			
			new Handle:playerModelAngles = json_object_get(playerModel, "angles");
			
			for (new x = 0; x <= 2; x++)
			{
				g_playerModels[g_playerModelCount][Angles][x] = json_array_get_float(playerModelAngles, x);
			}
			
			strcopy(g_playerModels[g_playerModelCount][EquipmentName], STORE_MAX_NAME_LENGTH, itemName);
			
			g_playerModels[g_playerModelCount][currentlyLockedByClient] = -1;
			
			CloseHandle(playerModelAngles);
			CloseHandle(playerModel);
			
			g_playerModelCount++;
		}
		
		CloseHandle(playerModels);
	}
	
	CloseHandle(json);
	
	g_equipmentCount++;
}

public OnGetPlayerEquipment(ids[], count, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	for (new i = 0; i < count; i++)
	{
		new String:itemName[STORE_MAX_NAME_LENGTH];
		Store_GetItemName(ids[i], itemName, sizeof(itemName));

		new String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(ids[i], displayName, sizeof(displayName));
		
		new String:loadoutSlot[STORE_MAX_LOADOUTSLOT_LENGTH];
		Store_GetItemLoadoutSlot(ids[i], loadoutSlot, sizeof(loadoutSlot));
		
		new loadoutSlotIndex = FindStringInArray(g_loadoutSlotList, loadoutSlot);
		
		if (loadoutSlotIndex == -1)
		{
			loadoutSlotIndex = PushArrayString(g_loadoutSlotList, loadoutSlot);
		}
		
		Unequip(client, loadoutSlotIndex);
		
		if (!g_bZombieReloaded || (g_bZombieReloaded && ZR_IsClientHuman(client)))
		{
			Equip(client, loadoutSlotIndex, itemName, displayName);
		}
	}
}

public Store_ItemUseAction:OnEquip(client, itemId, bool:equipped)
{
	if (!IsClientInGame(client))
	{
		return Store_DoNothing;
	}
	
	if (!IsPlayerAlive(client))
	{
		//PrintToChat(client, "%s%t", STORE_PREFIX, "Must be alive to equip");
		return equipped ? Store_UnequipItem : Store_EquipItem;
	}
	
	if (g_bZombieReloaded && !ZR_IsClientHuman(client))
	{
		PrintToChat(client, "%s%t", STORE_PREFIX, "Must be human to equip");	
		return Store_DoNothing;
	}
	
	new String:name[STORE_MAX_NAME_LENGTH];
	Store_GetItemName(itemId, name, sizeof(name));
	
	new String:loadoutSlot[STORE_MAX_LOADOUTSLOT_LENGTH];
	Store_GetItemLoadoutSlot(itemId, loadoutSlot, sizeof(loadoutSlot));
	
	new loadoutSlotIndex = FindStringInArray(g_loadoutSlotList, loadoutSlot);
	
	if (loadoutSlotIndex == -1)
	{
		loadoutSlotIndex = PushArrayString(g_loadoutSlotList, loadoutSlot);
	}
	
	if (equipped)
	{
		if (!Unequip(client, loadoutSlotIndex))
		{
			return Store_DoNothing;
		}
		
		new String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Unequipped item", displayName);
		return Store_UnequipItem;
	}
	else
	{
		new String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));

		if (!Equip(client, loadoutSlotIndex, name, displayName))
		{
			return Store_DoNothing;
		}
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Equipped item", displayName);
		return Store_EquipItem;
	}
}

SetEntityVectors(source, ent, equipment)
{
	new Float:or[3];
	new Float:ang[3];
	new Float:fForward[3];
	new Float:fRight[3];
	new Float:fUp[3];
	
	GetEntPropVector(source, Prop_Send, "m_vecOrigin", or);

	new String:clsname[255];
	if (GetEntityNetClass(source, clsname, sizeof(clsname)) && FindSendPropOffs(clsname, "m_angRotation") >= 0)
	{
		GetEntPropVector(source, Prop_Send, "m_angRotation", ang);
	}

	new String:m_ModelName[PLATFORM_MAX_PATH];
	GetEntPropString(source, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
	
	new playerModel = -1;
	for (new i = 0; i < g_playerModelCount; i++)
	{	
		if (StrEqual(g_equipment[equipment][EquipmentName], g_playerModels[i][EquipmentName]) && StrEqual(m_ModelName, g_playerModels[i][PlayerModelPath], false))
		{
			playerModel = i;
			break;
		}
	}

	if (playerModel == -1)
	{
		ang[0] += g_equipment[equipment][EquipmentAngles][0];
		ang[1] += g_equipment[equipment][EquipmentAngles][1];
		ang[2] += g_equipment[equipment][EquipmentAngles][2];
	}
	else
	{
		ang[0] += g_playerModels[playerModel][Angles][0];
		ang[1] += g_playerModels[playerModel][Angles][1];
		ang[2] += g_playerModels[playerModel][Angles][2];		
	}

	new Float:fOffset[3];

	if (playerModel == -1)
	{
		fOffset[0] = g_equipment[equipment][EquipmentPosition][0];
		fOffset[1] = g_equipment[equipment][EquipmentPosition][1];
		fOffset[2] = g_equipment[equipment][EquipmentPosition][2];	
	}
	else
	{
		fOffset[0] = g_playerModels[playerModel][Position][0];
		fOffset[1] = g_playerModels[playerModel][Position][1];
		fOffset[2] = g_playerModels[playerModel][Position][2];		
	}

	GetAngleVectors(ang, fForward, fRight, fUp);

	or[0] += fRight[0]*fOffset[0]+fForward[0]*fOffset[1]+fUp[0]*fOffset[2];
	or[1] += fRight[1]*fOffset[0]+fForward[1]*fOffset[1]+fUp[1]*fOffset[2];
	or[2] += fRight[2]*fOffset[0]+fForward[2]*fOffset[1]+fUp[2]*fOffset[2];

	TeleportEntity(ent, or, ang, NULL_VECTOR); 
}

GetEquipmentIndexFromName(const String:name[])
{
	new equipment = -1;
	
	if (!GetTrieValue(g_equipmentNameIndex, name, equipment))
	{
		return -1;
	}
	
	return equipment;
}

bool:Equip(client, loadoutSlot, const String:name[], const String:displayName[]="")
{
	Unequip(client, loadoutSlot);

	new equipment = GetEquipmentIndexFromName(name);
	if (equipment < 0)
	{
		PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
		return false;
	}
	
	if (!LookupAttachment(client, g_equipment[equipment][EquipmentAttachment])) 
	{
		PrintToChat(client, "%s%t", STORE_PREFIX, "Player model unsupported");
		return false;
	}

	if (g_equipment[equipment][EquipmentTeam] > 1) // assume 0 is unassigned, 1 is spec
	{
		if (GetClientTeam(client) != g_equipment[equipment][EquipmentTeam])
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "Equipment wrong team", strlen(displayName) == 0 ? name : displayName);
			return false;
		}
	}

	new ent = CreateEntityByName("prop_dynamic_override");
	
	DispatchKeyValue(ent, "model", g_equipment[equipment][EquipmentModelPath]);
	DispatchKeyValue(ent, "solid", "0");
	
	if (g_equipment[equipment][EquipmentScale] > 0)
	{
		SetEntPropFloat(ent, Prop_Data, "m_flModelScale", g_equipment[equipment][EquipmentScale]);
	}
	
	DispatchSpawn(ent);

	ActivateEntity(ent);
	AcceptEntityInput(ent, "TurnOn");
	AcceptEntityInput(ent, "Enable");

	SetEntityVectors(client, ent, equipment);
	
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent);
	
	SetVariantString(g_equipment[equipment][EquipmentAttachment]);
	AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset");

	strcopy(g_sCurrentEquipment[client][loadoutSlot], STORE_MAX_NAME_LENGTH, name);
	g_iEquipment[client][loadoutSlot] = ent;
	
	SDKHook(ent, SDKHook_SetTransmit, ShouldHide);
	
	return true;
}

bool:Unequip(client, loadoutSlot, bool:destroy=true)
{
	new oldequip = g_iEquipment[client][loadoutSlot];
	g_iEquipment[client][loadoutSlot] = 0;

	if (oldequip != 0 && IsValidEdict(oldequip))
	{
		SDKUnhook(oldequip, SDKHook_SetTransmit, ShouldHide);

		if(destroy)
		{
			AcceptEntityInput(oldequip, "Kill");
			return true;
		}

		switch(g_player_death_equipment_effect)
		{
			case 1: // stay on ragdoll
			{
				new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
				if (ragdoll > 0 && IsValidEdict(ragdoll))
				{
					AcceptEntityInput(oldequip, "ClearParent");
					
					new equipment = GetEquipmentIndexFromName(g_sCurrentEquipment[client][loadoutSlot]);
					if (equipment < 0)
					{
						AcceptEntityInput(oldequip, "Kill");
						return true;
					}

					SetEntityVectors(ragdoll, oldequip, equipment);
	
					SetVariantString("!activator");
					AcceptEntityInput(oldequip, "SetParent", ragdoll, oldequip);
					
					SetVariantString(g_equipment[equipment][EquipmentAttachment]);
					AcceptEntityInput(oldequip, "SetParentAttachmentMaintainOffset");
				}
			}
			case 2: // physics
			{
				AcceptEntityInput(oldequip, "ClearParent");

				new Float:velocity[3];
				
				new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
				if (ragdoll > 0 && IsValidEdict(ragdoll))
				{
					GetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollVelocity", velocity);
				}

				velocity[0] *= 1.2;
				velocity[1] *= 1.2;
				velocity[2] *= 1.2;
				
				new equipment = GetEquipmentIndexFromName(g_sCurrentEquipment[client][loadoutSlot]);
				if (equipment < 0)
				{
					AcceptEntityInput(oldequip, "Kill");
					return true;
				}
				
				new ent = CreateEntityByName("prop_physics_multiplayer");
				if (ent < 0 || !IsValidEdict(ent))
				{
					AcceptEntityInput(oldequip, "Kill");
					return true;
				}
				
				if (strlen(g_equipment[equipment][EquipmentPhysicsModelPath]) > 0)
				{
					DispatchKeyValue(ent, "model", g_equipment[equipment][EquipmentPhysicsModelPath]);
				}
				else 
				{
					DispatchKeyValue(ent, "model", g_default_physics_model);
				}
				
				DispatchKeyValue(ent, "spawnflags", "6");
				DispatchKeyValue(ent, "physicsmode", "2");
				DispatchKeyValue(ent, "rendermode", "10"); // invisible
				DispatchKeyValue(ent, "renderamt", "0");
				
				DispatchSpawn(ent);
				ActivateEntity(ent);

				new Float:origin[3], Float:len;
				for (new i = 0; i < 3; i++)
				{
					new Float:n = g_equipment[equipment][EquipmentPosition][i];
					
					if (n < 0) 
					{
						n *= -1;
					}
					
					len += n;
				}
				
				if (len > 20.0)
				{
					GetClientEyePosition(client, origin);
				}
				else
				{
					GetEntPropVector(oldequip, Prop_Send, "m_vecOrigin", origin);
				}

				TeleportEntity(ent, origin, NULL_VECTOR, velocity);

				SetVariantString("!activator");
				AcceptEntityInput(oldequip, "SetParent", ent, oldequip);

				SetEntPropVector(ent, Prop_Data, "m_vecVelocity", velocity); // is this necessary ?

				// kill the physics entity (and equipment as it is attached) in 10 seconds
				new String:addoutput[64];
				Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1", 10.0);
				SetVariantString(addoutput);
				
				AcceptEntityInput(ent, "AddOutput");
				AcceptEntityInput(ent, "FireUser1");
			}
			case 3: // dissolver
			{
				AcceptEntityInput(oldequip, "ClearParent");
				
				new dissolver = CreateEntityByName("env_entity_dissolver");
				if (dissolver < 0 || !IsValidEdict(dissolver))
				{
					AcceptEntityInput(oldequip, "Kill");
					return true;
				}
				
				DispatchKeyValue(dissolver, "dissolvetype", g_player_death_dissolve_type);
				DispatchKeyValue(dissolver, "magnitude", "1");
				DispatchKeyValue(dissolver, "target", "!activator");

				AcceptEntityInput(dissolver, "Dissolve", oldequip);
				AcceptEntityInput(dissolver, "Kill");
			}
			default: // 0/anything else = kill
			{
				AcceptEntityInput(oldequip, "Kill");
			}
		}
	}
	return true;
}

UnequipAll(client, bool:destroy=true)
{
	for (new i = 0, size = GetArraySize(g_loadoutSlotList); i < size; i++)
	{
		Unequip(client, i, destroy);
	}
}

public Action:ShouldHide(ent, client)
{
	// if not hiding any own items, just show them all
	if (g_bShowOwnItemsClients[client] || g_bShowOwnItems)
	{
		return Plugin_Continue;
	}
	
	// hide all items for the client if they have the toggle special fx cookie set
	if (g_bToggleEffects && !ShowClientEffects(client))
	{
		return Plugin_Handled;
	}
	
	// hide items on ourself to stop obstructions to first person view
	for (new i = 0, size = GetArraySize(g_loadoutSlotList); i < size; i++)
	{
		if (ent == g_iEquipment[client][i])
		{
			return Plugin_Handled;
		}
	}
	
	// hide items on our observer target if in first person mode
	if (IsClientInGame(client) && GetEntProp(client, Prop_Send, "m_iObserverMode") == 4 && GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") >= 0)
	{
		for (new i = 0, size = GetArraySize(g_loadoutSlotList); i < size; i++)
		{
			if (ent == g_iEquipment[GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")][i])
			{
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

bool:LookupAttachment(client, String:point[])
{
	if (g_hLookupAttachment == INVALID_HANDLE || client <= 0 || !IsClientInGame(client))
	{
		return false;
	}
	
	return SDKCall(g_hLookupAttachment, client, point);
}

public ConVarChanged_ShowOnItem(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bShowOwnItems = bool:StringToInt(newValue);
}

public Action:Command_OpenEditor(client, args)
{
	if (!client)
	{
		ReplyToCommand(client, "%sError: this command hast be executed by a player ingame.", STORE_PREFIX);
		return Plugin_Handled;
	}
	
	if (!args)
	{
		OpenEditor(client);
		return Plugin_Handled;
	}
		
	new String:sTargets[64];
	GetCmdArg(1, sTargets, sizeof(sTargets));
		
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS];
	new target_count;
	new bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(sTargets, 0, target_list, sizeof(target_list), COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		OpenEditor(target_list[i]);
	}
	
	return Plugin_Handled;
}

OpenEditor(client)
{
	new Handle:menu = CreateMenu(Editor_LoadoutSlotSelectHandle);
	SetMenuTitle(menu, "Select loadout slot:");

	for (new i = 0, size = GetArraySize(g_loadoutSlotList); i < size; i++)
	{
		new String:loadoutSlot[32];
		GetArrayString(g_loadoutSlotList, i, loadoutSlot, sizeof(loadoutSlot));

		new String:value[32];
		Format(value, sizeof(value), "%d,%d", client, i);

		AddMenuItem(menu, value, loadoutSlot);
	}

	DisplayMenu(menu, client, 0);
}

public Editor_LoadoutSlotSelectHandle(Handle:menu, MenuAction:action, client, slot)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				new String:value[48];
				GetMenuItem(menu, slot, value, sizeof(value));
				
				new String:values[2][16];
				ExplodeString(value, ",", values, sizeof(values), sizeof(values[]));

				new target = StringToInt(values[0]);
				new loadoutSlot = StringToInt(values[1]);
				
				lastTargetSelected[client] = target;
				lastLoadOutSlotSelected[client] = loadoutSlot;

				Editor_OpenLoadoutSlotMenu(client, target, loadoutSlot);
				Editor_OnClientStartedEditing(client, target, loadoutSlot);
			}
		case MenuAction_End: CloseHandle(menu);
	}
}

/*
 * Generate a menu with the
 * following items (In this order)
 * 
 * - Position X-
 * - Position X+
 * - Position Y-
 * - Position Y+
 * - Position Z-
 * - Position Z+
 * - Angle X-
 * - Angle X+
 * - Angle Y-
 * - Angle Y+
 * - Angle Z-
 * - Angle Z+
 * - Save
*/
Editor_OpenLoadoutSlotMenu(client, target, loadoutSlot, menuSelectionPosition = 0, Float:amount = 0.5)
{
	new Handle:menu = CreateMenu(Editor_ActionSelectHandle);
	SetMenuTitle(menu, "Select action:   Press +speed (Shift) for\nnegative values and +store_editor_bigchange (custom) for +- 5.0");
	
	for (new axis = 'x'; axis <= 'z'; axis++)
	{
		if (g_show_negative_numbers)
		{
			Editor_AddMenuItem(menu, target, "position", loadoutSlot, axis, false, amount);
		}
		
		Editor_AddMenuItem(menu, target, "position", loadoutSlot, axis, true,  amount);
	}

	for (new axis = 'x'; axis <= 'z'; axis++)
	{
		if (g_show_negative_numbers)
		{
			Editor_AddMenuItem(menu, target, "angles",   loadoutSlot, axis, false, amount);
		}
		
		Editor_AddMenuItem(menu, target, "angles",   loadoutSlot, axis, true,  amount);
	}

	Editor_AddMenuItem(menu, target, "save", loadoutSlot);
	DisplayMenuAtItem(menu, client, menuSelectionPosition, 0);
}

Editor_AddMenuItem(Handle:menu, target, const String:actionType[], loadoutSlot, axis = 0, bool:add = false, Float:amount = 0.0)
{
	new String:value[128];
	Format(value, sizeof(value), "%s,%d,%d,%c,%b", actionType, target, loadoutSlot, axis, add);

	new String:text[32];

	if (StrEqual(actionType, "position") || StrEqual(actionType, "angles"))
	{
		new String:actionTypeDisplay[16];
		strcopy(actionTypeDisplay, sizeof(actionTypeDisplay), actionType);

		// Make the first letter uppercase for the menu
		actionTypeDisplay[0] = CharToUpper(actionTypeDisplay[0]);

		Format(text, sizeof(text), "%c ", CharToUpper(axis));

		switch (add)
		{
			case true: Format(text, sizeof(text), "%s   +", text);
			case false: Format(text, sizeof(text), "%s   - ", text);
		}

		Format(text, sizeof(text), "%s %s %.1f", actionType, text, amount);
	}
	else
	{
		Format(text, sizeof(text), "Save");
	}

	AddMenuItem(menu, value, text);
}

public Editor_ActionSelectHandle(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
			{
				new String:value[128];
				GetMenuItem(menu, param2, value, sizeof(value));
				
				new String:values[5][32];
				ExplodeString(value, ",", values, sizeof(values), sizeof(values[]));

				new target = StringToInt(values[1]);
				new loadoutSlot = StringToInt(values[2]);

				new String:modelPath[PLATFORM_MAX_PATH];
				GetClientModel(target, modelPath, sizeof(modelPath));

				new axis = values[3][0];
				new bool:add = bool:StringToInt(values[4]);

				if (GetClientButtons(param1) & IN_SPEED)
				{
					// Negate the units in any case when the sprint
					// button is pressed.
					add = false;
				}

				new Float:scaleUnits = 0.5;
				if (clientsPressStoreEditorBigchange[param1])
				{
					scaleUnits = 5.0;
				}

				new equipment = GetEquipmentIndexFromName(g_sCurrentEquipment[target][loadoutSlot]);
				if (equipment < 0)
				{
					PrintToChat(param1, "%s%t", STORE_PREFIX, "No item attributes");
					return;
				}

				new playerModel = GetCurrentPlayerModelByLoadoutSlot(param1, loadoutSlot);
				if (playerModel == -1)
				{
					strcopy(g_playerModels[g_playerModelCount][PlayerModelPath], PLATFORM_MAX_PATH, modelPath);
					strcopy(g_playerModels[g_playerModelCount][EquipmentName], STORE_MAX_NAME_LENGTH, g_sCurrentEquipment[target][loadoutSlot]);

					for (new i = 0; i < 3; i++)
					{
						g_playerModels[g_playerModelCount][Position][i] = g_equipment[equipment][EquipmentPosition][i];
						g_playerModels[g_playerModelCount][Angles][i] = g_equipment[equipment][EquipmentAngles][i];
					}

					playerModel = g_playerModelCount;
					g_playerModelCount++;
				}

				if (StrEqual(values[0], "save"))
				{
					Editor_OnClientStoppedEditing(param1, target, lastLoadOutSlotSelected[param1]);
					Editor_SavePlayerModelAttributes(param1, equipment);
				}
				else
				{
					if (StrEqual(values[0], "angles"))
					{
						if (axis == 'x')
						{
							switch (add)
							{
							case true: g_playerModels[playerModel][Angles][0] += scaleUnits;
							case false: g_playerModels[playerModel][Angles][0] -= scaleUnits;
							}
						}
						else if (axis == 'y')
						{
							switch (add)
							{
							case true: g_playerModels[playerModel][Angles][1] += scaleUnits;
							case false: g_playerModels[playerModel][Angles][1] -= scaleUnits;
							}
						} 
						else if (axis == 'z')
						{
							switch (add)
							{
							case true: g_playerModels[playerModel][Angles][2] += scaleUnits;
							case false: g_playerModels[playerModel][Angles][2] -= scaleUnits;
							}
						}
					}
					else
					{
						if (axis == 'x')
						{
							switch (add)
							{
							case true: g_playerModels[playerModel][Position][0] += scaleUnits;
							case false: g_playerModels[playerModel][Position][0] -= scaleUnits;
							}
						}
						else if (axis == 'y')
						{
							switch (add)
							{
							case true: g_playerModels[playerModel][Position][1] += scaleUnits;
							case false: g_playerModels[playerModel][Position][1] -= scaleUnits;
							}
						} 
						else if (axis == 'z')
						{
							switch (add)
							{
							case true: g_playerModels[playerModel][Position][2] += scaleUnits;
							case false: g_playerModels[playerModel][Position][2] -= scaleUnits;
							}
						}
					}

					Equip(target, loadoutSlot, g_sCurrentEquipment[target][loadoutSlot]);
					Editor_OpenLoadoutSlotMenu(param1, target, loadoutSlot, GetMenuSelectionPosition());

					// Call this again in case round restarted or something
					Editor_OnClientStartedEditing(param1, target, loadoutSlot);
				}
			}
		case MenuAction_Cancel: Editor_OnClientStoppedEditing(param1, lastTargetSelected[param1], lastLoadOutSlotSelected[param1]);
		case MenuAction_End: CloseHandle(menu);
	}
}

GetCurrentPlayerModelByLoadoutSlot(target, loadoutSlot)
{
	new String:modelPath[PLATFORM_MAX_PATH];
	GetClientModel(target, modelPath, sizeof(modelPath));

	new playerModel = -1;
	for (new i = 0; i < g_playerModelCount; i++)
	{	
		if (!StrEqual(g_sCurrentEquipment[target][loadoutSlot], g_playerModels[i][EquipmentName]) || !StrEqual(modelPath, g_playerModels[i][PlayerModelPath], false))
		{
			continue;
		}

		playerModel = i;
		break;
	}

	return playerModel;
}

Editor_OnClientStartedEditing(client, target, loadoutSlot)
{
	new playerModel = GetCurrentPlayerModelByLoadoutSlot(target, loadoutSlot);
	
	if (playerModel != -1)
	{
		g_playerModels[playerModel][currentlyLockedByClient] = client;
	}

	if (client == target)
	{
		g_bShowOwnItemsClients[client] = true;
		Client_SetThirdPersonMode(client, true);
	}
}

Editor_OnClientStoppedEditing(client, target, loadoutSlot)
{
	new playerModel = GetCurrentPlayerModelByLoadoutSlot(target, loadoutSlot);
	
	if (playerModel != -1)
	{
		g_playerModels[playerModel][currentlyLockedByClient] = -1;
	}

	if (client == target)
	{
		g_bShowOwnItemsClients[client] = false;
		Client_SetThirdPersonMode(client, false);
	}
}

Editor_SavePlayerModelAttributes(client, equipment)
{
        new Handle:json = json_object();
        json_object_set_new(json, "model", json_string(g_equipment[equipment][EquipmentModelPath]));
        Editor_AppendJSONVector(json, "position", g_equipment[equipment][EquipmentPosition]);
        Editor_AppendJSONVector(json, "angles", g_equipment[equipment][EquipmentAngles]);
        json_object_set_new(json, "attachment", json_string(g_equipment[equipment][EquipmentAttachment]));

        new Handle:playerModels = json_array();

        for (new i = 0; i < g_playerModelCount; i++)
        {        
                if (!StrEqual(g_equipment[equipment][EquipmentName], g_playerModels[i][EquipmentName]))
				{
                        continue;
				}
				
                Editor_AppendJSONPlayerModel(playerModels, g_playerModels[i][PlayerModelPath], g_playerModels[i][Position], g_playerModels[i][Angles]);
        }

        json_object_set_new(json, "playermodels", playerModels);

        new String:sJSON[10 * 1024];
        json_dump(json, sJSON, sizeof(sJSON));        

        CloseHandle(json);

        Store_WriteItemAttributes(g_equipment[equipment][EquipmentName], sJSON, Editor_OnSave, client);
}

public Editor_OnSave(bool:success, any:client)
{
	PrintToChat(client, "%sSave successful.", STORE_PREFIX);

	for (new i = 0; i < g_playerModelCount; i++)
	{
		if (g_playerModels[i][currentlyLockedByClient] > 0)
		{
			PrintToChat(client, "%sWarning: Not reloading items because player model of equipment \"%s\" is currently in process by \"%N\". You can force reload however.", STORE_PREFIX, g_playerModels[i][EquipmentName], g_playerModels[i][currentlyLockedByClient]);
			return;
		}
	}

	Store_ReloadItemCache();
}

Editor_AppendJSONVector(Handle:json, const String:key[], Float:vector[])
{
	new Handle:array = json_array();

	for (new i = 0; i < 3; i++)
	{
		json_array_append_new(array, json_real(vector[i]));
	}
	
	json_object_set_new(json, key, array);		
}

Editor_AppendJSONPlayerModel(Handle:json, const String:modelPath[], Float:position[], Float:angles[])
{
	new Handle:playerModel = json_object();
	
	json_object_set_new(playerModel, "playermodel", json_string(modelPath));
	
	Editor_AppendJSONVector(playerModel, "position", position);
	Editor_AppendJSONVector(playerModel, "angles", angles);

	json_array_append_new(json, playerModel);
}