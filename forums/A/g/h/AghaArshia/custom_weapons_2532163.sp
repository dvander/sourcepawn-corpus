#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <clientprefs>
#include <cw_stocks>

#define PLUGIN_VERSION 	"1.1.27"

#define GAME_UNDEFINED 0
#define GAME_CSS_34 1
#define GAME_CSS 2
#define GAME_CSGO 3

new Engine_Version = GAME_UNDEFINED;

new iDroppedModel[2049];

new Handle:hPlugin[MAXPLAYERS+1];
new Function:weapon_switch[MAXPLAYERS+1];
new Function:weapon_sequence[MAXPLAYERS+1];

new observer_mode;

enum
{
	Type_Primary,
	Type_C4,
	Type_Max
}

new Handle:g_hTrieSequence[MAXPLAYERS+1];

new bool:g_bMuzzleFlash[MAXPLAYERS+1],
	Float:g_fMuzzleScale[MAXPLAYERS+1],
Float:g_fMuzzlePos[MAXPLAYERS+1][3];

new m_hMyWeapons;

new bool:IsCategoryFilled[7];

new WeaponAddons[MAXPLAYERS+1][Type_Max];

new OldBits[MAXPLAYERS+1];
new OldWeapon[MAXPLAYERS+1];
new OldSequence[MAXPLAYERS+1];
new ClientVM[MAXPLAYERS+1];
new ClientVM2[MAXPLAYERS+1];

new Float:OldCycle[MAXPLAYERS+1];
new Float:NextSeq[MAXPLAYERS+1];
new Float:NextChange[MAXPLAYERS+1];

new bool:g_bMenuSpawn[MAXPLAYERS+1] = {true, ...}, Handle:g_hCookieMenuSpawn;
new bool:g_bEnabled[MAXPLAYERS+1] = {true, ...}, Handle:g_hCookieWeaponModels;

new bool:SpawnCheck[MAXPLAYERS+1];
new bool:IsCustom[MAXPLAYERS+1];

new String:g_sClLang[MAXPLAYERS+1][3];
new String:g_sServLang[3];

new String:g_sDroppedModel[32] = "world_model_index";
new iPrevIndex[MAXPLAYERS+1];



new Handle:hCvar_Enable, bool:bCvar_Enable;
new Handle:hCvar_SpawnMenu, bool:bCvar_SpawnMenu;
new Handle:hCvar_OldStyleModelChange, bool:bCvar_OldStyleModelChange;
new Handle:hCvar_ForceSpawnMenu, bool:bCvar_ForceSpawnMenu;
new Handle:hCvar_DefaultDisabled, bool:bCvar_DefaultDisabled;
new Handle:hCvar_ForceDisabled, bool:bCvar_ForceDisabled;
new Handle:hCvar_MenuCloseNotice, bool:bCvar_MenuCloseNotice;
new Handle:hCvar_AdminFlags, iCvar_AdminFlags;
new Handle:hCvar_WeaponsPath, String:sCvar_WeaponsPath[PLATFORM_MAX_PATH];
new Handle:hCvar_DownloadsPath, String:sCvar_DownloadsPath[PLATFORM_MAX_PATH];



new Handle:hKv;
new bool:g_bShouldLoadReload = true;
new Handle:hRegKv;
new Handle:hRegTrie;
new g_iTable = INVALID_STRING_TABLE;

new Handle:hTrie_Cookies;
new bool:g_bDev[MAXPLAYERS+1];
new iCycle[MAXPLAYERS+1], Float:next_cycle[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "[CS] Custom Weapons",
	author = "FrozDark",
	description = "Custom weapon models - server side",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	hRegTrie = CreateTrie();
	hRegKv = CreateKeyValues("Weapons");
	
	hKv = CreateKeyValues("Weapons");
	
	CreateNative("CW_RegisterWeapon", Native_RegisterWeapon);
	CreateNative("CW_IsWeaponRegistered", Native_IsWeaponRegistered);
	CreateNative("CW_UnregisterWeapon", Native_UnregisterWeapon);
	CreateNative("CW_UnregisterMe", Native_UnregisterMe);
	CreateNative("CW_IsCurrentlyCustom", Native_IsCurrentlyCustom);
	
	MarkNativeAsOptional("GuessSDKVersion"); 
	MarkNativeAsOptional("GetEngineVersion");
	
	MarkNativeAsOptional("GetUserMessageType");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbAddString");
	
	RegPluginLibrary("custom_weapons");
	
	return APLRes_Success;
}

GetCSGame()
{
	if (GetFeatureStatus(FeatureType_Native, "GetEngineVersion") == FeatureStatus_Available) 
	{ 
		switch (GetEngineVersion()) 
		{ 
			case Engine_SourceSDK2006: return GAME_CSS_34; 
			case Engine_CSS: return GAME_CSS; 
			case Engine_CSGO: return GAME_CSGO; 
		} 
	} 
	else if (GetFeatureStatus(FeatureType_Native, "GuessSDKVersion") == FeatureStatus_Available) 
	{ 
		switch (GuessSDKVersion())
		{ 
			case SOURCE_SDK_EPISODE1: return GAME_CSS_34;
			case SOURCE_SDK_CSS: return GAME_CSS;
			case SOURCE_SDK_CSGO: return GAME_CSGO;
		}
	}
	return GAME_UNDEFINED;
}

public OnPluginStart()
{
	Engine_Version = GetCSGame();
	if (Engine_Version == GAME_UNDEFINED)
	{
		SetFailState("Game is not supported!");
	}
	
	CreateConVar("sm_custom_weapons_version", PLUGIN_VERSION, "Custom weapons version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	hCvar_Enable = CreateConVar("sm_custom_weapons_enable", "1", "Whether to enable custom weapon models", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bCvar_Enable = GetConVarBool(hCvar_Enable);
	HookConVarChange(hCvar_Enable, OnConVarChange);
	
	hCvar_SpawnMenu = CreateConVar("sm_custom_weapons_menu_spawn", "0", "Whether to enable open weapons models menu on spawn", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bCvar_SpawnMenu = GetConVarBool(hCvar_SpawnMenu);
	HookConVarChange(hCvar_SpawnMenu, OnConVarChange);
	
	hCvar_ForceSpawnMenu = CreateConVar("sm_custom_weapons_force_menu_spawn", "0", "Forcibly open menu at every spawn", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bCvar_ForceSpawnMenu = GetConVarBool(hCvar_ForceSpawnMenu);
	HookConVarChange(hCvar_ForceSpawnMenu, OnConVarChange);
	
	hCvar_DefaultDisabled = CreateConVar("sm_custom_weapons_default_disabled", "1", "Disable model change by default to new players?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bCvar_DefaultDisabled = GetConVarBool(hCvar_DefaultDisabled);
	HookConVarChange(hCvar_DefaultDisabled, OnConVarChange);
	
	hCvar_ForceDisabled = CreateConVar("sm_custom_weapons_force_disabled", "0", "Force disabled model change for players. Enable only from menu", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bCvar_ForceDisabled = GetConVarBool(hCvar_ForceDisabled);
	HookConVarChange(hCvar_ForceDisabled, OnConVarChange);
	
	hCvar_MenuCloseNotice = CreateConVar("sm_custom_weapons_menu_close_notice", "1", "Notice a player in chat about the command to open menu again when it's close", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bCvar_MenuCloseNotice = GetConVarBool(hCvar_MenuCloseNotice);
	HookConVarChange(hCvar_MenuCloseNotice, OnConVarChange);
	
	hCvar_OldStyleModelChange = CreateConVar("sm_custom_weapons_css_old_style_model_change", "0", "CS:S OB Use old style model change method for flip view model support. Not recommended! May reduce server performance", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bCvar_OldStyleModelChange = GetConVarBool(hCvar_OldStyleModelChange);
	HookConVarChange(hCvar_OldStyleModelChange, OnConVarChange);
	
	decl String:buffer[PLATFORM_MAX_PATH];
	hCvar_AdminFlags = CreateConVar("sm_custom_weapons_admin_flags", "", "Set admin flags to make it available for admins only (Can be set serveral flags. Ex.: abc) or leave it empty to make it available for everyone", FCVAR_PLUGIN);
	GetConVarString(hCvar_AdminFlags, buffer, sizeof(buffer));
	iCvar_AdminFlags = ReadFlagString(buffer);
	HookConVarChange(hCvar_AdminFlags, OnConVarChange);
	
	hCvar_WeaponsPath = CreateConVar("sm_custom_weapons_models_path", "configs/custom_weapons.txt", "Path to custom weapon models config relative to the sourcemod folder", FCVAR_PLUGIN);
	GetConVarString(hCvar_WeaponsPath, buffer, sizeof(buffer));
	BuildPath(Path_SM, sCvar_WeaponsPath, sizeof(sCvar_WeaponsPath), buffer);
	HookConVarChange(hCvar_WeaponsPath, OnConVarChange);
	
	hCvar_DownloadsPath = CreateConVar("sm_custom_weapons_downloads_path", "configs/custom_weapons_downloads.txt", "Path to custom weapon models downloads list relative to the sourcemod folder", FCVAR_PLUGIN);
	GetConVarString(hCvar_DownloadsPath, buffer, sizeof(buffer));
	BuildPath(Path_SM, sCvar_DownloadsPath, sizeof(sCvar_DownloadsPath), buffer);
	HookConVarChange(hCvar_DownloadsPath, OnConVarChange);
	
	GetLanguageInfo(GetServerLanguage(), g_sServLang, sizeof(g_sServLang));
	
	if (Engine_Version == GAME_CSS_34)
	{
		HookEvent("player_team", OnPlayerDeath);
		HookEvent("player_death", OnPlayerDeath);
		observer_mode = 3;
	}
	else
	{
		if (Engine_Version == GAME_CSGO)
		{
			strcopy(g_sDroppedModel, sizeof(g_sDroppedModel), "drop_model_index");
		}
		
		observer_mode = 4;
	}
	
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("bomb_planted", OnBombPlanted);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	
	RegAdminCmd("cw_dev", Command_Dev, ADMFLAG_ROOT);
	
	g_iTable = FindStringTable("modelprecache");
	
	RegisterOffsets();
	
	hTrie_Cookies = CreateTrie();
	
	g_hCookieWeaponModels = RegClientCookie("custom_weapons_enable", "Whether to enable custom models", CookieAccess_Private);
	g_hCookieMenuSpawn = RegClientCookie("custom_weapons_menu_spawn", "Whether to enable menu open at every player spawn", CookieAccess_Private);
	SetCookieMenuItem(CustomWeaponsPrefSelected, 0, "Custom weapons");
	
	m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
	
	RegConsoleCmd("sm_weapon", Command_CookieWeapons, "Weapon models menu");
	RegConsoleCmd("sm_cw", Command_CookieWeapons, "Weapon models menu");
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client))
		{
			OnClientConnected(client);
			if (IsClientInGame(client))
			{
				OnClientPutInServer(client);
				if (AreClientCookiesCached(client))
				{
					OnClientCookiesCached(client);
				}
				
				if (IsClientAuthorized(client))
				{
					OnClientPostAdminCheck(client);
				}
				
				ClientVM[client] = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
				
				if (Engine_Version != GAME_CSGO)
				{
					new PVM = MaxClients+1;
					while ((PVM = FindEntityByClassname(PVM, "predicted_viewmodel")) != -1)
					{
						if (CSViewModel_GetOwner(PVM) == client)
						{
							if (CSViewModel_GetViewModelIndex(PVM) == 1)
							{
								ClientVM2[client] = PVM;
								break;
							}
						}
					}
				}
			}
		}
	}
	
	LoadTranslations("custom_weapons.phrases.txt");
	
	AutoExecConfig(true, "custom_weapons");
}

public OnPluginEnd()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		for (new i = 0; i < Type_Max; i++)
		{
			if (WeaponAddons[client][i] > 0 && IsValidEdict(WeaponAddons[client][i]))
			{
				AcceptEntityInput(WeaponAddons[client][i], "kill");
			}
		}
		if (IsCustom[client] && IsClientInGame(client))
		{
			if (Engine_Version == GAME_CSS_34 || (Engine_Version == GAME_CSS && bCvar_OldStyleModelChange))
			{
				CSViewModel_AddEffects(ClientVM2[client], EF_NODRAW);
				CSViewModel_RemoveEffects(ClientVM[client], EF_NODRAW);
				
				new weapon = CSPlayer_GetActiveWeapon(client);
				if (weapon != -1)
				{
					new seq = CSViewModel_GetSequence(ClientVM[client]);
					Function_OnWeaponSwitch(hPlugin[client], weapon_switch[client], client, weapon, ClientVM2[client], OldSequence[client], seq);
				}
			}
			else
			{
				CSViewModel_SetModelIndex(ClientVM[client], iPrevIndex[client]);
				
				new weapon = CSPlayer_GetActiveWeapon(client);
				if (weapon != -1)
				{
					new seq = CSViewModel_GetSequence(ClientVM[client]);
					Function_OnWeaponSwitch(hPlugin[client], weapon_switch[client], client, weapon, ClientVM[client], OldSequence[client], seq);
				}
			}
		}
	}
}

public CustomWeaponsPrefSelected(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption :
		{
			SetGlobalTransTarget(client);
			FormatEx(buffer, maxlen, "%t", "CookieMenu_CustomModels");
		}
		case CookieMenuAction_SelectOption :
		{
			if (!CanSetCustomModel(client))
			{
				CPrintToChat(client, "%T", "Chat_NoAccess", client);
				return;
			}
			if (!OpenMainMenu(client, MENU_TIME_FOREVER, 0, true))
			{
				ShowCookieMenu(client);
				CPrintToChat(client, "%T", "Chat_NoModelsData", client);
			}
		}
	}
}

/*public OnEntityDestroyed(entity)
{
	iDroppedModel[entity] = 0;
}*/

public Action:Command_CookieWeapons(client, args)
{
	if (!client)
	{
		return Plugin_Continue;
	}
	
	if (!CanSetCustomModel(client))
	{
		CPrintToChat(client, "%T", "Chat_NoAccess", client);
	}
	else
	{
		if (!g_bEnabled[client])
		{
			g_bEnabled[client] = true;
			SetClientCookie(client, g_hCookieWeaponModels, "1");
		}
		if (!OpenMainMenu(client))
		{
			CPrintToChat(client, "%T", "Chat_NoModelsData", client);
		}
	}
	
	return Plugin_Handled;
}

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == hCvar_Enable)
	{
		bCvar_Enable = bool:StringToInt(newValue);
		
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				new weapon = CSPlayer_GetActiveWeapon(client);
				if (weapon != -1)
				{
					OnWeaponChanged(client, weapon, CSViewModel_GetSequence(ClientVM[client]));
				}
				
				OldBits[client] = 0;
			}
		}
	}
	else if (convar == hCvar_SpawnMenu)
	{
		bCvar_SpawnMenu = bool:StringToInt(newValue);
	}
	else if (convar == hCvar_ForceSpawnMenu)
	{
		bCvar_ForceSpawnMenu = bool:StringToInt(newValue);
	}
	else if (convar == hCvar_DefaultDisabled)
	{
		bCvar_DefaultDisabled = bool:StringToInt(newValue);
	}
	else if (convar == hCvar_ForceDisabled)
	{
		bCvar_ForceDisabled = bool:StringToInt(newValue);
	}
	else if (convar == hCvar_MenuCloseNotice)
	{
		bCvar_MenuCloseNotice = bool:StringToInt(newValue);
	}
	else if (convar == hCvar_OldStyleModelChange)
	{
		bCvar_OldStyleModelChange = bool:StringToInt(newValue);
		if (Engine_Version == GAME_CSS)
		{
			for (new client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client))
				{
					if (bCvar_OldStyleModelChange)
					{
						if (IsCustom[client])
						{
							CSViewModel_RemoveEffects(ClientVM2[client], EF_NODRAW);
							CSViewModel_AddEffects(ClientVM[client], EF_NODRAW);
							
							OnWeaponChanged(client, CSPlayer_GetActiveWeapon(client), CSViewModel_GetSequence(ClientVM[client]));
						}
						SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
						SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost_Old);
					}
					else
					{
						if (IsCustom[client])
						{
							CSViewModel_AddEffects(ClientVM2[client], EF_NODRAW);
							CSViewModel_RemoveEffects(ClientVM[client], EF_NODRAW);
							
							OnWeaponChanged(client, CSPlayer_GetActiveWeapon(client), CSViewModel_GetSequence(ClientVM[client]));
						}
						SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost_Old);
						SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
					}
				}
			}
		}
	}
	else if (convar == hCvar_WeaponsPath)
	{
		BuildPath(Path_SM, sCvar_WeaponsPath, sizeof(sCvar_WeaponsPath), newValue);
		g_bShouldLoadReload = true;
	}
	else if (convar == hCvar_DownloadsPath)
	{
		BuildPath(Path_SM, sCvar_DownloadsPath, sizeof(sCvar_DownloadsPath), newValue);
	}
	else if (convar == hCvar_AdminFlags)
	{
		iCvar_AdminFlags = ReadFlagString(newValue);
	}
}

public OnMapStart()
{
	if (!g_bShouldLoadReload)
	{
		CacheModels(hKv);
		if (!ReadDownloadList(sCvar_DownloadsPath))
		{
			PrintToServer("%s not found", sCvar_DownloadsPath);
		}
	}
	
	CacheModels(hRegKv);
	
	if (!iCvar_AdminFlags)
	{
		RoundStartChangeModels(hKv);
		RoundStartChangeModels(hRegKv);
	}
}

public OnMapEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		g_bMenuSpawn[i] = bCvar_ForceSpawnMenu;
		NextChange[i] = 0.0;
	}
}

public OnConfigsExecuted()
{
	if (g_bShouldLoadReload)
	{
		ClearKV(hKv);
		if (!FileToKeyValues(hKv, sCvar_WeaponsPath))
		{
			SetFailState("Couldn't parse %s", sCvar_WeaponsPath);
		}
		
		g_bShouldLoadReload = false;
		
		CacheModels(hKv);
		
		if (!ReadDownloadList(sCvar_DownloadsPath))
		{
			PrintToServer("%s not found", sCvar_DownloadsPath);
		}
	}
}

CacheModels(Handle:kv)
{
	if (kv == hKv)
	{
		for (new i = 0; i < sizeof(IsCategoryFilled); i++)
		{
			IsCategoryFilled[i] = false;
		}
	}
	if (KvGotoFirstSubKey(kv))	// to classnames
	{
		decl String:clsName[32], String:name[64], String:buffer[PLATFORM_MAX_PATH];
		do
		{
			buffer[0] = '\0';
			
			if (kv == hRegKv)
			{
				KvGetString(kv, "view_model", buffer, sizeof(buffer));
				if (buffer[0] && IsModelFile(buffer))
				{
					KvSetNum(kv, "view_model_index", PrecacheModel(buffer));
				}
				else
				{
					KvSetNum(kv, "view_model_index", 0);
				}
				
				KvGetString(kv, "world_model", buffer, sizeof(buffer));
				if (buffer[0] && IsModelFile(buffer))
				{
					KvSetNum(kv, "world_model_index", PrecacheModel(buffer));
				}
				else
				{
					KvSetNum(kv, "world_model_index", 0);
				}
				if (Engine_Version == GAME_CSGO)
				{
					KvGetString(kv, "drop_model", buffer, sizeof(buffer));
					if (buffer[0] && IsModelFile(buffer))
					{
						KvSetNum(kv, "drop_model_index", PrecacheModel(buffer));
					}
					else
					{
						KvSetNum(kv, "drop_model_index", 0);
					}
				}
			}
			else
			{
				new category = KvGetNum(kv, "category");
				if (!(-1 < category < sizeof(IsCategoryFilled)))
				{
					category = 0;
				}
				
				IsCategoryFilled[category] = true;
				
				KvGetString(hKv, "flags", buffer, sizeof(buffer));
				if (buffer[0])
				{
					KvSetNum(hKv, "flag_bits", ReadFlagString(buffer));
				}
				
				KvGetSectionName(kv, clsName, sizeof(clsName));
				StringToLower(clsName, clsName, sizeof(clsName));
				KvSetSectionName(kv, clsName);
				
				if (KvGotoFirstSubKey(kv))	// to names
				{
					new Handle:hCookie = INVALID_HANDLE;
					if (!GetTrieValue(hTrie_Cookies, clsName, hCookie))
					{
						hCookie = INVALID_HANDLE;
						
						decl String:descr[128];
						strcopy(descr, sizeof(descr), "Custom model for weapon ");
						StrCat(descr, sizeof(descr), clsName);
						
						strcopy(buffer, sizeof(buffer), clsName);
						StrCat(buffer, sizeof(buffer), "_custom");
						
						if ((hCookie = RegClientCookie(buffer, descr, CookieAccess_Private)) != INVALID_HANDLE)
						{
							SetTrieValue(hTrie_Cookies, clsName, hCookie, true);
						}
						else
						{
							SetFailState("Couldn't register cookie for weapon %s (%s)", clsName, buffer);
						}
					}
					
					do
					{
						KvGetString(kv, g_sServLang, name, sizeof(name));
						if (!name[0])
						{
							KvGetSectionName(kv, name, sizeof(name));
							KvSetString(kv, g_sServLang, name);
						}
						
						KvGetString(hKv, "flags", buffer, sizeof(buffer));
						StringToLower(buffer, buffer, sizeof(buffer));
						KvSetNum(hKv, "flag_bits", ReadFlagString(buffer));
						
						KvGetString(kv, "view_model", buffer, sizeof(buffer));
						if (buffer[0] && IsModelFile(buffer))
						{
							KvSetNum(kv, "view_model_index", PrecacheModel(buffer));
						}
						else
						{
							KvSetNum(kv, "view_model_index", 0);
						}
						
						KvGetString(kv, "world_model", buffer, sizeof(buffer));
						if (buffer[0] && IsModelFile(buffer))
						{
							KvSetNum(kv, "world_model_index", PrecacheModel(buffer));
						}
						else
						{
							KvSetNum(kv, "world_model_index", 0);
						}
						if (Engine_Version == GAME_CSGO)
						{
							KvGetString(kv, "drop_model", buffer, sizeof(buffer));
							if (buffer[0] && IsModelFile(buffer))
							{
								KvSetNum(kv, "drop_model_index", PrecacheModel(buffer));
							}
							else
							{
								KvSetNum(kv, "drop_model_index", 0);
							}
						}
						KvGetString(kv, "planted_world_model", buffer, sizeof(buffer));
						if (buffer[0] && IsModelFile(buffer))
						{
							PrecacheModel(buffer);
						}
						else
						{
							KvSetString(kv, "planted_world_model", "");
						}
					} while (KvGotoNextKey(kv));
					
					KvRewind(kv);
					KvJumpToKey(kv, clsName);
				}
			}
		} while (KvGotoNextKey(kv));
	}
	
	KvRewind(kv);
}

public Action:Command_Dev(client, argc)
{
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	
	g_bDev[client] = !g_bDev[client];
	
	return Plugin_Handled;
}

public OnClientConnected(client)
{
	if (g_hTrieSequence[client] == INVALID_HANDLE)
	{
		g_hTrieSequence[client] = CreateTrie();
	}
}

public OnClientPutInServer(client)
{
	hPlugin[client] = INVALID_HANDLE;
	weapon_switch[client] = INVALID_FUNCTION;
	weapon_sequence[client] = INVALID_FUNCTION;
	
	if (IsFakeClient(client))
	{
		g_bEnabled[client] = true;
		g_bMenuSpawn[client] = false;
	}
	
	if (Engine_Version == GAME_CSS_34 || (Engine_Version == GAME_CSS && bCvar_OldStyleModelChange))
	{
		if (Engine_Version == GAME_CSS_34)
		{
			SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDropPost_Old);
		}
		SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost_Old);
	}
	else
	{
		SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	}
	
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public OnClientPostAdminCheck(client)
{
	GetLanguageInfo(GetClientLanguage(client), g_sClLang[client], sizeof(g_sClLang[]));
}

public OnClientCookiesCached(client)
{
	decl String:buffer[4];
	if (bCvar_ForceDisabled)
	{
		g_bEnabled[client] = false;
		SetClientCookie(client, g_hCookieWeaponModels, "0");
	}
	else
	{
		GetClientCookie(client, g_hCookieWeaponModels, buffer, sizeof(buffer));
		if (buffer[0])
		{
			g_bEnabled[client] = bool:StringToInt(buffer);
		}
		else
		{
			g_bEnabled[client] = !bCvar_DefaultDisabled;
			SetClientCookie(client, g_hCookieWeaponModels, g_bEnabled[client] ? "1" : "0");
		}
	}
	
	if (bCvar_ForceSpawnMenu)
	{
		g_bMenuSpawn[client] = true;
		SetClientCookie(client, g_hCookieMenuSpawn, "1");
	}
	else
	{
		GetClientCookie(client, g_hCookieMenuSpawn, buffer, sizeof(buffer));
		if (buffer[0])
		{
			g_bMenuSpawn[client] = bool:StringToInt(buffer);
		}
		else
		{
			g_bMenuSpawn[client] = bCvar_SpawnMenu;
			SetClientCookie(client, g_hCookieMenuSpawn, g_bMenuSpawn[client] ? "1" : "0");
		}
	}
}

bool:CanSetCustomModel(client)
{
	return bool:(!iCvar_AdminFlags || (!IsFakeClient(client) && bool:(GetUserFlagBits(client) & iCvar_AdminFlags)));
}

public OnClientDisconnect(client)
{
	if (Engine_Version == GAME_CSS_34 && IsClientInGame(client) && CanSetCustomModel(client) && g_bEnabled[client] && bCvar_Enable)
	{
		for (new i = 0, weaponIndex = -1; i < 188; i += 4)
		{
			weaponIndex = GetEntDataEnt2(client, m_hMyWeapons + i);
			if (weaponIndex < 1 || iDroppedModel[weaponIndex] < 1)
			{
				continue;
			}
			
			CreateTimer(0.0, Timer_SetDelayedWorldModel, EntIndexToEntRef(weaponIndex), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public OnClientDisconnect_Post(client)
{
	NextChange[client] = 0.0;
	g_bDev[client] = false;
	g_bEnabled[client] = false;
	
	hPlugin[client] = INVALID_HANDLE;
	weapon_switch[client] = INVALID_FUNCTION;
	weapon_sequence[client] = INVALID_FUNCTION;
	
	ClearTrie(g_hTrieSequence[client]);
	
	for (new i = 0; i < Type_Max; i++)
	{
		if (WeaponAddons[client][i] > 0 && IsValidEdict(WeaponAddons[client][i]))
		{
			AcceptEntityInput(WeaponAddons[client][i], "kill");
		}
		
		WeaponAddons[client][i] = 0;
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "predicted_viewmodel", false))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
	}
	else if (StrContains(classname, "_projectile", false) != -1)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnProjectileSpawned);
	}
	else if (StrContains(classname, "weapon_", false) == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnWeaponSpawn);
	}
}

public OnEntitySpawned(entity)
{
	new Owner = CSViewModel_GetOwner(entity);
	if (0 < Owner <= MaxClients)
	{
		if (Engine_Version == GAME_CSGO)
		{
			ClientVM[Owner] = entity;
		}
		else
		{
			switch (CSViewModel_GetViewModelIndex(entity))
			{
				case 0 :
				{
					ClientVM[Owner] = entity;
				}
				case 1 :
				{
					ClientVM2[Owner] = entity;
				}
			}
		}
	}
}

bool:GetCookieValue(client, const String:weapon[], &Handle:cookie, String:value[], size)
{
	value[0] = '\0';
	if (GetTrieValue(hTrie_Cookies, weapon, cookie))
	{
		GetClientCookie(client, cookie, value, size);
		return true;
	}
	return false;
}

public OnProjectileSpawned(entity)
{
	new client = CSGrenadeProjectile_GetOwner(entity);
	if (0 < client <= MaxClients)
	{
		if (IsClientInGame(client) && CanSetCustomModel(client) && g_bEnabled[client] && bCvar_Enable)
		{
			new weapon = CSPlayer_GetActiveWeapon(client);
			if (weapon != -1)
			{
				if (iDroppedModel[weapon] == 0)
				{
					return;
				}
				
				decl String:buffer[PLATFORM_MAX_PATH];
				buffer[0] = '\0';
				GetPrecachedModelOfIndex(iDroppedModel[weapon], buffer, sizeof(buffer));
				
				if (buffer[0])
				{
					SetEntityModel(entity, buffer);
				}
			}
		}
	}
}

public OnWeaponSpawn(weapon)
{
	decl String:szClsname[32];
	GetEdictClassname(weapon, szClsname, sizeof(szClsname));
	
	new start_index = 0;
	if (StrContains(szClsname, "weapon_", false) == 0)
	{
		start_index = 7;
	}
	
	if (KvJumpToKey(hKv, szClsname[start_index]))
	{
		if (!KvGetNum(hKv, "flag_bits", false))
		{
			new index = KvGetNum(hKv, g_sDroppedModel);
			if (KvGotoFirstSubKey(hKv))
			{
				do
				{
					new dummy = KvGetNum(hKv, g_sDroppedModel);
					if (!KvGetNum(hKv, "flag_bits", false) && dummy != 0)
					{
						index = dummy;
						break;
					}
				}
				while KvGotoNextKey(hKv);
			}
			if (index != 0)
			{
				iDroppedModel[weapon] = index;
				
				CreateTimer(0.0, Timer_SetDelayedWorldModel, EntIndexToEntRef(weapon), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		KvRewind(hKv);
	}
}

public OnBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client || !CanSetCustomModel(client) || !g_bEnabled[client] || !bCvar_Enable)
	{
		return;
	}
	
	new planted_c4 = FindEntityByClassname(MaxClients+1, "planted_c4");
	if (planted_c4 != -1)
	{
		new weapon = CSPlayer_GetActiveWeapon(client);
		if (weapon != -1)
		{
			decl String:buffer[PLATFORM_MAX_PATH];
			buffer[0] = '\0';
			
			if (KvJumpToKey(hRegKv, "c4"))
			{
				KvGetString(hRegKv, "planted_world_model", buffer, sizeof(buffer));
				
				KvRewind(hRegKv);
			}
			else if (CanSetCustomModel(client) && g_bEnabled[client] && bCvar_Enable && KvJumpToKey(hKv, "c4"))
			{
				decl Handle:hCookie, String:sValue[64];
				GetCookieValue(client, "c4", hCookie, sValue, sizeof(sValue));
				
				if (sValue[0] && KvJumpToKey(hKv, sValue))
				{
					KvGetString(hKv, "planted_world_model", buffer, sizeof(buffer));
				}
				KvRewind(hKv);
			}
			
			if (!buffer[0] && iDroppedModel[weapon] != 0)
			{
				GetPrecachedModelOfIndex(iDroppedModel[weapon], buffer, sizeof(buffer));
			}
			
			if (buffer[0])
			{
				SetEntityModel(planted_c4, buffer);
			}
		}
	}
}

public OnWeaponDropPost_Old(client, weaponIndex)
{
	if (weaponIndex > 0 && IsClientInGame(client) && CanSetCustomModel(client) && g_bEnabled[client] && bCvar_Enable && iDroppedModel[weaponIndex] > 0)
	{
		decl String:clsName[32];
		GetEdictClassname(weaponIndex, clsName, sizeof(clsName));
		
		StringToLower(clsName, clsName, sizeof(clsName));
		
		new start_index = 0;
		if (StrContains(clsName, "weapon_", false) == 0)
		{
			start_index = 7;
		}
		
		decl Handle:hCookie, String:sValue[64];
		if (GetCookieValue(client, clsName[start_index], hCookie, sValue, sizeof(sValue)) && sValue[0] != '0')
		{
			CreateTimer(0.0, Timer_SetDelayedWorldModel, EntIndexToEntRef(weaponIndex), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:CS_OnCSWeaponDrop(client, weaponIndex)
{
	if (IsClientInGame(client) && CanSetCustomModel(client) && g_bEnabled[client] && bCvar_Enable && iDroppedModel[weaponIndex] > 0)
	{
		CreateTimer(0.0, Timer_SetDelayedWorldModel, EntIndexToEntRef(weaponIndex), TIMER_FLAG_NO_MAPCHANGE);
	}
}


public Action:Timer_SetDelayedWorldModel(Handle:timer, any:ref)
{
	new weapon = EntRefToEntIndex(ref);
	if (weapon == INVALID_ENT_REFERENCE)
	{
		return;
	}
	
	if (iDroppedModel[weapon] > 0 && GetEntProp(weapon, Prop_Data, "m_iState") == 0)
	{
		if (Engine_Version != GAME_CSGO)
		{
			new silencer_offset = GetEntSendPropOffs(weapon, "m_bSilencerOn");
			if (silencer_offset != -1 && bool:GetEntData(weapon, silencer_offset))
			{
				SetEntData(weapon, silencer_offset, false, true, true);
				
				HookSingleEntityOutput(weapon, "OnPlayerPickup", OnPlayerPickup, true);
			}
			
			SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", iDroppedModel[weapon]);
		}
		
		else
		{
			decl String:buffer[PLATFORM_MAX_PATH];
			GetPrecachedModelOfIndex(iDroppedModel[weapon], buffer, sizeof(buffer));
			SetEntityModel(weapon, buffer);
		}
	}
}

public OnPlayerPickup(const String:output[], weapon, client, Float:delay)
{
	new offset = GetEntSendPropOffs(weapon, "m_weaponMode");
	if (offset != -1)
	{
		SetEntProp(weapon, Prop_Send, "m_bSilencerOn", GetEntData(weapon, offset));
	}
	else
	{
		SetEntProp(weapon, Prop_Send, "m_bSilencerOn", true);
	}
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		OldBits[client] = 0;
		for (new i = 0; i < Type_Max; i++)
		{
			WeaponAddons[client][i] = 0;
		}
	}
	
	if (!iCvar_AdminFlags)
	{
		RoundStartChangeModels(hKv);
		RoundStartChangeModels(hRegKv);
	}
}

RoundStartChangeModels(Handle:kv)
{
	if (KvGotoFirstSubKey(kv))
	{
		decl String:sWeapon[32];
		do
		{
			new nModel = KvGetNum(kv, g_sDroppedModel);
			
			if (kv == hKv)
			{
				if (KvGetNum(kv, "flag_bits", false) != 0)
				{
					continue;
				}
				
				new dummy;
				
				KvSavePosition(kv);
				if (KvGotoFirstSubKey(kv))
				{
					do
					{
						dummy = KvGetNum(kv, g_sDroppedModel);
						if (!KvGetNum(kv, "flag_bits", false) && dummy != 0)
						{
							nModel = dummy;
							break;
						}
					}
					while KvGotoNextKey(kv);
					
					KvGoBack(kv);
				}
			}
			
			if (nModel != 0)
			{
				KvGetSectionName(kv, sWeapon, sizeof(sWeapon));
				Format(sWeapon, sizeof(sWeapon), "weapon_%s", sWeapon);
				
				new weaponIndex = MaxClients+1;
				while ((weaponIndex = FindEntityByClassname(weaponIndex, sWeapon)) != -1)
				{
					iDroppedModel[weaponIndex] = nModel;
					
					CreateTimer(0.0, Timer_SetDelayedWorldModel, EntIndexToEntRef(weaponIndex), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		while (KvGotoNextKey(kv));
		
		KvRewind(kv);
	}
}

OnPrePostThinkPost(client)
{
	new bits = CSPlayer_GetAddonBits(client);
	
	new bits_to_remove;
	if (bits & CSAddon_PrimaryWeapon)
	{
		if (!(OldBits[client] & CSAddon_PrimaryWeapon))
		{
			if (WeaponAddons[client][Type_Primary] > 0 && IsValidEdict(WeaponAddons[client][Type_Primary]))
			{
				AcceptEntityInput(WeaponAddons[client][Type_Primary], "kill");
			}
			
			WeaponAddons[client][Type_Primary] = 0;
			
			new weapon = GetPlayerWeaponSlot(client, 0);
			
			if (weapon != -1)
			{
				CacheWeaponOn(client, weapon, Type_Primary, "primary");
			}
		}
	}
	else if (OldBits[client] & CSAddon_PrimaryWeapon)
	{
		if (WeaponAddons[client][Type_Primary] > 0 && IsValidEdict(WeaponAddons[client][Type_Primary]))
		{
			AcceptEntityInput(WeaponAddons[client][Type_Primary], "kill");
		}
		
		WeaponAddons[client][Type_Primary] = 0;
	}
	if (bits & CSAddon_C4)
	{
		if (!(OldBits[client] & CSAddon_C4))
		{
			if (WeaponAddons[client][Type_C4] > 0 && IsValidEdict(WeaponAddons[client][Type_C4]))
			{
				AcceptEntityInput(WeaponAddons[client][Type_C4], "kill");
			}
			
			WeaponAddons[client][Type_C4] = 0;
			
			new weapon = GetPlayerWeaponSlot(client, 4);
			
			if (weapon != -1)
			{
				CacheWeaponOn(client, weapon, Type_C4, "c4");
			}
		}
	}
	else if (OldBits[client] & CSAddon_C4)
	{
		if (WeaponAddons[client][Type_C4] > 0 && IsValidEdict(WeaponAddons[client][Type_C4]))
		{
			AcceptEntityInput(WeaponAddons[client][Type_C4], "kill");
		}
		
		WeaponAddons[client][Type_C4] = 0;
	}
	
	if (WeaponAddons[client][Type_Primary] != 0)
	{
		bits_to_remove |= CSAddon_PrimaryWeapon;
	}
	if (WeaponAddons[client][Type_C4] != 0)
	{
		bits_to_remove |= CSAddon_C4;
	}
	
	CSPlayer_SetAddonBits(client, bits &~ bits_to_remove);
	
	OldBits[client] = bits;
}

CacheWeaponOn(client, weapon, type, const String:attachment[])
{
	if (!CanSetCustomModel(client) || !g_bEnabled[client] || !bCvar_Enable || iDroppedModel[weapon] == 0)
	{
		return;
	}
	
	decl String:buffer[PLATFORM_MAX_PATH];
	buffer[0] = '\0';
	
	GetPrecachedModelOfIndex(iDroppedModel[weapon], buffer, sizeof(buffer));
	
	if (buffer[0])
	{
		WeaponAddons[client][type] = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(WeaponAddons[client][type], "model", buffer);
		DispatchKeyValue(WeaponAddons[client][type], "spawnflags", "256");
		DispatchKeyValue(WeaponAddons[client][type], "solid", "0");
		DispatchSpawn(WeaponAddons[client][type]);
		
		SetEntPropEnt(WeaponAddons[client][type], Prop_Send, "m_hOwnerEntity", client);
		
		SetVariantString("!activator");
		AcceptEntityInput(WeaponAddons[client][type], "SetParent", client, WeaponAddons[client][type]);
		
		SetVariantString(attachment);
		AcceptEntityInput(WeaponAddons[client][type], "SetParentAttachment", WeaponAddons[client][type]);
		
		SDKHook(WeaponAddons[client][type], SDKHook_SetTransmit, OnTransmit);
	}
}

public Action:OnTransmit(entity, client)
{
	for (new i = 0; i < Type_Max; i++)
	{
		if (WeaponAddons[client][i] == entity)
		{
			if (GetEntProp(client, Prop_Send, "m_iObserverMode"))
			{
				return Plugin_Continue;
			}
			return Plugin_Handled;
		}
	}
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (GetEntProp(client, Prop_Send, "m_iObserverMode") == observer_mode && owner == GetEntPropEnt(client, Prop_Send, "m_hObserverTarget"))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public OnPostThinkPost_Old(client)
{
	OnPrePostThinkPost(client);
	
	new Sequence;
	new Float:Cycle;
	new WeaponIndex = CSPlayer_GetActiveWeapon(client);
	if (IsValidEdict(ClientVM[client]))
	{
		Sequence = CSViewModel_GetSequence(ClientVM[client]);
		Cycle = CSViewModel_GetCycle(ClientVM[client]);
	}
	
	if (WeaponIndex < 1)
	{
		if (IsCustom[client])
		{
			CSViewModel_AddEffects(ClientVM2[client], EF_NODRAW);
			CSViewModel_RemoveEffects(ClientVM[client], EF_NODRAW);
			
			IsCustom[client] = false;
			
			OldSequence[client] = 0;
	
			iCycle[client] = 0;
			next_cycle[client] = 0.0;
			
			ClearTrie(g_hTrieSequence[client]);
			
			NextSeq[client] = 0.0;
			
			Function_OnWeaponSwitch(hPlugin[client], weapon_switch[client], client, WeaponIndex, ClientVM2[client], OldSequence[client], Sequence);
			
			hPlugin[client] = INVALID_HANDLE;
			weapon_switch[client] = INVALID_FUNCTION;
			weapon_sequence[client] = INVALID_FUNCTION;
		}
		
		OldWeapon[client] = WeaponIndex;
		
		return;
	}
	
	new Float:game_time = GetGameTime();
	
	if (WeaponIndex != OldWeapon[client] && !OnWeaponChanged(client, WeaponIndex, Sequence))
	{
		OldWeapon[client] = WeaponIndex;
		return;
	}
	else
	if (IsCustom[client])
	{
		if (g_bDev[client])
		{
			PrintHintText(client, "Sequence: %d\nCycle: %d", Sequence, iCycle[client]);
		}
		
		if (IsValidEdict(ClientVM2[client]))
		{
			if (IsValidEdict(ClientVM[client]))
			{
				CSViewModel_SetPlaybackRate(ClientVM2[client], CSViewModel_GetPlaybackRate(ClientVM[client]));
			}
			
			switch (Function_OnWeaponThink(hPlugin[client], weapon_sequence[client], client, WeaponIndex, ClientVM2[client], OldSequence[client], Sequence))
			{
				case Plugin_Continue :
				{
					static String:local_buffer[PLATFORM_MAX_PATH];
					IntToString(Sequence, local_buffer, sizeof(local_buffer));
					GetTrieValue(g_hTrieSequence[client], local_buffer, Sequence);	// Sequence mapper
					if (Cycle < OldCycle[client] && Sequence == OldSequence[client])
					{
						CSViewModel_SetSequence(ClientVM2[client], 0);
						NextSeq[client] = game_time + 0.02;
					}
					else if (NextSeq[client] < game_time)
					{
						CSViewModel_SetSequence(ClientVM2[client], Sequence);
					}
					
				}
				case Plugin_Changed :
				{
					CSViewModel_SetSequence(ClientVM2[client], Sequence);
				}
			}
		}
		
		if (next_cycle[client] < game_time)
		{
			iCycle[client]++;
			
			next_cycle[client] = game_time + 0.05;
		}
	}
	
	if (SpawnCheck[client])
	{
		SpawnCheck[client] = false;
		if (IsCustom[client])
		{
			CSViewModel_AddEffects(ClientVM[client], EF_NODRAW);
		}
	}
	
	OldWeapon[client] = WeaponIndex;
	OldSequence[client] = Sequence;
	OldCycle[client] = Cycle;
}

public OnPostThinkPost(client)
{
	OnPrePostThinkPost(client);
	
	if (!IsValidEdict(ClientVM[client]))
	{
		return;
	}
	
	static iOldCycle[MAXPLAYERS+1];
	static iPrevSeq[MAXPLAYERS+1];
	
	new Sequence;
	
	if (iPrevSeq[client] != 0)
	{
		Sequence = iPrevSeq[client];
	}
	else
	{
		Sequence = CSViewModel_GetSequence(ClientVM[client]);
	}
	
	new WeaponIndex = CSPlayer_GetActiveWeapon(client);
	
	if (WeaponIndex < 1)
	{
		if (IsCustom[client])
		{
			CSViewModel_SetModelIndex(ClientVM[client], iPrevIndex[client]);
			
			IsCustom[client] = false;
			
			OldSequence[client] = 0;
	
			iCycle[client] = 0;
			next_cycle[client] = 0.0;
			
			ClearTrie(g_hTrieSequence[client]);
			
			NextSeq[client] = 0.0;
			
			Function_OnWeaponSwitch(hPlugin[client], weapon_switch[client], client, WeaponIndex, ClientVM[client], OldSequence[client], Sequence);
			
			hPlugin[client] = INVALID_HANDLE;
			weapon_switch[client] = INVALID_FUNCTION;
			weapon_sequence[client] = INVALID_FUNCTION;
		}
		
		OldWeapon[client] = WeaponIndex;
		
		return;
	}
	
	new Float:game_time = GetGameTime();
	
	new Float:Cycle = CSViewModel_GetCycle(ClientVM[client]);
	
	if (Cycle < OldCycle[client])
	{
		iCycle[client] = 0;
		iOldCycle[client] = -1;
		next_cycle[client] = game_time + 0.05;
	}
	
	if (WeaponIndex != OldWeapon[client] && !OnWeaponChanged(client, WeaponIndex, Sequence, true))
	{
		OldWeapon[client] = WeaponIndex;
		return;
	}
	else
	if (IsCustom[client])
	{
		switch (Function_OnWeaponThink(hPlugin[client], weapon_sequence[client], client, WeaponIndex, ClientVM[client], OldSequence[client], Sequence))
		{
			case Plugin_Continue :
			{
				static String:local_buffer[PLATFORM_MAX_PATH];
				IntToString(Sequence, local_buffer, sizeof(local_buffer));
				if (OldSequence[client] != Sequence && GetTrieValue(g_hTrieSequence[client], local_buffer, Sequence))	// Sequence mapper
				{
					CSViewModel_SetSequence(ClientVM[client], Sequence);
					if (g_bDev[client])
					{
						PrintToChat(client, "\x04Sequence mapped (%s -> %d)", local_buffer, Sequence);
					}
				}
			}
			case Plugin_Changed :
			{
				CSViewModel_SetSequence(ClientVM[client], Sequence);
			}
		}
	}
	
	if (iPrevSeq[client] != 0 && NextSeq[client] < game_time)
	{
		//CSViewModel_RemoveEffects(ClientVM[client], EF_NODRAW);
		CSViewModel_SetSequence(ClientVM[client], iPrevSeq[client]);
		iPrevSeq[client] = 0;
	}
	
	if (g_bDev[client])
	{
		PrintHintText(client, "Sequence: %d\nCycle: %d", Sequence, iCycle[client]);
		if (GetClientButtons(client) & IN_USE)
		{
			PrintToChat(client, "\x03Sequence %d | Cycle %d", Sequence, iCycle[client]);
		}
	}
	
	if (Cycle < OldCycle[client])
	{
		//iCycle[client] = 0;
		//iOldCycle[client] = -1;
		//next_cycle[client] = game_time + 0.05;
	
		if (IsCustom[client] && Sequence == OldSequence[client])
		{
			//CSViewModel_AddEffects(ClientVM[client], EF_NODRAW);
			CSViewModel_SetSequence(ClientVM[client], 0);
			iPrevSeq[client] = Sequence;
			
			NextSeq[client] = game_time + 0.03;
		}
	}
	
	if (next_cycle[client] < game_time)
	{
		iCycle[client]++;
		
		next_cycle[client] = game_time + 0.05;
	}
	
	OldWeapon[client] = WeaponIndex;
	OldSequence[client] = Sequence;
	OldCycle[client] = Cycle;
}

public OnWeaponEquipPost(client, weapon)
{
	iDroppedModel[weapon] = 0;
	
	decl String:szClsname[64];
	GetEdictClassname(weapon, szClsname, sizeof(szClsname));
	
	StringToLower(szClsname, szClsname, sizeof(szClsname));
	
	new start_index = 0;
	if (StrContains(szClsname, "weapon_", false) == 0)
	{
		start_index = 7;
	}
	new index = 0, dropped_index = 0;
	if (KvJumpToKey(hRegKv, szClsname[start_index]))
	{
		index = KvGetNum(hRegKv, "world_model_index");
		KvRewind(hRegKv);
	}
	else if (CanSetCustomModel(client) && g_bEnabled[client] && bCvar_Enable && KvJumpToKey(hKv, szClsname[start_index]))
	{
		decl Handle:hCookie, String:sValue[64];
		GetCookieValue(client, szClsname[start_index], hCookie, sValue, sizeof(sValue));
		
		if (sValue[0] == '0')
		{
			KvRewind(hKv);
			return;
		}
		
		new iClFlags = GetUserFlagBits(client);
		
		new bits = KvGetNum(hKv, "flag_bits");
		if (!bits || iClFlags & bits)
		{
			if (sValue[0] && KvJumpToKey(hKv, sValue))
			{
				bits = KvGetNum(hKv, "flag_bits");
				if ((!bits || iClFlags & bits))
				{
					index = KvGetNum(hKv, "world_model_index");
					dropped_index = KvGetNum(hKv, "drop_model_index");
				}
				KvGoBack(hKv);
			}
			
			if (index == 0)
			{
				index = KvGetNum(hKv, "world_model_index");
				dropped_index = KvGetNum(hKv, "drop_model_index");
				
				if (KvGotoFirstSubKey(hKv))
				{
					new dummy_index;
					do
					{
						bits = KvGetNum(hKv, "flag_bits");
						if ((!bits || iClFlags & bits) && (dummy_index = KvGetNum(hKv, "world_model_index")) != 0)
						{
							index = dummy_index;
							dropped_index = KvGetNum(hKv, "drop_model_index");
							break;
						}
					}
					while (KvGotoNextKey(hKv));
				}
			}
		}
		
		KvRewind(hKv);
	}
	if (index != 0)
	{
		if (Engine_Version == GAME_CSGO)
		{
			new iWorldModel = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel"); 
			if (iWorldModel != -1)
			{
				SetEntProp(iWorldModel, Prop_Send, "m_nModelIndex", index);
			}
		}
		else
		{
			SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", index);
		}
	}
	
	if (Engine_Version == GAME_CSGO)
	{
		iDroppedModel[weapon] = dropped_index;
	}
	else
	{
		iDroppedModel[weapon] = index;
	}
}

bool:OnWeaponChanged(client, WeaponIndex, Sequence, bool:really_change = false)
{
	if (Engine_Version == GAME_CSS_34 || (Engine_Version == GAME_CSS && bCvar_OldStyleModelChange))
	{
		ClearTrie(g_hTrieSequence[client]);
		
		iCycle[client] = 0;
		next_cycle[client] = 0.0;
		
		decl String:ClassName[32];
		GetEdictClassname(WeaponIndex, ClassName, sizeof(ClassName));
		
		StringToLower(ClassName, ClassName, sizeof(ClassName));
		
		new start_index = 0;
		if (StrContains(ClassName, "weapon_", false) == 0)
		{
			start_index = 7;
		}
		
		new world_model;
		
		Function_OnWeaponSwitch(hPlugin[client], weapon_switch[client], client, WeaponIndex, ClientVM2[client], OldSequence[client], Sequence);
		
		hPlugin[client] = INVALID_HANDLE;
		weapon_switch[client] = INVALID_FUNCTION;
		weapon_sequence[client] = INVALID_FUNCTION;
		
		new bool:result = false;
		if (KvJumpToKey(hRegKv, ClassName[start_index]))
		{
			decl any:aInfo[3];
			GetTrieArray(hRegTrie, ClassName[start_index], aInfo, sizeof(aInfo));
			
			hPlugin[client] = aInfo[0];
			weapon_switch[client] = aInfo[1];
			weapon_sequence[client] = aInfo[2];
			
			new bool:custom_change = false;
			if (Function_OnWeaponSwitch(hPlugin[client], weapon_switch[client], client, WeaponIndex, ClientVM2[client], OldSequence[client], Sequence, false, custom_change) != Plugin_Continue)
			{
				KvRewind(hRegKv);
				
				hPlugin[client] = INVALID_HANDLE;
				weapon_switch[client] = INVALID_FUNCTION;
				weapon_sequence[client] = INVALID_FUNCTION;
			}
			else 
			{
				new index = KvGetNum(hRegKv, "view_model_index");
				
				if (IsValidEdict(ClientVM2[client]))
				{
					if (custom_change)
					{
						index = 0;
					}
					
					if (index != 0)
					{
						CSViewModel_SetModelIndex(ClientVM2[client], index);
						custom_change = true;
					}
					
					if (custom_change)
					{
						CSViewModel_AddEffects(ClientVM[client], EF_NODRAW);
						
						CSViewModel_RemoveEffects(ClientVM2[client], EF_NODRAW);
						
						CSViewModel_SetWeapon(ClientVM2[client], WeaponIndex);
						
						CSViewModel_SetSequence(ClientVM2[client], Sequence);
						CSViewModel_SetPlaybackRate(ClientVM2[client], CSViewModel_GetPlaybackRate(ClientVM[client]));
					}
				}
				
				IsCustom[client] = custom_change;
				result = custom_change;
				
				world_model = KvGetNum(hRegKv, "world_model_index");
			}
			
			KvRewind(hRegKv);
		}
		
		if (!result)
		{
			if (CanSetCustomModel(client) && g_bEnabled[client] && bCvar_Enable && KvJumpToKey(hKv, ClassName[start_index]))
			{
				decl Handle:hCookie, String:sValue[64];
				GetCookieValue(client, ClassName[start_index], hCookie, sValue, sizeof(sValue));
				
				new iClFlags = GetUserFlagBits(client);
				
				new bits = KvGetNum(hKv, "flag_bits");
				if (sValue[0] != '0' && (!bits || iClFlags & bits))
				{
					new index;
					
					decl Float:vTemp[3];
					KvGetVector(hKv, "muzzle_move", vTemp);
					g_fMuzzlePos[client] = vTemp;
					
					new bool:jumped = false;
					if (!sValue[0] || !(jumped = KvJumpToKey(hKv, sValue)) || ((bits = KvGetNum(hKv, "flag_bits")) > 0 && !(iClFlags & bits)))
					{
						if (jumped)
						{
							KvGoBack(hKv);
						}
						if (KvGotoFirstSubKey(hKv))
						{
							do
							{
								bits = KvGetNum(hKv, "flag_bits");
								if (!bits || iClFlags & bits)
								{
									index = KvGetNum(hKv, "view_model_index");
									world_model = KvGetNum(hKv, "world_model_index");
									
									g_bMuzzleFlash[client] = bool:KvGetNum(hKv, "muzzle_flash", false);
									g_fMuzzleScale[client] = KvGetFloat(hKv, "muzzle_scale", 2.0);
									
									KvGetVector(hKv, "muzzle_move", vTemp);
									g_fMuzzlePos[client] = vTemp;
									
									KvGetSectionName(hKv, sValue, sizeof(sValue));
									
									if (hCookie != INVALID_HANDLE)
									{
										SetClientCookie(client, hCookie, sValue);
									}
									
									break;
								}
							}
							while (KvGotoNextKey(hKv));
						}
					}
					else
					{
						index = KvGetNum(hKv, "view_model_index");
						world_model = KvGetNum(hKv, "world_model_index");
						
						g_bMuzzleFlash[client] = bool:KvGetNum(hKv, "muzzle_flash", false);
						g_fMuzzleScale[client] = KvGetFloat(hKv, "muzzle_scale", 2.0);
						
						KvGetVector(hKv, "muzzle_move", vTemp);
						g_fMuzzlePos[client] = vTemp;
					}
					
					if (index != 0)
					{
						if (KvJumpToKey(hKv, "Sequences"))
						{
							if (KvGotoFirstSubKey(hKv, false))
							{
								decl String:sSequence[4];
								do
								{
									if (KvGetSectionName(hKv, sSequence, sizeof(sSequence)) && sSequence[0])
									{
										SetTrieValue(g_hTrieSequence[client], sSequence, KvGetNum(hKv, NULL_STRING));
									}
								}
								while (KvGotoNextKey(hKv, false));
								KvGoBack(hKv);
							}
							KvGoBack(hKv);
						}
						new bool:b_flip_model = bool:KvGetNum(hKv, "flip_view_model", false);
						
						if (IsValidEdict(ClientVM2[client]))
						{
							CSViewModel_AddEffects(ClientVM[client], EF_NODRAW);
							
							CSViewModel_RemoveEffects(ClientVM2[client], EF_NODRAW);
							CSViewModel_SetModelIndex(ClientVM2[client], index);
							
							if (b_flip_model)
							{
								new weapon = GetPlayerWeaponSlot(client, 2);
								if (weapon != -1)
								{
									CSViewModel_SetWeapon(ClientVM2[client], weapon);
								}
							}
							else
							{
								CSViewModel_SetWeapon(ClientVM2[client], WeaponIndex);
							}
							
							CSViewModel_SetSequence(ClientVM2[client], Sequence);
							CSViewModel_SetPlaybackRate(ClientVM2[client], CSViewModel_GetPlaybackRate(ClientVM[client]));
							
							IsCustom[client] = true;
							
							result = true;
						}
					}
				}
				
				KvRewind(hKv);
			}
			if (!result && IsCustom[client])
			{
				CSViewModel_RemoveEffects(ClientVM[client], EF_NODRAW);
				if (IsValidEdict(ClientVM2[client]))
				{
					CSViewModel_AddEffects(ClientVM2[client], EF_NODRAW);
					CSViewModel_SetSequence(ClientVM2[client], 0);
				}
				
				IsCustom[client] = false;
				
				NextSeq[client] = 0.0;
			}
			
			if (world_model > 0)
			{
				SetEntProp(WeaponIndex, Prop_Send, "m_iWorldModelIndex", world_model);
			}
			iDroppedModel[WeaponIndex] = world_model;
		}
		
		return result;
	}
	
	ClearTrie(g_hTrieSequence[client]);
	
	iCycle[client] = 0;
	next_cycle[client] = 0.0;
	
	decl String:ClassName[32];
	GetEdictClassname(WeaponIndex, ClassName, sizeof(ClassName));
	
	StringToLower(ClassName, ClassName, sizeof(ClassName));
	
	new start_index = 0;
	if (StrContains(ClassName, "weapon_", false) == 0)
	{
		start_index = 7;
	}
	
	new world_model, dropped_model;
	
	Function_OnWeaponSwitch(hPlugin[client], weapon_switch[client], client, WeaponIndex, ClientVM[client], OldSequence[client], Sequence);
	
	hPlugin[client] = INVALID_HANDLE;
	weapon_switch[client] = INVALID_FUNCTION;
	weapon_sequence[client] = INVALID_FUNCTION;
	
	new bool:result = false;
	if (KvJumpToKey(hRegKv, ClassName[start_index]))
	{
		decl any:aInfo[3];
		GetTrieArray(hRegTrie, ClassName[start_index], aInfo, sizeof(aInfo));
		
		hPlugin[client] = aInfo[0];
		weapon_switch[client] = aInfo[1];
		weapon_sequence[client] = aInfo[2];
		
		new bool:custom_change = false;
		if (Function_OnWeaponSwitch(hPlugin[client], weapon_switch[client], client, WeaponIndex, ClientVM[client], OldSequence[client], Sequence, false, custom_change) != Plugin_Continue)
		{
			KvRewind(hRegKv);
			
			hPlugin[client] = INVALID_HANDLE;
			weapon_switch[client] = INVALID_FUNCTION;
			weapon_sequence[client] = INVALID_FUNCTION;
		}
		else 
		{
			new index = KvGetNum(hRegKv, "view_model_index");
			
			if (!IsCustom[client])
			{
				iPrevIndex[client] = CSViewModel_GetModelIndex(ClientVM[client]);
			}
			
			SetEntProp(WeaponIndex, Prop_Send, "m_nModelIndex", 0);
			
			if (!custom_change)
			{
				CSViewModel_SetModelIndex(ClientVM[client], index);
			}
			
			IsCustom[client] = custom_change;
			result = custom_change;
			
			world_model = KvGetNum(hRegKv, "world_model_index");
			dropped_model = KvGetNum(hRegKv, "drop_model_index");
		}
		
		KvRewind(hRegKv);
	}
	
	if (!result)
	{
		if (CanSetCustomModel(client) && g_bEnabled[client] && bCvar_Enable && KvJumpToKey(hKv, ClassName[start_index]))
		{
			decl Handle:hCookie, String:sValue[64];
			GetCookieValue(client, ClassName[start_index], hCookie, sValue, sizeof(sValue));
			
			new iClFlags = GetUserFlagBits(client);
			
			new bits = KvGetNum(hKv, "flag_bits");
			if (sValue[0] != '0' && (!bits || iClFlags & bits))
			{
				new index;
				
				decl Float:vTemp[3];
				KvGetVector(hKv, "muzzle_move", vTemp);
				g_fMuzzlePos[client] = vTemp;
				
				new bool:jumped = false;
				if (!sValue[0] || !(jumped = KvJumpToKey(hKv, sValue)) || ((bits = KvGetNum(hKv, "flag_bits")) > 0 && !(iClFlags & bits)))
				{
					if (jumped)
					{
						KvGoBack(hKv);
					}
					if (KvGotoFirstSubKey(hKv))
					{
						do
						{
							bits = KvGetNum(hKv, "flag_bits");
							if (!bits || iClFlags & bits)
							{
								index = KvGetNum(hKv, "view_model_index");
								world_model = KvGetNum(hKv, "world_model_index");
								dropped_model = KvGetNum(hKv, "drop_model_index");
								
								g_bMuzzleFlash[client] = bool:KvGetNum(hKv, "muzzle_flash", false);
								g_fMuzzleScale[client] = KvGetFloat(hKv, "muzzle_scale", 2.0);
								
								KvGetVector(hKv, "muzzle_move", vTemp);
								g_fMuzzlePos[client] = vTemp;
								
								KvGetSectionName(hKv, sValue, sizeof(sValue));
								
								if (hCookie != INVALID_HANDLE)
								{
									SetClientCookie(client, hCookie, sValue);
								}
								
								break;
							}
						}
						while (KvGotoNextKey(hKv));
					}
				}
				else
				{
					index = KvGetNum(hKv, "view_model_index");
					world_model = KvGetNum(hKv, "world_model_index");
					dropped_model = KvGetNum(hKv, "drop_model_index");
					
					g_bMuzzleFlash[client] = bool:KvGetNum(hKv, "muzzle_flash", false);
					g_fMuzzleScale[client] = KvGetFloat(hKv, "muzzle_scale", 2.0);
					
					KvGetVector(hKv, "muzzle_move", vTemp);
					g_fMuzzlePos[client] = vTemp;
				}
				
				if (index != 0)
				{
					if (KvJumpToKey(hKv, "Sequences"))
					{
						if (KvGotoFirstSubKey(hKv, false))
						{
							decl String:sSequence[4];
							do
							{
								if (KvGetSectionName(hKv, sSequence, sizeof(sSequence)) && sSequence[0])
								{
									SetTrieValue(g_hTrieSequence[client], sSequence, KvGetNum(hKv, NULL_STRING));
								}
							}
							while (KvGotoNextKey(hKv, false));
							KvGoBack(hKv);
						}
						KvGoBack(hKv);
					}
					new bool:b_flip_model = bool:KvGetNum(hKv, "flip_view_model", false);
					
					if (!IsCustom[client])
					{
						iPrevIndex[client] = CSViewModel_GetModelIndex(ClientVM[client]);
					}
					if (b_flip_model)
					{
						new weapon = GetPlayerWeaponSlot(client, 2);
						if (weapon != -1)
						{
							CSViewModel_SetWeapon(ClientVM[client], WeaponIndex);
						}
					}
					SetEntProp(WeaponIndex, Prop_Send, "m_nModelIndex", 0);
					CSViewModel_SetModelIndex(ClientVM[client], index);
					IsCustom[client] = true;
					
					result = true;
				}
			}
			
			KvRewind(hKv);
		}
	}
	if (!result && IsCustom[client])
	{
		if (!really_change)
		{
			CSViewModel_SetModelIndex(ClientVM[client], iPrevIndex[client]);
		}
		
		iPrevIndex[client] = 0;
		
		IsCustom[client] = false;
		
		NextSeq[client] = 0.0;
	}
	
	if (Engine_Version != GAME_CSGO)
	{
		iDroppedModel[WeaponIndex] = world_model;
		if (world_model > 0)
		{
			SetEntProp(WeaponIndex, Prop_Send, "m_iWorldModelIndex", world_model);
		}
	}
	else
	{
		iDroppedModel[WeaponIndex] = dropped_model;
		if (dropped_model > 0)
		{
			new iWorldModel = GetEntPropEnt(WeaponIndex, Prop_Send, "m_hWeaponWorldModel"); 
			if (iWorldModel != -1)
			{
				SetEntProp(iWorldModel, Prop_Send, "m_nModelIndex", dropped_model);
			}
		}
	}
	
	return result;
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client || !IsClientInGame(client) || IsPlayerAlive(client))
	{
		return;
	}
	
	OnClientDisconnect(client);
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
	{
		return;
	}
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && !IsClientObserver(client))
	{
		SpawnCheck[client] = true;
		if (CanSetCustomModel(client) && g_bMenuSpawn[client])
		{
			OpenMainMenu(client, 10);
		}
	}
}

bool:OpenMainMenu(client, time = MENU_TIME_FOREVER, pos = 0, bool:from_settings = false)
{
	SetGlobalTransTarget(client);
	
	new Handle:menu = CreateMenu(MainMenu_Handler);
	SetMenuTitle(menu, "%t\n ", "Menu_Main");
	SetMenuExitButton(menu, true);
	
	SetMenuExitBackButton(menu, from_settings);
	
	decl String:buffer[128];
	if (IsCategoryFilled[0])
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Menu_Rifles");
		AddMenuItem(menu, "0", buffer);
	}
	if (IsCategoryFilled[1])
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Menu_SMG");
		AddMenuItem(menu, "1", buffer);
	}
	if (IsCategoryFilled[6])
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Menu_Snipers");
		AddMenuItem(menu, "6", buffer);
	}
	if (IsCategoryFilled[2])
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Menu_Shotguns");
		AddMenuItem(menu, "2", buffer);
	}
	if (IsCategoryFilled[3])
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Menu_Pistols");
		AddMenuItem(menu, "3", buffer);
	}
	if (IsCategoryFilled[4])
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Menu_Melee");
		AddMenuItem(menu, "4", buffer);
	}
	if (IsCategoryFilled[5])
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Menu_Bomb");
		AddMenuItem(menu, "5", buffer);
	}
	
	if (!GetMenuItemCount(menu))
	{
		CloseHandle(menu);
		return false;
	}
	
	FormatEx(buffer, sizeof(buffer), "%t: %t", "Menu_ModelChange", g_bEnabled[client] ? "Enabled" : "Disabled");
	AddMenuItem(menu, "7", buffer);
	
	FormatEx(buffer, sizeof(buffer), "%t: %t", "Menu_OpenMenuSpawn", g_bMenuSpawn[client] ? "Enabled" : "Disabled");
	AddMenuItem(menu, "8", buffer);
	
	DisplayMenuAtItem(menu, client, pos, time);
	
	return true;
}

public MainMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End :
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel :
		{
			switch (param2)
			{
				case MenuCancel_Exit, MenuCancel_Timeout :
				{
					if (bCvar_MenuCloseNotice)
					{
						CPrintToChat(param1, "%T", "Chat_TypeCommand", param1);
					}
				}
				case MenuCancel_ExitBack :
				{
					ShowCookieMenu(param1);
				}
			}
		}
		case MenuAction_Select :
		{
			if (!CanSetCustomModel(param1))
			{
				CPrintToChat(param1, "%T", "Chat_NoAccess", param1);
				return;
			}
			
			decl String:sInfo[3], String:title[128];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo), _, title, sizeof(title));
			
			new item = StringToInt(sInfo);
			
			switch (item)
			{
				case 7 :
				{
					new Float:game_time = GetGameTime();
					
					if (NextChange[param1] < game_time)
					{
						g_bEnabled[param1] = !g_bEnabled[param1];
						SetClientCookie(param1, g_hCookieWeaponModels, g_bEnabled[param1] ? "1" : "0");
						new weapon = CSPlayer_GetActiveWeapon(param1);
						if (weapon != -1)
						{
							NextChange[param1] = game_time + 5.0;
							
							OnWeaponChanged(param1, weapon, CSViewModel_GetSequence(ClientVM[param1]));
							OldBits[param1] = 0;
						}
					}
					else
					{
						CPrintToChat(param1, "%T", "Chat_Delay", param1, RoundToCeil(NextChange[param1]-game_time));
					}
					OpenMainMenu(param1, MENU_TIME_FOREVER, GetMenuSelectionPosition());
				}
				case 8 : 
				{
					g_bMenuSpawn[param1] = !g_bMenuSpawn[param1];
					SetClientCookie(param1, g_hCookieMenuSpawn, g_bMenuSpawn[param1] ? "1" : "0");
					OpenMainMenu(param1, MENU_TIME_FOREVER, GetMenuSelectionPosition());
				}
				default :
				{
					if (!Menu_ShowCategory(param1, item, title))
					{
						OpenMainMenu(param1, MENU_TIME_FOREVER, GetMenuSelectionPosition());
						CPrintToChat(param1, "%T", "Chat_CategoryEmpty", param1);
					}
				}
			}
		}
	}
}

new iCategory[MAXPLAYERS+1], String:sCategoryTitle[MAXPLAYERS+1][128];

bool:Menu_ShowCategory(client, category, const String:title[])
{
	new Handle:menu = CreateMenu(CategoryMenu_Handler);
	SetMenuTitle(menu, "%s\n ", title);
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	
	iCategory[client] = category;
	strcopy(sCategoryTitle[client], sizeof(sCategoryTitle[]), title);
	
	KvRewind(hKv);
	if (KvGotoFirstSubKey(hKv))
	{
		new iClFlags = GetUserFlagBits(client);
		decl String:section[64], String:buffer[128];
		do
		{
			if (KvGetNum(hKv, "category", 0) != category)
			{
				continue;
			}
			
			KvGetSectionName(hKv, section, sizeof(section));
			StringToLower(section, section, sizeof(section));
			KvGetString(hKv, g_sClLang[client], buffer, sizeof(buffer));
			if (!buffer[0])
			{
				KvGetString(hKv, g_sServLang, buffer, sizeof(buffer));
				if (!buffer[0])
				{
					strcopy(buffer, sizeof(buffer), section);
				}
			}
			
			new bits = KvGetNum(hKv, "flag_bits");
			
			new bool:has_access = bool:(!bits || iClFlags & bits);
			
			if (!has_access)
			{
				SetGlobalTransTarget(client);
				Format(buffer, sizeof(buffer), "%s (%t)", buffer, "Menu_NoAccess");
			}
			
			AddMenuItem(menu, section, buffer, has_access ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
		while (KvGotoNextKey(hKv));
		
		KvRewind(hKv);
	}
	
	if (!GetMenuItemCount(menu))
	{
		CloseHandle(menu);
		return false;
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return true;
}

public CategoryMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End :
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				OpenMainMenu(param1);
			}
		}
		case MenuAction_Select :
		{
			if (!CanSetCustomModel(param1))
			{
				CPrintToChat(param1, "%T", "Chat_NoAccess", param1);
				return;
			}
			
			decl String:sInfo[64], String:title[128];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo), _, title, sizeof(title));
			
			if (!Menu_ShowWeapon(param1, sInfo, title))
			{
				OpenMainMenu(param1);
				CPrintToChat(param1, "%T", "Chat_WeaponEmpty", param1);
			}
		}
	}
}

new String:szWeapon[MAXPLAYERS+1][32];
new String:sTitle[MAXPLAYERS+1][128];
bool:Menu_ShowWeapon(client, const String:weapon[], const String:title[])
{
	new Handle:menu = CreateMenu(WeaponMenu_Handler);
	
	SetMenuTitle(menu, "%s\n ", title);
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	
	if (!KvJumpToKey(hKv, weapon))
	{
		return false;
	}
	
	strcopy(szWeapon[client], sizeof(szWeapon[]), weapon);
	strcopy(sTitle[client], sizeof(sTitle[]), title);
	
	decl String:sUserValue[64], Handle:hCookie;
	GetCookieValue(client, weapon, hCookie, sUserValue, sizeof(sUserValue));
	
	SetGlobalTransTarget(client);
	
	decl String:buffer[128];
	FormatEx(buffer, sizeof(buffer), "%t", "Menu_WeaponDefault");
	if (sUserValue[0] == '0')
	{
		StrCat(buffer, sizeof(buffer), " [+]");
		AddMenuItem(menu, "0", buffer, ITEMDRAW_DISABLED);
	}
	else
	{
		AddMenuItem(menu, "0", buffer);
	}
	
	if (KvGotoFirstSubKey(hKv))
	{
		new iClFlags = GetUserFlagBits(client);
		
		decl String:section[64];
		do
		{
			KvGetSectionName(hKv, section, sizeof(section));
			KvGetString(hKv, g_sClLang[client], buffer, sizeof(buffer));
			if (!buffer[0])
			{
				strcopy(buffer, sizeof(buffer), section);
			}
			
			new bits = KvGetNum(hKv, "flag_bits");
			
			new bool:has_access = bool:(!bits || iClFlags & bits);
			
			if (!has_access)
			{
				Format(buffer, sizeof(buffer), "%s (%t)", buffer, "Menu_NoAccess");
			}
			else if (StrEqual(section, sUserValue))
			{
				StrCat(buffer, sizeof(buffer), " [+]");
				AddMenuItem(menu, section, buffer, ITEMDRAW_DISABLED);
				
				continue;
			}
			
			AddMenuItem(menu, section, buffer, has_access ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
		while (KvGotoNextKey(hKv));
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%t", "Menu_Custom");
		
		if (!sUserValue[0])
		{
			StrCat(buffer, sizeof(buffer), " [+]");
			AddMenuItem(menu, "", buffer, ITEMDRAW_DISABLED);
		}
		else
		{
			AddMenuItem(menu, "", buffer);
		}
	}
	
	KvRewind(hKv);
	
	if (GetMenuItemCount(menu) == 1)
	{
		CloseHandle(menu);
		return false;
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return true;
}

public WeaponMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End :
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Menu_ShowCategory(param1, iCategory[param1], sCategoryTitle[param1]);
			}
		}
		case MenuAction_Select :
		{
			if (!CanSetCustomModel(param1))
			{
				CPrintToChat(param1, "%T", "Chat_NoAccess", param1);
				return;
			}
			
			decl String:sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			
			decl Handle:hCookie;
			if (GetTrieValue(hTrie_Cookies, szWeapon[param1], hCookie))
			{
				SetClientCookie(param1, hCookie, sInfo);
			}
			else
			{
				LogError("Cookie is not registered for %s", szWeapon[param1]);
				PrintToChat(param1, "Cookie is not registered for %s", szWeapon[param1]);
			}
			
			new weapon = CSPlayer_GetActiveWeapon(param1);
			if (CheckWeapon(param1, weapon))
			{
				OnWeaponChanged(param1, weapon, CSViewModel_GetSequence(ClientVM[param1]));
			}
			else
			{
				for (new i = 0; i < Type_Max; i++)
				{
					if (WeaponAddons[param1][i] > 0)
					{
						switch (i)
						{
							case Type_Primary :
							{
								weapon = GetPlayerWeaponSlot(param1, 0);
							}
							case Type_C4 :
							{
								weapon = GetPlayerWeaponSlot(param1, 4);
							}
						}
						
						if (CheckWeapon(param1, weapon))
						{
							OnWeaponEquipPost(param1, weapon);
							OldBits[param1] = 0;
						}
					}
				}
			}
			
			Menu_ShowWeapon(param1, szWeapon[param1], sTitle[param1]);
		}
	}
}

bool:CheckWeapon(client, weapon)
{
	decl String:buffer[32];
	if (weapon != -1 && GetEdictClassname(weapon, buffer, sizeof(buffer)))
	{
		new start_index = 0;
		if (StrContains(buffer, "weapon_", false) == 0)
		{
			start_index = 7;
		}
		if (StrEqual(buffer[start_index], szWeapon[client]))
		{
			return true;
		}
	}
	return false;
}

Action:Function_OnWeaponSwitch(Handle:plugin, Function:func_weapon_switch, client, weapon, predicted_viewmodel, old_sequence, &new_sequence, bool:switch_from = true, &bool:custom_change = false)
{
	new Action:result = Plugin_Continue;
	
	if (func_weapon_switch != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, func_weapon_switch);
		Call_PushCell(client);
		Call_PushCell(weapon);
		Call_PushCell(predicted_viewmodel);
		Call_PushCell(old_sequence);
		Call_PushCellRef(new_sequence);
		Call_PushCell(switch_from);
		Call_PushCellRef(custom_change);
		Call_Finish(result);
	}
	
	return result;
}

Action:Function_OnWeaponThink(Handle:plugin, Function:func_weapon_think, client, weapon, predicted_viewmodel, old_sequence, &new_sequence)
{
	new Action:result = Plugin_Continue;
	
	if (func_weapon_think != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, func_weapon_think);
		Call_PushCell(client);
		Call_PushCell(weapon);
		Call_PushCell(predicted_viewmodel);
		Call_PushCell(old_sequence);
		Call_PushCellRef(new_sequence);
		Call_Finish(result);
	}
	
	return result;
}

public Native_RegisterWeapon(Handle:plugin, numParams)
{
	decl String:sWeapon[32];
	GetNativeString(1, sWeapon, sizeof(sWeapon));
	
	if (KvJumpToKey(hRegKv, sWeapon))
	{
		KvRewind(hKv);
		ThrowNativeError(SP_ERROR_NATIVE, "Weapon '%s' is already registered!", sWeapon);
	}
	
	decl String:buffer[PLATFORM_MAX_PATH];
	GetNativeString(2, buffer, sizeof(buffer));
	
	KvJumpToKey(hRegKv, sWeapon, true);
	
	if (buffer[0])
	{
		if (!IsModelFile(buffer))
		{
			KvDeleteThis(hRegKv);
			KvRewind(hRegKv);
			
			ThrowNativeError(SP_ERROR_NATIVE, "Invalid view model %s");
		}
		KvSetString(hRegKv, "view_model", buffer);
		KvSetNum(hRegKv, "view_model_index", PrecacheModel(buffer));
	}
	
	GetNativeString(3, buffer, sizeof(buffer));
	if (buffer[0])
	{
		if (!IsModelFile(buffer))
		{
			KvDeleteThis(hRegKv);
			KvRewind(hRegKv);
			
			ThrowNativeError(SP_ERROR_NATIVE, "Invalid world model %s");
		}
		KvSetString(hRegKv, "world_model", buffer);
		KvSetNum(hRegKv, "world_model_index", PrecacheModel(buffer));
	}
	
	GetNativeString(4, buffer, sizeof(buffer));
	if (buffer[0])
	{
		if (!IsModelFile(buffer))
		{
			KvDeleteThis(hRegKv);
			KvRewind(hRegKv);
			
			ThrowNativeError(SP_ERROR_NATIVE, "Invalid world model %s");
		}
		KvSetString(hRegKv, "drop_model", buffer);
		KvSetNum(hRegKv, "drop_model_index", PrecacheModel(buffer));
	}
	
	KvRewind(hRegKv);
	
	decl any:aInfo[3];
	aInfo[0] = plugin;
	aInfo[1] = GetNativeCell(5);
	aInfo[2] = GetNativeCell(6);
	
	SetTrieArray(hRegTrie, sWeapon, aInfo, sizeof(aInfo));
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			new weapon = CSPlayer_GetActiveWeapon(client);
			if (weapon == -1)
			{
				continue;
			}
			if (Native_CheckWeapon(weapon, sWeapon))
			{
				OnWeaponChanged(client, weapon, CSViewModel_GetSequence(ClientVM[client]));
			}
			else
			{
				for (new i = 0; i < Type_Max; i++)
				{
					if (WeaponAddons[client][i] > 0)
					{
						switch (i)
						{
							case Type_Primary :
							{
								weapon = GetPlayerWeaponSlot(client, 0);
							}
							case Type_C4 :
							{
								weapon = GetPlayerWeaponSlot(client, 4);
							}
						}
						
						if (Native_CheckWeapon(weapon, sWeapon))
						{
							OnWeaponEquipPost(client, weapon);
							OldBits[client] = 0;
						}
					}
				}
			}
		}
	}
	
	return true;
}

public Native_IsCurrentlyCustom(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return bool:(0 < client <= MaxClients && IsCustom[client]);
}

public Native_IsWeaponRegistered(Handle:plugin, numParams)
{
	decl String:sWeapon[32];
	GetNativeString(1, sWeapon, sizeof(sWeapon));
	
	new bool:result = false;
	
	if (KvJumpToKey(hRegKv, sWeapon))
	{
		KvRewind(hRegKv);
		result = true;
	}
	
	return result;
}

public Native_UnregisterWeapon(Handle:plugin, numParams)
{
	decl String:sWeapon[32];
	GetNativeString(1, sWeapon, sizeof(sWeapon));
	
	if (!KvJumpToKey(hRegKv, sWeapon))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Weapon '%s' is not registered!", sWeapon);
	}
	
	decl any:aInfo[3];
	GetTrieArray(hRegTrie, sWeapon, aInfo, sizeof(aInfo));
	
	if (aInfo[0] != plugin)
	{
		KvRewind(hRegKv);
		ThrowNativeError(SP_ERROR_NATIVE, "Weapon '%s' is not registered by this plugin!", sWeapon);
	}
	
	KvDeleteThis(hRegKv);
	KvRewind(hRegKv);
	
	RemoveFromTrie(hRegTrie, sWeapon);
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			new weapon = CSPlayer_GetActiveWeapon(client);
			if (weapon == -1)
			{
				continue;
			}
			if (Native_CheckWeapon(weapon, sWeapon))
			{
				OnWeaponChanged(client, weapon, CSViewModel_GetSequence(ClientVM[client]));
			}
			else
			{
				for (new i = 0; i < Type_Max; i++)
				{
					if (WeaponAddons[client][i] > 0)
					{
						switch (i)
						{
							case Type_Primary :
							{
								weapon = GetPlayerWeaponSlot(client, 0);
							}
							case Type_C4 :
							{
								weapon = GetPlayerWeaponSlot(client, 4);
							}
						}
						
						if (Native_CheckWeapon(weapon, sWeapon))
						{
							OnWeaponEquipPost(client, weapon);
							OldBits[client] = 0;
						}
					}
				}
			}
		}
	}
}

public Native_UnregisterMe(Handle:plugin, numParams)
{
	if (KvGotoFirstSubKey(hRegKv))
	{
		decl String:sWeapon[32];
		decl any:aInfo[3];
		do
		{
			KvGetSectionName(hRegKv, sWeapon, sizeof(sWeapon));
			GetTrieArray(hRegTrie, sWeapon, aInfo, sizeof(aInfo));
			if (aInfo[0] == plugin)
			{
				KvDeleteThis(hRegKv);
				KvRewind(hRegKv);
				RemoveFromTrie(hRegTrie, sWeapon);
				
				for (new client = 1; client <= MaxClients; client++)
				{
					if (IsClientInGame(client))
					{
						new weapon = CSPlayer_GetActiveWeapon(client);
						if (weapon == -1)
						{
							continue;
						}
						if (Native_CheckWeapon(weapon, sWeapon))
						{
							OnWeaponChanged(client, weapon, CSViewModel_GetSequence(ClientVM[client]));
						}
						else
						{
							for (new i = 0; i < Type_Max; i++)
							{
								if (WeaponAddons[client][i] > 0)
								{
									switch (i)
									{
										case Type_Primary :
										{
											weapon = GetPlayerWeaponSlot(client, 0);
										}
										case Type_C4 :
										{
											weapon = GetPlayerWeaponSlot(client, 4);
										}
									}
									
									if (weapon != -1 && Native_CheckWeapon(weapon, sWeapon))
									{
										OnWeaponEquipPost(client, weapon);
										OldBits[client] = 0;
									}
								}
							}
						}
					}
				}
				
				KvGotoFirstSubKey(hRegKv);
			}
		}
		while (KvGotoNextKey(hRegKv));
	}
	KvRewind(hRegKv);
}

Native_CheckWeapon(weapon, const String:sWeapon[])
{
	decl String:buffer[32];
	if (GetEdictClassname(weapon, buffer, sizeof(buffer)))
	{
		new start_index = 0;
		if (StrContains(buffer, "weapon_", false) == 0)
		{
			start_index = 7;
		}
		if (StrEqual(buffer[start_index], sWeapon))
		{
			return true;
		}
	}
	return false;
}

bool:IsModelFile(const String:model[])
{
	decl String:buf[4];
	ZGetExtension(model, buf, sizeof(buf));
	
	return !strcmp(buf, "mdl", false);
}

GetPrecachedModelOfIndex(index, String:buffer[], maxlength)
{
	ReadStringTable(g_iTable, index, buffer, maxlength);
}

stock FakePrecacheSound(const String:szPath[])
{
	static hTable = INVALID_STRING_TABLE;

	if (hTable == INVALID_STRING_TABLE)
	{
		hTable = FindStringTable("soundprecache");
	}
	
	AddToStringTable(hTable, szPath);
}

stock AddToDownloadsTable(String:path[], bool:recursive=true)
{
	if (path[0] == '\0')
	{
		return;
	}
	
	new len = strlen(path)-1;
	
	if (path[len] == '\\' || path[len] == '/')
	{
		path[len] = '\0';
	}

	if (FileExists(path))
	{
		decl String:fileExtension[4];
		ZGetExtension(path, fileExtension, sizeof(fileExtension));
		
		if (StrEqual(fileExtension, "bz2", false) || StrEqual(fileExtension, "ztmp", false))
		{
			return;
		}
		
		if (StrEqual(fileExtension, "txt", false) || StrEqual(fileExtension, "ini", false))
		{
			ReadDownloadList(path);
			return;
		}

		AddFileToDownloadsTable(path);
	}
	else if (recursive && DirExists(path))
	{
		decl String:dirEntry[PLATFORM_MAX_PATH];
		new Handle:__dir = OpenDirectory(path);

		while (ReadDirEntry(__dir, dirEntry, sizeof(dirEntry)))
		{
			if (StrEqual(dirEntry, ".") || StrEqual(dirEntry, ".."))
			{
				continue;
			}
			
			Format(dirEntry, sizeof(dirEntry), "%s/%s", path, dirEntry);
			AddToDownloadsTable(dirEntry, recursive);
		}
		
		CloseHandle(__dir);
	}
	else if (FindCharInString(path, '*', true))
	{
		decl String:fileExtension[4];
		ZGetExtension(path, fileExtension, sizeof(fileExtension));

		if (StrEqual(fileExtension, "*"))
		{
			decl String:dirName[PLATFORM_MAX_PATH],
				String:fileName[PLATFORM_MAX_PATH],
				String:dirEntry[PLATFORM_MAX_PATH];

			ZGetDirName(path, dirName, sizeof(dirName));
			ZGetFileName(path, fileName, sizeof(fileName));
			StrCat(fileName, sizeof(fileName), ".");

			new Handle:__dir = OpenDirectory(dirName);
			while (ReadDirEntry(__dir, dirEntry, sizeof(dirEntry)))
			{
				if (StrEqual(dirEntry, ".") || StrEqual(dirEntry, ".."))
				{
					continue;
				}

				if (strncmp(dirEntry, fileName, strlen(fileName)) == 0)
				{
					Format(dirEntry, sizeof(dirEntry), "%s/%s", dirName, dirEntry);
					AddToDownloadsTable(dirEntry, recursive);
				}
			}

			CloseHandle(__dir);
		}
	}
}

stock bool:ReadDownloadList(const String:path[])
{
	new Handle:file = OpenFile(path, "r");
	
	if (file == INVALID_HANDLE)
	{
		return false;
	}

	new String:buffer[PLATFORM_MAX_PATH];
	while (!IsEndOfFile(file))
	{
		ReadFileLine(file, buffer, sizeof(buffer));
		
		new pos;
		pos = StrContains(buffer, "//");
		if (pos != -1)
		{
			buffer[pos] = '\0';
		}
		
		pos = StrContains(buffer, "#");
		if (pos != -1)
		{
			buffer[pos] = '\0';
		}

		pos = StrContains(buffer, ";");
		if (pos != -1)
		{
			buffer[pos] = '\0';
		}
		
		TrimString(buffer);
		
		if (buffer[0] == '\0')
		{
			continue;
		}

		AddToDownloadsTable(buffer);
	}

	CloseHandle(file);
	
	return true;
}



stock AddInFrontOf(const Float:vecOrigin[3], const Float:vecAngle[3], Float:units, Float:output[3])
{
	decl Float:vecView[3];
	GetAngleVectors(vecAngle, vecView, NULL_VECTOR, NULL_VECTOR);
    
	output[0] = vecView[0] * units + vecOrigin[0];
	output[1] = vecView[1] * units + vecOrigin[1];
	output[2] = vecView[2] * units + vecOrigin[2];
}

stock bool:IsSoundFile(const String:sound[])
{
	decl String:buf[4];
	ZGetExtension(sound, buf, sizeof(buf));
	
	return (!strcmp(buf, "mp3", false) || !strcmp(buf, "wav", false));
}

stock ZGetExtension(const String:path[], String:buffer[], size)
{
	new extpos = FindCharInString(path, '.', true);
	
	if (extpos == -1)
	{
		buffer[0] = '\0';
		return;
	}

	strcopy(buffer, size, path[++extpos]);
}

stock bool:ZGetFileName(const String:path[], String:buffer[], size)
{	
	if (path[0] == '\0') {
		buffer[0] = '\0';
		return;
	}
	
	ZGetBaseName(path, buffer, size);
	
	new pos_ext = FindCharInString(buffer, '.', true);

	if (pos_ext != -1) {
		buffer[pos_ext] = '\0';
	}
}

stock bool:ZGetDirName(const String:path[], String:buffer[], size)
{	
	if (path[0] == '\0') {
		buffer[0] = '\0';
		return;
	}
	
	new pos_start = FindCharInString(path, '/', true);
	
	if (pos_start == -1) {
		pos_start = FindCharInString(path, '\\', true);
		
		if (pos_start == -1) {
			buffer[0] = '\0';
			return;
		}
	}
	
	strcopy(buffer, size, path);
	buffer[pos_start] = '\0';
}

stock bool:ZGetBaseName(const String:path[], String:buffer[], size)
{	
	if (path[0] == '\0') {
		buffer[0] = '\0';
		return;
	}
	
	new pos_start = FindCharInString(path, '/', true);
	
	if (pos_start == -1) {
		pos_start = FindCharInString(path, '\\', true);
	}
	
	pos_start++;
	
	strcopy(buffer, size, path[pos_start]);
}

stock ClearKV(Handle:kv)
{
	KvRewind(kv);
	if (KvGotoFirstSubKey(kv))
	{
		do
		{
			KvDeleteThis(kv);
			KvRewind(kv);
		}
		while (KvGotoFirstSubKey(kv));
	}
}

stock StringToLower(const String:input[], String:output[], size)
{
	size--;

	new x = 0;
	while (input[x] != '\0' || x < size)
	{
		if (IsCharUpper(input[x]))
		{
			output[x] = CharToLower(input[x]);
		}
		else
		{
			output[x] = input[x];
		}
		
		x++;
	}

	output[x] = '\0';
}