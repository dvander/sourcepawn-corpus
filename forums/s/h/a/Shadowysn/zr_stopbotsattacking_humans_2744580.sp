#define PLUGIN_NAME "[CS:S ZR] Bots Don't Attack Humans"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Stops bots from attacking humans."
#define PLUGIN_VERSION "1.0.2"
#define PLUGIN_URL ""
#define PLUGIN_NAME_SHORT "Bots Don't Attack Humans"
#define PLUGIN_NAME_TECH "bots_stop_attack_humans"

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <zombiereloaded>

#pragma semicolon 1
#pragma newdecls required

#define TEAM_T 2
#define TEAM_CT 3

#define GAMEDATA "zr_stopbotsattacking_humans"

Handle hConf = null;
// CBaseEntity::InSameTeam
#define NAME_InSameTeam "CBaseEntity::InSameTeam"
static Handle hDHookInSameTeam = null;

// CCSBot::OnAudibleEvent
#define NAME_OnAudibleEvent "CCSBot::OnAudibleEvent"
static Handle hDHookOnAudibleEvent = null;

// CCSBot::OnPlayerRadio
#define NAME_OnPlayerRadio "CCSBot::OnPlayerRadio"
//static Handle hDHookOnPlayerRadio = null;

// CCSBot::OnPlayerDeath
#define NAME_OnPlayerDeath "CCSBot::OnPlayerDeath"
//static Handle hDHookOnPlayerDeath = null;

// CCSBot::SetBotEnemy
#define NAME_SetBotEnemy "CCSBot::SetBotEnemy"
//static Handle hDHookSetBotEnemy = null;
static Handle sdkSetBotEnemy = null;

#define SIG_InSameTeam_LINUX			"_ZNK11CBaseEntity10InSameTeamEPKS_"
#define SIG_InSameTeam_WINDOWS			"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x57\\x8B\\xF9\\x85\\xC0\\x75\\x2A\\x32\\xC0\\x5F\\x5D\\xC2"
#define SIG_InSameTeam_WINDOWS64		"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x48\\x8B\\xF9\\x48\\x85\\xD2\\x75\\x08\\x32\\xC0\\x48\\x83"
#define SIG_OnAudibleEvent_LINUX		"_ZN6CCSBot14OnAudibleEventEP10IGameEventP11CBasePlayerf12PriorityTypebbPK6Vector"
#define SIG_OnAudibleEvent_WINDOWS		"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x56\\x8B\\x2A\\x2A\\x57\\x8B\\xF9\\x85\\xF6\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x06\\x8B\\xCE\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\xFF\\xD0\\x84\\xC0\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x06\\x8B\\xCE\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\xFF\\xD0\\x84\\xC0\\x2A\\x2A\\x2A\\x2A\\x00\\x00"
#define SIG_OnAudibleEvent_WINDOWS64	"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x00\\x00\\x56\\x57\\x41\\x56\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x49\\x8B\\x00\\x48\\x8B\\xF9"
#define SIG_OnPlayerRadio_LINUX		"_ZN6CCSBot13OnPlayerRadioEP10IGameEvent"
#define SIG_OnPlayerRadio_WINDOWS		"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\xFF\\xD0\\x84\\xC0\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x53\\x56\\x2A\\x2A\\x8B\\x01\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x50"
#define SIG_OnPlayerRadio_WINDOWS64		"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x48\\x8B\\x01\\x4C\\x8B\\xF2\\x48\\x8B\\xF1\\x2A\\x2A\\x2A\\x2A\\x00\\x00\\x84\\xC0\\x2A\\x2A\\x2A\\x2A\\x00\\x00\\x49\\x8B\\x06"
#define SIG_OnPlayerDeath_LINUX		"_ZN6CCSBot13OnPlayerDeathEP10IGameEvent"
#define SIG_OnPlayerDeath_WINDOWS		"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x07\\x2A\\x2A\\x2A\\x2A\\x00\\x00\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x53\\x2A\\x2A\\x2A\\x8B\\xCB\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x03"
#define SIG_OnPlayerDeath_WINDOWS64		"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x00\\x00\\x84\\xC0\\x2A\\x2A\\x2A\\x2A\\x00\\x00\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x00\\x00\\x49\\x8B\\xCE"
#define SIG_SetBotEnemy_LINUX			"_ZN6CCSBot11SetBotEnemyEP9CCSPlayer"
#define SIG_SetBotEnemy_WINDOWS		"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x00\\x00\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x00\\x00\\x2A\\x2A\\x2A\\x2A\\x2A\\x0F\\xB7\\xCA\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x00\\x2A\\x2A\\x33\\xC0\\x2A\\x2A\\x2A\\x3B\\xC7"
#define SIG_SetBotEnemy_WINDOWS64		"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x00\\x00\\x2A\\x2A\\xFA\\x2A\\x2A\\xD9\\x45\\x85\\xC0\\x2A\\x2A\\x2A\\x2A\\x2A\\x00\\x00\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x41\\x0F\\xB7\\xC0"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_CSS)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Counter-Strike: Source.");
	return APLRes_SilentFailure;
}

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

bool isDHooksToggled = false;

public void OnPluginStart()
{
	char version_str[64];
	Format(version_str, sizeof(version_str), "%s version.", PLUGIN_NAME_SHORT);
	char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, version_str, 0|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		version_cvar.SetString(PLUGIN_VERSION);
	
	HookEvent("round_start", round_start, EventHookMode_PostNoCopy);
	//HookEvent("round_end", round_start, EventHookMode_PostNoCopy);
	
	GetGamedata();
}

void round_start(Event event, const char[] name, bool dontBroadcast)
{
	if (!isDHooksToggled)
	{
		PrintToServer("[ZR Bots Don't Attack Humans] Bots are no longer attacking.");
		isDHooksToggled = true;
		ToggleDHooks(true);
	}
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	if (isDHooksToggled)
	{
		PrintToServer("[ZR Bots Don't Attack Humans] Bots are now attacking.");
		isDHooksToggled = false;
		ToggleDHooks(false);
		
		if (sdkSetBotEnemy != null)
		{
			if (client != 0 && IsFakeClient(client)) SDKCall(sdkSetBotEnemy, client, GetNearestEnemy(client));
			if (attacker != 0 && IsFakeClient(attacker)) SDKCall(sdkSetBotEnemy, attacker, GetNearestEnemy(attacker));
		}
	}
}

int GetNearestEnemy(int client)
{
	float origin[3];
	GetClientAbsOrigin(client, origin);
	
	float distance = -1.0;
	int retrievedEnemy = 0;
	int team = GetClientTeam(client);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i, true, true) || !IsPlayerAlive(i)) continue;
		if (GetClientTeam(i) == team) continue;
		
		float enemyOrigin[3];
		GetClientAbsOrigin(i, enemyOrigin);
		
		float newDist = GetVectorDistance(origin, enemyOrigin, true);
		if (distance == -1.0 || newDist < distance)
		{
			distance = newDist;
			retrievedEnemy = i;
		}
	}
	return retrievedEnemy;
}

/*public void OnAllPluginsLoaded()
{
	if (FindConVar("zr_version") == null)
	{
		SetFailState("Zombie:Reloaded is not running on this server");
	}
}*/

public MRESReturn InSameTeam_Pre(int client, Handle hReturn, Handle hParams)
{
	//if (DHookGetParam(hParams, 0) < 1) return MRES_Ignored;
	//int other_cl = DHookGetParam(hParams, 1);
	//if (!hasRoundStarted)
	//{
		DHookSetReturn(hReturn, true);
		return MRES_Supercede;
	//}
	//return MRES_Ignored;
}

public MRESReturn IsOtherEnemy_Pre(int client, Handle hReturn, Handle hParams)
{
	//if (DHookGetParam(hParams, 0) < 1) return MRES_Ignored;
	//int other_cl = DHookGetParam(hParams, 1);
	//if (!hasRoundStarted)
	//{
		DHookSetReturn(hReturn, false);
		return MRES_Supercede;
	//}
	//return MRES_Ignored;
}

MRESReturn OnAudibleEvent_Pre(int client, Handle hParams)
{
	//if (DHookGetParam(hParams, 0) < 2) return MRES_Ignored;
	//int other_cl = DHookGetParam(hParams, 2);
	//if (!hasRoundStarted)
	//{
		return MRES_Supercede;
	//}
	//return MRES_Ignored;
}

/*public MRESReturn OnPlayerRadio_Pre(int client, Handle hParams)
{
	int other_cl = GetClientOfUserId(DHookGetParam(hParams, 1));
	if (other_cl != 0 && IsPlayerAlive(other_cl) && 
	client != 0 && IsPlayerAlive(client) && 
	(ZR_IsClientHuman(client) && ZR_IsClientHuman(other_cl)))
	{
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public MRESReturn OnPlayerDeath_Pre(int client, Handle hParams)
{
	int other_cl = GetClientOfUserId(DHookGetParam(hParams, 1));
	if (other_cl != 0 && IsPlayerAlive(other_cl) && 
	client != 0 && IsPlayerAlive(client) && 
	(ZR_IsClientHuman(client) && ZR_IsClientHuman(other_cl)))
	{
		return MRES_Supercede;
	}
	return MRES_Ignored;
}*/

stock bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }

stock bool IsValidClient(int client, bool replaycheck = true, bool isLoop = false)
{
	if ((isLoop || client > 0 && client <= MaxClients) && IsClientInGame(client))
	{
		//if (HasEntProp(client, Prop_Send, "m_bIsCoaching")) // TF2, CSGO?
		//	if (view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsCoaching"))) return false;
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}

void GetGamedata()
{
	char filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, sizeof(filePath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(filePath) )
	{
		hConf = LoadGameConfigFile(GAMEDATA); // For some reason this doesn't return null even for invalid files, so check they exist first.
	}
	else
	{
		PrintToServer("[SM] %s plugin unable to get %s.txt gamedata file. Generating...", PLUGIN_NAME_SHORT, GAMEDATA);
		
		Handle fileHandle = OpenFile(filePath, "a+");
		if (fileHandle == null)
		{ SetFailState("[SM] Couldn't generate gamedata file!"); }
		
	//	for (int i = 0; i <= 2; i++)
	//	{
	//		WriteFileLine(fileHandle, "\"Games\"");
	//		WriteFileLine(fileHandle, "{");
	//		switch (i)
	//		{
	//			case GAME_CSS: WriteFileLine(fileHandle, "	\"cstrike\"");
	//			case GAME_CSGO: WriteFileLine(fileHandle, "	\"csgo\"");
	//		}
	//		WriteFileLine(fileHandle, "	{");
	//		WriteFileLine(fileHandle, "		\"Signatures\"");
	//		WriteFileLine(fileHandle, "		{");
	//		for (int j = 0; j <= 3; j++)
	//		{
	//			switch (j)
	//			{
	//				case 0: WriteFileLine(fileHandle, "			\"%s\"", NAME_InSameTeam);
	//				case 1: WriteFileLine(fileHandle, "			\"%s\"", NAME_OnAudibleEvent);
	//				case 2: WriteFileLine(fileHandle, "			\"%s\"", NAME_OnPlayerRadio);
	//				case 3: WriteFileLine(fileHandle, "			\"%s\"", NAME_OnPlayerDeath);
	//			}
	//			WriteFileLine(fileHandle, "			{");
	//			WriteFileLine(fileHandle, "				\"library\"	\"server\"");
	//			char temp_str[64];
	//			switch (j)
	//			{
	//				temp_str
	//			}
	//			WriteFileLine(fileHandle, "			}");
	//		}
	//		WriteFileLine(fileHandle, "		}");
	//		WriteFileLine(fileHandle, "	}");
	//		WriteFileLine(fileHandle, "}");
	//	}
		
		WriteFileLine(fileHandle, "\"Games\"");
		WriteFileLine(fileHandle, "{");
		WriteFileLine(fileHandle, "	\"cstrike\"");
		WriteFileLine(fileHandle, "	{");
		WriteFileLine(fileHandle, "		\"Signatures\"");
		WriteFileLine(fileHandle, "		{");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_InSameTeam);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"",		SIG_InSameTeam_LINUX);
		WriteFileLine(fileHandle, "				\"linux64\"	\"%s\"",		SIG_InSameTeam_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"",		SIG_InSameTeam_WINDOWS);
		WriteFileLine(fileHandle, "				\"windows64\"	\"%s\"",	SIG_InSameTeam_WINDOWS64);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_OnAudibleEvent);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"",		SIG_OnAudibleEvent_LINUX);
		WriteFileLine(fileHandle, "				\"linux64\"	\"%s\"",		SIG_OnAudibleEvent_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"",		SIG_OnAudibleEvent_WINDOWS);
		WriteFileLine(fileHandle, "				\"windows64\"	\"%s\"",	SIG_OnAudibleEvent_WINDOWS64);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_OnPlayerRadio);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"",		SIG_OnPlayerRadio_LINUX);
		WriteFileLine(fileHandle, "				\"linux64\"	\"%s\"",		SIG_OnPlayerRadio_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"",		SIG_OnPlayerRadio_WINDOWS);
		WriteFileLine(fileHandle, "				\"windows64\"	\"%s\"",	SIG_OnPlayerRadio_WINDOWS64);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_OnPlayerDeath);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"",		SIG_OnPlayerDeath_LINUX);
		WriteFileLine(fileHandle, "				\"linux64\"	\"%s\"",		SIG_OnPlayerDeath_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"",		SIG_OnPlayerDeath_WINDOWS);
		WriteFileLine(fileHandle, "				\"windows64\"	\"%s\"",	SIG_OnPlayerDeath_WINDOWS64);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_SetBotEnemy);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"",		SIG_SetBotEnemy_LINUX);
		WriteFileLine(fileHandle, "				\"linux64\"	\"%s\"",		SIG_SetBotEnemy_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"",		SIG_SetBotEnemy_WINDOWS);
		WriteFileLine(fileHandle, "				\"windows64\"	\"%s\"",	SIG_SetBotEnemy_WINDOWS64);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "		}");
		WriteFileLine(fileHandle, "	}");
		WriteFileLine(fileHandle, "}");
		
		CloseHandle(fileHandle);
		hConf = LoadGameConfigFile(GAMEDATA);
		if (hConf == null)
		{ SetFailState("[SM] Failed to load auto-generated gamedata file!"); }
		
		PrintToServer("[SM] %s successfully generated %s.txt gamedata file!", PLUGIN_NAME_SHORT, GAMEDATA);
	}
	PrepDHooks();
}

void ToggleDHooks(bool toggle)
{
	if (toggle == true)
	{
		DHookEnableDetour(hDHookInSameTeam, false, InSameTeam_Pre);
		DHookEnableDetour(hDHookOnAudibleEvent, false, OnAudibleEvent_Pre);
		//DHookEnableDetour(hDHookOnPlayerRadio, false, OnPlayerRadio_Pre);
		//DHookEnableDetour(hDHookOnPlayerDeath, false, OnPlayerDeath_Pre);
	}
	else
	{
		DHookDisableDetour(hDHookInSameTeam, false, InSameTeam_Pre);
		DHookDisableDetour(hDHookOnAudibleEvent, false, OnAudibleEvent_Pre);
		//DHookDisableDetour(hDHookOnPlayerRadio, false, OnPlayerRadio_Pre);
		//DHookDisableDetour(hDHookOnPlayerDeath, false, OnPlayerDeath_Pre);
	}
}

void PrepDHooks()
{
	hConf = LoadGameConfigFile(GAMEDATA);
	if (hConf == null)
	{ SetFailState("[SM] Failed to load gamedata file!"); }
	
	hDHookInSameTeam = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	DHookSetFromConf(hDHookInSameTeam, hConf, SDKConf_Signature, NAME_InSameTeam);
	DHookAddParam(hDHookInSameTeam, HookParamType_CBaseEntity);
	
	hDHookOnAudibleEvent = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	DHookSetFromConf(hDHookOnAudibleEvent, hConf, SDKConf_Signature, NAME_OnAudibleEvent);
	DHookAddParam(hDHookOnAudibleEvent, HookParamType_Int);
	DHookAddParam(hDHookOnAudibleEvent, HookParamType_CBaseEntity);
	DHookAddParam(hDHookOnAudibleEvent, HookParamType_Int);
	DHookAddParam(hDHookOnAudibleEvent, HookParamType_Int);
	DHookAddParam(hDHookOnAudibleEvent, HookParamType_Int);
	DHookAddParam(hDHookOnAudibleEvent, HookParamType_Int);
	DHookAddParam(hDHookOnAudibleEvent, HookParamType_Int);
	
	/*hDHookOnPlayerRadio = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	DHookSetFromConf(hDHookOnPlayerRadio, hConf, SDKConf_Signature, NAME_OnPlayerRadio);
	DHookAddParam(hDHookOnPlayerRadio, HookParamType_Int);
	
	hDHookOnPlayerDeath = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	DHookSetFromConf(hDHookOnPlayerDeath, hConf, SDKConf_Signature, NAME_OnPlayerDeath);
	DHookAddParam(hDHookOnPlayerDeath, HookParamType_Int);*/
	
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, NAME_SetBotEnemy))
	{ PrintToServer("[%s] WARNING: Unable to find %s signature in gamedata file.", PLUGIN_NAME_SHORT, NAME_SetBotEnemy); }
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	sdkSetBotEnemy = EndPrepSDKCall();
	if (sdkSetBotEnemy == null)
	{ PrintToServer("[%s] WARNING: Cannot initialize %s SDKCall, signature is broken.", PLUGIN_NAME_SHORT, NAME_SetBotEnemy); }
	
	delete hConf;
}