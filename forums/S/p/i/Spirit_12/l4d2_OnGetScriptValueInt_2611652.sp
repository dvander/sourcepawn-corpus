#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define GAMEDATA			"l4d2_OnGetScriptValueInt"
#define PLUGIN_VERSION 		"1.0"

Handle g_GetScriptValueIntForward;

public Plugin myinfo =
{
	name = "Get Scrpt Value Int",
	author = "$atanic $pirit",
	description = "Creates GetScriptValueInt forward to be used by other plugins.",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	g_GetScriptValueIntForward = CreateGlobalForward("L4D_OnGetScriptValueInt", ET_Event, Param_String, Param_Cell);
	
	// ====================================================================================================
	// Detour	-	CDirector::GetScriptValue
	// ====================================================================================================
		
	// Create a hook from config.
	Handle hDetour_OnGetScriptValueInt = DHookCreateFromConf(hGameData, "CDirector::GetScriptValueInt");
	if( !hDetour_OnGetScriptValueInt )
		SetFailState("Failed to setup detour for CDirector::GetScriptValueInt");
	delete hGameData;
	
	// Add a pre hook on the function.
	if (!DHookEnableDetour(hDetour_OnGetScriptValueInt, false, Detour_OnGetScriptValueInt))
		SetFailState("Failed to detour OnGetScriptValueInt.");
}

// ====================================================================================================
// Function	-	CDirector::GetScriptValue
// ====================================================================================================

public MRESReturn Detour_OnGetScriptValueInt(Handle hReturn, Handle hParams)
{
	// Get the Key name
	char key[1024];
	DHookGetParamString(hParams, 1, key, sizeof(key));
	
	// Get the Int value
	int  num		= DHookGetParam(hParams, 2);
	
	Action result;
	
	/* Start function call */
	Call_StartForward(g_GetScriptValueIntForward);

	/* Push parameters one at a time */
	Call_PushString(key);
	Call_PushCell(num);

	/* Finish the call, get the result */
	Call_Finish(result);
	
	if(result == Plugin_Handled)
	{
		DHookSetReturn(hReturn, num);
		return MRES_Override;
	}
	return MRES_Ignored;
}