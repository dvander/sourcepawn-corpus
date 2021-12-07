#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define GAMEDATA			"l4d2_OnGetSurvivorSet"
#define PLUGIN_VERSION 		"1.0"

Handle g_GetSurvivorSetForward;

public Plugin myinfo =
{
	name = "Get Survivor Set",
	author = "$atanic $pirit",
	description = "Creates L4D_OnGetSurvivorSet forward to be used by other plugins.",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	g_GetSurvivorSetForward = CreateGlobalForward("L4D_OnGetSurvivorSet", ET_Event, Param_CellByRef);
	
	// ====================================================================================================
	// Detour	-	CTerrorGameRules::GetSurvivorSet
	// ====================================================================================================
		
	// Create a hook from config.
	Handle hDetour_OnGetSurvivorSet = DHookCreateFromConf(hGameData, "CTerrorGameRules::GetSurvivorSet");
	if( !hDetour_OnGetSurvivorSet )
		SetFailState("Failed to setup detour for CTerrorGameRules::GetSurvivorSet");
	delete hGameData;
	
	// Add a pre hook on the function.
	if (!DHookEnableDetour(hDetour_OnGetSurvivorSet, true, Detour_OnGetSurvivorSet))
		SetFailState("Failed to detour OnGetSurvivorSet.");
}

// ====================================================================================================
// Function	-	CTerrorGameRules::GetSurvivorSet
// ====================================================================================================

public MRESReturn Detour_OnGetSurvivorSet(Handle hReturn)
{	
	// Build LogFile path
	char LogFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, LogFilePath, sizeof(LogFilePath), "logs/l4d2_OnGetSurvivorSet.txt");
	
	// Store the return value
	int originalreturn = DHookGetReturn(hReturn);
	
	int newreturn = originalreturn;
	
	LogToFile(LogFilePath, "Original return value %d.", newreturn);
	
	if(g_GetSurvivorSetForward)
	{
		Action result = Plugin_Continue;
		
		/* Start function call */
		Call_StartForward(g_GetSurvivorSetForward);

		/* Push parameters one at a time */
		Call_PushCellRef(newreturn);

		/* Finish the call, get the result */
		Call_Finish(result);
		
		if (result == Plugin_Handled)
		{
			LogToFile(LogFilePath, "New return value %d.", newreturn);
			DHookSetReturn(hReturn, newreturn);
			return MRES_Supercede;
		}
	}
	return MRES_Ignored;
}