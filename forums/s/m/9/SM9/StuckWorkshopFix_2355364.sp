/****************************************************************************************************
[CSGO] STUCK WORKSHOP FIX v0.2
*****************************************************************************************************/

/****************************************************************************************************
CHANGELOG
*****************************************************************************************************
* 
* 0.1 	     - 
* 
* 				First Public Release.		
* 0.2	     - 
* 
* 				Fixed force map change.
*				Added cvar to control time before forcing map change (swf_force_time "30").
*				Attempt to kill timer on map start as a safety measure.
*/

/****************************************************************************************************
TO BE DONE
*****************************************************************************************************
* - Detect if workshop is actually down or not.
*/

/****************************************************************************************************
INCLUDES
*****************************************************************************************************/

/****************************************************************************************************
DEFINES
*****************************************************************************************************/
#define PLUGIN_AUTHOR "SM9"
#define VERSION "0.2"

/****************************************************************************************************
ETIQUETTE.
*****************************************************************************************************/
#pragma newdecls required // To be moved before includes one day.
#pragma semicolon 1

/****************************************************************************************************
HANDLES & CONVARS.
*****************************************************************************************************/
Handle g_hMapTimer = null;
Handle g_hNextLevel = null;
ConVar g_hCvarFallBackMap = null;
ConVar g_hCvarChangeTime = null;

/****************************************************************************************************
PLUGIN INFO.
*****************************************************************************************************/
public Plugin myinfo = 
{
	name = "Stuck Workshop Fix",
	author = PLUGIN_AUTHOR,
	description = "Changes to the none workshop variant of map if workshop is down.",
	version = VERSION,
	url = "www.fragdeluxe.com"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO) {
		SetFailState("This plugin is for currently for CSGO only.");
	}
	
	g_hNextLevel = FindConVar("nextlevel");
	g_hCvarFallBackMap = CreateConVar("swf_fallback_map", "de_inferno", "The map to change to if the workshop alternative is not found.");
	g_hCvarChangeTime = CreateConVar("swf_force_time", "30", "Time before forcing a map change.");
	
	CreateConVar("swf_version", VERSION, "Current version of Stuck Workshop Fix", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	AutoExecConfig(true, "stuckworkshopfix");
	
	HookEvent("cs_win_panel_match", Event_CsWinPanelMatch);
}

public void Event_CsWinPanelMatch(Handle hEvent, char[] chName, bool bDontBroadcast) 
{
	HookConVarChange(g_hNextLevel, OnNextLevel);
}

public void OnNextLevel(Handle hConVar, const char[] chOldValue, const char[] chNewValue) 
{
	char chBuffer[128]; GetConVarString(hConVar, chBuffer, 128);
	RemoveMapPath(chBuffer, chBuffer, 128);
	
	DataPack dPack; CreateDataTimer(float(GetConVarInt(g_hCvarChangeTime)), Timer_FixMap, dPack, TIMER_FLAG_NO_MAPCHANGE);
	dPack.WriteString(chBuffer); ResetPack(dPack);
	
	UnhookConVarChange(g_hNextLevel, OnNextLevel);
}

public Action Timer_FixMap(Handle hTimer, DataPack dPack)
{
	char chBuffer[128]; char chBuffer2[128];
	ReadPackString(dPack, chBuffer, 128); Format(chBuffer2, 128, "maps/%s.bsp", chBuffer);
	
	if(!FileExists(chBuffer2)) {
		GetConVarString(g_hCvarFallBackMap, chBuffer, 128);
		LogError("[SWF] Map %s not found, Using fallback map %s", chBuffer2, chBuffer);
		Format(chBuffer2, 128, "maps/%s.bsp", chBuffer);
		
		if(!FileExists(chBuffer2)) {
			LogError("[SWF] (CRITICAL) Fallback map %s not found, Attempting map change to de_dust2", chBuffer);
			strcopy(chBuffer, 128, "de_dust2");
		}
	}
	
	ServerCommand("map %s", chBuffer);
	
	KillTimer2(g_hMapTimer);
	return Plugin_Stop;
}

public void OnMapEnd(){
	KillTimer2(g_hMapTimer);
}

public void OnMapStart(){
	KillTimer2(g_hMapTimer);
}

public void KillTimer2(Handle hTimer)
{
	if(hTimer == null || hTimer == INVALID_HANDLE) {
		return;
	}
	
	KillTimer(g_hMapTimer);
	g_hMapTimer = null;
}

/****************************************************************************************************
Thanks Powerlord.
*****************************************************************************************************/
stock bool RemoveMapPath(const char[] chMap, char[] chDestination, int iMaxLen)
{
	if (strlen(chMap) < 1) {
		ThrowError("Bad map name: %s", chMap);
	}
	
	int iPos = FindCharInString(chMap, '/', true);
	
	if (iPos == -1)
	{
		iPos = FindCharInString(chMap, '\\', true);
		
		if (iPos == -1)
		{
			strcopy(chDestination, iMaxLen, chMap);
			return false;
		}
	}
	
	strcopy(chDestination, iMaxLen, chMap[iPos+1]);
	return true;
}