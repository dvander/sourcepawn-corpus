#define PLUGIN_NAME "[CS:S ZR] Bots Don't Attack Humans"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Stops bots from attacking humans."
#define PLUGIN_VERSION "1.0.1"
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

#define GAME_CSS 0
#define GAME_CSGO 1
static int gameVar = GAME_CSS;

#define GAMEDATA "zr_stopbotsattacking_humans"

Handle hConf = null;
// CBaseEntity::InSameTeam
#define NAME_InSameTeam "CBaseEntity::InSameTeam"
static Handle hDHookInSameTeam = null;

#define SIG_InSameTeam_LINUX "@_ZNK11CBaseEntity10InSameTeamEPS_"
#define SIG_InSameTeam_WINDOWS "\\x55\\x8B\\xEC\\x8B\\x45\\x08\\x57\\x8B\\xF9\\x85\\xC0\\x75\\x2A\\x32\\xC0\\x5F\\x5D\\xC2\\x04\\x00"

#define SIG_CSGOInSameTeam_LINUX "\\x55\\x31\\xC0\\x89\\xE5\\x53\\x83\\xEC\\x14\\x8B\\x55\\x0C\\x85\\xD2"


// CCSPlayer::IsOtherEnemy (CS:GO Only)
#define NAME_IsOtherEnemy "CCSPlayer::IsOtherEnemy"
static Handle hDHookIsOtherEnemy = null;

#define SIG_CSGOIsOtherEnemy_LINUX "\\x55\\x31\\xC0\\x89\\xE5\\x56\\x53\\x83\\xEC\\x10\\x8B\\x5D\\x0C\\x8B\\x75\\x08\\x85\\xDB"
#define SIG_CSGOIsOtherEnemy_WINDOWS "\\x55\\x8B\\xEC\\x56\\x8B\\x75\\x08\\x57\\x8B\\xF9\\x85\\xF6\\x75\\x2A\\x5F\\x32\\xC0\\x5E\\x5D\\xC2\\x04\\x00\\x8B\\x47"


// CCSBot::OnAudibleEvent
#define NAME_OnAudibleEvent "CCSBot::OnAudibleEvent"
static Handle hDHookOnAudibleEvent = null;

#define SIG_OnAudibleEvent_LINUX "@_ZN6CCSBot14OnAudibleEventEP10IGameEventP11CBasePlayerf12PriorityTypebbPK6Vector"
#define SIG_OnAudibleEvent_WINDOWS "\\x55\\x8B\\xEC\\x83\\xEC\\x1C\\x56\\x8B\\x75\\x0C\\x57\\x8B\\xF9\\x85\\xF6"

#define SIG_CSGOOnAudibleEvent_LINUX "\\x55\\x89\\xE5\\x57\\x56\\x53\\x81\\xEC\\xAC\\x00\\x00\\x00\\x8B\\x5D\\x10\\x8B\\x75\\x08"
#define SIG_CSGOOnAudibleEvent_WINDOWS "\\x55\\x8B\\xEC\\x83\\xE4\\xF0\\x83\\xEC\\x2A\\x56\\x57\\x8B\\x7D\\x0C\\x8B\\xF1\\xF3\\x0F\\x11\\x5C\\x24"


// CCSBot::OnPlayerRadio
#define NAME_OnPlayerRadio "CCSBot::OnPlayerRadio"
//static Handle hDHookOnPlayerRadio = null;

#define SIG_OnPlayerRadio_LINUX "@_ZN6CCSBot13OnPlayerRadioEP10IGameEvent"
#define SIG_OnPlayerRadio_WINDOWS "\\x55\\x8B\\xEC\\x83\\xEC\\x0C\\x57\\x8B\\xF9\\x8B\\x07\\x8B\\x80\\x04\\x01\\x00\\x00\\xFF\\xD0\\x84\\xC0"

#define SIG_CSGOOnPlayerRadio_LINUX "\\x55\\x89\\xE5\\x83\\xEC\\x48\\x89\\x5D\\xF4\\x8B\\x5D\\x08\\x89\\x75\\xF8\\x8B\\x75\\x0C\\x89\\x7D\\xFC\\x8B\\x03\\x89\\x1C\\x24\\xFF\\x90\\x18\\x01\\x00\\x00\\x84\\xC0\\x75\\x2A\\x8B\\x5D\\xF4\\x8B\\x75\\xF8\\x8B\\x7D\\xFC\\x89\\xEC\\x5D\\xC3\\x8D\\xB4\\x26\\x00\\x00\\x00\\x00\\x8B\\x06\\xC7\\x44\\x24\\x08\\x00\\x00\\x00\\x00\\xC7\\x44\\x24\\x04\\x2A\\x2A\\x2A\\x2A\\x89\\x34\\x24\\xFF\\x50\\x1C\\x89\\x04\\x24\\xE8\\x2A\\x2A\\x2A\\x2A\\x85\\xC0"
#define SIG_CSGOOnPlayerRadio_WINDOWS "\\x55\\x8B\\xEC\\x83\\xEC\\x0C\\x56\\x8B\\xF1\\x8B\\x06\\x8B\\x80\\x14\\x01\\x00\\x00\\xFF\\xD0\\x84\\xC0\\x0F\\x2A\\x2A\\x2A\\x2A\\x2A\\x53\\x8B\\x5D\\x08\\x8B\\xCB"

// CCSBot::OnPlayerDeath
#define NAME_OnPlayerDeath "CCSBot::OnPlayerDeath"
//static Handle hDHookOnPlayerDeath = null;

#define SIG_OnPlayerDeath_LINUX "@_ZN6CCSBot13OnPlayerDeathEP10IGameEvent"
#define SIG_OnPlayerDeath_WINDOWS "\\x55\\x8B\\xEC\\x83\\xEC\\x28\\x57\\x8B\\xF9\\x8B\\x07\\x8B\\x80\\x04\\x01\\x00\\x00\\xFF\\xD0\\x84\\xC0"

#define SIG_CSGOOnPlayerDeath_LINUX "\\x55\\x89\\xE5\\x83\\xEC\\x78\\x89\\x5D\\xF4\\x8B\\x5D\\x08\\x89\\x7D\\xFC\\x8B\\x7D\\x0C"
#define SIG_CSGOOnPlayerDeath_WINDOWS "\\x55\\x8B\\xEC\\x83\\xE4\\xF8\\x83\\xEC\\x20\\x56\\x57\\x8B\\xF9\\x8B\\x07\\x8B"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_CSGO)
	{
		gameVar = GAME_CSGO;
		PrintToServer("WARNING: zr_stopbotsattacking_humans.smx only properly supports Counter-Strike: Source.");
		return APLRes_Success;
	}
	else if (GetEngineVersion() == Engine_CSS)
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
	
	if (gameVar != GAME_CSGO)
	{ CloseHandle(hDHookIsOtherEnemy); }
	
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
	}
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

public MRESReturn OnAudibleEvent_Pre(int client, Handle hParams)
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
		if (HasEntProp(client, Prop_Send, "m_bIsCoaching")) // TF2, CSGO?
			if (view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsCoaching"))) return false;
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
		
		/*for (int i = 0; i <= 2; i++)
		{
			WriteFileLine(fileHandle, "\"Games\"");
			WriteFileLine(fileHandle, "{");
			switch (i)
			{
				case GAME_CSS: WriteFileLine(fileHandle, "	\"cstrike\"");
				case GAME_CSGO: WriteFileLine(fileHandle, "	\"csgo\"");
			}
			WriteFileLine(fileHandle, "	{");
			WriteFileLine(fileHandle, "		\"Signatures\"");
			WriteFileLine(fileHandle, "		{");
			for (int j = 0; j <= 5; j++)
			{
				switch (j)
				{
					case 0: WriteFileLine(fileHandle, "			\"%s\"", NAME_InSameTeam);
					case 1: { if (gameVar == GAME_CSGO) WriteFileLine(fileHandle, "			\"%s\"", NAME_IsOtherEnemy); }
					case 2: WriteFileLine(fileHandle, "			\"%s\"", NAME_OnAudibleEvent);
					case 3: WriteFileLine(fileHandle, "			\"%s\"", NAME_OnPlayerRadio);
					case 4: WriteFileLine(fileHandle, "			\"%s\"", NAME_OnPlayerDeath);
				}
				WriteFileLine(fileHandle, "			{");
				WriteFileLine(fileHandle, "				\"library\"	\"server\"");
				char temp_str[64];
				switch (j)
				{
					temp_str
				}
				WriteFileLine(fileHandle, "			}");
			}
			WriteFileLine(fileHandle, "		}");
			WriteFileLine(fileHandle, "	}");
			WriteFileLine(fileHandle, "}");
		}*/
		
		WriteFileLine(fileHandle, "\"Games\"");
		WriteFileLine(fileHandle, "{");
		WriteFileLine(fileHandle, "	\"cstrike\"");
		WriteFileLine(fileHandle, "	{");
		WriteFileLine(fileHandle, "		\"Signatures\"");
		WriteFileLine(fileHandle, "		{");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_InSameTeam);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_InSameTeam_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_InSameTeam_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_InSameTeam_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_OnAudibleEvent);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_OnAudibleEvent_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_OnAudibleEvent_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_OnAudibleEvent_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_OnPlayerRadio);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_OnPlayerRadio_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_OnPlayerRadio_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_OnPlayerRadio_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_OnPlayerDeath);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_OnPlayerDeath_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_OnPlayerDeath_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_OnPlayerDeath_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "		}");
		WriteFileLine(fileHandle, "	}");
		WriteFileLine(fileHandle, "	\"csgo\"");
		WriteFileLine(fileHandle, "	{");
		WriteFileLine(fileHandle, "		\"Signatures\"");
		WriteFileLine(fileHandle, "		{");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_InSameTeam);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_CSGOInSameTeam_LINUX);
	//	WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_CSGOInSameTeam_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_CSGOInSameTeam_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_IsOtherEnemy);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_CSGOIsOtherEnemy_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_CSGOIsOtherEnemy_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_CSGOIsOtherEnemy_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_OnAudibleEvent);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_CSGOOnAudibleEvent_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_CSGOOnAudibleEvent_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_CSGOOnAudibleEvent_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_OnPlayerRadio);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_CSGOOnPlayerRadio_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_CSGOOnPlayerRadio_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_CSGOOnPlayerRadio_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_OnPlayerDeath);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_CSGOOnPlayerDeath_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_CSGOOnPlayerDeath_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_CSGOOnPlayerDeath_LINUX);
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
		if (gameVar == GAME_CSGO) DHookEnableDetour(hDHookIsOtherEnemy, false, IsOtherEnemy_Pre);
		DHookEnableDetour(hDHookOnAudibleEvent, false, OnAudibleEvent_Pre);
	}
	else
	{
		DHookDisableDetour(hDHookInSameTeam, false, InSameTeam_Pre);
		if (gameVar == GAME_CSGO) DHookDisableDetour(hDHookIsOtherEnemy, false, IsOtherEnemy_Pre);
		DHookDisableDetour(hDHookOnAudibleEvent, false, OnAudibleEvent_Pre);
	}
}

void PrepDHooks()
{
	if (hConf == null)
	{
		SetFailState("Error: Gamedata not found");
	}
	
	hDHookInSameTeam = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	DHookSetFromConf(hDHookInSameTeam, hConf, SDKConf_Signature, NAME_InSameTeam);
	DHookAddParam(hDHookInSameTeam, HookParamType_CBaseEntity);
	
	if (gameVar == GAME_CSGO)
	{
		hDHookIsOtherEnemy = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
		DHookSetFromConf(hDHookIsOtherEnemy, hConf, SDKConf_Signature, NAME_IsOtherEnemy);
		DHookAddParam(hDHookIsOtherEnemy, HookParamType_CBaseEntity);
	}
	
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
	DHookEnableDetour(hDHookOnPlayerRadio, false, OnPlayerRadio_Pre);
	
	hDHookOnPlayerDeath = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	DHookSetFromConf(hDHookOnPlayerDeath, hConf, SDKConf_Signature, NAME_OnPlayerDeath);
	DHookAddParam(hDHookOnPlayerDeath, HookParamType_Int);
	DHookEnableDetour(hDHookOnPlayerDeath, false, OnPlayerDeath_Pre);*/
}