#include <sourcemod>
#define PLUGIN_VERSION  "1.0.5"
#define L4D_BCL_CONFIG  "configs/L4D_BCL.cfg"
#define MAX_VARLENGTH   64
#define MAX_VALUELENGTH 128
#pragma semicolon 1;
#pragma newdecls required;

char g_mode[16];
Handle mp_gamemode = INVALID_HANDLE;
Handle g_mode_kvorig = INVALID_HANDLE;
int OrigFlags;
bool IsL4D2 = false;

public Plugin myinfo={
	name="[L4D1 & L4D2] Bot Config Loader",
	author="Omixsat",
	description="Allow changing bot convars to use user-generated values",
	version=PLUGIN_VERSION,
	url="https://forums.alliedmods.net/showthread.php?p=2783210"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion Check_GEngine = GetEngineVersion();
	if(Check_GEngine == Engine_Left4Dead2)
		IsL4D2 = true;
	else if(Check_GEngine == Engine_Left4Dead)
		IsL4D2 = false;
	else
	{
		strcopy(error, err_max, "Plug-In is incompatible with this engine");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_botconfigloader_version", PLUGIN_VERSION, " Version of L4D Bot Config Loader on this server ", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	mp_gamemode = FindConVar("mp_gamemode");
	RemoveLauncherProperty("sb_temp_health_consider_factor");
	AddCheatProperty("sb_temp_health_consider_factor");
	RemoveLauncherProperty("sb_allow_leading");
	AddCheatProperty("sb_allow_leading");
	RemoveLauncherProperty("sb_toughness_buffer");
	AddCheatProperty("sb_toughness_buffer");
	RemoveLauncherProperty("sb_skill");
	AddCheatProperty("sb_skill");
	if (IsL4D2 == true)
	{
		RemoveLauncherProperty("sb_melee_approach_victim");
		AddCheatProperty("sb_melee_approach_victim");
	}
	IdentifyGameMode();
	g_mode_kvorig = CreateKeyValues("GameModeCvars_Orig");  // store original values
}

public void OnPluginEnd()
{
	ResetGameModePrefs();
}


public void OnMapStart()
{
	IdentifyGameMode();
	if(StrEqual(g_mode, "coop", false) || StrEqual(g_mode,"teamversus", false) || StrEqual(g_mode, "versus", false) || StrEqual(g_mode, "survival", false) || StrEqual(g_mode, "realism", false) || StrEqual(g_mode, "scavenge", false))
	{
		GetGameModePrefs();
		PrintToServer("[BCL] INFO: Loaded L4D_BCL %s configuration", g_mode);
	}
	else
	{
		PrintToServer("[BCL] INFO: Loading custom game mode - %s", g_mode);
		GetGameModePrefs();
	}
}

public void OnMapEnd()
{
	ResetGameModePrefs();
}

int GetGameModePrefs()
{
	int BCLChangedConVars = 0;	// how many cvars were changed for g_mode (iNumChanged)

	// reopen original keyvalues for clean slate:
	if (g_mode_kvorig != INVALID_HANDLE) { delete g_mode_kvorig; }
	g_mode_kvorig = CreateKeyValues("GameModeCvars_Orig");	  // store original values for game mode
	
	
	// build path to current config's keyvalues file
	char usePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, usePath, sizeof(usePath), "%s", L4D_BCL_CONFIG);
	
	if (!FileExists(usePath)) {
		PrintToServer("[BCL] ERROR: File does not exist! (%s)", usePath);
		return 0;
	}

	PrintToServer("[BCL] Attempting keyvalue read (from [%s])...", usePath);
	Handle BCL_GM = CreateKeyValues("GameModes");
	FileToKeyValues(BCL_GM, usePath);
	
	if (BCL_GM == INVALID_HANDLE) {
		
		PrintToServer("[BCL] ERROR: Couldn't read file.");
		return 0;
	}
	
	if (!KvJumpToKey(BCL_GM, g_mode))
	{
		// no special settings for game mode
		delete BCL_GM;
		
		PrintToServer("[BCL] ERROR: Couldn't find this mode (%s) from %s", g_mode, L4D_BCL_CONFIG);
		
		return 0;
	}

	char tmpKey[MAX_VARLENGTH];
	char BCL_ConfValue[MAX_VALUELENGTH];
	char BCL_Defaults[MAX_VALUELENGTH];
	Handle hConVar = INVALID_HANDLE;
	
	
	if (KvGotoFirstSubKey(BCL_GM, false))							  // false to get values
	{
		do
		{
			// read keys
			KvGetSectionName(BCL_GM, tmpKey, sizeof(tmpKey));			  // the subkey is a key-value pair, so get this to get the 'convar'
			
			PrintToServer("[BCL] INFO: ConVar found: [%s]", tmpKey);
			
			// is it a convar?
			hConVar = FindConVar(tmpKey);
			
			if (hConVar != INVALID_HANDLE)
			{
				
				KvGetString(BCL_GM, NULL_STRING, BCL_ConfValue, sizeof(BCL_ConfValue), "[:none:]");

				if (!StrEqual(BCL_ConfValue,"[:none:]"))
				{
					GetConVarString(hConVar, BCL_Defaults, sizeof(BCL_Defaults));
						
					if (!StrEqual(BCL_ConfValue,BCL_Defaults))
					{
						// different, save the old
						BCLChangedConVars++;
						KvSetString(g_mode_kvorig, tmpKey, BCL_Defaults);
						SetConVarString(hConVar, BCL_ConfValue);
					}
				}
			}
			else
			{
				
				PrintToServer("[BCL] ERROR: ConVar doesn't exist: [%s]", tmpKey);
				
			}
		} while (KvGotoNextKey(BCL_GM, false));
	} 

	delete BCL_GM;
	return BCLChangedConVars;
}

void IdentifyGameMode()
{
	GetCurrentGameMode(g_mode, sizeof(g_mode));
}

void GetCurrentGameMode(char[] mode, int maxlength)
{
	if(mp_gamemode != INVALID_HANDLE)
	{
		GetConVarString(mp_gamemode, mode, maxlength);
		PrintToServer("Current Game mode: %s", g_mode);
	}
	else
		PrintToServer("Not in a valid game mode");
	return;
}

stock void RemoveCheatProperty(char cmd[50])
{
	OrigFlags = GetCommandFlags(cmd);
	SetCommandFlags(cmd, OrigFlags & ~FCVAR_CHEAT);
}

stock void AddCheatProperty(char cmd[50])
{
	OrigFlags = GetCommandFlags(cmd);
	SetCommandFlags(cmd, OrigFlags |= FCVAR_CHEAT);
}

stock void RemoveLauncherProperty(char cmd[50])
{
	OrigFlags = GetCommandFlags(cmd);
	SetCommandFlags(cmd, OrigFlags & ~FCVAR_DEVELOPMENTONLY);
}

void ResetGameModePrefs()
{
	KvRewind(g_mode_kvorig);
	
	// find all cvar keys and reset to original values
	char tmpKey[64];
	char BCL_Defaults[512];
	Handle hConVar = INVALID_HANDLE;
	
	if (KvGotoFirstSubKey(g_mode_kvorig, false))							  // false to get values
	{
		do
		{
			// read keys
			KvGetSectionName(g_mode_kvorig, tmpKey, sizeof(tmpKey));	  // the subkey is a key-value pair, so get this to get the 'convar'
			
			if (StrEqual(tmpKey, "__EOF__")) { 
				PrintToServer("[BCL] INFO: KV original settings, all read. (EOF)."); //safety net in case all stored values are read but not available
				break;
			}
			else
			{
				// is it a convar?
				hConVar = FindConVar(tmpKey);
				
				if (hConVar != INVALID_HANDLE) {
					
					KvGetString(g_mode_kvorig, NULL_STRING, BCL_Defaults, sizeof(BCL_Defaults), "[:none:]");

					if (!StrEqual(BCL_Defaults,"[:none:]")) {
						SetConVarString(hConVar, BCL_Defaults);
						PrintToServer("[BCL] INFO: ConVar reset to default: [%s])", tmpKey);
					}
				} else {
					PrintToServer("[BCL] ERROR: ConVar doesn't exist: [%s]", tmpKey);
				}
			}
		} while (KvGotoNextKey(g_mode_kvorig, false));
	}
}