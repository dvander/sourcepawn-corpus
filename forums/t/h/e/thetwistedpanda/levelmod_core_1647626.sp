/*
	Revision 0.1.4 (Unofficial)
	----------------
	Added internal support for ClientPrefs into levelmod., removing the need for levelmod.permanent.clientprefs.sp
	Added support saving/loading information to a SQL database, "levelmod" by default.
		Note; You could export your clientpref data to another sqlite database and use it with the sql support feature.
	Added proper support for loading levelmod.core late, so that data is loaded without requiring a map change.
	Modified various segments of code for personal reasons and for minor adjustments/improvements.
	Modified client loading process for ClientPrefs to a method that I know functions properly (shouldn't be a race condition issue anymore).
	Fixed a few timer issues, while not necessarily harmful, could have caused issues later down the road in future development.
	Raised the hardcoded level support of levelmod.core to 1000, as opposed to 101, as well as the cvar cap.
	Modified several natives to return values based on whether or not a client had properly loaded.
		lm_SetClientLevel, lm_SetClientXP, lm_GiveXP, lm_GiveLevel return true is successful, false if not loaded
		lm_GetClientLevel, lm_GetClientXP, lm_GetClientXPNext return -1 if not loaded, otherwise correct value.
	Added forward lm_OnCoreLoad, which fires when levelmod.core is loaded for the first time.
	Added forward lm_OnClientLoad, which fires when a client is successfully loaded by levelmod.core	
	Added cvar sm_lm_exp_savemethod, which determines the save method for levelmod.core: (0 = Disabled, 1 = ClientPrefs, 2 = Database)
	Added cvar sm_lm_exp_savefrequency, which saves clients lvl/exp every x seconds (0 = Disabled, Default: 15 minutes)
		Note: The original clientprefs save plugin would only save on levelup/disconnect; both are true for the internal version, but this is extra incase of crash / long maps.
	Added extra checks to ensure a client's Next Level EXP is always -1 if at max level.
	Added native lm_IsClientLoaded, which checks if a client has been fully loaded by levelmod.core.
	The experience table is now created only at plugin launch (delayed 0.1 seconds after), and upon change of cvar sm_lm_exp_reqmulti.
	Levelmod.core now creates a cvar config file, which should be located somewhere along the lines of <game>/<config>/sourcemod/levelmod.core.cfg
	Added cvar sm_lm_exp_savebots, which will save bots under their name if sm_lm_exp_savemethod is set to 2.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <dbi>

#define PLUGIN_VERSION "0.1.4 (Unofficial)"

//The maximum level the script supports, increase to allow for more.
#define MAXLEVELS 1000

//The rate at which clients are checked for level changes
#define TIMER_CHECK_RATE 2.0

//The corresponding entry in databases.cfg for LevelMod (optional)
#define PLUGIN_DATABASE "levelmod"

//The corresponding table for LevelMod
#define PLUGIN_TABLE "levelmod"

//Flags for determining save mode (optional)
#define DATABASE_NONE 0
#define DATABASE_PREFS 1
#define DATABASE_SQL 2

//Pre-defined queries for SQL support
new String:g_sSQL_CreateTable[] = { "CREATE TABLE IF NOT EXISTS %s (steam_id varchar(32) PRIMARY KEY default '', levelmod_level int(12) NOT NULL default 0, levelmod_xp int(12) NOT NULL default 0)" };
new String:g_sSQL_LoadClient[] = { "SELECT levelmod_level, levelmod_xp FROM %s WHERE steam_id = '%s'" };
new String:g_sSQL_SaveClient[] = { "REPLACE INTO %s (steam_id, levelmod_level, levelmod_xp) VALUES ('%s', %d, %d)" };

new g_iXPForLevel[MAXLEVELS];
new g_iPlayerLVL[MAXPLAYERS+1];
new g_iPlayerEXP[MAXPLAYERS+1];
new g_iPlayerNXT[MAXPLAYERS+1];
new bool:g_bFake[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new Float:g_fPlayerSave[MAXPLAYERS + 1];
new String:g_sSteam[MAXPLAYERS + 1][32];

new Handle:g_hTimerCheckLevelUp[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new Handle:g_hCvarEnable = INVALID_HANDLE;
new Handle:g_hCvarLevel_Default = INVALID_HANDLE;
new Handle:g_hCvarLevel_Max = INVALID_HANDLE;
new Handle:g_hCvarExp_ReqBase = INVALID_HANDLE;
new Handle:g_hCvarExp_ReqMulti = INVALID_HANDLE;
new Handle:g_hCvarExp_SaveMethod = INVALID_HANDLE;
new Handle:g_hCvarExp_SaveFrequency = INVALID_HANDLE;
new Handle:g_hCvarExp_SaveBots = INVALID_HANDLE;
new Handle:g_hForwardCoreLoad = INVALID_HANDLE;
new Handle:g_hForwardClientLoad = INVALID_HANDLE;
new Handle:g_hForwardLevelUp = INVALID_HANDLE;
new Handle:g_hForwardXPGained = INVALID_HANDLE;
new Handle:g_hCookieLvl = INVALID_HANDLE;
new Handle:g_hCookieExp = INVALID_HANDLE;
new Handle:g_hDatabase = INVALID_HANDLE;

new g_iLevelMaxForced = -1;
new g_iLevelDefaultForced = -1;
new g_iExpReqBaseForced = -1;
new Float:g_fExpReqMultForced = -1.0;

new g_iLevelHighest, g_iLevelLowest, g_iLevelDefault, g_iLevelMax, g_iExpReqBase, g_iSaveMethod;
new bool:g_bEnabled, bool:g_bLateLoad, bool:g_bSaveBots;
new Float:g_fExpReqMult, Float:g_fSaveFrequency;

public Plugin:myinfo =
{
	name = "Leveling Core",
	author = "noodleboy347, Thrawn, Twisted|Panda",
	description = "A RPG-like leveling core to be used by other plugins.",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
	public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
	public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{
	g_bLateLoad = late;
	RegPluginLibrary("levelmod");

	CreateNative("lm_GetClientXP", Native_GetClientXP);
	CreateNative("lm_SetClientXP", Native_SetClientXP);
	CreateNative("lm_GiveXP", Native_GiveXP);

	CreateNative("lm_GetClientLevel", Native_GetClientLevel);
	CreateNative("lm_SetClientLevel", Native_SetClientLevel);
	CreateNative("lm_GiveLevel", Native_GiveLevel);

	CreateNative("lm_GetClientXPNext", Native_GetClientXPNext);
	CreateNative("lm_GetXpRequiredForLevel", Native_GetClientXPForLevel);
	CreateNative("lm_GetLevelMax", Native_GetLevelMax);

	CreateNative("lm_GetLevelHighest", Native_GetLevelHighest);
	CreateNative("lm_GetLevelLowest", Native_GetLevelLowest);

	CreateNative("lm_ForceExpReqBase", Native_ForceExpReqBase);
	CreateNative("lm_ForceExpReqMult", Native_ForceExpReqMult);
	CreateNative("lm_ForceLevelDefault", Native_ForceLevelDefault);
	CreateNative("lm_ForceLevelMax", Native_ForceLevelMax);

	CreateNative("lm_IsEnabled", Native_GetEnabled);
	CreateNative("lm_IsClientLoaded", Native_GetClientLoad);

	#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
		return APLRes_Success;
	#else
		return true;
	#endif
}

public OnPluginStart()
{
	CreateConVar("sm_tlevelmod_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hCvarEnable = CreateConVar("sm_lm_enabled", "1", "Enables the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnable, OnSettingChanged);
	g_hCvarLevel_Default = CreateConVar("sm_lm_level_default", "0", "The default level for players when they join.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hCvarLevel_Default, OnSettingChanged);
	g_hCvarLevel_Max = CreateConVar("sm_lm_level_max", "100", "The maximum level players can reach.", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_hCvarLevel_Max, OnSettingChanged);
	g_hCvarExp_ReqBase = CreateConVar("sm_lm_exp_reqbase", "100", " The experience required for the first level.", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_hCvarExp_ReqBase, OnSettingChanged);
	g_hCvarExp_ReqMulti = CreateConVar("sm_lm_exp_reqmulti", "1.1", "The experience required grows by this multiplier every level.", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_hCvarExp_ReqMulti, OnSettingChanged);
	g_hCvarExp_SaveMethod = CreateConVar("sm_lm_exp_savemethod", "0", "Determines which saving method to use. (0 = None, 1 = ClientPrefs, 2 = Database)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	HookConVarChange(g_hCvarExp_SaveMethod, OnSettingChanged);
	g_hCvarExp_SaveFrequency = CreateConVar("sm_lm_exp_savefrequency", "900.0", "Determines how often client progression is saved. (0 = Disabled, # = Seconds)", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hCvarExp_SaveFrequency, OnSettingChanged);
	g_hCvarExp_SaveBots = CreateConVar("sm_lm_exp_savebots", "1", "If enabled, bots will be saved via their name if sm_lm_exp_savemethod is 2.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarExp_SaveBots, OnSettingChanged);
	AutoExecConfig(true, "levelmod.core");
	
	g_hForwardCoreLoad = CreateGlobalForward("lm_OnCoreLoad", ET_Ignore);
	g_hForwardClientLoad = CreateGlobalForward("lm_OnClientLoad", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardLevelUp = CreateGlobalForward("lm_OnClientLevelUp", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardXPGained = CreateGlobalForward("lm_OnClientExperience", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	g_bEnabled = GetConVarBool(g_hCvarEnable);
	g_iLevelMax = g_iLevelMaxForced == -1 ? GetConVarInt(g_hCvarLevel_Max) : g_iLevelMaxForced;
	g_iExpReqBase = g_iExpReqBaseForced == -1 ? GetConVarInt(g_hCvarExp_ReqBase) : g_iExpReqBaseForced;
	g_fExpReqMult = g_fExpReqMultForced == -1.0 ? GetConVarFloat(g_hCvarExp_ReqMulti) : g_fExpReqMultForced;
	g_iLevelDefault = g_iLevelDefaultForced == -1 ? GetConVarInt(g_hCvarLevel_Default) : g_iLevelDefaultForced;
	g_iSaveMethod = GetConVarInt(g_hCvarExp_SaveMethod);
	g_fSaveFrequency = GetConVarFloat(g_hCvarExp_SaveFrequency);
	g_bSaveBots = GetConVarBool(g_hCvarExp_SaveBots);
	
	g_hCookieLvl = RegClientCookie("levelmod_level", "Player's current level.", CookieAccess_Private); //"
	g_hCookieExp = RegClientCookie("levelmod_xp", "Player's current experience.", CookieAccess_Private); //"

	Forward_CoreLoad();
	CreateTimer(0.1, Timer_CreateExpTable);
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		if(g_iSaveMethod == DATABASE_SQL)
		{
			if(g_hDatabase == INVALID_HANDLE)
				SQL_TConnect(SQL_ConnectCall, PLUGIN_DATABASE);
		}
		else if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_bFake[i] = IsFakeClient(i) ? true : false;
					if(g_bFake[i])
						GetClientName(i, g_sSteam[i], sizeof(g_sSteam[]));
					else
						GetClientAuthString(i, g_sSteam[i], 32);
					
					if(!g_bLoaded[i])
						Void_LoadClient(i);
				}
			}
			
			g_bLateLoad = false;
		}
	}
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		g_bFake[client] = IsFakeClient(client) ? true : false;
		if(g_bFake[client])
			GetClientName(client, g_sSteam[client], sizeof(g_sSteam[]));
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_bEnabled && IsClientInGame(client))
	{
		if(!g_bFake[client])
			GetClientAuthString(client, g_sSteam[client], 32);
		if(!g_bLoaded[client])
			Void_LoadClient(client);
	}
}

public OnClientCookiesCached(client)
{
	if(g_bEnabled && IsClientInGame(client))
	{
		if(!g_bLoaded[client] && g_iSaveMethod == DATABASE_PREFS)
			Void_LoadClient(client);
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		if(g_iSaveMethod)
		{
			if(!g_bFake[client] || g_bFake[client] && g_bSaveBots)
				Void_SaveClient(client);
		}

		g_bFake[client] = false;
		g_bLoaded[client] = false;
		if(g_hTimerCheckLevelUp[client] != INVALID_HANDLE && CloseHandle(g_hTimerCheckLevelUp[client]))
			g_hTimerCheckLevelUp[client] = INVALID_HANDLE;
	}
}

Void_LoadClient(client)
{
	switch(g_iSaveMethod)
	{
		case DATABASE_NONE:
		{
			g_iPlayerLVL[client] = g_iLevelDefault;
			g_iPlayerEXP[client] = GetMinXPForLevel(g_iLevelDefault);
			g_iPlayerNXT[client] = GetMinXPForLevel(g_iLevelDefault + 1);
		}
		case DATABASE_PREFS:
		{
			if(!AreClientCookiesCached(client))
				return;

			new String:_sBuffer[20];
			GetClientCookie(client, g_hCookieLvl, _sBuffer, sizeof(_sBuffer));
			if(StrEqual(_sBuffer, ""))
			{
				g_iPlayerLVL[client] = g_iLevelDefault;
				g_iPlayerEXP[client] = GetMinXPForLevel(g_iLevelDefault);
				g_iPlayerNXT[client] = GetMinXPForLevel(g_iLevelDefault + 1);
			}
			else
			{
				g_iPlayerLVL[client] = StringToInt(_sBuffer);
				GetClientCookie(client, g_hCookieExp, _sBuffer, sizeof(_sBuffer));
				g_iPlayerEXP[client] = StringToInt(_sBuffer);
				if(g_iPlayerLVL[client] >= g_iLevelMax)
					g_iPlayerNXT[client] = -1;
				else
					g_iPlayerNXT[client] = GetMinXPForLevel(g_iPlayerLVL[client] + 1);
			}
		}
		case DATABASE_SQL:
		{
			if(g_hDatabase == INVALID_HANDLE)
				return;

			decl String:_sBuffer[256];
			Format(_sBuffer, sizeof(_sBuffer), g_sSQL_LoadClient, PLUGIN_TABLE, g_sSteam[client]);
			SQL_TQuery(g_hDatabase, SQL_LoadPlayerCall, _sBuffer, GetClientUserId(client));
			
			return;
		}
	}

	LogMessage("DB-LOAD: %N (%s) is level %i, with %i exp, and %i tnl", client, g_sSteam[client], g_iPlayerLVL[client], g_iPlayerEXP[client], (g_iPlayerNXT[client] - g_iPlayerEXP[client]));

	g_bLoaded[client] = true;
	g_hTimerCheckLevelUp[client] = CreateTimer(TIMER_CHECK_RATE, Timer_CheckLevelUp, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	Forward_ClientLoad(client, g_iPlayerLVL[client], g_iPlayerEXP[client], g_iPlayerNXT[client]);
}

Void_SaveClient(client)
{
	switch(g_iSaveMethod)
	{
		case DATABASE_PREFS:
		{
			decl String:_sBuffer[20];
			Format(_sBuffer, sizeof(_sBuffer), "%i", g_iPlayerLVL[client]);
			SetClientCookie(client, g_hCookieLvl, _sBuffer);

			Format(_sBuffer, sizeof(_sBuffer), "%i", g_iPlayerEXP[client]);
			SetClientCookie(client, g_hCookieExp, _sBuffer);
		}
		case DATABASE_SQL:
		{
			if(g_hDatabase == INVALID_HANDLE)
				return;
				
			decl String:_sBuffer[256];
			Format(_sBuffer, sizeof(_sBuffer), g_sSQL_SaveClient, PLUGIN_TABLE, g_sSteam[client], g_iPlayerLVL[client], g_iPlayerEXP[client]);
			SQL_TQuery(g_hDatabase, SQL_SavePlayerCall, _sBuffer, GetClientUserId(client));
		}
	}

	LogMessage("DB-SAVE: %N (%s) is level %i, with %i exp, and %i tnl", client, g_sSteam[client], g_iPlayerLVL[client], g_iPlayerEXP[client], (g_iPlayerNXT[client] - g_iPlayerEXP[client]));

	g_fPlayerSave[client] = 0.0;
}

public Action:Timer_CheckLevelUp(Handle:timer, any:client)
{
	if(g_bEnabled)
	{
		CheckAndLevel(client);
		
		if(g_iSaveMethod)
		{
			g_fPlayerSave[client] += TIMER_CHECK_RATE;
			if(g_fPlayerSave[client] >= g_fSaveFrequency)
			{
				g_fPlayerSave[client] = 0.0;
				Void_SaveClient(client);
			}
		}
		
		return Plugin_Continue;
	}
	else
	{
		g_hTimerCheckLevelUp[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
}

public Action:Timer_CreateExpTable(Handle:timer)
{
	g_iXPForLevel[0] = 0;
	g_iXPForLevel[1] = g_iExpReqBase;
	for(new level = 2; level < g_iLevelMax; level++)
		g_iXPForLevel[level] = g_iXPForLevel[level-1] + RoundFloat((g_iXPForLevel[level-1] - g_iXPForLevel[level-2]) * g_fExpReqMult);
}

stock CheckAndLevel(client)
{
	new _iLevelMod, bool:_bLostLevel;
	while(g_iPlayerLVL[client] > 0 && g_iPlayerEXP[client] < GetMinXPForLevel(g_iPlayerLVL[client]))
	{
		LogMessage("Player %N is not level %i anymore, (%i < %i)", client, g_iPlayerLVL[client], g_iPlayerEXP[client], GetMinXPForLevel(g_iPlayerLVL[client]));

		_iLevelMod++;
		_bLostLevel = true;
		g_iPlayerLVL[client]--;
		g_iPlayerNXT[client] = GetMinXPForLevel(g_iPlayerLVL[client]+1);
	}

	if(!_bLostLevel)
	{
		while(g_iPlayerNXT[client] != -1 && g_iPlayerEXP[client] >= g_iPlayerNXT[client] && g_iPlayerLVL[client] < g_iLevelMax)
		{
			LogMessage("Player is not level %i anymore, (%i >= %i)", g_iPlayerLVL[client], g_iPlayerEXP[client], g_iPlayerNXT[client]);

			_iLevelMod++;
			g_iPlayerLVL[client]++;
			if(g_iPlayerLVL[client] >= g_iLevelMax)
				g_iPlayerNXT[client] = -1;
			else
				g_iPlayerNXT[client] = GetMinXPForLevel(g_iPlayerLVL[client]+1);
		}
	}

	if(_iLevelMod > 0)
	{
		CalculateBorders();
		Void_SaveClient(client);
		Forward_LevelChange(client, g_iPlayerLVL[client], _iLevelMod, _bLostLevel);
	}
}

stock CalculateBorders() 
{
	g_iLevelHighest = 0;
	g_iLevelLowest = MAXLEVELS;

	for(new i = 1; i <= MaxClients; i++) 
	{
		if(g_iPlayerLVL[i] > g_iLevelHighest)
			g_iLevelHighest = g_iPlayerLVL[i];

		if(g_iPlayerLVL[i] < g_iLevelLowest)
			g_iLevelLowest = g_iPlayerLVL[i];
	}
}

stock AddLevels(client, levels = 1)
{
	if(g_iPlayerLVL[client] >= g_iLevelMax)
		return;

	if(g_iPlayerLVL[client] + levels >= g_iLevelMax)
		g_iPlayerEXP[client] = GetMinXPForLevel(g_iLevelMax);
	else
		g_iPlayerEXP[client] = GetMinXPForLevel(g_iPlayerLVL[client] + levels);
}

stock SetLevel(client, level) 
{
	g_iPlayerEXP[client] = GetMinXPForLevel(level);
	g_iPlayerNXT[client] = GetMinXPForLevel(level+1);
	g_iPlayerLVL[client] = level;
}

stock GetMinXPForLevel(level) 
{
	return g_iXPForLevel[level];
}

stock GiveXP(client, amount, iChannel)
{
	g_iPlayerEXP[client] += amount;
	Forward_XPGained(client, amount, iChannel);
}

public SQL_ConnectCall(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("LevelMod was unable to connect to the provided database!");
		LogError("- Source: SQL_ConnectCall");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogError("- Error: %s", _sError);
		}
		else if(strlen(error) > 0)
			LogError("- Error: %s", error);
	}
	else
	{
		decl String:_sBuffer[256];
		SQL_LockDatabase(hndl);
		Format(_sBuffer, sizeof(_sBuffer), g_sSQL_CreateTable, PLUGIN_TABLE);
		if(!SQL_FastQuery(hndl, _sBuffer))
		{
			LogError("LevelMod was unable to create the necessary table!");
			LogError("- Source: SQL_ConnectCall");
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogError(" - Error: %s", _sError);
			CloseHandle(hndl);
			return;
		}
		
		SQL_UnlockDatabase(hndl);
		g_hDatabase = hndl;

		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_bFake[i] = IsFakeClient(i) ? true : false;
					if(g_bFake[i])
						GetClientName(i, g_sSteam[i], sizeof(g_sSteam[]));
					else
						GetClientAuthString(i, g_sSteam[i], 32);
						
					Format(_sBuffer, sizeof(_sBuffer), g_sSQL_LoadClient, PLUGIN_TABLE, g_sSteam[i]);
					SQL_TQuery(g_hDatabase, SQL_LoadPlayerCall, _sBuffer, GetClientUserId(i));
				}
			}

			g_bLateLoad = false;
		}
	}
}

public SQL_LoadPlayerCall(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	new client = GetClientOfUserId(userid);
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("LevelMod was unable to load client %d (%s)!", client, g_sSteam[client]);
		LogError("- Source: SQL_LoadPlayerCall");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[256];
			SQL_GetError(hndl, _sError, 256);
			LogError("- Error: %s", _sError);
		}
		else
			LogError("- Error: %s", error);
	}
	else
	{
		if(client > 0 && IsClientInGame(client))
		{
			if(SQL_HasResultSet(hndl))
			{
				if(SQL_FetchRow(hndl))
				{
					g_iPlayerLVL[client] = SQL_FetchInt(hndl, 0);
					g_iPlayerEXP[client] = SQL_FetchInt(hndl, 1);
					if(g_iPlayerLVL[client] >= g_iLevelMax)
						g_iPlayerNXT[client] = -1;
					else
						g_iPlayerNXT[client] = GetMinXPForLevel(g_iPlayerLVL[client] + 1);
				}
				else
				{
					g_iPlayerLVL[client] = g_iLevelDefault;
					g_iPlayerEXP[client] = GetMinXPForLevel(g_iLevelDefault);
					g_iPlayerNXT[client] = GetMinXPForLevel(g_iLevelDefault + 1);
				}

				LogMessage("DB-LOAD: %N is level %i, with %i exp, and %i tnl", client, g_iPlayerLVL[client], g_iPlayerEXP[client], (g_iPlayerNXT[client] - g_iPlayerEXP[client]));

				g_bLoaded[client] = true;
				g_hTimerCheckLevelUp[client] = CreateTimer(TIMER_CHECK_RATE, Timer_CheckLevelUp, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				Forward_ClientLoad(client, g_iPlayerLVL[client], g_iPlayerEXP[client], g_iPlayerNXT[client]);
			}
		}
	}
}

public SQL_SavePlayerCall(Handle:owner, Handle:hndl, const String:error[], any:userid)
{	
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		new client = GetClientOfUserId(userid);
		LogError("LevelMod was unable to load client %d (%s)!", GetClientOfUserId(client), g_sSteam[client]);
		LogError("- Source: SQL_SavePlayerCall");
		if(hndl != INVALID_HANDLE)
		{
			decl String:_sError[512];
			SQL_GetError(hndl, _sError, 512);
			LogError("- Error: %s", _sError);
		}
		else
			LogError("- Error: %s", error);
	}
}

public OnSettingChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if(cvar == g_hCvarEnable)
		g_bEnabled = StringToInt(newValue) ? true : false;
	else if(cvar == g_hCvarLevel_Max)
		g_iLevelMax = g_iLevelMaxForced == -1 ? StringToInt(newValue) : g_iLevelMaxForced;
	else if(cvar == g_hCvarExp_ReqBase)
		g_iExpReqBase = g_iExpReqBaseForced == -1 ? StringToInt(newValue) : g_iExpReqBaseForced;
	else if(cvar == g_hCvarExp_ReqMulti)
	{
		g_fExpReqMult = g_fExpReqMultForced == -1.0 ? StringToFloat(newValue) : g_fExpReqMultForced;
		CreateTimer(0.1, Timer_CreateExpTable);
	}
	else if(cvar == g_hCvarLevel_Default)
		g_iLevelDefault = g_iLevelDefaultForced == -1 ? StringToInt(newValue) : g_iLevelDefaultForced;
	else if(cvar == g_hCvarExp_SaveMethod)
		g_iSaveMethod = StringToInt(newValue);
	else if(cvar == g_hCvarExp_SaveFrequency)
		g_fSaveFrequency = StringToFloat(newValue); 
	else if(cvar == g_hCvarExp_SaveBots)
		g_bSaveBots = StringToInt(newValue) ? true : false;
}

//lm_GetClientLevel(iClient);
public Native_GetClientLevel(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	if(!g_bLoaded[iClient])
		return -1;
		
	return g_iPlayerLVL[iClient];
}

//lm_GetClientXP(iClient);
public Native_GetClientXP(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	if(!g_bLoaded[iClient])
		return -1;
		
	return g_iPlayerEXP[iClient];
}

//lm_SetClientLevel(iClient, iLevel);
public Native_SetClientLevel(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iLevel = GetNativeCell(2);
	if(!g_bLoaded[iClient])
		return false;
		
	SetLevel(iClient, iLevel);
	return true;
}

//lm_SetClientXP(iClient, iXP);
public Native_SetClientXP(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iXP = GetNativeCell(2);
	if(!g_bLoaded[iClient])
		return false;

	g_iPlayerEXP[iClient] = iXP;
	return true;
}

//lm_GiveXP(iClient, iXP, iChannel);
public Native_GiveXP(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iXP = GetNativeCell(2);
	new iChannel = GetNativeCell(3);
	if(!g_bLoaded[iClient])
		return false;

	GiveXP(iClient, iXP, iChannel);
	return true;
}

//lm_GiveLevel(iClient, iLevels);
public Native_GiveLevel(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iLevels = GetNativeCell(2);
	if(!g_bLoaded[iClient])
		return false;
		
	AddLevels(iClient, iLevels);
	return true;
}

//lm_GetClientXPNext(iClient);
public Native_GetClientXPNext(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	if(!g_bLoaded[iClient])
		return -1;

	return g_iPlayerNXT[iClient];
}

//lm_GetLevelMax();
public Native_GetLevelMax(Handle:hPlugin, iNumParams)
{
	return g_iLevelMax;
}

//lm_GetLevelHighest();
public Native_GetLevelHighest(Handle:hPlugin, iNumParams)
{
	return g_iLevelHighest;
}

//lm_GetLevelLowest();
public Native_GetLevelLowest(Handle:hPlugin, iNumParams)
{
	return g_iLevelLowest;
}

//lm_IsEnabled();
public Native_GetEnabled(Handle:hPlugin, iNumParams)
{
	return g_bEnabled;
}

//lm_IsClientLoaded(iClient);
public Native_GetClientLoad(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);

	return g_bLoaded[iClient];
}

//lm_GetClientXPForLevel(iLevel);
public Native_GetClientXPForLevel(Handle:hPlugin, iNumParams)
{
	new iLevel = GetNativeCell(1);

	return GetMinXPForLevel(iLevel);
}

//lm_ForceLevelMax(iClient, iXP);
public Native_ForceLevelMax(Handle:hPlugin, iNumParams)
{
	if(GetNativeCell(1) < g_iLevelMaxForced || g_iLevelMaxForced == -1)
		g_iLevelMaxForced = GetNativeCell(1);
}

//lm_ForceLevelDefault(iClient, iXP);
public Native_ForceLevelDefault(Handle:hPlugin, iNumParams)
{
	g_iLevelDefaultForced = GetNativeCell(1);
}

//lm_ForceExpReqBase(iClient, iXP);
public Native_ForceExpReqBase(Handle:hPlugin, iNumParams)
{
	g_iExpReqBaseForced = GetNativeCell(1);
}

//lm_ForceExpReqMult(iClient, iXP);
public Native_ForceExpReqMult(Handle:hPlugin, iNumParams)
{
	g_fExpReqMultForced = GetNativeCell(1);
}

//public lm_OnClientLevelUp(iClient, iLevel, iAmount, bool:isLevelDown) {};
public Forward_LevelChange(client, level, amount, bool:isLevelDown)
{
	Call_StartForward(g_hForwardLevelUp);
	Call_PushCell(client);
	Call_PushCell(level);
	Call_PushCell(amount);
	Call_PushCell(isLevelDown);
	Call_Finish();
}

//public lm_OnClientExperience(iClient, iXP, iChannel) {};
public Forward_XPGained(client, xp, channel)
{
	Call_StartForward(g_hForwardXPGained);
	Call_PushCell(client);
	Call_PushCell(xp);
	Call_PushCell(channel);
	Call_Finish();
}

//public lm_OnCoreLoad() {};
public Forward_CoreLoad()
{
	Call_StartForward(g_hForwardCoreLoad);
	Call_Finish();
}

//public lm_OnClientLoad(iClient) {};
public Forward_ClientLoad(client, lvl, xp, tnl)
{
	Call_StartForward(g_hForwardClientLoad);
	Call_PushCell(client);
	Call_PushCell(lvl);
	Call_PushCell(xp);
	Call_PushCell(tnl);
	Call_Finish();
}