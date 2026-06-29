// 
// The plugin I use to build props doesn't support creating doors.
// This plugin does a good job of it, but doesn't support saving it.
// I am going to adapt the build plugin I use to be able to save the locations.
// 
// The original build plugin I use is called 'Map Build' by BHaType
// 
// - EDSHOT
// 

#include <sourcemod>
#include <sdktools> 

#pragma newdecls required
#pragma semicolon 1

#define DOOR_SPEED "200"
#define CONFIGS_SPAWN "data/door_save_positions.cfg"
#define MAXENTITIES 64

int g_iBuilds[MAXENTITIES];
float g_vPos[MAXENTITIES][3], g_vAng[MAXENTITIES][3];
Menu g_hRemoveMenu;
bool g_bLoaded;

public Plugin myinfo =
{
	name = "Door Spawner (EDSHOT EDITION)",
	author = "HyperKiLLeR",
	version = "1.4.1-rev1"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_Left4Dead && GetEngineVersion() != Engine_Left4Dead2)
	{
		SetFailState("This plugin is only supported by the Left 4 Dead series.");
	}

	RegAdminCmd("sm_builddoor", Command_DoorMenu, ADMFLAG_ROOT, "Create and save a door");
	RegAdminCmd("sm_deletedoor", DeleteMenu, ADMFLAG_ROOT, "Remove and delete a door");
}

public Action Command_DoorMenu(int client, int args)
{
	Handle menu = CreateMenu(Menu_SpawnDoor);
	AddMenuItem(menu, "wood", "Wooden Door");
	AddMenuItem(menu, "safe", "Saferoom Door");
	AddMenuItem(menu, "metal", "Metal Door");
	AddMenuItem(menu, "freezer", "Freezer Door");
	SetMenuTitle(menu, "Select a door to spawn:");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Menu_SpawnDoor(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];

		GetMenuItem(menu, param2, info, sizeof(info));

		// Declare:
		int Door;
		float AbsAngles[3], ClientOrigin[3], pos[3], beampos[3], FurnitureOrigin[3], EyeAngles[3];

		// Initialize:
		GetClientAbsOrigin(param1, ClientOrigin);
		GetClientEyeAngles(param1, EyeAngles);
		GetClientAbsAngles(param1, AbsAngles);

		GetCollisionPoint(param1, pos);

		FurnitureOrigin[0] = pos[0];
		FurnitureOrigin[1] = pos[1];
		FurnitureOrigin[2] = (pos[2] + 50);

		beampos[0] = pos[0];
		beampos[1] = pos[1];
		beampos[2] = (FurnitureOrigin[2] + 20);

		// Spawn door:
		Door = CreateEntityByName("prop_door_rotating");
		TeleportEntity(Door, FurnitureOrigin, AbsAngles, NULL_VECTOR);

		if (StrEqual(info, "metal", false))
		{
			DispatchKeyValue(Door, "model", "models/props_doors/doormainmetal01.mdl");
		}
		else if (StrEqual(info, "safe", false))
		{
			DispatchKeyValue(Door, "model", "models/props_doors/checkpoint_door_01.mdl");
		}
		else if (StrEqual(info, "wood", false))
		{
			DispatchKeyValue(Door, "model", "models/props_doors/doormain_rural01.mdl");
		}
		else if (StrEqual(info, "freezer", false))
		{
			DispatchKeyValue(Door, "model", "models/props_doors/doorfreezer01.mdl");
		}

		DispatchKeyValue(Door, "hardware", "1");
		DispatchKeyValue(Door, "distance", "90");
		DispatchKeyValue(Door, "speed", DOOR_SPEED);
		DispatchKeyValue(Door, "returndelay", "-1");
		DispatchKeyValue(Door, "spawnflags", "8192");
		DispatchKeyValue(Door, "axis", "131.565 1302.86 2569, 131.565 1302.86 2569");
		DispatchSpawn(Door);
		ActivateEntity(Door);

		// Save door:
		if (StrEqual(info, "metal", false))
		{
			CreateBuild(-1, FurnitureOrigin, AbsAngles, "models/props_doors/doormainmetal01.mdl", param1, Door);
		}
		else if (StrEqual(info, "safe", false))
		{
			CreateBuild(-1, FurnitureOrigin, AbsAngles, "models/props_doors/checkpoint_door_01.mdl", param1, Door);
		}
		else if (StrEqual(info, "wood", false))
		{
			CreateBuild(-1, FurnitureOrigin, AbsAngles, "models/props_doors/doormain_rural01.mdl", param1, Door);
		}
		else if (StrEqual(info, "freezer", false))
		{
			CreateBuild(-1, FurnitureOrigin, AbsAngles, "models/props_doors/doorfreezer01.mdl", param1, Door);
		}

		PrintToChat(param1, "[SM] Door spawned and saved");
	}
}

public void GetCollisionPoint(int client, float pos[3])
{
	float vOrigin[3], vAngles[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return;
	}

	CloseHandle(trace);
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return (entity > MaxClients);
}

// 
// Saving Door Spawns
// - EDSHOT
// 

public int VRemoveHandler(Menu menu, MenuAction action, int client, int index)
{
	if ( action == MenuAction_Select )
	{
		char szMenuItem[128];
		GetMenuItem(menu, index, szMenuItem, sizeof szMenuItem);
		index = StringToInt(szMenuItem);
		DeleteModel(client, index + 1);
		g_hRemoveMenu.Display(client, MENU_TIME_FOREVER);
	}
}

public void OnPluginEnd()
{
	ResetPlugin();
}

void ResetPlugin()
{
	g_bLoaded = false;

	for ( int i = 0; i < MAXENTITIES; i++ )
	{
		g_vPos[i] = view_as<float>({0.0, 0.0, 0.0});

		if ( IsValidEntRef(g_iBuilds[i]) )
			AcceptEntityInput(g_iBuilds[i], "Kill");
		g_iBuilds[i] = 0;
	}
}

public void OnMapStart()
{
	g_bLoaded = false;
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	LoadModels();
}

public void OnRoundStart (Event event, const char[] name, bool dontbroadcast)
{
	ResetPlugin();
	g_bLoaded = false;
	LoadModels();
}

void LoadModels()
{
	if (g_bLoaded)
		return;
	g_bLoaded = true;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIGS_SPAWN);
	if ( !FileExists(sPath) )
		return;

	KeyValues hFile = new KeyValues("airdrop");
	hFile.ImportFromFile(sPath);

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if ( !hFile.JumpToKey(sMap) )
	{
		delete hFile;
		return;
	}

	char sTemp[16], szModel[128];
	float vPos[3], vAng[3];

	for ( int i = 0; i <= MAXENTITIES; i++ )
	{
		IntToString(i, sTemp, sizeof(sTemp));

		if ( hFile.JumpToKey(sTemp, false) )
		{
			hFile.GetVector("vpos", vPos);
			hFile.GetVector("vang", vAng);
			hFile.GetString("model", szModel, sizeof szModel);

			g_vPos[i] = vPos;
			g_vAng[i] = vAng;

			if ( vPos[0] != 0.0 && vPos[1] != 0.0 && vPos[2] != 0.0 )
			{
				CreateModel(i, vPos, vAng, szModel);
			}

			hFile.GoBack();
		}
	}

	delete hFile;
}

void CreateBuild(int index = -1, float vPos[3], float vAng[3], char[] szModel, int client, int door)
{
	if ( index == -1 )
	{
		for ( int i = 0; i < MAXENTITIES; i++ )
		{
			if (g_vAng[i][0] == 0.0 && g_vAng[i][1] == 0.0 && g_vAng[i][2] == 0.0 && g_vPos[i][0] == 0.0 && g_vPos[i][1] == 0.0 && g_vPos[i][2] == 0.0 && !IsValidEntRef(g_iBuilds[i]))
			{
				index = i;
				break;
			}
		}
	}
	if ( index == -1 )
	{
		PrintToChat(client, "[SM] Unable to save door. Entity limit reached.");
		return;
	}

	SaveModel(index, "vpos", vPos);
	SaveModel(index, "vang", vAng);
	SaveModel(index, "model", vAng, true, szModel);
	g_vPos[index] = vPos;
	g_vAng[index] = vAng;
	g_iBuilds[index] = EntIndexToEntRef(door);
}

void SaveModel(int index, char[] sKey, float vVec[3], bool string = false, char[] szModelName = "")
{
	KeyValues hFile = ConfigOpen();

	if ( hFile != null )
	{
		char sTemp[64];
		GetCurrentMap(sTemp, sizeof(sTemp));
		if ( hFile.JumpToKey(sTemp, true) )
		{
			IntToString(index, sTemp, sizeof(sTemp));

			if ( hFile.JumpToKey(sTemp, true) )
			{
				if (!string)
					hFile.SetVector(sKey, vVec);
				else
					hFile.SetString(sKey, szModelName);

				ConfigSave(hFile);
			}
		}

		delete hFile;
	}
}

void DeleteModel(int client, int cfgindex)
{
	KeyValues hFile = ConfigOpen();

	if ( hFile != null )
	{
		char sMap[64];
		GetCurrentMap(sMap, sizeof(sMap));

		if ( hFile.JumpToKey(sMap) )
		{
			char sTemp[16];
			IntToString(cfgindex - 1, sTemp, sizeof(sTemp));
			if ( hFile.JumpToKey(sTemp) )
			{
				if ( IsValidEntRef(g_iBuilds[cfgindex - 1]) )
					AcceptEntityInput(g_iBuilds[cfgindex - 1], "Kill");
				g_iBuilds[cfgindex - 1] = 0;

				hFile.DeleteKey("vpos");
				hFile.DeleteKey("vang");
				hFile.DeleteKey("Model");

				float vPos[3];
				hFile.GetVector("pos", vPos);


				hFile.GoBack();

				if ( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 )
				{
					for ( int i = cfgindex; i < MAXENTITIES; i++ )
					{
						g_iBuilds[i - 1] = g_iBuilds[i];
						g_iBuilds[i] = 0;

						g_vPos[i - 1] = g_vPos[i];
						g_vPos[i] = view_as<float>({ 0.0, 0.0, 0.0 });

						g_vAng[i - 1] = g_vAng[i];
						g_vAng[i] = view_as<float>({ 0.0, 0.0, 0.0 });

						IntToString(i, sTemp, sizeof(sTemp));
						if ( hFile.JumpToKey(sTemp) )
						{
							IntToString(i - 1, sTemp, sizeof(sTemp));
							hFile.SetSectionName(sTemp);
							hFile.GoBack();
						}
					}
				}
				PrintToChat(client, "[SM] Door has been removed and deleted");
				ConfigSave(hFile);
			}
		}

		delete hFile;
	}
}

void CreateModel(int index, float vPos[3], float vAng[3], char[] szModel)
{
	int Door = CreateEntityByName("prop_door_rotating");
	TeleportEntity(Door, vPos, vAng, NULL_VECTOR);

	DispatchKeyValue(Door, "model", szModel);
	DispatchKeyValue(Door, "hardware", "1");
	DispatchKeyValue(Door, "distance", "90");
	DispatchKeyValue(Door, "speed", DOOR_SPEED);
	DispatchKeyValue(Door, "returndelay", "-1");
	DispatchKeyValue(Door, "spawnflags", "8192");
	DispatchKeyValue(Door, "axis", "131.565 1302.86 2569, 131.565 1302.86 2569");
	DispatchSpawn(Door);
	ActivateEntity(Door);

	g_iBuilds[index] = EntIndexToEntRef(Door);
}

public Action DeleteMenu(int client, int args)
{
	int count;
	char szTemp[4];
	g_hRemoveMenu = new Menu(VRemoveHandler);

	for ( int i = 0; i < MAXENTITIES; i++ )
	{
		if ( g_vPos[i][0] != 0.0 && g_vPos[i][1] != 0.0 && g_vPos[i][2] != 0.0 && IsValidEntRef(g_iBuilds[i]) == true)
		{
			count++;
			IntToString(i, szTemp, sizeof szTemp);
			g_hRemoveMenu.AddItem(szTemp, szTemp);
		}
	}

	if (!count)
	{
		PrintToChat(client, "[SM] Error: Config didnt have any doors in config");
		return;
	}

	g_hRemoveMenu.SetTitle("Remove Menu: Select Info");
	g_hRemoveMenu.ExitBackButton = true;
	g_hRemoveMenu.Display(client, MENU_TIME_FOREVER);
}

public bool TraceFilter(int entity, int contentsMask)
{
	return (entity > MaxClients);
}

KeyValues ConfigOpen()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIGS_SPAWN);

	if ( !FileExists(sPath) )
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
	}

	KeyValues hFile = new KeyValues("doors");
	if ( !hFile.ImportFromFile(sPath) )
	{
		delete hFile;
		return null;
	}

	return hFile;
}

void ConfigSave(KeyValues hFile)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIGS_SPAWN);

	if ( !FileExists(sPath) )
		return;

	hFile.Rewind();
	hFile.ExportToFile(sPath);
}

bool IsValidEntRef(int entity)
{
	if ( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}
