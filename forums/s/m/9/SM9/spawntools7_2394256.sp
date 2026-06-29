/*
	[SPAWN<>TOOLS<>7]
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define VERSION "0.9"

public Plugin:myinfo = 
{
	name = "spawntools7", 
	author = "meng", 
	description = "spawn point editing tools", 
	version = VERSION, 
	url = ""
}

new Handle:AdminMenu;
new Handle:KillSpawnsADT;
new Handle:CustSpawnsADT;
new Handle:MapSpawnsADT;
new bool:RemoveDefSpawns;
new bool:InEditMode;
new String:MapCfgPath[PLATFORM_MAX_PATH];
new String:g_szMapName[64], String:g_szWorkShopID[64];
new RedGlowSprite;
new BlueGlowSprite;

public OnPluginStart()
{
	CreateConVar("sm_spawntools7_version", VERSION, "Spawn Tools 7 Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	decl String:configspath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configspath, sizeof(configspath), "configs/spawntools7");
	if (!DirExists(configspath))
		CreateDirectory(configspath, 509);
	
	BuildPath(Path_SM, configspath, sizeof(configspath), "configs/spawntools7/workshop");
	if (!DirExists(configspath))
		CreateDirectory(configspath, 509);
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
	
	KillSpawnsADT = CreateArray(3);
	CustSpawnsADT = CreateArray(5);
	MapSpawnsADT = CreateArray(5);
}

public void OnEntityCreated(int iEntity, const char[] chClassName) 
{
	if(StrEqual(chClassName, "info_player_terrorist") || StrEqual(chClassName, "info_player_counterterrorist")) {
		PushArrayCell(MapSpawnsADT, iEntity);
	}
}

public void OnEntityDestroyed(int iEntity)
{
	char chClassName[64];
	
	if(StrEqual(chClassName, "info_player_terrorist") || StrEqual(chClassName, "info_player_counterterrorist")) {
		RemoveFromArray(MapSpawnsADT, iEntity);
	}
}

public OnMapStart()
{
	RemoveDefSpawns = false;
	InEditMode = false;
	
	decl String:mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	
	if (StrContains(mapName, "workshop", false) != -1)
	{
		GetCurrentWorkshopMap(g_szMapName, sizeof(g_szMapName), g_szWorkShopID, sizeof(g_szWorkShopID));
		BuildPath(Path_SM, MapCfgPath, sizeof(MapCfgPath), "configs/spawntools7/workshop/%s/%s.cfg", g_szWorkShopID, g_szMapName);
	}
	else
	{
		BuildPath(Path_SM, MapCfgPath, sizeof(MapCfgPath), "configs/spawntools7/%s.cfg", mapName);
	}
	
	ReadConfig();
	
	RedGlowSprite = PrecacheModel("sprites/blueglow1.vmt");
	BlueGlowSprite = PrecacheModel("sprites/blueglow1.vmt");
}


ReadConfig()
{
	new Handle:kv = CreateKeyValues("ST7Root");
	if (FileToKeyValues(kv, MapCfgPath))
	{
		new num;
		decl String:sBuffer[32], Float:fVec[3], Float:DataFloats[5];
		if (KvGetNum(kv, "remdefsp"))
		{
			RemoveAllDefaultSpawns();
			RemoveDefSpawns = true;
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "rs:%d:pos", num);
			KvGetVector(kv, sBuffer, fVec);
			while (fVec[0] != 0.0)
			{
				RemoveSingleDefaultSpawn(fVec);
				PushArrayArray(KillSpawnsADT, fVec);
				num++;
				Format(sBuffer, sizeof(sBuffer), "rs:%d:pos", num);
				KvGetVector(kv, sBuffer, fVec);
			}
		}
		num = 0;
		Format(sBuffer, sizeof(sBuffer), "ns:%d:pos", num);
		KvGetVector(kv, sBuffer, fVec);
		while (fVec[0] != 0.0)
		{
			DataFloats[0] = fVec[0];
			DataFloats[1] = fVec[1];
			DataFloats[2] = fVec[2];
			Format(sBuffer, sizeof(sBuffer), "ns:%d:ang", num);
			DataFloats[3] = KvGetFloat(kv, sBuffer);
			Format(sBuffer, sizeof(sBuffer), "ns:%d:team", num);
			DataFloats[4] = KvGetFloat(kv, sBuffer);
			CreateSpawn(DataFloats, false);
			PushArrayArray(CustSpawnsADT, DataFloats);
			num++;
			Format(sBuffer, sizeof(sBuffer), "ns:%d:pos", num);
			KvGetVector(kv, sBuffer, fVec);
		}
	}
	
	CloseHandle(kv);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		AdminMenu = INVALID_HANDLE;
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == AdminMenu)
		return;
	
	AdminMenu = topmenu;
	new TopMenuObject:serverCmds = FindTopMenuCategory(AdminMenu, ADMINMENU_SERVERCOMMANDS);
	AddToTopMenu(AdminMenu, "sm_spawntools7", TopMenuObject_Item, TopMenuHandler, serverCmds, "sm_spawntools7", ADMFLAG_RCON);
}

public TopMenuHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Spawn Tools 7");
	
	else if (action == TopMenuAction_SelectOption)
		ShowToolzMenu(param);
}

ShowToolzMenu(client)
{
	new Handle:menu = CreateMenu(MainMenuHandler);
	SetMenuTitle(menu, "Spawn Tools 7");
	decl String:menuItem[64];
	Format(menuItem, sizeof(menuItem), "%s Edit Mode", InEditMode == false ? "Enable" : "Disable");
	AddMenuItem(menu, "0", menuItem);
	Format(menuItem, sizeof(menuItem), "%s Default Spawn Removal", RemoveDefSpawns == false ? "Enable" : "Disable");
	AddMenuItem(menu, "1", menuItem);
	AddMenuItem(menu, "2", "Add T Spawn");
	AddMenuItem(menu, "3", "Add CT Spawn");
	AddMenuItem(menu, "4", "Remove Spawn");
	AddMenuItem(menu, "5", "Save Configuration");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MainMenuHandler(Handle:menu, MenuAction:action, client, selection)
{
	if (action == MenuAction_Select)
	{
		if (selection == 0)
		{
			InEditMode = InEditMode == false ? true : false;
			PrintToChatAll("[SpawnTools7] Edit Mode %s.", InEditMode == false ? "Disabled" : "Enabled");
			if (InEditMode)
				CreateTimer(1.0, ShowEditModeGoodies, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			
			ShowToolzMenu(client);
		}
		else if (selection == 1)
		{
			RemoveDefSpawns = RemoveDefSpawns == false ? true : false;
			PrintToChatAll("[SpawnTools7] Default Spawn Removal will be %s.", RemoveDefSpawns == false ? "Disabled" : "Enabled");
			ShowToolzMenu(client);
		}
		else if (selection == 2)
		{
			InitializeNewSpawn(client, 2);
			ShowToolzMenu(client);
		}
		else if (selection == 3)
		{
			InitializeNewSpawn(client, 3);
			ShowToolzMenu(client);
		}
		else if (selection == 4)
		{
			if (!RemoveSpawn(client))
				PrintToChatAll("[SpawnTools7] No valid spawn point found.");
			else
				PrintToChatAll("[SpawnTools7] Spawn point removed!");
			
			ShowToolzMenu(client);
		}
		else if (selection == 5)
		{
			SaveConfiguration();
			ShowToolzMenu(client);
		}
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

public Action:ShowEditModeGoodies(Handle:timer)
{
	if (!InEditMode)
		return Plugin_Stop;
	
	new tsCount, ctsCount;
	decl String:sClassName[64], Float:fVec[3];
	
	for (new i = 0; i < GetArraySize(MapSpawnsADT); i++)
	{
		int x = EntRefToEntIndex(GetArrayCell(MapSpawnsADT, i));
		
		if(x == -1) {
			continue;
		}
		
		if (GetEntityClassname(x, sClassName, sizeof(sClassName)))
		{
			if (StrEqual(sClassName, "info_player_terrorist"))
			{
				tsCount++;
				GetEntPropVector(x, Prop_Data, "m_vecOrigin", fVec);
				TE_SetupGlowSprite(fVec, RedGlowSprite, 1.0, 0.4, 249);
				TE_SendToAll();
			}
			else if (StrEqual(sClassName, "info_player_counterterrorist"))
			{
				ctsCount++;
				GetEntPropVector(x, Prop_Data, "m_vecOrigin", fVec);
				TE_SetupGlowSprite(fVec, BlueGlowSprite, 1.0, 0.3, 237);
				TE_SendToAll();
			}
		}
	}
	PrintHintTextToAll("T Spawns: %i \nCT Spawns: %i", tsCount, ctsCount);
	
	return Plugin_Continue;
}

RemoveAllDefaultSpawns()
{
	decl String:sClassName[64];
	
	for (new i = 0; i < GetArraySize(MapSpawnsADT); i++)
	{
		int x = EntRefToEntIndex(GetArrayCell(MapSpawnsADT, i));
		
		if(x == -1) {
			continue;
		}
		
		if (GetEntityClassname(x, sClassName, sizeof(sClassName)) && 
			(StrEqual(sClassName, "info_player_terrorist") || StrEqual(sClassName, "info_player_counterterrorist")))
		AcceptEntityInput(x, "Kill");
	}
}

RemoveSingleDefaultSpawn(Float:fVec[3])
{
	decl String:sClassName[64], Float:ent_fVec[3];
	for (new i = 0; i < GetArraySize(MapSpawnsADT); i++)
	{
		int x = EntRefToEntIndex(GetArrayCell(MapSpawnsADT, i));
		
		if(x == -1) {
			continue;
		}
		
		if (GetEntityClassname(x, sClassName, sizeof(sClassName)) && 
			(StrEqual(sClassName, "info_player_terrorist") || StrEqual(sClassName, "info_player_counterterrorist")))
		{
			GetEntPropVector(x, Prop_Data, "m_vecOrigin", ent_fVec);
			if (fVec[0] == ent_fVec[0])
			{
				AcceptEntityInput(x, "Kill");
				break;
			}
		}
	}
}

InitializeNewSpawn(client, team)
{
	decl Float:DataFloats[5], Float:posVec[3], Float:angVec[3];
	GetClientAbsOrigin(client, posVec);
	GetClientEyeAngles(client, angVec);
	DataFloats[0] = posVec[0];
	DataFloats[1] = posVec[1];
	DataFloats[2] = (posVec[2] + 16.0);
	DataFloats[3] = angVec[1];
	DataFloats[4] = float(team);
	
	if (CreateSpawn(DataFloats, true))
		PrintToChatAll("[SpawnTools7] New spawn point created!");
	else
		LogError("failed to create new sp entity");
}

CreateSpawn(Float:DataFloats[5], bool:isNew)
{
	decl Float:posVec[3], Float:angVec[3];
	posVec[0] = DataFloats[0];
	posVec[1] = DataFloats[1];
	posVec[2] = DataFloats[2];
	angVec[0] = 0.0;
	angVec[1] = DataFloats[3];
	angVec[2] = 0.0;
	
	new entity = CreateEntityByName(DataFloats[4] == 2.0 ? "info_player_terrorist" : "info_player_counterterrorist");
	if (DispatchSpawn(entity))
	{
		TeleportEntity(entity, posVec, angVec, NULL_VECTOR);
		if (isNew)
			PushArrayArray(CustSpawnsADT, DataFloats);
		
		return true;
	}
	
	return false;
}

RemoveSpawn(client)
{
	new arraySize = GetArraySize(CustSpawnsADT);
	decl Float:client_posVec[3], Float:DataFloats[5], String:sClassName[64], Float:ent_posVec[3], i, d;
	GetClientAbsOrigin(client, client_posVec);
	client_posVec[2] += 16;
	
	for (d = 0; d < GetArraySize(MapSpawnsADT); d++)
	{
		int e = EntRefToEntIndex(GetArrayCell(MapSpawnsADT, d));
		
		if(e == -1) {
			continue;
		}
		
		if (GetEntityClassname(e, sClassName, sizeof(sClassName)) && 
			(StrEqual(sClassName, "info_player_terrorist") || StrEqual(sClassName, "info_player_counterterrorist")))
		{
			GetEntPropVector(e, Prop_Data, "m_vecOrigin", ent_posVec);
			if (GetVectorDistance(client_posVec, ent_posVec) < 42.7)
			{
				for (i = 0; i < arraySize; i++)
				{
					GetArrayArray(CustSpawnsADT, i, DataFloats);
					if (DataFloats[0] == ent_posVec[0])
					{
						/* spawn was custom */
						RemoveFromArray(CustSpawnsADT, i);
						AcceptEntityInput(e, "Kill");
						
						return true;
					}
				}
				/* spawn was default */
				PushArrayArray(KillSpawnsADT, ent_posVec);
				AcceptEntityInput(e, "Kill");
				
				return true;
			}
		}
	}
	
	return false;
}

SaveConfiguration()
{
	decl String:configspath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configspath, sizeof(configspath), "configs/spawntools7/workshop/%s", g_szWorkShopID);
	if (!DirExists(configspath))
		CreateDirectory(configspath, 509);
	
	new Handle:kv = CreateKeyValues("ST7Root");
	decl arraySize, String:sBuffer[32], Float:DataFloats[5], Float:posVec[3];
	KvJumpToKey(kv, "smdata", true);
	KvSetNum(kv, "remdefsp", RemoveDefSpawns == true ? 1 : 0);
	arraySize = GetArraySize(CustSpawnsADT);
	if (arraySize)
	{
		for (new i = 0; i < arraySize; i++)
		{
			GetArrayArray(CustSpawnsADT, i, DataFloats);
			posVec[0] = DataFloats[0];
			posVec[1] = DataFloats[1];
			posVec[2] = DataFloats[2];
			Format(sBuffer, sizeof(sBuffer), "ns:%d:pos", i);
			KvSetVector(kv, sBuffer, posVec);
			Format(sBuffer, sizeof(sBuffer), "ns:%d:ang", i);
			KvSetFloat(kv, sBuffer, DataFloats[3]);
			Format(sBuffer, sizeof(sBuffer), "ns:%d:team", i);
			KvSetFloat(kv, sBuffer, DataFloats[4]);
		}
	}
	arraySize = GetArraySize(KillSpawnsADT);
	if (arraySize)
	{
		for (new i = 0; i < arraySize; i++)
		{
			GetArrayArray(KillSpawnsADT, i, posVec);
			Format(sBuffer, sizeof(sBuffer), "rs:%d:pos", i);
			KvSetVector(kv, sBuffer, posVec);
		}
	}
	
	if (KeyValuesToFile(kv, MapCfgPath))
		PrintToChatAll("[SpawnTools7] Configuration Saved!");
	else
		LogError("failed to save to key values");
	
	CloseHandle(kv);
}

public OnMapEnd()
{
	ClearArray(KillSpawnsADT);
	ClearArray(CustSpawnsADT);
}

stock GetCurrentWorkshopMap(String:szMap[], iMapBuf, String:szWorkShopID[], iWorkShopBuf)
{
	decl String:szCurMap[128];
	decl String:szCurMapSplit[2][64];
	
	GetCurrentMap(szCurMap, sizeof(szCurMap));
	
	ReplaceString(szCurMap, sizeof(szCurMap), "workshop/", "", false);
	
	ExplodeString(szCurMap, "/", szCurMapSplit, 2, 64);
	
	strcopy(szMap, iMapBuf, szCurMapSplit[1]);
	strcopy(szWorkShopID, iWorkShopBuf, szCurMapSplit[0]);
} 