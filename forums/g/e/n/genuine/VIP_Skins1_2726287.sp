#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <vip_core>
#include <cstrike>

public Plugin:myinfo =
{
	name = "[VIP] Skins",
	author = "R1KO (skype: vova.andrienko1)",
	version = "1.0.5",
	url = "hlmod.ru"
};

#define DEBUG_MODE 0

#if DEBUG_MODE
new String:g_sDebugLogFile[PLATFORM_MAX_PATH];
#endif

#if DEBUG_MODE
stock DebugMsg(const String:sMsg[], any:...)
{
	decl String:sBuffer[250];
	VFormat(sBuffer, sizeof(sBuffer), sMsg, 2);
	LogToFile(g_sDebugLogFile, sBuffer);
}
#define DebugMessage(%0) DebugMsg(%0);
#else
#define DebugMessage(%0)
#endif

new bool:g_bIsCSGO;

#define VIP_SKINS			"Skins"
#define VIP_SKINS_MENU		"Skins_Menu"

new Handle:		g_hKeyValues					= INVALID_HANDLE,
	Handle:		g_hCookieSkin[2]	= {INVALID_HANDLE, ...},
	bool:		g_bClientPreview[MAXPLAYERS+1],
	String:		g_sSkinModel[MAXPLAYERS+1][PLATFORM_MAX_PATH],
	String:		g_sArmsModel[MAXPLAYERS+1][PLATFORM_MAX_PATH];

new m_szArmsModel = -1;

new const String:g_sTeamNames[][] =
{
	"ALL",
	"TEAM_T",
	"TEAM_CT"
};
	
public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(VIP_SKINS, STRING, _, OnToggleItem);
	VIP_RegisterFeature(VIP_SKINS_MENU, _, SELECTABLE, OnSelectItem, _, OnDrawItem);

	//VIP_HookClientSpawn(OnPlayerSpawn);
}

public OnPluginStart()
{
	#if DEBUG_MODE	
	BuildPath(Path_SM, g_sDebugLogFile, sizeof(g_sDebugLogFile), "logs/VIP_Skins_Debug.log");
	#endif

	g_bIsCSGO = bool:(GetEngineVersion() == Engine_CSGO);
	
	g_hCookieSkin[0] = RegClientCookie("VIP_Skin_T", "VIP_Skin_T", CookieAccess_Public);
	g_hCookieSkin[1] = RegClientCookie("VIP_Skin_CT", "VIP_Skin_CT", CookieAccess_Public);

	RegConsoleCmd("sm_skins", OnEnterCommand);

	HookEvent("player_team", Event_PlayerTeam);
	if(g_bIsCSGO)
	{
		m_szArmsModel = FindSendPropInfo("CCSPlayer", "m_szArmsModel");
		HookEvent("player_spawn", Event_PlayerSpawn);
	}

	LoadTranslations("vip_skins.phrases");
	LoadTranslations("vip_core.phrases");
	LoadTranslations("vip_modules.phrases");
}

public OnMapStart()
{
	if(g_hKeyValues != INVALID_HANDLE)
	{
		CloseHandle(g_hKeyValues);
	}

	g_hKeyValues = CreateKeyValues("Skins");
	
	decl String:sBuffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "data/vip/modules/skins.txt");

	if (!FileToKeyValues(g_hKeyValues, sBuffer)) SetFailState("Couldn't parse file %s", sBuffer);
	
	KvRewind(g_hKeyValues);
	if(KvGotoFirstSubKey(g_hKeyValues))
	{
		do
		{
			KvSetNum(g_hKeyValues, "loaded", 0);
			KvSetNum(g_hKeyValues, "arms_loaded", 0);
		//	KvGetSectionName(g_hKeyValues, sBuffer, sizeof(sBuffer));
			KvGetString(g_hKeyValues, "model", sBuffer, sizeof(sBuffer));
			DebugMessage("Read model: '%s'", sBuffer)
			if(sBuffer[0] && LoadSkin(sBuffer, true))
			{
				if(g_bIsCSGO)
				{
					KvGetString(g_hKeyValues, "arms_model", sBuffer, sizeof(sBuffer));
					DebugMessage("Read arms_model: '%s'", sBuffer)
					if(sBuffer[0] && LoadSkin(sBuffer, false))
					{
						KvSetNum(g_hKeyValues, "arms_loaded", 1);
					}
				}
				KvSetNum(g_hKeyValues, "loaded", 1);
			}
		} while (KvGotoNextKey(g_hKeyValues));
	}
}

bool:LoadSkin(const String:sModel[], bool:bNecessarily)
{
	DebugMessage("LoadSkin %b: '%s' -> Exists: %b", bNecessarily, sModel, FileExists(sModel))
	if(FileExists(sModel, true))
	{
		PrecacheModel(sModel, true);
		if(IsModelPrecached(sModel))
		{
			AddFileToDownloadsTable(sModel);
			return true;
		}
		else
		{
			LogError("Model '%s' doesn't pass precache", sModel);
		}
	}
	else if(bNecessarily)
	{
		LogError("File '%s' does not exist", sModel);
	}
	return false;
}

public OnClientPutInServer(iClient)
{
	g_sSkinModel[iClient][0] = '\0';
	if(g_bIsCSGO)
	{
		g_sArmsModel[iClient][0] = '\0';
	}
}

public OnClientDisconnect(iClient)
{
	g_sSkinModel[iClient][0] = '\0';
	if(g_bIsCSGO)
	{
		g_sArmsModel[iClient][0] = '\0';
	}
}

public bool:OnSelectItem(iClient, const String:sFeatureName[])
{
	if(GetClientTeam(iClient) <= 1)
	{
		VIP_PrintToChatClient(iClient, "%t", "JOIN_TEAM");
		return true;
	}
	DisplayMenu(CreateSkinsMenu(iClient), iClient, MENU_TIME_FOREVER);
	return false;
}

Action OnEnterCommand(int iClient, int iArgs)
{
	if(GetClientTeam(iClient) <= 1)
	{
		VIP_PrintToChatClient(iClient, "%t", "JOIN_TEAM");
		return true;
	}
	DisplayMenu(CreateSkinsMenu(iClient), iClient, MENU_TIME_FOREVER);
	return false;
}

public OnDrawItem(iClient, const String:sFeatureName[], iStyle)
{
	switch(VIP_GetClientFeatureStatus(iClient, VIP_SKINS))
	{
		case ENABLED: return ITEMDRAW_DEFAULT;
		case DISABLED: return ITEMDRAW_DISABLED;
		case NO_ACCESS: return ITEMDRAW_RAWLINE;
	}

	return iStyle;
}

Handle:CreateSkinsMenu(iClient)
{
	new Handle:hMenu = CreateMenu(SkinsMenu_Handler);
	SetMenuExitBackButton(hMenu, true);
	SetMenuTitle(hMenu, "%T\n \n", "SKINS", iClient);
	
	decl String:sClientSkins[128];
	FormatEx(sClientSkins, sizeof(sClientSkins), "%T\n \n", "DISABLE_SKIN", iClient);

	AddMenuItem(hMenu, "", sClientSkins);

	KvRewind(g_hKeyValues);
	if(KvGotoFirstSubKey(g_hKeyValues))
	{
		decl String:sBuffer[64], String:sName[64], bool:bAll, iSkinTeam, iTeam;
		VIP_GetClientFeatureString(iClient, VIP_SKINS, sClientSkins, sizeof(sClientSkins));
		bAll = StrEqual(sClientSkins, "all", false);
		iTeam = GetClientTeam(iClient);
		SetTrieValue(VIP_GetVIPClientTrie(iClient), "SkinTeam", iTeam);
		iTeam--;
		do
		{
			if(KvGetNum(g_hKeyValues, "loaded") == 0) continue;

			KvGetSectionName(g_hKeyValues, sBuffer, sizeof(sBuffer));

			KvGetString(g_hKeyValues, "team", sName, sizeof(sName));
			iSkinTeam = GetTeamFromString(sName);
			if(iSkinTeam == iTeam || iSkinTeam == 0)
			{
				KvGetString(g_hKeyValues, "name", sName, sizeof(sName), sBuffer);
				AddMenuItem(hMenu, sBuffer, sName, (bAll == false && StrContains(sClientSkins, sBuffer, false) == -1) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			}
		} while (KvGotoNextKey(g_hKeyValues));
	}
	
	KvRewind(g_hKeyValues);
	
	if(GetMenuItemCount(hMenu) < 2)
	{
		FormatEx(sClientSkins, sizeof(sClientSkins), "%T", "NO_SKINS_AVAILABLE", iClient);
		AddMenuItem(hMenu, "", sClientSkins, ITEMDRAW_DISABLED);
	}

	return hMenu;
}

GetTeamFromString(const String:sBuffer[])
{
	switch(sBuffer[0])
	{
		case 'C', 'c':	return 2;
		case 'T', 't':	return 1;
		case 'A', 'a':	return 0;
		case '\0':		return -1;
	}
	return -1;
}

public SkinsMenu_Handler(Handle:hMenu, MenuAction:action, iClient, Item)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) VIP_SendClientVIPMenu(iClient);
		}
		case MenuAction_Select:
		{
			new iTeam = GetClientTeam(iClient), iSkinTeam;
			GetTrieValue(VIP_GetVIPClientTrie(iClient), "SkinTeam", iSkinTeam);
			if(iSkinTeam != 0 && iTeam != iSkinTeam)
			{
				VIP_PrintToChatClient(iClient, "%t", "ERROR");
				VIP_SendClientVIPMenu(iClient);
				return;
			}

			if(iTeam <= 1)
			{
				VIP_PrintToChatClient(iClient, "%t", "JOIN_TEAM");
				VIP_SendClientVIPMenu(iClient);
				return;
			}

			if(Item == 0)
			{
				g_sSkinModel[iClient][0] = '\0';
				if(g_bIsCSGO)
				{
					g_sArmsModel[iClient][0] = '\0';
				}
				//SetClientDefSkin(iClient);
				CS_UpdateClientModel(iClient);
				VIP_SendClientVIPMenu(iClient);
				return;
			}
	
			decl String:sInfo[64];
			GetMenuItem(hMenu, Item, sInfo, sizeof(sInfo));

			DisplayMenu(CreateSkinInfoMenu(iClient, sInfo), iClient, MENU_TIME_FOREVER);
		}
	}
}

Handle:CreateSkinInfoMenu(iClient, const String:sKey[])
{
	new Handle:hMenu;
	KvRewind(g_hKeyValues);
	if(KvJumpToKey(g_hKeyValues, sKey, false))
	{
		hMenu = CreateMenu(SkinInfoMenu_Handler);
		SetMenuExitBackButton(hMenu, true);
		decl String:sName[64], iTeam;
		KvGetString(g_hKeyValues, "team", sName, sizeof(sName));
		iTeam = GetTeamFromString(sName);
		KvGetString(g_hKeyValues, "name", sName, sizeof(sName));
		SetMenuTitle(hMenu, "%T\n \n%T %s\n%T %T\n \n", "INFO", iClient, "NAME", iClient, sName, "TEAM", iClient, g_sTeamNames[iTeam], iClient);
		
		FormatEx(sName, sizeof(sName), "%T", g_bClientPreview[iClient] ? "DISABLE_PREVIEW":"ENABLE_PREVIEW", iClient);
		AddMenuItem(hMenu, sKey, sName, (GetClientTeam(iClient) > 1 && IsPlayerAlive(iClient)) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		
		FormatEx(sName, sizeof(sName), "%T", "SET", iClient);
		AddMenuItem(hMenu, sKey, sName);
		
		AddMenuItem(hMenu, "", "", ITEMDRAW_NOTEXT);
		AddMenuItem(hMenu, "", "", ITEMDRAW_NOTEXT);
		AddMenuItem(hMenu, "", "", ITEMDRAW_NOTEXT);
		AddMenuItem(hMenu, "", "", ITEMDRAW_NOTEXT);
	}

	return hMenu;
}

public SkinInfoMenu_Handler(Handle:hMenu, MenuAction:action, iClient, Item)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(hMenu);
		case MenuAction_Cancel:
		{
			ClientPreview(iClient, _, false);
			if(Item == MenuCancel_ExitBack) DisplayMenu(CreateSkinsMenu(iClient), iClient, MENU_TIME_FOREVER);
		}
		case MenuAction_Select:
		{
			new iTeam = GetClientTeam(iClient), iSkinTeam;
			GetTrieValue(VIP_GetVIPClientTrie(iClient), "SkinTeam", iSkinTeam);
			if(iSkinTeam != 0 && iTeam != iSkinTeam)
			{
				VIP_PrintToChatClient(iClient, "%t", "ERROR");
				VIP_SendClientVIPMenu(iClient);
				return;
			}

			if(iTeam <= 1)
			{
				VIP_PrintToChatClient(iClient, "%t", "JOIN_TEAM");
				VIP_SendClientVIPMenu(iClient);
				return;
			}
	
			decl String:sInfo[64];
			GetMenuItem(hMenu, Item, sInfo, sizeof(sInfo));
			KvRewind(g_hKeyValues);
			if(KvJumpToKey(g_hKeyValues, sInfo, false))
			{
				
				switch(Item)
				{
					case 0:
					{
						if(IsPlayerAlive(iClient))
						{
							if(g_bClientPreview[iClient])
							{
								ClientPreview(iClient, _, false);
							}
							else
							{
								decl String:sBuffer[PLATFORM_MAX_PATH];
								KvGetString(g_hKeyValues, "model", sBuffer, sizeof(sBuffer));
								ClientPreview(iClient, sBuffer, true);
							}
							DisplayMenu(CreateSkinInfoMenu(iClient, sInfo), iClient, MENU_TIME_FOREVER);
						}
						else
						{
							VIP_PrintToChatClient(iClient, "%t", "ERROR");
							VIP_SendClientVIPMenu(iClient);
						}
						
					}
					case 1:
					{
						ClientPreview(iClient, _, false);
						decl String:sName[64], String:sBuffer[64];
						KvGetString(g_hKeyValues, "name", sName, sizeof(sName));
						FormatEx(sBuffer, sizeof(sBuffer), "%T", g_sTeamNames[iTeam-1], iClient);
						VIP_PrintToChatClient(iClient, "%t", "YOU_SET_SKIN", sName, sBuffer);
						KvGetSectionName(g_hKeyValues, g_sSkinModel[iClient], sizeof(g_sSkinModel[]));
						SetClientCookie(iClient, g_hCookieSkin[iTeam-2], g_sSkinModel[iClient]);
						KvGetString(g_hKeyValues, "model", g_sSkinModel[iClient], sizeof(g_sSkinModel[]));
						if(g_bIsCSGO && KvGetNum(g_hKeyValues, "arms_loaded") == 1)
						{
							KvGetString(g_hKeyValues, "arms_model", g_sArmsModel[iClient], sizeof(g_sArmsModel[]));
						}

						if(IsPlayerAlive(iClient))
						{
							SetClientVIPSkin(iClient);
							SetClientVIPArms(iClient);
						}

						VIP_SendClientVIPMenu(iClient);
					}
				}
			}	

			
		}
	}
}

ClientPreview(iClient, const String:sModel[] = "", bool:bEnabled = true)
{
	g_bClientPreview[iClient] = bEnabled;
	//static String:sOriginalModel[MAXPLAYERS+1][PLATFORM_MAX_PATH];
	if(IsClientInGame(iClient))
	{
		if (g_bClientPreview[iClient])
		{
			//GetClientModel(iClient, sOriginalModel[iClient], sizeof(sOriginalModel[]));
			SetEntityModel(iClient, sModel);
			SetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget", 0);
			SetEntProp(iClient, Prop_Send, "m_iObserverMode", 1);
			SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", false);
			SetEntProp(iClient, Prop_Send, "m_iFOV", 120);
		} else
		{
			//PrecacheModel(sOriginalModel[iClient]);
			//SetEntityModel(iClient, sOriginalModel[iClient]);
			CS_UpdateClientModel(iClient);
			SetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget", -1);
			SetEntProp(iClient, Prop_Send, "m_iObserverMode", 0);
			SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", true);
			SetEntProp(iClient, Prop_Send, "m_iFOV", 90);
		}
	}
}

public Event_PlayerTeam(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(g_bClientPreview[iClient])
	{
		ClientPreview(iClient, _, false);
	}
	if(iClient && VIP_IsClientVIP(iClient) && VIP_GetClientFeatureStatus(iClient, VIP_SKINS) != NO_ACCESS)
	{
		new iTeam = GetEventInt(hEvent, "team");
		if (iTeam > 1 && iTeam != GetEventInt(hEvent, "oldteam"))
		{
			GetClientCookie(iClient, g_hCookieSkin[iTeam-2], g_sSkinModel[iClient], sizeof(g_sSkinModel[]));
			KvRewind(g_hKeyValues);
			if(KvJumpToKey(g_hKeyValues, g_sSkinModel[iClient], false))
			{
				if(KvGetNum(g_hKeyValues, "loaded") == 1)
				{
					decl String:sTeam[10], iSkinTeam;
					KvGetString(g_hKeyValues, "team", sTeam, sizeof(sTeam));
					iSkinTeam = GetTeamFromString(sTeam);
					if(iSkinTeam == 0 || iSkinTeam == iTeam-1)
					{
						KvGetString(g_hKeyValues, "model", g_sSkinModel[iClient], sizeof(g_sSkinModel[]));
						if(g_bIsCSGO && KvGetNum(g_hKeyValues, "arms_loaded") == 1)
						{
							KvGetString(g_hKeyValues, "arms_model", g_sArmsModel[iClient], sizeof(g_sArmsModel[]));
						}
						return;
					}
				}
			}

			g_sSkinModel[iClient][0] = '\0';
			if(g_bIsCSGO)
			{
				g_sArmsModel[iClient][0] = '\0';
			}
		}
	}
}

public VIP_OnPlayerSpawn(iClient, iTeam, bool:bIsVIP)
{
	if(g_bIsCSGO == false && bIsVIP && VIP_IsClientFeatureUse(iClient, VIP_SKINS)) SetClientVIPSkin(iClient);
}

public Event_PlayerSpawn(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, VIP_SKINS) && IsPlayerAlive(iClient))
	{
		SetClientVIPSkin(iClient);
		SetClientVIPArms(iClient);
	}
}

SetClientVIPSkin(iClient)
{
	if(g_sSkinModel[iClient][0] != '\0')
	{
		SetEntityModel(iClient, g_sSkinModel[iClient]);
	}
}

SetClientVIPArms(iClient)
{
	if(g_sArmsModel[iClient][0] != '\0')
	{
		SetEntDataString(iClient, m_szArmsModel, g_sArmsModel[iClient], sizeof(g_sArmsModel[]));
	}
}

public Action:OnToggleItem(iClient, const String:sFeatureName[], VIP_ToggleState:OldStatus, &VIP_ToggleState:NewStatus)
{
	if(NewStatus == ENABLED)
	{
		if(GetClientTeam(iClient) > 1 && IsPlayerAlive(iClient))
		{
			SetClientVIPSkin(iClient);
			SetClientVIPArms(iClient);
		}
	}
	else
	{
		if(IsPlayerAlive(iClient)) CS_UpdateClientModel(iClient);
		//SetClientDefSkin(iClient);
	}

	return Plugin_Continue;
}