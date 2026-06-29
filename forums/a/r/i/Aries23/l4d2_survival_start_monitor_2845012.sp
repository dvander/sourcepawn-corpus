#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
	name = "[L4D2] Survival Start Monitor",
	author = "NTLDR",
	description = "Monitors, logs, and announces who starts the survival round",
	version = "1.0",
	url = ""
};

ConVar g_hCvarNotifyType;
ConVar g_hCvarAdminsOnly;
ConVar g_hCvarLog;
ConVar g_hCvarTrackBots;
ConVar g_hCvarDoorMaps;
ConVar g_hCvarGameMode;

bool g_bIsSurvivalMode;
bool g_bSurvivalStarted;
bool g_bAllowDoorOnMap;
bool g_bHasActivator;

char g_sActivatorName[MAX_NAME_LENGTH];
char g_sActivatorSteamID[64];
char g_sActivatorSteamID32[32];

int   g_iLastStartPropAttacker;
float g_flLastPropDamageTime;
char  g_sLastPropAttackerName[MAX_NAME_LENGTH];
char  g_sLastPropAttackerSteamID[64];
char  g_sLastPropAttackerSteamID32[32];

int   g_iLastDoorUser;
float g_flLastDoorTime;
char  g_sLastDoorUserName[MAX_NAME_LENGTH];
char  g_sLastDoorUserSteamID[64];
char  g_sLastDoorUserSteamID32[32];

StringMap g_hProjectileOwner;

public void OnPluginStart()
{
	LoadTranslations("l4d2_survival_start_monitor.phrases");

	HookEvent("round_start",            Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end",              Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("survival_round_start",   Event_SurvivalRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_use",             Event_PlayerUse, EventHookMode_Post);
	HookEvent("break_prop",             Event_BreakProp, EventHookMode_Post);

	HookEntityOutput("func_button", "OnPressed",                    Button_Pressed);
	HookEntityOutput("func_physical_button", "OnPressed",           Button_Pressed);
	HookEntityOutput("func_rot_button", "OnPressed",                Button_Pressed);
	HookEntityOutput("func_button_timed", "OnTimeUp",               Button_Pressed);
	HookEntityOutput("point_script_use_target", "OnUseFinished",    Button_Pressed);
	HookEntityOutput("prop_door_rotating", "OnOpen",                Door_Opened);
	HookEntityOutput("prop_door_rotating_checkpoint", "OnOpen",     Door_Opened);
	HookEntityOutput("func_door", "OnOpen",                         Door_Opened);
	HookEntityOutput("func_door_rotating", "OnOpen",                Door_Opened);

	g_hCvarNotifyType  = CreateConVar("l4d2_ssm_notify_type",           "1",   "Notification type\n1 = Chatbox\n2 = Hint", 0, true, 1.0, true, 2.0);
	g_hCvarAdminsOnly  = CreateConVar("l4d2_ssm_notify_admins_only",    "0",   "Show notification to:\n0 = All players\n1 = Admins only", 0, true, 0.0, true, 1.0);
	g_hCvarLog         = CreateConVar("l4d2_ssm_record_log",            "1",   "Record start timer to log?\n0 = No\n1 = Yes", 0, true, 0.0, true, 1.0);
	g_hCvarTrackBots   = CreateConVar("l4d2_ssm_track_bots",            "0",   "Track survivor bots as survival starters?\n0 = No\n1 = Yes", 0, true, 0.0, true, 1.0);
	g_hCvarDoorMaps    = CreateConVar("l4d2_ssm_trigger_door_maps",     "c1m2_streets,c12m2_traintunnel", "Comma-separated list of maps where door opening triggers survival.", 0);
	
	g_hCvarGameMode 	= FindConVar("mp_gamemode");
	if (g_hCvarGameMode != null)
	{
		g_hCvarGameMode.AddChangeHook(OnConVarChanged);
	}
	
	g_hCvarDoorMaps.AddChangeHook(OnConVarChanged);
	
	AutoExecConfig(true, "l4d2_survival_start_monitor");
	
	CheckGameMode();
	CheckDoorAllowedMap();
	HookExistingProps();
	
	g_hProjectileOwner = new StringMap();
	
	char sProjectiles[][] = { 
		"grenade_launcher_projectile", 
		"pipe_bomb_projectile", 
		"molotov_projectile" 
	};
	
	for (int i = 0; i < sizeof(sProjectiles); i++)
	{
		int ent = -1;
		while ((ent = FindEntityByClassname(ent, sProjectiles[i])) != -1)
		{
			if (ent > 0)
			{
				int ref = EntIndexToEntRef(ent);
				char sKey[16];
				IntToString(ref, sKey, sizeof(sKey));
				g_hProjectileOwner.SetValue(sKey, GetThrowerOrOwner(ent));
			}
		}
	}
}

public void OnPluginEnd()
{
	if (g_hProjectileOwner != null)
	{
		delete g_hProjectileOwner;
		g_hProjectileOwner = null;
	}
}

public void OnMapStart()
{
	ResetTrackingVariables();
	CheckGameMode();
	CheckDoorAllowedMap();
	HookExistingProps();
}

public void OnConfigsExecuted()
{
	CheckGameMode();
	CheckDoorAllowedMap();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CheckGameMode();
	CheckDoorAllowedMap();
}

void CheckGameMode()
{
	g_bIsSurvivalMode = false;
	
	if (g_hCvarGameMode != null)
	{
		char sGameMode[32];
		g_hCvarGameMode.GetString(sGameMode, sizeof(sGameMode));
		
		if (StrContains(sGameMode, "survival", false) != -1)
		{
			g_bIsSurvivalMode = true;
		}
	}
}

void CheckDoorAllowedMap()
{
	g_bAllowDoorOnMap = false;
	
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	
	char sDoorMaps[512];
	g_hCvarDoorMaps.GetString(sDoorMaps, sizeof(sDoorMaps));
	
	char sMapList[32][64];
	int iCount = ExplodeString(sDoorMaps, ",", sMapList, sizeof(sMapList), sizeof(sMapList[]));
	
	for (int i = 0; i < iCount; i++)
	{
		TrimString(sMapList[i]);
		
		if (sMapList[i][0] != '\0' && StrContains(sMap, sMapList[i], false) != -1)
		{
			g_bAllowDoorOnMap = true;
			break;
		}
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CheckGameMode();
	ResetTrackingVariables();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetTrackingVariables();
}

void ResetTrackingVariables()
{
	g_bSurvivalStarted = false;
	g_bHasActivator = false;
	
	g_sActivatorName[0] = '\0';
	g_sActivatorSteamID[0] = '\0';
	g_sActivatorSteamID32[0] = '\0';
	
	g_iLastStartPropAttacker = 0;
	g_flLastPropDamageTime = 0.0;
	g_sLastPropAttackerName[0] = '\0';
	g_sLastPropAttackerSteamID[0] = '\0';
	g_sLastPropAttackerSteamID32[0] = '\0';
	
	g_iLastDoorUser = 0;
	g_flLastDoorTime = 0.0;
	g_sLastDoorUserName[0] = '\0';
	g_sLastDoorUserSteamID[0] = '\0';
	g_sLastDoorUserSteamID32[0] = '\0'; 
	
	if (g_hProjectileOwner != null)
	{
		g_hProjectileOwner.Clear();
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (g_bSurvivalStarted) 
		return;
		
	if (entity <= 0) 
		return;
		
	if (strncmp(classname, "prop_physics", 12) == 0 || strcmp(classname, "physics_prop") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnPropSpawnPost);
	}
	else if (strcmp(classname, "pipe_bomb_projectile") == 0 || 
			 strcmp(classname, "grenade_launcher_projectile") == 0 || 
			 strcmp(classname, "molotov_projectile") == 0)
	{
		RequestFrame(OnProjectileSpawnFrameDelay, EntIndexToEntRef(entity));
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity > 0 && g_hProjectileOwner != null)
	{
		int ref = EntIndexToEntRef(entity);
		char sKey[16];
		IntToString(ref, sKey, sizeof(sKey));
		g_hProjectileOwner.Remove(sKey);
	}
}

public void OnPropSpawnPost(int entity)
{
	RequestFrame(OnPropSpawnPostFrameDelay, EntIndexToEntRef(entity));
}

public void OnPropSpawnPostFrameDelay(any entRef)
{
	int entity = EntRefToEntIndex(entRef);
	if (entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity)) 
		return;
		
	HookPropIfMatch(entity);
}

public void OnProjectileSpawnFrameDelay(any entRef)
{
	int entity = EntRefToEntIndex(entRef);
	if (entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity)) 
		return;
		
	int owner = GetThrowerOrOwner(entity);
	if (owner > 0 && g_hProjectileOwner != null)
	{
		int ref = entRef;
		char sKey[16];
		IntToString(ref, sKey, sizeof(sKey));
		g_hProjectileOwner.SetValue(sKey, owner);
	}
}

void HookExistingProps()
{
	char sClasses[][] = { 
		"prop_physics", 
		"prop_physics_override", 
		"prop_physics_multiplayer", 
		"physics_prop" 
	};
	
	for (int i = 0; i < sizeof(sClasses); i++)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, sClasses[i])) != -1)
		{
			HookPropIfMatch(entity);
		}
	}
}

void HookPropIfMatch(int entity)
{
	if (!IsValidEntity(entity)) 
		return;
		
	char sTargetname[128], sModel[256];
	GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
	GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	bool bHook = false;
	
	if (StrContains(sTargetname, "barricade_gas_can", false) != -1 ||
		StrContains(sTargetname, "gas_pump", false) != -1 || 
		StrContains(sTargetname, "gaspump", false) != -1 ||
		StrContains(sModel,      "gas_pump", false) != -1)
	{
		bHook = true;
	}
	
	if (bHook)
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnStartPropDamage);
	}
}

public Action OnStartPropDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_bIsSurvivalMode || g_bSurvivalStarted || g_bHasActivator) 
		return Plugin_Continue;
		
	int client = GetActualClient(attacker, inflictor);
	if (IsValidSurvivor(client))
	{
		g_iLastStartPropAttacker = client;
		CacheClientData(client, g_sLastPropAttackerName, sizeof(g_sLastPropAttackerName), g_sLastPropAttackerSteamID, sizeof(g_sLastPropAttackerSteamID), g_sLastPropAttackerSteamID32, sizeof(g_sLastPropAttackerSteamID32));
		g_flLastPropDamageTime = GetGameTime();
	}
	
	return Plugin_Continue;
}

int GetActualClient(int attacker, int inflictor)
{
	int owner = 0;
	char sKey[16];
	
	if (g_hProjectileOwner != null)
	{
		if (attacker > 0 && IsValidEntity(attacker))
		{
			int attRef = EntIndexToEntRef(attacker);
			IntToString(attRef, sKey, sizeof(sKey));
			
			if (g_hProjectileOwner.GetValue(sKey, owner) && owner != 0)
				return owner;
		}
		
		if (inflictor > 0 && IsValidEntity(inflictor))
		{
			int infRef = EntIndexToEntRef(inflictor);
			IntToString(infRef, sKey, sizeof(sKey));
			
			if (g_hProjectileOwner.GetValue(sKey, owner) && owner != 0)
				return owner;
		}
	}
	
	if (IsValidSurvivor(attacker)) 
		return attacker;
		
	owner = GetThrowerOrOwner(attacker);
	if (owner > 0) 
		return owner;
		
	owner = GetThrowerOrOwner(inflictor);
	if (owner > 0) 
		return owner;
		
	return 0;
}

int GetThrowerOrOwner(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity)) 
		return 0;
		
	int owner = -1;
	
	if (HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
	{
		owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if (IsValidSurvivor(owner)) 
			return owner;
	}
	
	if (HasEntProp(entity, Prop_Send, "m_hThrower"))
	{
		owner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
		if (IsValidSurvivor(owner)) 
			return owner;
	}
	else if (HasEntProp(entity, Prop_Data, "m_hThrower"))
	{
		owner = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		if (IsValidSurvivor(owner)) 
			return owner;
	}
	
	return 0;
}

void CacheClientData(int client, char[] name, int nameLen, char[] steam64, int steam64Len, char[] steam32, int steam32Len)
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client))
    {
        strcopy(name, nameLen, "Disconnected Player");
        strcopy(steam64, steam64Len, "Unknown_SteamID64");
        strcopy(steam32, steam32Len, "Unknown_SteamID32");
        return;
    }
    
    GetClientName(client, name, nameLen);
    
    if (IsFakeClient(client))
    {
        strcopy(steam64, steam64Len, "SURVIVOR_BOT");
        strcopy(steam32, steam32Len, "SURVIVOR_BOT");
        return;
    }
    
    if (!GetClientAuthId(client, AuthId_SteamID64, steam64, steam64Len))
    {
        strcopy(steam64, steam64Len, "Unknown_SteamID64");
    }
    
    if (!GetClientAuthId(client, AuthId_Steam2, steam32, steam32Len))
    {
        strcopy(steam32, steam32Len, "Unknown_SteamID32");
    }
}

void RecordFirstActivator(int client)
{
	g_bHasActivator = true;
	CacheClientData(client, g_sActivatorName, sizeof(g_sActivatorName), g_sActivatorSteamID, sizeof(g_sActivatorSteamID), g_sActivatorSteamID32, sizeof(g_sActivatorSteamID32));
}

public void Button_Pressed(const char[] output, int caller, int activator, float delay)
{
	if (!g_bIsSurvivalMode || g_bSurvivalStarted || g_bHasActivator) 
		return;
		
	if (!IsValidSurvivor(activator) || !IsValidEnt(caller)) 
		return;
		
	RecordFirstActivator(activator);
}

bool IsValidTriggerDoor(int entity)
{
	if (!IsValidEntity(entity))
		return false;
		
	char sTargetname[128];
	GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
	
	if (sTargetname[0] == '\0')
		return false;
		
	return true;
}

public void Door_Opened(const char[] output, int caller, int activator, float delay)
{
	if (!g_bIsSurvivalMode || g_bSurvivalStarted || g_bHasActivator || !g_bAllowDoorOnMap) 
		return;
		
	if (IsValidSurvivor(activator) && IsValidTriggerDoor(caller))
	{
		float flCurrentTime = GetGameTime();
		
		if (g_flLastDoorTime != 0.0 && (flCurrentTime - g_flLastDoorTime <= 5.0))
		{
			return; 
		}
		
		g_iLastDoorUser = activator;
		CacheClientData(activator, g_sLastDoorUserName, sizeof(g_sLastDoorUserName), g_sLastDoorUserSteamID, sizeof(g_sLastDoorUserSteamID), g_sLastDoorUserSteamID32, sizeof(g_sLastDoorUserSteamID32));
		g_flLastDoorTime = flCurrentTime;
	}
}

public void Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bIsSurvivalMode || g_bSurvivalStarted || g_bHasActivator || !g_bAllowDoorOnMap) 
		return;
		
	int client = GetClientOfUserId(event.GetInt("userid"));
	int entity = event.GetInt("targetid");
	
	if (!IsValidSurvivor(client) || !IsValidEnt(entity)) 
		return;
		
	char sClassname[64];
	GetEntityClassname(entity, sClassname, sizeof(sClassname));
	
	if (strncmp(sClassname, "prop_door", 9) == 0 || strncmp(sClassname, "func_door", 9) == 0)
	{
		if (IsValidTriggerDoor(entity))
		{
			float flCurrentTime = GetGameTime();
			
			if (g_flLastDoorTime != 0.0 && (flCurrentTime - g_flLastDoorTime <= 5.0))
			{
				return;
			}
			
			g_iLastDoorUser = client;
			CacheClientData(client, g_sLastDoorUserName, sizeof(g_sLastDoorUserName), g_sLastDoorUserSteamID, sizeof(g_sLastDoorUserSteamID), g_sLastDoorUserSteamID32, sizeof(g_sLastDoorUserSteamID32));
			g_flLastDoorTime = flCurrentTime;
		}
	}
}

public void Event_BreakProp(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bIsSurvivalMode || g_bSurvivalStarted || g_bHasActivator) 
		return;
		
	int entity = event.GetInt("entindex");
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!IsValidEnt(entity)) 
		return;
		
	char sTargetname[128], sModel[256];
	GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
	GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	bool bIsStartTriggerProp = false;
	
	if (StrContains(sTargetname, "barricade_gas_can", false) != -1 ||
		StrContains(sTargetname, "gas_pump", false) != -1 || 
		StrContains(sTargetname, "gaspump", false) != -1 ||
		StrContains(sModel,      "gas_pump", false) != -1)
	{
		bIsStartTriggerProp = true;
	}
	
	if (bIsStartTriggerProp)
	{
		if (IsValidSurvivor(client))
		{
			RecordFirstActivator(client);
			return;
		}
		
		if (g_iLastStartPropAttacker != 0)
		{
			g_bHasActivator = true;
			strcopy(g_sActivatorName, sizeof(g_sActivatorName), g_sLastPropAttackerName);
			strcopy(g_sActivatorSteamID, sizeof(g_sActivatorSteamID), g_sLastPropAttackerSteamID);
			strcopy(g_sActivatorSteamID32, sizeof(g_sActivatorSteamID32), g_sLastPropAttackerSteamID32);
			return;
		}
	}
}

public void Event_SurvivalRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bIsSurvivalMode || g_bSurvivalStarted) 
		return;
		
	g_bSurvivalStarted = true;
	
	if (!g_bHasActivator)
	{
		float flCurrentTime = GetGameTime();
		
		if (g_iLastStartPropAttacker != 0 && (flCurrentTime - g_flLastPropDamageTime <= 5.0))
		{
			g_bHasActivator = true;
			strcopy(g_sActivatorName, sizeof(g_sActivatorName), g_sLastPropAttackerName);
			strcopy(g_sActivatorSteamID, sizeof(g_sActivatorSteamID), g_sLastPropAttackerSteamID);
			strcopy(g_sActivatorSteamID32, sizeof(g_sActivatorSteamID32), g_sLastPropAttackerSteamID32);
		}
		else if (g_iLastDoorUser != 0 && (flCurrentTime - g_flLastDoorTime <= 5.0))
		{
			g_bHasActivator = true;
			strcopy(g_sActivatorName, sizeof(g_sActivatorName), g_sLastDoorUserName);
			strcopy(g_sActivatorSteamID, sizeof(g_sActivatorSteamID), g_sLastDoorUserSteamID);
			strcopy(g_sActivatorSteamID32, sizeof(g_sActivatorSteamID32), g_sLastDoorUserSteamID32);
		}
	}
	
	if (g_bHasActivator)
	{
		SendNotification(g_hCvarNotifyType.IntValue, g_hCvarAdminsOnly.BoolValue);
		
		if (g_hCvarLog.BoolValue)
		{
			char sTimeStr[16];
			FormatTime(sTimeStr, sizeof(sTimeStr), "%Y_%m", GetTime());
			
			char sLogPath[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, sLogPath, sizeof(sLogPath), "logs/l4d2_survival_timer_monitor_%s.log", sTimeStr);
			
			char sMapName[64];
			GetCurrentMap(sMapName, sizeof(sMapName));
			
			LogToFile(sLogPath, "[Map: %s] %s (64: %s | 32: %s) started the Survival Round timer!", sMapName, g_sActivatorName, g_sActivatorSteamID, g_sActivatorSteamID32);
		}
	}
}

void SendNotification(int showType, bool onlyAdmins)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
			
		AdminId admin = GetUserAdmin(i);
		bool isAdmin = (admin != INVALID_ADMIN_ID);
		
		if (onlyAdmins && !isAdmin)
			continue;	
			
		if (showType == 1)
		{
			char sBuffer[254];
			Format(sBuffer, sizeof(sBuffer), "%T", "StartChat", i, g_sActivatorName);
			ReplaceColors(sBuffer, sizeof(sBuffer));
			PrintToChat(i, "%s", sBuffer);
		}
		else
		{
			PrintHintText(i, "%T", "StartHint", i, g_sActivatorName);
		}
	}
}

void ReplaceColors(char[] message, int maxlen)
{
	ReplaceString(message, maxlen, "{default}", 	"\x01", false);
	ReplaceString(message, maxlen, "{lightgreen}", 	"\x03", false);
	ReplaceString(message, maxlen, "{orange}", 		"\x04", false);
	ReplaceString(message, maxlen, "{green}", 		"\x05", false);
}

bool IsValidSurvivor(int client)
{
	if (client >= 1 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		if (!g_hCvarTrackBots.BoolValue && IsFakeClient(client))
		{
			return false;
		}
		return true;
	}
	return false;
}

bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity));
}