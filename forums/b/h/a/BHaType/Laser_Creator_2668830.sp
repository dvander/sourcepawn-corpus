#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CONFIG_SPAWNS		"data/l4d2_lasers.cfg"

#define Sprite "sprites/laserbeam.spr"

#define MAXENTITIES		8
//#define MAX_KEY_LENGHT 32

static const char g_szNetProps [][] =
{
	"NoiseAmplitude",
	"TextureScroll",
	"damage",
	"renderamt",
	"rendercolor",
	"width",
	"LaserTarget"
};

Menu g_hMainMenu, g_hCreate, g_hCounter, g_hSettings, g_hSettingsChanger, g_hOriginControl;
int g_iLasers[MAXENTITIES], g_iTargets[MAXENTITIES], g_iSelected[MAXPLAYERS + 1];

bool g_bLoaded, g_bHookChat[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[L4D2] Lasers Creator",
	author = "BHaType",
	description = "Creates lasers and save them",
	version = "0.0",
	url = "N/A"
}

public void OnMapStart()
{
	g_bLoaded = false;
	LoadConfig();
}

public void eEvent (Event event, const char[] name, bool dontbroadcast)
{
	g_bLoaded = false;
	LoadConfig();
}

void LoadConfig()
{
	if (g_bLoaded)
		return;
	
	g_bLoaded = true;
	
	bool switchsys;
	int entity;
	
	for (int l; l < 2; l++)
	{
		for (int i; i < MAXENTITIES; i++)
		{
			if (!switchsys)
			{
				if ((entity = EntRefToEntIndex(g_iLasers[i])) > MaxClients && IsValidEntity(entity))
					AcceptEntityInput(entity, "kill");
				g_iLasers[i] = 0;
			}
			else
			{
				if ((entity = EntRefToEntIndex(g_iTargets[i])) > MaxClients && IsValidEntity(entity))
					AcceptEntityInput(entity, "kill");
				g_iTargets[i] = 0;
			}
		}
		
		switchsys = true;
	}
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;
		
	KeyValues hFile = new KeyValues("Data");
	hFile.ImportFromFile(sPath);
	
	char sMap[64];
	GetCurrentMap(sMap, sizeof sMap);
	
	if (!hFile.JumpToKey(sMap))
	{
		delete hFile;
		return;
	}
	
	if (!hFile.JumpToKey("Targets Section"))
	{
		delete hFile;
		return;
	}
	
	switchsys = true;
	char szTemp[8], szName[36];
	float vOrigin[3];
	
	int iTempint;
	
	for (int l; l < 2; l++)
	{
		for (int i; i < MAXENTITIES; i++)
		{
			IntToString(i, szTemp, sizeof szTemp);
			
			if (hFile.JumpToKey(szTemp))
			{
				if (switchsys)
				{
					hFile.GetVector("vOrigin", vOrigin);
					hFile.GetString("MyName", szName, sizeof szName);
					
					entity = CreateEntityAlt("info_target", vOrigin, true);
					DispatchKeyValue(entity, "targetname", szName);
					g_iTargets[i] = EntIndexToEntRef(entity);
				}
				else
				{
					hFile.GetVector("vOrigin", vOrigin);
					entity = CreateEntityAlt("env_laser", vOrigin, false);

					DispatchKeyValue(entity, "texture", Sprite);
					DispatchKeyValue(entity, "decalname", "Bigshot");
					
					for (int v; v < sizeof g_szNetProps; v++)
					{
						switch (v)
						{
							case 4:
							{
								hFile.GetString(g_szNetProps[v], szTemp, sizeof szTemp);
								DispatchKeyValue(entity, g_szNetProps[v], szTemp);
							}
							case 5: DispatchKeyValueFloat(entity, g_szNetProps[v], hFile.GetFloat(g_szNetProps[v]));
							case 6:
							{
								hFile.GetString("target", szName, sizeof szName);
								DispatchKeyValue(entity, g_szNetProps[v], szName);
							}
							default: 
							{
								iTempint = hFile.GetNum(g_szNetProps[v]);
								IntToString(iTempint, szTemp, sizeof szTemp);
								DispatchKeyValue(entity, g_szNetProps[v], szTemp);
							}
						}
					}
					
					DispatchSpawn(entity);
					
					g_iLasers[i] = EntIndexToEntRef(entity);
				}
				hFile.GoBack();
			}
		}

		hFile.GoBack();
		hFile.JumpToKey("Laser Section");
		switchsys = false;
	}
	delete hFile;
}

public Action eStart (int client, int args)
{
	if (!client || !IsClientInGame(client))
		return Plugin_Handled;
		
	g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action eRespawn (int client, int args)
{
	if (!client || !IsClientInGame(client))
		return Plugin_Handled;
		
	g_bLoaded = false;
	LoadConfig();
	ReplyToCommand(client, "Config has been reloaded");
	return Plugin_Handled;
}

public void OnPluginStart()
{	
	RegAdminCmd("sm_laser_control", eStart, ADMFLAG_ROOT);
	RegAdminCmd("sm_respawn_all_lasers", eRespawn, ADMFLAG_ROOT);
	
	HookEvent("round_start", eEvent);
	
	AddCommandListener(cListener, "say");
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);

	if (!FileExists(sPath))
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
	}
	
	g_hMainMenu = new Menu(VMenuHandler);
	g_hMainMenu.AddItem("", "Create Laser | Target");
	g_hMainMenu.AddItem("", "Delete Laser | Target");
	g_hMainMenu.AddItem("", "Change Settings");
	g_hMainMenu.AddItem("", "Change Position");

	g_hMainMenu.SetTitle("Main Menu");
	g_hMainMenu.ExitButton = true;
	
	g_hCreate = new Menu(VCreateHandler);
	g_hCreate.AddItem("", "Setup Laser");
	g_hCreate.AddItem("", "Setup Target");
	g_hCreate.SetTitle("Creating entity switch");
	g_hCreate.ExitBackButton = true;	
	
	g_hSettings = new Menu(VSettingsHandler);
	g_hSettings.AddItem("0", "Setup name (Targets)");
	g_hSettings.AddItem("1", "Change Settings (Lasers)");
	g_hSettings.SetTitle("Setup settings of laser");
	g_hSettings.ExitBackButton = true;
	
	g_hOriginControl = new Menu(VOriginControlHandler);
	g_hOriginControl.AddItem("", "By my position");
	g_hOriginControl.AddItem("", "By my eye position");
	g_hOriginControl.AddItem("", "By crosshair pos");
	g_hOriginControl.SetTitle("Setup settings of laser");
	g_hOriginControl.ExitBackButton = true;
}

public Action cListener(int client, const char[] command, int iArgs)
{
	if (g_bHookChat[client])
	{
		g_bHookChat[client] = false;
		
		int iEntity = EntRefToEntIndex(g_iTargets[g_iSelected[client]]);
		
		if (!IsValidEntity(iEntity))
			return Plugin_Handled;
		
		char szPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, szPath, sizeof(szPath), CONFIG_SPAWNS);
		
		KeyValues hFile = OpenConfig(szPath);
		
		if (!hFile)
		{
			delete hFile;
			return Plugin_Handled;
		}
		
		char szName[36], szTemp[16];
		GetCmdArg(1, szName, sizeof szName);
		int index;
		if ((index = GetEntProp(client, Prop_Data, "m_iHammerID") - 666) >= 0)
		{
			hFile.JumpToKey("Laser Section");
			
			IntToString(g_iSelected[client], szTemp, sizeof szTemp);

			if (!hFile.JumpToKey(szTemp))
			{
				delete hFile;
				return Plugin_Handled;
			}

			switch (index)
			{
				case 0, 1, 2, 3:
				{
					for(int i; i < strlen(szName); i++)
					{
						if (!IsCharNumeric(szName[i]))
						{
							PrintToChat(client, "Dont use any non numeric symbols");
							delete hFile;
							return Plugin_Handled;
						}
					}
					
					hFile.SetNum(g_szNetProps[index], StringToInt(szName));
				}
				case 4: hFile.SetString(g_szNetProps[index], szName);
				case 5: hFile.SetFloat(g_szNetProps[index], StringToFloat(szName));
			}
			
			hFile.Rewind();
			hFile.ExportToFile(szPath);
			
			delete hFile;
			SetEntProp(client, Prop_Data, "m_iHammerID", 0);
			return Plugin_Handled;
		}
		
		hFile.JumpToKey("Targets Section");
			
		IntToString(g_iSelected[client], szTemp, sizeof szTemp);
		if (hFile.JumpToKey(szTemp))
			hFile.SetString("MyName", szName);
		
		SetEntPropString(iEntity, Prop_Data, "m_iName", szName);
		
		hFile.Rewind();
		hFile.ExportToFile(szPath);
		
		PrintToChat(client, "Name has been successfully set to << %s >>", szName);

		g_iSelected[client] = -1;
		
		delete hFile;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public int VOriginControlHandler (Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_Select )
	{
		g_hCounter = new Menu(VCounterHandler);
		
		int iTargets, iLasers, entity;
		
		for (int i; i < MAXENTITIES; i++)
		{
			if ((entity = EntRefToEntIndex(g_iTargets[i])) > MaxClients && IsValidEntity(entity))
				iTargets++;
				
			if ((entity = EntRefToEntIndex(g_iLasers[i])) > MaxClients && IsValidEntity(entity))
				iLasers++;
		}
		
		char szTemp[16], szBuffer[36];
		
		Format(szBuffer, sizeof szBuffer, "TARGET_POS_CHANGER %i", index);
		Format(szTemp, sizeof szTemp, "Targets (%i)", iTargets);
		g_hCounter.AddItem(szBuffer, szTemp);
		
		Format(szBuffer, sizeof szBuffer, "LASER_POS_CHANGER %i", index);
		Format(szTemp, sizeof szTemp, "Lasers (%i)", iLasers);
		g_hCounter.AddItem(szBuffer, szTemp);
		
		g_hCounter.SetTitle("Select category");
		g_hCounter.Display(client, MENU_TIME_FOREVER);
	}
}

public int VCounterHandler (Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_Select )
	{
		char szMenuItem[56], szTemp[36], szNameEx[56];
		GetMenuItem(menu, index, szMenuItem, sizeof szMenuItem);
		int entity;

		if (StrContains(szMenuItem, "POSITION_SAVE") != -1)
		{
			bool switchsys;
			
			if (ReplaceString(szMenuItem, sizeof szMenuItem, "TARGET_POSITION_SAVE", "") > 0)
				switchsys = true;
			else
				ReplaceString(szMenuItem, sizeof szMenuItem, "LASER_POSITION_SAVE", "");
			
			float vOrigin[3], vAngles[3];
			char szExplodeString[2][8];
			
			ExplodeString(szMenuItem, "|", szExplodeString, sizeof szExplodeString, sizeof szExplodeString[]);
			
			TrimString(szExplodeString[0]);
			TrimString(szExplodeString[1]);
			
			switch(StringToInt(szExplodeString[1]))
			{
				case 0: GetClientAbsOrigin(client, vOrigin);
				case 1:	GetClientEyePosition(client, vOrigin);
				case 2:
				{
					GetClientEyePosition(client, vOrigin);
					GetClientEyeAngles(client, vAngles);
					
					Handle hRayTrace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilter);
	
					if(TR_DidHit(hRayTrace))
						TR_GetEndPosition(vOrigin, hRayTrace);
					
					delete hRayTrace;
				}
			}

			ConfigOriginChanger(StringToInt(szExplodeString[0]), switchsys, vOrigin);
		}
		else if (StrContains(szMenuItem, "POS_CHANGER") != -1)
		{
			g_hCounter = new Menu(VCounterHandler);
		
			if (ReplaceString(szMenuItem, sizeof szMenuItem, "TARGET_POS_CHANGER", "") > 0)
			{
				for (int l; l < MAXENTITIES; l++)
				{
					if ((entity = EntRefToEntIndex(g_iTargets[l])) > MaxClients && IsValidEntity(entity))
					{
						GetEntPropString(entity, Prop_Data, "m_iName", szNameEx, sizeof szNameEx);
						Format(szTemp, sizeof szTemp, "%s (%i | %i)", szNameEx, entity, l);
						Format(szNameEx, sizeof szNameEx, "TARGET_POSITION_SAVE %i|%i", l, StringToInt(szMenuItem));
						g_hCounter.AddItem(szNameEx, szTemp);
					}
				}
			}
			else if (ReplaceString(szMenuItem, sizeof szMenuItem, "LASER_POS_CHANGER", "") > 0)
			{
				for (int l; l < MAXENTITIES; l++)
				{
					if ((entity = EntRefToEntIndex(g_iLasers[l])) > MaxClients && IsValidEntity(entity))
					{
						Format(szTemp, sizeof szTemp, "Laser (%i | %i)", entity, l);
						Format(szNameEx, sizeof szNameEx, "LASER_POSITION_SAVE %i|%i", l, StringToInt(szMenuItem));
						g_hCounter.AddItem(szNameEx, szTemp);
					}
				}
			}
			
			g_hCounter.SetTitle("Select target");
			g_hCounter.Display(client, MENU_TIME_FOREVER);
		}
		else if (strcmp(szMenuItem, "TARGET") == 0)
			TargetLaserMenu(client, true, true);
		else if (strcmp(szMenuItem, "LASER") == 0)
			TargetLaserMenu(client, true, false);
		else
		{
			bool switchsys = false;
			
			if (StrContains(szMenuItem, "TARGET_DELETE_INDEX") != -1)
			{
				ReplaceString(szMenuItem, sizeof szMenuItem, "TARGET_DELETE_INDEX", "");
				switchsys = true;
			}
			else
				ReplaceString(szMenuItem, sizeof szMenuItem, "LASER_DELETE_INDEX", "");
			
			TrimString(szMenuItem);
			
			DeleteFromConfig(switchsys, StringToInt(szMenuItem));
			g_hMainMenu.Display(client, MENU_TIME_FOREVER);
		}
	}
}

public int VSettingsHandler (Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_Select )
	{
		char szMenuItem[56];
		GetMenuItem(menu, index, szMenuItem, sizeof szMenuItem);
		
		if (ReplaceString(szMenuItem, sizeof szMenuItem, "SETUP_LASER_TARGET", "") != 0)
		{
			TrimString(szMenuItem);

			int iTarget;
			
			if ((iTarget = EntRefToEntIndex(g_iTargets[StringToInt(szMenuItem)])) <= MaxClients || !IsValidEntity(iTarget))
				return;

			char szPath[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, szPath, sizeof(szPath), CONFIG_SPAWNS);
			
			KeyValues hFile = OpenConfig(szPath);
			
			if (!hFile)
			{
				delete hFile;
				return;
			}

			hFile.JumpToKey("Laser Section");
			
			char szTemp[8], szExName[36];
			IntToString(g_iSelected[client], szTemp, sizeof szTemp);

			if (!hFile.JumpToKey(szTemp))
			{
				delete hFile;
				return;
			}

			GetEntPropString(iTarget, Prop_Data, "m_iName", szExName, sizeof szExName);
			
			hFile.SetString("target", szExName);
			
			hFile.Rewind();
			hFile.ExportToFile(szPath);
			
			PrintToChat(client, "Target %s has been successfully set for laser %i", szExName, g_iSelected[client]);
			g_hSettings.Display(client, MENU_TIME_FOREVER);
			delete hFile;
			return;
		}
		
		if (ReplaceString(szMenuItem, sizeof szMenuItem, "LASER_SETTINGS_INDEX", "") != 0)
		{
			TrimString(szMenuItem);
			
			g_iSelected[client] = StringToInt(szMenuItem);
			
			g_hSettingsChanger = new Menu(VSettingsHandler);
			for (int i; i < sizeof g_szNetProps; i++)
				g_hSettingsChanger.AddItem(g_szNetProps[i], g_szNetProps[i]);
			g_hSettingsChanger.SetTitle("Netprops Selecting");
			g_hSettingsChanger.Display(client, MENU_TIME_FOREVER);
			return;
		}
		
		for (int i; i < sizeof g_szNetProps; i++)
		{
			if (i == 6 && strcmp(g_szNetProps[i], szMenuItem) == 0)
			{
				char szNameEx[36], szTemp[16];
				g_hSettingsChanger = new Menu(VSettingsHandler);
				
				int entity;
				for (int l; l < MAXENTITIES; l++)
				{
					if ((entity = EntRefToEntIndex(g_iTargets[l])) > MaxClients && IsValidEntity(entity))
					{
						GetEntPropString(entity, Prop_Data, "m_iName", szNameEx, sizeof szNameEx);
						Format(szTemp, sizeof szTemp, "%s (%i | %i)", szNameEx, entity, l);
						Format(szNameEx, sizeof szNameEx, "SETUP_LASER_TARGET %i", l);
						g_hSettingsChanger.AddItem(szNameEx, szTemp);
					}
				}
				g_hSettingsChanger.SetTitle("Select target");
				g_hSettingsChanger.Display(client, MENU_TIME_FOREVER);
				return;
			}
			else if (strcmp(g_szNetProps[i], szMenuItem) == 0)
			{
				g_bHookChat[client] = true;
				SetEntProp(client, Prop_Data, "m_iHammerID", i + 666);
				if (i == 4) PrintToChat(client, "Example: <R(0 - 255) G(0 - 255) B(0 - 255)>");
				
				return;
			}
		}
		
		if (ReplaceString(szMenuItem, sizeof szMenuItem, "TARGET_SETTINGS_INDEX", "") != 0)
		{
			TrimString(szMenuItem);
			
			g_bHookChat[client] = true;
			g_iSelected[client] = StringToInt(szMenuItem);
			
			PrintToChat(client, "What name do you want to use?");
			return;
		}
		
		int entity;
		char szNameEx[36], szTemp[36];
		
		g_hSettingsChanger = new Menu(VSettingsHandler);
		
		switch (StringToInt(szMenuItem))
		{
			case 0: 
			{
				for (int i; i < MAXENTITIES; i++)
				{
					if ((entity = EntRefToEntIndex(g_iTargets[i])) > MaxClients && IsValidEntity(entity))
					{
						GetEntPropString(entity, Prop_Data, "m_iName", szNameEx, sizeof(szNameEx));
						Format(szTemp, sizeof szTemp, "%s (%i | %i)", szNameEx, entity, i);
						Format(szNameEx, sizeof szNameEx, "TARGET_SETTINGS_INDEX %i", i);
						g_hSettingsChanger.AddItem(szNameEx, szTemp);
					}
				}
				g_hSettingsChanger.SetTitle("Name changer");
				g_hSettingsChanger.Display(client, MENU_TIME_FOREVER);
			}
			case 1:
			{
				g_hSettingsChanger = new Menu(VSettingsHandler);
				for (int i; i < MAXENTITIES; i++)
				{
					if ((entity = EntRefToEntIndex(g_iLasers[i])) > MaxClients && IsValidEntity(entity))
					{
						Format(szTemp, sizeof szTemp, "Laser (%i | %i)", entity, i);
						Format(szNameEx, sizeof szNameEx, "LASER_SETTINGS_INDEX %i", i);
						g_hSettingsChanger.AddItem(szNameEx, szTemp);
					}
				}
				
				g_hSettingsChanger.SetTitle("Netprops Changer");
				g_hSettingsChanger.Display(client, MENU_TIME_FOREVER);
			}
		}
	}
}

public int VMenuHandler (Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		switch (index)
		{
			case 0: g_hCreate.Display(client, MENU_TIME_FOREVER);
			case 1: TargetLaserMenu(client, false, false);
			case 2: g_hSettings.Display(client, MENU_TIME_FOREVER);
			case 3: g_hOriginControl.Display(client, MENU_TIME_FOREVER);
		}
	}
}

public int VCreateHandler (Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_Select )
	{
		switch (index)
		{
			case 0: CreateEntity(client, false);
			case 1: CreateEntity(client, true);
		}
	}
}

KeyValues OpenConfig(char[] szPath)
{
	if (!FileExists(szPath))
		return null;
	
	KeyValues hFile = new KeyValues("Data");
	
	if (!hFile.ImportFromFile(szPath))
	{
		delete hFile;
		return null;
	}
	
	char sMap[64];
	GetCurrentMap(sMap, sizeof sMap);
	
	if (!hFile.JumpToKey(sMap))
	{
		delete hFile;
		return null;
	}
	
	return hFile;
}

int CreateEntity (int client, bool switchz)
{
	int entity;
	
	float vOrigin[3], vAngles[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle hRayTrace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilter);
	
	if(TR_DidHit(hRayTrace))
		TR_GetEndPosition(vOrigin, hRayTrace);
	
	delete hRayTrace;
	bool saved;
	if (switchz)
	{
		entity = CreateEntityByName("info_target");
		DispatchKeyValueVector(entity, "origin", vOrigin);
		DispatchKeyValue(entity, "targetname", "NULL_NAME");
		DispatchSpawn(entity);
		
		if (!IsValidEntity(entity))
			return INVALID_ENT_REFERENCE;
		
		for (int i; i < MAXENTITIES; i++)
		{
			if (EntRefToEntIndex(g_iTargets[i]) == INVALID_ENT_REFERENCE || EntRefToEntIndex(g_iTargets[i]) == 0)
			{
				g_iTargets[i] = EntIndexToEntRef(entity);
				SaveToConfig(true, i, vOrigin);
				saved = true;
				break;
			}
		}
		
		if (!saved)
		{
			AcceptEntityInput(entity, "kill");
			PrintToChat(client, "Limit has been reached");
		}
	}
	else
	{
		entity = CreateEntityByName("env_laser");
		
		if (!IsValidEntity(entity))
			return INVALID_ENT_REFERENCE;
			
		DispatchKeyValue(entity, "width", "0.5");
		DispatchKeyValue(entity, "decalname", "Bigshot");
		DispatchKeyValue(entity, "NoiseAmplitude", "0");
		DispatchKeyValue(entity, "TextureScroll", "60");
		DispatchKeyValue(entity, "damage", "5");
		DispatchKeyValue(entity, "renderamt", "255");
		DispatchKeyValue(entity, "rendercolor", "25 25 255");
		DispatchKeyValue(entity, "texture", Sprite);
		
		DispatchSpawn(entity);
	
		TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
		
		for (int i; i < MAXENTITIES; i++)
		{
			if (EntRefToEntIndex(g_iLasers[i]) == INVALID_ENT_REFERENCE || EntRefToEntIndex(g_iLasers[i]) == 0)
			{
				g_iLasers[i] = EntIndexToEntRef(entity);
				SaveToConfig(false, i, vOrigin);
				saved = true;
				break;
			}
		}
		
		if (!saved)
		{
			AcceptEntityInput(entity, "kill");
			PrintToChat(client, "Limit has been reached");
		}
	}
	g_hCreate.Display(client, MENU_TIME_FOREVER);
	return entity;
}

void SaveToConfig(bool switchz, int index, float vOrigin[3])
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), CONFIG_SPAWNS);
	
	if (!FileExists(szPath))
		return;
	
	KeyValues hFile = new KeyValues("Data");
	
	if (!hFile.ImportFromFile(szPath))
		return;
		
	char sMap[64], szTemp[8];
	GetCurrentMap(sMap, sizeof sMap);
	
	if (hFile.JumpToKey(sMap, true))
	{
		if (!switchz)
			hFile.JumpToKey("Laser Section", true);
		else
			hFile.JumpToKey("Targets Section", true);
		
		IntToString(index, szTemp, sizeof szTemp);
		if (hFile.JumpToKey(szTemp, true))
		{
			hFile.SetVector("vOrigin", vOrigin);
			
			if (!switchz)
			{
				hFile.SetNum("NoiseAmplitude", 0);
				hFile.SetNum("TextureScroll", 60);
				hFile.SetNum("damage", 5);
				hFile.SetNum("renderamt", 0);
				
				hFile.SetString("rendercolor", "25 25 255");
				hFile.SetFloat("width", 0.5);
				hFile.SetString("target", "NULL_TARGET");
			}
			else
				hFile.SetString("MyName", "NULL_NAME");
			
			hFile.Rewind();
			hFile.ExportToFile(szPath);
		}
	}
	
	delete hFile;
}

public bool TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients;
}

int CreateEntityAlt(const char[] classname, float vOrigin[3], bool bDispatch)
{
	int entity = CreateEntityByName(classname);
	
	if (!IsValidEntity(entity))
		return -1;
		
	DispatchKeyValueVector(entity, "origin", vOrigin);
	
	if (bDispatch)
		DispatchSpawn(entity);
		
	return entity;
}

void ConfigOriginChanger(int index, bool switchsys, float vOrigin[3])
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), CONFIG_SPAWNS);
	
	KeyValues hFile = OpenConfig(szPath);
	
	if (!hFile)
	{
		delete hFile;
		return;
	}
	
	if (!switchsys)
		hFile.JumpToKey("Laser Section");
	else
		hFile.JumpToKey("Targets Section");
		
	char szTemp[8];
	IntToString(index, szTemp, sizeof szTemp);

	if (!hFile.JumpToKey(szTemp))
	{
		delete hFile;
		return;
	}
	
	hFile.SetVector("vOrigin", vOrigin);
			
	hFile.Rewind();
	hFile.ExportToFile(szPath);
	
	delete hFile;
}

void DeleteFromConfig(bool switchz, int index)
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), CONFIG_SPAWNS);
	
	if (!FileExists(szPath))
		return;
	
	KeyValues hFile = new KeyValues("Data");
	
	if (!hFile.ImportFromFile(szPath))
		return;
	
	char sMap[64], sTemp[8];
	GetCurrentMap(sMap, sizeof sMap);
	
	if (hFile.JumpToKey(sMap))
	{
		if (!switchz)
			hFile.JumpToKey("Laser Section");
		else
			hFile.JumpToKey("Targets Section");
		
		IntToString(index, sTemp, sizeof sTemp);
		if (hFile.JumpToKey(sTemp))
		{
			hFile.DeleteKey("vOrigin");
			
			if (!switchz)
			{
				AcceptEntityInput(EntRefToEntIndex(g_iLasers[index]), "kill");
				hFile.DeleteKey("NoiseAmplitude");
				hFile.DeleteKey("TextureScroll");
				hFile.DeleteKey("damage");
				hFile.DeleteKey("renderamt");
				hFile.DeleteKey("rendercolor");
				hFile.DeleteKey("width");
				hFile.DeleteKey("target");
				
				g_iLasers[index] = INVALID_ENT_REFERENCE;
			}
			else
			{
				hFile.DeleteKey("MyName");
				AcceptEntityInput(EntRefToEntIndex(g_iTargets[index]), "kill");
				g_iTargets[index] = INVALID_ENT_REFERENCE;
			}
			
			hFile.GoBack();
			for (int i = index + 1; i < MAXENTITIES; i++)
			{
				if (i != 0)
				{
					if (!switchz)
					{
						g_iLasers[i - 1] = g_iLasers[i];
						g_iLasers[i] = 0;
					}
					else
					{
						g_iTargets[i - 1] = g_iTargets[i];
						g_iTargets[i] = 0;
					}
				}
				
				IntToString(i, sTemp, sizeof(sTemp));

				if (hFile.JumpToKey(sTemp))
				{
					IntToString(i - 1, sTemp, sizeof(sTemp));
					hFile.SetSectionName(sTemp);
					hFile.GoBack();
				}
			}
			
			hFile.Rewind();
			hFile.ExportToFile(szPath);
		}
	}

	delete hFile;
}


void TargetLaserMenu (int client, bool iState, bool iSwitch)
{
	g_hCounter = new Menu(VCounterHandler);
	
	char szTemp[56];
	int entity;
	
	if (!iState)
	{
		int iTargets, iLasers;
		
		for (int i; i < MAXENTITIES; i++)
		{
			if ((entity = EntRefToEntIndex(g_iTargets[i])) > MaxClients && IsValidEntity(entity))
				iTargets++;
				
			if ((entity = EntRefToEntIndex(g_iLasers[i])) > MaxClients && IsValidEntity(entity))
				iLasers++;
		}
		
		Format(szTemp, sizeof szTemp, "Targets (%i)", iTargets);
		g_hCounter.AddItem("TARGET", szTemp);
		
		Format(szTemp, sizeof szTemp, "Lasers (%i)", iLasers);
		g_hCounter.AddItem("LASER", szTemp);
		
		g_hCounter.SetTitle("Switch");
	}
	else
	{
		char szNameEx[36];
		if (iSwitch)
		{
			for (int i; i < MAXENTITIES; i++)
			{
				if ((entity = EntRefToEntIndex(g_iTargets[i])) > MaxClients && IsValidEntity(entity))
				{
					GetEntPropString(entity, Prop_Data, "m_iName", szNameEx, sizeof(szNameEx));
					Format(szTemp, sizeof szTemp, "%s (%i | %i)", szNameEx, entity, i);
					Format(szNameEx, sizeof szNameEx, "TARGET_DELETE_INDEX %i", i);
					g_hCounter.AddItem(szNameEx, szTemp);
				}
			}
		}
		else
		{
			for (int i; i < MAXENTITIES; i++)
			{
				if ((entity = EntRefToEntIndex(g_iLasers[i])) > MaxClients && IsValidEntity(entity))
				{
					Format(szTemp, sizeof szTemp, "Laser (%i | %i)", entity, i);
					Format(szNameEx, sizeof szNameEx, "LASER_DELETE_INDEX %i", i);
					g_hCounter.AddItem(szNameEx, szTemp);
				}
			}
		}
		g_hCounter.SetTitle("Selecting entity");
	}
	
	g_hCounter.ExitBackButton = true;
	g_hCounter.Display(client, MENU_TIME_FOREVER);
}