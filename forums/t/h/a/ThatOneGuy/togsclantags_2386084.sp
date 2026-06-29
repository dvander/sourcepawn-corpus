#pragma semicolon 1
#define PLUGIN_VERSION "1.5"

#include <sourcemod>
#include <cstrike>
#include <autoexecconfig>

new String:g_sCfgPath[PLATFORM_MAX_PATH];

new Handle:g_hAdminFlag = INVALID_HANDLE;
new String:g_sAdminFlag[30];
new	Handle:g_hIncludeBots = INVALID_HANDLE;
new bool:g_bIncludeBots;
new	Handle:g_hEnforceTags = INVALID_HANDLE;
new g_iEnforceTags;
new Handle:g_hUpdateFreq = INVALID_HANDLE;
new Float:g_fUpdateFreq;

new String:ga_sTag[MAXPLAYERS + 1][50];
new bool:ga_bLoaded[MAXPLAYERS + 1] = {false, ...};

new Handle:g_hTagsInCfg = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "TOG Clan Tags",
	author = "That One Guy",
	description = "Configurable clan tag setups.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=188078"
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("togsclantags");
	AutoExecConfig_CreateConVar("togsclantags_version", PLUGIN_VERSION, "TOG Clan Tags: Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hAdminFlag = CreateConVar("togsclantags_admflag", "b", "Admin flag(s) used for sm_rechecktags command.", FCVAR_PLUGIN);
	HookConVarChange(g_hAdminFlag, OnCVarChange);
	GetConVarString(g_hAdminFlag, g_sAdminFlag, sizeof(g_sAdminFlag));
	
	g_hIncludeBots = AutoExecConfig_CreateConVar("togsclantags_bots", "0", "Do bots get tags? (1 = yes, 0 = no)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hIncludeBots, OnCVarChange);
	g_bIncludeBots = GetConVarBool(g_hIncludeBots);
	
	g_hEnforceTags = AutoExecConfig_CreateConVar("togsclantags_enforcetags", "0", "If no matching setup is found, should their tag be forced to be blank? (0 = allow players setting any clan tags they want, 1 = if no matching setup found, they can only use tags found in the cfg file, 2 = only get tags by having a matching setup in cfg file).", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hEnforceTags, OnCVarChange);
	g_iEnforceTags = GetConVarInt(g_hEnforceTags);
	
	g_hUpdateFreq = AutoExecConfig_CreateConVar("togsclantags_updatefreq", "30.0", "Frequency to re-load clients from cfg file (0 = only check once). This function is namely used to help interact with other plugins changing admin status late.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hUpdateFreq, OnCVarChange);
	g_fUpdateFreq = GetConVarFloat(g_hUpdateFreq);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	RegConsoleCmd("sm_rechecktags", Cmd_ResetTags, "Recheck tags for all players in the server.");
	
	HookEvent("player_spawn", Event_Recheck);
	HookEvent("player_team", Event_Recheck);
	BuildPath(Path_SM, g_sCfgPath, sizeof(g_sCfgPath), "configs/togsclantags.cfg");
	
	g_hTagsInCfg = CreateArray(64);
	LoadCfgTags();
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i, g_bIncludeBots))
		{
			ga_bLoaded[i] = false;
			GetTags(i);
		}
	}
}

public OnCVarChange(Handle:hCVar, const String:sOldValue[], const String:sNewValue[])
{
	if(hCVar == g_hAdminFlag)
	{
		GetConVarString(g_hAdminFlag, g_sAdminFlag, sizeof(g_sAdminFlag));
	}
	else if(hCVar == g_hIncludeBots)
	{
		g_bIncludeBots = GetConVarBool(g_hIncludeBots);
	}
	else if(hCVar == g_hEnforceTags)
	{
		g_iEnforceTags = StringToInt(sNewValue);
	}
	else if(hCVar == g_hUpdateFreq)
	{
		g_fUpdateFreq = GetConVarFloat(g_hUpdateFreq);
	}
}

public OnMapStart()
{
	LoadCfgTags();
}

LoadCfgTags()
{
	ClearArray(g_hTagsInCfg);
	new Handle:hKeyValues = CreateKeyValues("Setups");

	if(!FileExists(g_sCfgPath))
	{
		CloseHandle(hKeyValues);
		SetFailState("Configuration file not found: %s", g_sCfgPath);
		return;
	}

	if(!FileToKeyValues(hKeyValues, g_sCfgPath))
	{
		CloseHandle(hKeyValues);
		SetFailState("Improper structure for configuration file: %s", g_sCfgPath);
		return;
	}

	if(KvGotoFirstSubKey(hKeyValues))
	{
		decl String:sBuffer[128];
		do
		{
			KvGetString(hKeyValues, "exclude", sBuffer, sizeof(sBuffer), "0");
			new iExcluded = StringToInt(sBuffer);
			if(!iExcluded)
			{
				KvGetString(hKeyValues, "tag", sBuffer, sizeof(sBuffer));
				ResizeArray(g_hTagsInCfg, GetArraySize(g_hTagsInCfg) + 1);
				SetArrayString(g_hTagsInCfg, GetArraySize(g_hTagsInCfg) - 1, sBuffer);
			}
		}
		while(KvGotoNextKey(hKeyValues));
	}
	else
	{
		CloseHandle(hKeyValues);
		SetFailState("Can't find subkey in configuration file %s!", g_sCfgPath);
		return;
	}
	CloseHandle(hKeyValues);
}

public Action:Cmd_ResetTags(client,iArgs)
{
	if(!HasFlags(client, g_sAdminFlag))
	{
		ReplyToCommand(client, "\x04You do not have access to this command!");
		return Plugin_Handled;
	}
	
	ReRetrieveAllTags();
	
	return Plugin_Continue;
}

ReRetrieveAllTags()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i, g_bIncludeBots))
		{
			ga_bLoaded[i] = false;
			GetTags(i);
		}
	}
}

public OnClientConnected(client)
{
	ga_sTag[client] = "";
	ga_bLoaded[client] = false;
}

public OnClientDisconnect(client)
{
	ga_sTag[client] = "";
	ga_bLoaded[client] = false;
}

public OnClientPostAdminCheck(client)
{
	GetTags(client);
	if(g_fUpdateFreq)
	{
		CreateTimer(g_fUpdateFreq, TimerCB_ReCheckCfg, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:TimerCB_ReCheckCfg(Handle:hTimer, any:iUserID)
{
	new client = GetClientOfUserId(iUserID);
	if(!IsValidClient(client, g_bIncludeBots))
	{
		return Plugin_Stop;
	}
	ga_bLoaded[client] = false;
	GetTags(client);
	return Plugin_Continue;
}

public OnClientSettingsChanged(client)	//hooked in case they change their clan tag
{
	if(IsClientAuthorized(client)) //dont want them to try loading before steam id loads
	{
		CheckTags(client);
	}
}

public Action:Event_Recheck(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(IsValidClient(client, g_bIncludeBots))
	{
		if(!ga_bLoaded[client])
		{
			GetTags(client);
		}
		else
		{
			CheckTags(client);
		}
	}
	return Plugin_Continue;
}

GetTags(client)
{
	ga_sTag[client] = "";
	if(!FileExists(g_sCfgPath))
	{
		SetFailState("Configuration file %s not found!", g_sCfgPath);
		return;
	}

	new Handle:hKeyValues = CreateKeyValues("Setups");
	if(!FileToKeyValues(hKeyValues, g_sCfgPath))
	{
		CloseHandle(hKeyValues);
		SetFailState("Improper structure for configuration file %s!", g_sCfgPath);
		return;
	}

	if(!KvGotoFirstSubKey(hKeyValues))
	{
		CloseHandle(hKeyValues);
		SetFailState("Can't find subkey in configuration file %s!", g_sCfgPath);
		return;
	}
	
	ga_sTag[client] = "";
	
	decl String:sBuffer[150], String:sSteamID[MAX_NAME_LENGTH], String:sAltUnivID[MAX_NAME_LENGTH];
	if(IsValidClient(client))
	{
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 7
		GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));
#else
		GetClientAuthString(client, sSteamID, sizeof(sSteamID));
#endif
		strcopy(sAltUnivID, sizeof(sAltUnivID), sSteamID);
		if(StrContains(sAltUnivID, "STEAM_1", true) != -1)
		{
			ReplaceString(sAltUnivID, sizeof(sAltUnivID), "STEAM_1", "STEAM_0", true);
		}
		else
		{
			ReplaceString(sAltUnivID, sizeof(sAltUnivID), "STEAM_0", "STEAM_1", true);
		}
	}
	else if(IsFakeClient(client) && g_bIncludeBots) //not a valid player - check if bot and bots allowed
	{
		Format(sSteamID, sizeof(sSteamID), "BOT");
		strcopy(sAltUnivID, sizeof(sAltUnivID), sSteamID);
	}
	else
	{
		CloseHandle(hKeyValues);
		return;
	}

	do
	{
		KvGetString(hKeyValues, "flag",	sBuffer, sizeof(sBuffer));
		new iIgnore = KvGetNum(hKeyValues, "ignore", 0);
		
		if(StrEqual("BOT", sBuffer, false)) //check if BOT config
		{
			if(StrEqual("BOT", sSteamID, false)) //check if player is BOT
			{
				KvGetString(hKeyValues, "tag", ga_sTag[client], sizeof(ga_sTag[]));
				break;
			}
		}
		else if(StrContains(sBuffer, "STEAM_", true) != -1) //check if steam ID
		{
			if(StrEqual(sBuffer, sSteamID, true) || StrEqual(sBuffer, sAltUnivID, true))
			{
				if(!iIgnore)
				{
					KvGetString(hKeyValues, "tag", ga_sTag[client], sizeof(ga_sTag[]));
				}
				break;
			}
		}
		else if(HasFlags(client, sBuffer)) //check if player has defined flags
		{
			if(!iIgnore)
			{
				KvGetString(hKeyValues, "tag", ga_sTag[client], sizeof(ga_sTag[]));
			}
			break;
		}
	}
	while(KvGotoNextKey(hKeyValues));
	
	CloseHandle(hKeyValues);
	
	ga_bLoaded[client] = true;
	CheckTags(client);
}

CheckTags(client)
{	
	if(!ga_bLoaded[client])
	{
		GetTags(client);
		return;
	}
	
	if(!StrEqual(ga_sTag[client], "", true))
	{
		CS_SetClientClanTag(client, ga_sTag[client]);
	}
	else if(g_iEnforceTags == 1)
	{
		new String:sTag[50];
		CS_GetClientClanTag(client, sTag, sizeof(sTag));
		if(FindStringInArray(g_hTagsInCfg, sTag) == -1)
		{
			CS_SetClientClanTag(client, "");
		}
	}
	else if(g_iEnforceTags == 2)
	{
		CS_SetClientClanTag(client, "");
	}
	
}

bool:HasFlags(client, String:sFlags[])
{
	if(StrEqual(sFlags, "public", false) || StrEqual(sFlags, "", false))
	{
		return true;
	}
	
	if(StrEqual(sFlags, "none", false))
	{
		return false;
	}
	
	new AdminId:id = GetUserAdmin(client);
	if(id == INVALID_ADMIN_ID)
	{
		return false;
	}
	
	if(CheckCommandAccess(client, "sm_not_a_command", ADMFLAG_ROOT, true))
	{
		return true;
	}
	new iCount, iFound, flags;
	if(StrContains(sFlags, ";", false) != -1) //check if multiple strings
	{
		new c = 0, iStrCount = 0;
		while(sFlags[c] != '\0')
		{
			if(sFlags[c++] == ';')
			{
				iStrCount++;
			}
		}
		iStrCount++; //add one more for IP after last comma
		decl String:sTempArray[iStrCount][30];
		ExplodeString(sFlags, ";", sTempArray, iStrCount, 30);
		
		for(new i = 0; i < iStrCount; i++)
		{
			flags = ReadFlagString(sTempArray[i]);
			iCount = 0;
			iFound = 0;
			for(new j = 0; j <= 20; j++)
			{
				if(flags & (1<<j))
				{
					iCount++;

					if(GetAdminFlag(id, AdminFlag:j))
					{
						iFound++;
					}
				}
			}
			
			if(iCount == iFound)
			{
				return true;
			}
		}
	}
	else
	{
		flags = ReadFlagString(sFlags);
		iCount = 0;
		iFound = 0;
		for(new i = 0; i <= 20; i++)
		{
			if(flags & (1<<i))
			{
				iCount++;

				if(GetAdminFlag(id, AdminFlag:i))
				{
					iFound++;
				}
			}
		}

		if(iCount == iFound)
		{
			return true;
		}
	}
	return false;
}

bool:IsValidClient(client, bool:bAllowBots = false)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots))
	{
		return false;
	}
	return true;
}

public OnRebuildAdminCache(AdminCachePart:part)
{
	ReRetrieveAllTags();
}

/*
CHANGELOG:
	1.0:
		* Plugin coded for private. Released to Allied Modders after suggestion from requester.
	1.1:
		* Fixed memory leak due to missing a CloseHandle on one of the returns.
	1.2:
		* Added OnRebuildAdminCache event.
		* Added cvar for rechecking client against cfg file on a configurable interval. This was added so that the plugin can interact with other plugins that dont fwd admin cache changes properly.
	1.3:
		* Minor edits to make sure clients load tag when spawning in late, etc.
	1.4:
		* Edited togsclantags_enforcetags cvar: was missing 'c' in name, and added an option to allow tags if they exist in the cfg.
	1.5:
		* Added "ignore" kv.
*/